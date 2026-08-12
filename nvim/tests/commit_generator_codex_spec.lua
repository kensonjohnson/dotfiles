local source = debug.getinfo(1, "S").source:sub(2)
vim.opt.rtp:append(vim.fn.fnamemodify(source, ":p:h:h"))

local codex = require("commit-generator.codex")
local device_login_ui = require("commit-generator.codex.device_login")
local protocol = require("commit-generator.codex.protocol")
local storage_module = require("commit-generator.codex.storage")

local function assert_true(value, message)
  assert(value, message or "assertion failed")
end

local function process(stdout, code, signal)
  return {
    wait = function()
      return { stdout = stdout or "", stderr = "ignored", code = code or 0, signal = signal or 0 }
    end,
  }
end

local function response(body, status)
  return body .. "\n__DIRECT_CODEX_HTTP_STATUS__:" .. status .. "\n"
end

local function jwt(account)
  local payload = vim.base64.encode(vim.json.encode({ [protocol.account_claim] = account }))
    :gsub("+", "-"):gsub("/", "_"):gsub("=", "")
  return "header." .. payload .. ".signature"
end

local ui_maps, ui_closes, ui_valid = {}, 0, true
local login_handle = device_login_ui.show({
  url = protocol.device_verification_url,
  user_code = "ABCD-EFGH",
  open_url = function()
    return true
  end,
  api = {
    nvim_list_uis = function()
      return { { width = 100, height = 40 } }
    end,
    nvim_create_buf = function()
      return 11
    end,
    nvim_open_win = function()
      return 12
    end,
    nvim_win_get_buf = function()
      return 11
    end,
    nvim_set_option_value = function() end,
    nvim_buf_set_lines = function() end,
    nvim_win_is_valid = function()
      return ui_valid
    end,
    nvim_win_close = function()
      ui_valid = false
      ui_closes = ui_closes + 1
    end,
  },
  fn = { strdisplaywidth = function(text)
    return #text
  end, setreg = function() end },
  keymap = { set = function(_, lhs, callback)
    ui_maps[lhs] = callback
  end },
  notify = function() end,
  levels = { INFO = 1 },
})
assert_true(login_handle.win == 12 and type(login_handle.close) == "function", "device login returns a close handle")
ui_maps.q()
ui_maps["<Esc>"]()
login_handle.close()
assert_true(ui_closes == 1, "device login close handle is idempotent")

local credential = { access = "test-access-token", account_id = "test-account" }
local prepared = protocol.build_curl_command(protocol.build_request("Summarize staged changes."), credential)
assert_true(prepared.argv[1] == "curl")
assert_true(not table.concat(prepared.argv, " "):find(credential.access, 1, true), "access token leaked to argv")
assert_true(prepared.stdin:find(credential.access, 1, true), "access token must use curl stdin")
assert_true(prepared.stdin:find("chatgpt-account-id", 1, true))
assert_true(protocol.decode_jwt_account_id(jwt("account-from-jwt")) == "account-from-jwt")

local expected_bridge_source = vim.fn.fnamemodify(source, ":p:h:h") .. "/native/commit-generator-codex-keychain.swift"
assert_true(storage_module.bridge_source_path() == expected_bridge_source, "bridge source must resolve from the config root")
assert_true(vim.fn.filereadable(storage_module.bridge_source_path()) == 1, "bridge source must be readable from a symlinked config")

local function storage_put_error(resolve_bridge, system)
  local storage = storage_module.new({ resolve_bridge = resolve_bridge, system = system })
  local _, err = storage:put("test credential value")
  return err
end

assert_true(storage_put_error(function()
  return nil, "bridge-unavailable"
end) == "bridge-unavailable", "missing bridge must report its safe category")
assert_true(storage_put_error(function()
  return nil, "bridge-build"
end) == "bridge-build", "failed bridge build must report its safe category")
assert_true(storage_put_error(function()
  return "/mock/keychain-bridge"
end, function()
  return process("", 1)
end) == "bridge-process", "failed bridge process must report its safe category")
assert_true(storage_put_error(function()
  return "/mock/keychain-bridge"
end, function()
  return process(vim.json.encode({ ok = false, error = "keychain-failure" }))
end) == "keychain", "Keychain failure must report its safe category")

local bridge_calls, bridge_secret = {}, "test credential value"
local keychain = storage_module.new({
  resolve_bridge = function()
    return "/mock/keychain-bridge"
  end,
  system = function(argv, opts)
    assert_true(#argv == 1 and argv[1] == "/mock/keychain-bridge", "bridge argv must stay constant")
    assert_true(opts.env == nil, "bridge must not receive a credential environment")
    assert_true(not table.concat(argv, " "):find(bridge_secret, 1, true), "credential leaked to bridge argv")
    local request = vim.json.decode(opts.stdin)
    table.insert(bridge_calls, request)
    if request.op == "get" then
      return process(vim.json.encode({ ok = true, value = vim.base64.encode(bridge_secret) }))
    end
    return process(vim.json.encode({ ok = true }))
  end,
})
assert_true(keychain:put(bridge_secret) == true)
assert_true(keychain:get() == bridge_secret)
assert_true(keychain:delete() == true)
assert_true(bridge_calls[1].op == "set" and vim.base64.decode(bridge_calls[1].value) == bridge_secret)
assert_true(bridge_calls[2].op == "get" and bridge_calls[3].op == "delete")

local function memory_storage(initial)
  local value, deleted = initial, 0
  return {
    get = function()
      return value
    end,
    put = function(_, next_value)
      value = next_value
      return true
    end,
    delete = function()
      value = nil
      deleted = deleted + 1
      return true
    end,
    status = function()
      return { backend = "macos-keychain", bridge_installed = true, credential_state = "not-inspected" }
    end,
    value = function()
      return value
    end,
    deletes = function()
      return deleted
    end,
  }
end

local original = vim.json.encode({
  access = jwt("old-account"),
  refresh = "old-refresh-token",
  account_id = "old-account",
  expires = 1,
})
local calls, generated_storage = 0, memory_storage(original)
local client = codex.new({
  storage = generated_storage,
  system = function(argv, opts)
    calls = calls + 1
    assert_true(argv[1] == "curl" and #argv == 8, "curl argv must be fixed")
    assert_true(opts.env == nil, "curl must not receive a credential environment")
    assert_true(not table.concat(argv, " "):find("old-refresh-token", 1, true), "refresh token leaked to argv")
    if calls == 1 then
      assert_true(opts.stdin:find("old%-refresh%-token"), "refresh token must use curl stdin")
      return process(response(vim.json.encode({
        access_token = jwt("new-account"), refresh_token = "new-refresh-token", expires_in = 3600,
      }), "200"))
    end
    assert_true(opts.stdin:find("new%-account"), "refreshed account must use curl stdin")
    return process(response('data: {"type":"response.output_text.delta","delta":" fix: update docs "}\n\ndata: {"type":"response.completed","response":{"status":"completed"}}\n\n', "200"))
  end,
})
assert_true(client:generate("Summarize staged changes.") == "fix: update docs")
assert_true(calls == 2)
assert_true(vim.json.decode(generated_storage:value()).refresh == "new-refresh-token")
assert_true(client:status().credential_state == "not-inspected")
assert_true(client:logout() == true and generated_storage:deletes() == 1)

local sensitive_detail = "server secret-shaped detail"
local failed_client = codex.new({
  storage = memory_storage(original),
  system = function(_, opts)
    if opts.stdin:find("refresh_token", 1, true) then
      return process(response(vim.json.encode({
        access_token = jwt("new-account"), refresh_token = "new-refresh-token", expires_in = 3600,
      }), "200"))
    end
    return process(response(vim.json.encode({
      error = { code = "model_not_found", type = "invalid_request_error", message = sensitive_detail },
    }), "404"))
  end,
})
local text, generation_error = failed_client:generate("anything")
assert_true(text == nil and generation_error.code == "generation-failed")
assert_true(generation_error.metadata.http_status == 404 and generation_error.metadata.code == "model_not_found")
assert_true(not vim.inspect(generation_error):find(sensitive_detail, 1, true), "server detail leaked through public error")

local cancelled_calls = 0
local cancelled_client = codex.new({
  storage = memory_storage(original),
  system = function()
    cancelled_calls = cancelled_calls + 1
    return process()
  end,
})
local _, cancelled_error = cancelled_client:generate("anything", { cancelled = function()
  return true
end })
assert_true(cancelled_error.code == "cancelled" and cancelled_calls == 0, "cancelled request must not start curl")

local timeout_client = codex.new({
  storage = memory_storage(original),
  system = function()
    return process("", 124)
  end,
})
local _, timeout_error = timeout_client:generate("anything", { timeout_ms = 1 })
assert_true(timeout_error.code == "timeout", "timeout must be returned as a non-secret structured error")

local time, waits, login_ui, login_handle, login_calls, login_closes = 0, {}, nil, nil, 0, 0
local login_client = codex.new({
  storage = memory_storage(),
  now = function()
    return time
  end,
  wait = function(milliseconds)
    table.insert(waits, milliseconds)
    if #waits == 1 then
      login_handle.close()
    end
    time = time + milliseconds
  end,
  device_login_ui = {
    show = function(details)
      login_ui = details
      local closed = false
      login_handle = { close = function()
        if not closed then
          closed = true
          login_closes = login_closes + 1
        end
      end }
      return login_handle
    end,
  },
  system = function()
    login_calls = login_calls + 1
    if login_calls == 1 then
      return process(response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200"))
    elseif login_calls == 2 then
      return process(response(vim.json.encode({ error = "deviceauth_authorization_pending" }), "403"))
    elseif login_calls == 3 then
      return process(response(vim.json.encode({ authorization_code = "authorization-code", code_verifier = "verifier" }), "200"))
    end
    return process(response(vim.json.encode({
      access_token = jwt("login-account"), refresh_token = "login-refresh", expires_in = 3600,
    }), "200"))
  end,
})
assert_true(login_client:login({ timeout_ms = 5000 }) == true)
assert_true(login_ui.user_code == "ABCD-EFGH" and #waits == 2, "manual UI close must not stop polling")
assert_true(login_closes == 1, "successful exchange closes the device login UI")

local storage_failure_calls, storage_failure_time = 0, 0
local storage_failure_client = codex.new({
  storage = {
    put = function()
      return nil, "bridge-build"
    end,
  },
  now = function()
    return storage_failure_time
  end,
  wait = function(milliseconds)
    storage_failure_time = storage_failure_time + milliseconds
  end,
  device_login_ui = { show = function()
    return { close = function() end }
  end },
  system = function()
    storage_failure_calls = storage_failure_calls + 1
    if storage_failure_calls == 1 then
      return process(response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200"))
    elseif storage_failure_calls == 2 then
      return process(response(vim.json.encode({ authorization_code = "authorization-code", code_verifier = "verifier" }), "200"))
    end
    return process(response(vim.json.encode({
      access_token = jwt("storage-account"), refresh_token = "storage-refresh", expires_in = 3600,
    }), "200"))
  end,
})
local _, storage_failure = storage_failure_client:login({ timeout_ms = 5000 })
assert_true(
  storage_failure.code == "storage" and storage_failure.message == "credential storage failed (bridge-build)"
    and storage_failure.metadata.storage == "bridge-build",
  "credential persistence must expose only its safe storage category"
)

local function login_client_with_close(responses, options)
  local close_count, request_count, clock = 0, 0, 0
  local client = codex.new(vim.tbl_extend("force", {
    storage = memory_storage(),
    now = function()
      return clock
    end,
    wait = function(milliseconds)
      clock = clock + milliseconds
      if options and options.after_wait then
        options.after_wait()
      end
    end,
    device_login_ui = {
      show = function()
        return { close = function()
          close_count = close_count + 1
        end }
      end,
    },
    system = function()
      request_count = request_count + 1
      return process(responses[request_count])
    end,
  }, options or {}))
  return client, function()
    return close_count, request_count
  end
end

local terminal_client, terminal_state = login_client_with_close({
  response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200"),
  response(vim.json.encode({ error = "denied" }), "400"),
})
local _, terminal_error = terminal_client:login({ timeout_ms = 5000 })
assert_true(terminal_error.code == "device-poll-failed" and terminal_state() == 1, "terminal polling errors close the device login UI")

local timeout_client, timeout_state = login_client_with_close({
  response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 5 }), "200"),
})
local _, device_timeout_error = timeout_client:login({ timeout_ms = 100 })
assert_true(
  device_timeout_error.code == "timeout" and device_timeout_error.message == "device authorization timed out" and timeout_state() == 1,
  "device authorization timeout closes the UI with a clear terminal error"
)

local cancelled = false
local cancellation_client, cancellation_state = login_client_with_close({
  response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200"),
}, {
  after_wait = function()
    cancelled = true
  end,
})
local _, cancellation_error = cancellation_client:login({ timeout_ms = 5000, cancelled = function()
  return cancelled
end })
assert_true(cancellation_error.code == "cancelled" and cancellation_state() == 1, "user cancellation closes the device login UI")

local async_calls, deferred, async_ui, async_close_count, async_result = {}, {}, nil, 0, nil
local async_client = codex.new({
  storage = memory_storage(),
  now = function()
    return 0
  end,
  system_async = function(argv, opts, callback)
    table.insert(async_calls, { argv = argv, opts = opts, callback = callback })
  end,
  defer = function(callback, milliseconds)
    table.insert(deferred, { callback = callback, milliseconds = milliseconds })
  end,
  schedule = function(callback)
    callback()
  end,
  device_login_ui = {
    show = function()
      async_ui = true
      return { close = function()
        async_close_count = async_close_count + 1
      end }
    end,
  },
})
assert_true(async_client:login_async({ timeout_ms = 5000 }, function(ok, err)
  async_result = { ok = ok, err = err }
end) == true)
assert_true(#async_calls == 1 and not async_ui, "async login returns before the initial device endpoint responds")
async_calls[1].callback(process(response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200")):wait())
assert_true(async_ui and #deferred == 1 and deferred[1].milliseconds == 1000, "async login displays the UI before scheduling its first poll")
deferred[1].callback()
async_calls[2].callback(process(response(vim.json.encode({ authorization_code = "authorization-code", code_verifier = "verifier" }), "200")):wait())
async_calls[3].callback(process(response(vim.json.encode({
  access_token = jwt("async-account"), refresh_token = "async-refresh", expires_in = 3600,
}), "200")):wait())
assert_true(async_result.ok == true and async_close_count == 1, "async successful exchange closes the device login UI")

local fast_event, scheduled_callbacks, fast_async_calls = false, {}, {}
local fast_ui_shown, fast_notifies, fast_closes, fast_results = 0, 0, 0, 0
local fast_client = codex.new({
  storage = memory_storage(),
  system_async = function(_, _, callback)
    table.insert(fast_async_calls, callback)
  end,
  schedule = function(callback)
    table.insert(scheduled_callbacks, callback)
  end,
  defer = function(callback)
    callback()
  end,
  notify = function()
    assert_true(not fast_event, "device-login notifications must not run in a fast event")
    fast_notifies = fast_notifies + 1
  end,
  device_login_ui = {
    show = function(details)
      assert_true(not fast_event, "device-login floating UI must not run in a fast event")
      fast_ui_shown = fast_ui_shown + 1
      details.notify("mock device-login notification")
      return { close = function()
        assert_true(not fast_event, "device-login floating UI close must not run in a fast event")
        fast_closes = fast_closes + 1
      end }
    end,
  },
})
local function drain_scheduled_callbacks()
  while #scheduled_callbacks > 0 do
    local scheduled_callback = table.remove(scheduled_callbacks, 1)
    fast_event = false
    scheduled_callback()
    fast_event = true
  end
  fast_event = false
end
fast_client:login_async({ timeout_ms = 5000 }, function(ok, err)
  assert_true(not fast_event, "device-login completion callback must not run in a fast event")
  assert_true(ok == true and err == nil)
  fast_results = fast_results + 1
end)
fast_event = true
fast_async_calls[1](process(response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200")):wait())
assert_true(#scheduled_callbacks == 1 and fast_ui_shown == 0, "system callback must schedule device-login UI work")
drain_scheduled_callbacks()
fast_event = true
fast_async_calls[2](process(response(vim.json.encode({ authorization_code = "authorization-code", code_verifier = "verifier" }), "200")):wait())
drain_scheduled_callbacks()
fast_event = true
local fast_token = process(response(vim.json.encode({
  access_token = jwt("fast-account"), refresh_token = "fast-refresh", expires_in = 3600,
}), "200")):wait()
fast_async_calls[3](fast_token)
fast_async_calls[3](fast_token)
assert_true(#scheduled_callbacks == 1, "duplicate system completion must schedule only one completion path")
drain_scheduled_callbacks()
assert_true(
  fast_ui_shown == 1 and fast_notifies == 1 and fast_closes == 1 and fast_results == 1,
  "async login schedules UI, notifications, and completion exactly once"
)

local async_timeout_time, async_timeout_calls, async_timeout_delays, async_timeout_close, async_timeout_error = 0, {}, {}, 0, nil
local async_timeout_client = codex.new({
  storage = memory_storage(),
  now = function()
    return async_timeout_time
  end,
  system_async = function(_, opts, callback)
    table.insert(async_timeout_calls, { opts = opts, callback = callback })
  end,
  defer = function(callback, milliseconds)
    table.insert(async_timeout_delays, milliseconds)
    async_timeout_time = async_timeout_time + milliseconds
    callback()
  end,
  schedule = function(callback)
    callback()
  end,
  device_login_ui = { show = function()
    return { close = function()
      async_timeout_close = async_timeout_close + 1
    end }
  end },
})
async_timeout_client:login_async({ timeout_ms = 100 }, function(_, err)
  async_timeout_error = err
end)
async_timeout_calls[1].callback(process(response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 5 }), "200")):wait())
assert_true(async_timeout_calls[1].opts.timeout == 100 and async_timeout_delays[1] == 100, "async login applies its configured deadline to the initial request and poll delay")
assert_true(
  async_timeout_error.code == "timeout" and async_timeout_error.message == "device authorization timed out" and async_timeout_close == 1,
  "async timeout closes the device login UI with a clear terminal error"
)

local async_cancelled, async_cancel_calls, async_cancel_close, async_cancel_error = false, {}, 0, nil
local async_cancel_client = codex.new({
  storage = memory_storage(),
  system_async = function(_, _, callback)
    table.insert(async_cancel_calls, callback)
  end,
  defer = function(callback)
    async_cancelled = true
    callback()
  end,
  schedule = function(callback)
    callback()
  end,
  device_login_ui = { show = function()
    return { close = function()
      async_cancel_close = async_cancel_close + 1
    end }
  end },
})
async_cancel_client:login_async({ timeout_ms = 5000, cancelled = function()
  return async_cancelled
end }, function(_, err)
  async_cancel_error = err
end)
async_cancel_calls[1](process(response(vim.json.encode({ device_auth_id = "device-id", user_code = "ABCD-EFGH", interval = 1 }), "200")):wait())
assert_true(async_cancel_error.code == "cancelled" and async_cancel_close == 1, "async cancellation closes the device login UI")

print("commit-generator Codex tests: ok")
