local protocol = require("commit-generator.codex.protocol")
local storage_module = require("commit-generator.codex.storage")

local M = {}

local function error(code, message, metadata)
  return { code = code, message = message, metadata = metadata }
end

local storage_categories = {
  ["bridge-unavailable"] = true,
  ["bridge-build"] = true,
  ["bridge-process"] = true,
  ["keychain"] = true,
}

local function storage_error(category)
  category = storage_categories[category] and category or "keychain"
  return error("storage", "credential storage failed (" .. category .. ")", { storage = category })
end

local function default_now()
  return math.floor(vim.uv.hrtime() / 1000000)
end

local function credential_from_json(value)
  local ok, credential = pcall(vim.json.decode, value or "")
  if not ok or type(credential) ~= "table" then
    return nil
  end
  if type(credential.access) ~= "string" or credential.access == ""
    or type(credential.refresh) ~= "string" or credential.refresh == ""
    or type(credential.account_id) ~= "string" or credential.account_id == ""
    or type(credential.expires) ~= "number" then
    return nil
  end
  return credential
end

local function encode_credential(credential)
  return vim.json.encode({
    access = credential.access,
    refresh = credential.refresh,
    account_id = credential.account_id,
    expires = credential.expires,
  })
end

local function clean_message(message)
  if type(message) ~= "string" then
    return nil
  end
  message = vim.trim(message):gsub("^```[^\n]*\n", ""):gsub("\n```$", "")
  message = message:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
  message = vim.trim(message)
  return message ~= "" and message or nil
end

local function is_cancelled(options)
  if type(options.cancelled) ~= "function" then
    return false
  end
  local ok, cancelled = pcall(options.cancelled)
  return ok and cancelled == true
end

function M.new(opts)
  opts = opts or {}
  local storage = opts.storage or storage_module.new({ backend = "auto" })
  local system = opts.system or vim.system
  local system_async = opts.system_async or vim.system
  local open_system = opts.open_system or system
  local now = opts.now or default_now
  local defer = opts.defer or vim.defer_fn
  -- vim.system on_exit callbacks run in a fast event; dispatch UI-facing async work first.
  local schedule = opts.schedule or vim.schedule
  local wait = opts.wait or function(milliseconds)
    vim.wait(milliseconds, function()
      return false
    end, 50)
  end
  local notify = opts.notify or function(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Commit generator Codex" })
  end
  local device_login_ui = opts.device_login_ui or require("commit-generator.codex.device_login")
  local model = opts.model or protocol.default_model
  local reasoning = opts.reasoning or "low"
  -- Device authorization waits for user interaction, unlike a generation request.
  local login_timeout_ms = opts.login_timeout_ms or opts.device_timeout_ms or 15 * 60 * 1000
  assert(type(model) == "string" and model ~= "", "model must be a non-empty string")
  assert(protocol.is_reasoning_effort(reasoning), "reasoning must be none, minimal, low, medium, high, xhigh, or max")

  local function run_prepared(prepared, options, runner)
    if is_cancelled(options) then
      return nil, "cancelled"
    end
    local process_options = { text = true, stdin = prepared.stdin }
    if options.timeout_ms then
      process_options.timeout = options.timeout_ms
    end
    local process = runner(prepared.argv, process_options)
    local result = process:wait()
    if is_cancelled(options) then
      return nil, "cancelled"
    end
    if result.code ~= 0 or result.signal ~= 0 then
      return nil, result.code == 124 and "timeout" or "transport"
    end
    return result.stdout or ""
  end

  local function run_curl(prepared, options)
    local stdout, run_error = run_prepared(prepared, options, system)
    if not stdout then
      return nil, nil, run_error
    end
    local body, status = protocol.split_curl_response(stdout)
    if not body then
      return nil, nil, "invalid-response"
    end
    return body, status
  end

  local function run_prepared_async(prepared, options, callback)
    local completed = false
    local function complete(stdout, run_error)
      if completed then
        return
      end
      completed = true
      schedule(function()
        callback(stdout, run_error)
      end)
    end

    if is_cancelled(options) then
      complete(nil, "cancelled")
      return
    end
    local process_options = { text = true, stdin = prepared.stdin }
    if options.timeout_ms then
      process_options.timeout = options.timeout_ms
    end
    local ok = pcall(system_async, prepared.argv, process_options, function(result)
      if is_cancelled(options) then
        complete(nil, "cancelled")
        return
      end
      if type(result) ~= "table" or result.code ~= 0 or (result.signal and result.signal ~= 0) then
        complete(nil, type(result) == "table" and result.code == 124 and "timeout" or "transport")
        return
      end
      complete(result.stdout or "")
    end)
    if not ok then
      complete(nil, "transport")
    end
  end

  local function run_json_async(prepared, options, callback)
    run_prepared_async(prepared, options, function(stdout, run_error)
      if not stdout then
        callback(nil, nil, run_error)
        return
      end
      local body, status = protocol.split_curl_response(stdout)
      if not body then
        callback(nil, nil, "invalid-response")
        return
      end
      local ok, decoded = pcall(vim.json.decode, body)
      if not ok or type(decoded) ~= "table" then
        callback(nil, status, "invalid-response")
        return
      end
      callback(decoded, status)
    end)
  end

  local function run_json(prepared, options)
    local body, status, run_error = run_curl(prepared, options)
    if not body then
      return nil, status, run_error
    end
    local ok, decoded = pcall(vim.json.decode, body)
    if not ok or type(decoded) ~= "table" then
      return nil, status, "invalid-response"
    end
    return decoded, status
  end

  local function remaining_options(options, deadline)
    local remaining = deadline - now()
    if remaining <= 0 then
      return nil
    end
    return vim.tbl_extend("force", options, { timeout_ms = remaining })
  end

  local function public_transport_error(prefix, reason)
    if reason == "cancelled" then
      return error("cancelled", "request cancelled")
    end
    if reason == "timeout" then
      return error("timeout", prefix .. " timed out")
    end
    return error("transport", prefix .. " could not be completed")
  end

  local function credential_from_token(token)
    if type(token) ~= "table" or type(token.access_token) ~= "string" or token.access_token == ""
      or type(token.refresh_token) ~= "string" or token.refresh_token == ""
      or type(token.expires_in) ~= "number" or token.expires_in < 0 then
      return nil
    end
    local account_id = protocol.decode_jwt_account_id(token.access_token)
    if not account_id then
      return nil
    end
    return {
      access = token.access_token,
      refresh = token.refresh_token,
      account_id = account_id,
      expires = now() + token.expires_in * 1000,
    }
  end

  local function persist(credential)
    local ok, stored, storage_failure = pcall(storage.put, storage, encode_credential(credential))
    if not ok or stored ~= true then
      return nil, storage_error(storage_failure)
    end
    return true
  end

  local function load_credential()
    local ok, value = pcall(storage.get, storage)
    if not ok or not value then
      return nil, error("not-authenticated", "no stored direct-Codex credential")
    end
    local credential = credential_from_json(value)
    if not credential then
      return nil, error("invalid-credential", "stored direct-Codex credential is invalid")
    end
    return credential
  end

  local function refresh(credential, options)
    local token, status, reason = run_json(protocol.build_refresh_command(credential.refresh), options)
    if not token then
      return nil, public_transport_error("token refresh", reason)
    end
    if status ~= 200 then
      return nil, error("refresh-failed", "token refresh failed", { http_status = status })
    end
    local refreshed = credential_from_token(token)
    if not refreshed then
      return nil, error("invalid-credential", "token refresh returned invalid credentials")
    end
    local saved, save_error = persist(refreshed)
    if not saved then
      return nil, save_error
    end
    return refreshed
  end

  local client = { storage = storage, model = model, reasoning = reasoning }

  local function close_login_ui(handle)
    if type(handle) == "function" then
      pcall(handle)
    elseif type(handle) == "table" and type(handle.close) == "function" then
      pcall(handle.close)
    end
  end

  function client:login(options)
    options = options or {}
    local deadline = now() + (options.timeout_ms or login_timeout_ms)
    local request_options = remaining_options(options, deadline)
    if not request_options then
      return nil, error("timeout", "device authorization timed out")
    end
    local device, status, reason = run_json(protocol.build_device_start_command(), request_options)
    if not device then
      if reason == "cancelled" or reason == "timeout" or reason == "transport" then
        return nil, public_transport_error("device authorization", reason)
      end
      if status then
        return nil, error("device-start-failed", "device authorization could not be started", { http_status = status })
      end
      return nil, error("invalid-response", "device authorization returned an invalid response")
    end
    if status ~= 200 then
      return nil, error("device-start-failed", "device authorization could not be started", { http_status = status })
    end
    if type(device.device_auth_id) ~= "string" or device.device_auth_id == ""
      or type(device.user_code) ~= "string" or device.user_code == "" or type(tonumber(device.interval)) ~= "number" then
      return nil, error("invalid-response", "device authorization returned an invalid response")
    end

    local interval = math.max(1, tonumber(device.interval))
    local function open_url()
      local opened = open_system(protocol.build_open_command(protocol.device_verification_url).argv, { text = true }):wait()
      if opened.code ~= 0 or opened.signal ~= 0 then
        return nil, "could not open the device authorization page"
      end
      return true
    end
    local shown, login_ui = pcall(device_login_ui.show, {
      url = protocol.device_verification_url,
      user_code = device.user_code,
      open_url = open_url,
      notify = notify,
    })
    if not shown then
      notify("OpenAI device authorization: enter code " .. device.user_code .. " at " .. protocol.device_verification_url, vim.log.levels.INFO)
    end
    local function finish(value, login_error)
      if shown then
        close_login_ui(login_ui)
      end
      return value, login_error
    end

    while now() < deadline do
      if is_cancelled(options) then
        return finish(nil, error("cancelled", "request cancelled"))
      end
      wait(interval * 1000)
      request_options = remaining_options(options, deadline)
      if not request_options then
        break
      end
      local response, poll_status, poll_reason = run_json(protocol.build_device_poll_command(device.device_auth_id, device.user_code), request_options)
      if not response then
        if poll_reason == "cancelled" or poll_reason == "timeout" or poll_reason == "transport" then
          return finish(nil, public_transport_error("device authorization", poll_reason))
        end
        if poll_status ~= 403 and poll_status ~= 404 then
          return finish(nil, error("device-poll-failed", "device authorization polling failed", poll_status and { http_status = poll_status } or nil))
        end
      elseif poll_status == 200 then
        if type(response.authorization_code) ~= "string" or response.authorization_code == ""
          or type(response.code_verifier) ~= "string" or response.code_verifier == "" then
          return finish(nil, error("invalid-response", "device authorization returned an invalid response"))
        end
        request_options = remaining_options(options, deadline)
        if not request_options then
          break
        end
        local token, exchange_status, exchange_reason = run_json(protocol.build_token_exchange_command(response.authorization_code, response.code_verifier), request_options)
        if not token then
          if exchange_reason == "cancelled" or exchange_reason == "timeout" or exchange_reason == "transport" then
            return finish(nil, public_transport_error("token exchange", exchange_reason))
          end
          return finish(nil, error("invalid-response", "token exchange returned an invalid response"))
        end
        if exchange_status ~= 200 then
          return finish(nil, error("token-exchange-failed", "token exchange failed", { http_status = exchange_status }))
        end
        local credential = credential_from_token(token)
        if not credential then
          return finish(nil, error("invalid-credential", "token exchange returned invalid credentials"))
        end
        local saved, save_error = persist(credential)
        return finish(saved, save_error)
      elseif poll_status ~= 403 and poll_status ~= 404 then
        local poll_error = type(response.error) == "string" and response.error or type(response.error) == "table" and response.error.code
        if poll_error == "slow_down" then
          interval = interval + 5
        elseif poll_error ~= "deviceauth_authorization_pending" then
          return finish(nil, error("device-poll-failed", "device authorization polling failed", { http_status = poll_status }))
        end
      end
    end
    return finish(nil, error("timeout", "device authorization timed out"))
  end

  --- Start device authorization without blocking Neovim's UI event loop.
  --- @param options? table {timeout_ms?: number, cancelled?: fun(): boolean} Device-flow deadline, not generation timeout.
  --- @param callback? fun(ok: boolean|nil, error: table|nil)
  function client:login_async(options, callback)
    if type(options) == "function" then
      callback, options = options, {}
    end
    options = options or {}
    callback = callback or function() end

    local deadline = now() + (options.timeout_ms or login_timeout_ms)
    local shown, login_ui, finished = false, nil, false
    local device_auth_id, user_code, interval
    local schedule_poll

    local function finish(value, login_error)
      if finished then
        return
      end
      finished = true
      schedule(function()
        if shown then
          close_login_ui(login_ui)
        end
        callback(value, login_error)
      end)
    end

    local function request_options()
      local request = remaining_options(options, deadline)
      if not request then
        finish(nil, error("timeout", "device authorization timed out"))
      end
      return request
    end

    local function open_url()
      local opened = open_system(protocol.build_open_command(protocol.device_verification_url).argv, { text = true }):wait()
      if opened.code ~= 0 or opened.signal ~= 0 then
        return nil, "could not open the device authorization page"
      end
      return true
    end

    local function exchange(response)
      local request = request_options()
      if not request or finished then
        return
      end
      run_json_async(protocol.build_token_exchange_command(response.authorization_code, response.code_verifier), request, function(token, status, reason)
        if finished then
          return
        end
        if not token then
          if reason == "cancelled" or reason == "timeout" or reason == "transport" then
            finish(nil, public_transport_error("token exchange", reason))
          else
            finish(nil, error("invalid-response", "token exchange returned an invalid response"))
          end
          return
        end
        if status ~= 200 then
          finish(nil, error("token-exchange-failed", "token exchange failed", { http_status = status }))
          return
        end
        local credential = credential_from_token(token)
        if not credential then
          finish(nil, error("invalid-credential", "token exchange returned invalid credentials"))
          return
        end
        local saved, save_error = persist(credential)
        finish(saved, save_error)
      end)
    end

    schedule_poll = function()
      if finished then
        return
      end
      if is_cancelled(options) then
        finish(nil, error("cancelled", "request cancelled"))
        return
      end
      local remaining = deadline - now()
      if remaining <= 0 then
        finish(nil, error("timeout", "device authorization timed out"))
        return
      end
      local scheduled = pcall(defer, function()
        if finished then
          return
        end
        local request = request_options()
        if not request or finished then
          return
        end
        run_json_async(protocol.build_device_poll_command(device_auth_id, user_code), request, function(response, status, reason)
          if finished then
            return
          end
          if not response then
            if reason == "cancelled" or reason == "timeout" or reason == "transport" then
              finish(nil, public_transport_error("device authorization", reason))
            elseif status ~= 403 and status ~= 404 then
              finish(nil, error("device-poll-failed", "device authorization polling failed", status and { http_status = status } or nil))
            else
              schedule_poll()
            end
            return
          end
          if status == 200 then
            if type(response.authorization_code) ~= "string" or response.authorization_code == ""
              or type(response.code_verifier) ~= "string" or response.code_verifier == "" then
              finish(nil, error("invalid-response", "device authorization returned an invalid response"))
              return
            end
            exchange(response)
            return
          end
          if status ~= 403 and status ~= 404 then
            local poll_error = type(response.error) == "string" and response.error
              or type(response.error) == "table" and response.error.code
            if poll_error == "slow_down" then
              interval = interval + 5
            elseif poll_error ~= "deviceauth_authorization_pending" then
              finish(nil, error("device-poll-failed", "device authorization polling failed", { http_status = status }))
              return
            end
          end
          schedule_poll()
        end)
      end, math.min(interval * 1000, remaining))
      if not scheduled then
        finish(nil, error("transport", "device authorization could not be completed"))
      end
    end

    local request = request_options()
    if not request or finished then
      return true
    end
    run_json_async(protocol.build_device_start_command(), request, function(device, status, reason)
      if finished then
        return
      end
      if not device then
        if reason == "cancelled" or reason == "timeout" or reason == "transport" then
          finish(nil, public_transport_error("device authorization", reason))
        elseif status then
          finish(nil, error("device-start-failed", "device authorization could not be started", { http_status = status }))
        else
          finish(nil, error("invalid-response", "device authorization returned an invalid response"))
        end
        return
      end
      if status ~= 200 then
        finish(nil, error("device-start-failed", "device authorization could not be started", { http_status = status }))
        return
      end
      if type(device.device_auth_id) ~= "string" or device.device_auth_id == ""
        or type(device.user_code) ~= "string" or device.user_code == "" or type(tonumber(device.interval)) ~= "number" then
        finish(nil, error("invalid-response", "device authorization returned an invalid response"))
        return
      end

      device_auth_id, user_code = device.device_auth_id, device.user_code
      interval = math.max(1, tonumber(device.interval))
      local ui_ok, ui_handle = pcall(device_login_ui.show, {
        url = protocol.device_verification_url,
        user_code = device.user_code,
        open_url = open_url,
        notify = notify,
      })
      shown, login_ui = ui_ok, ui_handle
      if not ui_ok then
        notify("OpenAI device authorization: enter code " .. device.user_code .. " at " .. protocol.device_verification_url, vim.log.levels.INFO)
      end
      schedule_poll()
    end)
    return true
  end

  function client:status()
    local ok, state = pcall(storage.status, storage)
    state = ok and state or {}
    return {
      backend = state.backend or storage_module.backend,
      bridge_installed = state.bridge_installed == true,
      credential_state = state.credential_state or "not-inspected",
      model = model,
    }
  end

  function client:logout()
    local ok, deleted = pcall(storage.delete, storage)
    if not ok or deleted ~= true then
      return nil, error("storage", "credential removal failed")
    end
    return true
  end

  function client:generate(prompt, options)
    if type(prompt) ~= "string" or prompt == "" then
      return nil, error("invalid-prompt", "prompt must be non-empty")
    end
    if type(options) == "string" then
      options = { model = options }
    else
      options = options or {}
    end
    if options.model ~= nil and (type(options.model) ~= "string" or options.model == "") then
      return nil, error("invalid-model", "model must be a non-empty string")
    end
    if options.timeout_ms ~= nil and (type(options.timeout_ms) ~= "number" or options.timeout_ms <= 0) then
      return nil, error("invalid-timeout", "timeout must be a positive number of milliseconds")
    end
    if is_cancelled(options) then
      return nil, error("cancelled", "request cancelled")
    end
    local deadline = options.timeout_ms and now() + options.timeout_ms or nil
    local request_options = deadline and remaining_options(options, deadline) or options
    if not request_options then
      return nil, error("timeout", "Codex generation timed out")
    end
    local credential, credential_error = load_credential()
    if not credential then
      return nil, credential_error
    end
    local refreshed, refresh_error = refresh(credential, request_options)
    if not refreshed then
      return nil, refresh_error
    end
    request_options = deadline and remaining_options(options, deadline) or options
    if not request_options then
      return nil, error("timeout", "Codex generation timed out")
    end
    local body, status, reason = run_curl(protocol.build_curl_command(protocol.build_request(prompt, options.model or model, reasoning), refreshed), request_options)
    if not body then
      return nil, public_transport_error("Codex generation", reason)
    end
    if status ~= 200 then
      local metadata = protocol.error_metadata(body)
      metadata.http_status = status
      return nil, error("generation-failed", "Codex generation failed", metadata)
    end
    local events = protocol.parse_sse(body)
    local metadata = protocol.response_metadata(events)
    metadata.http_status = status
    if metadata.failed then
      return nil, error("generation-failed", "Codex generation failed", metadata)
    end
    local text = clean_message(protocol.response_text(events))
    if not metadata.completed or not text then
      return nil, error("incomplete-response", "Codex generation returned no completed text", metadata)
    end
    return text
  end

  return client
end

return M
