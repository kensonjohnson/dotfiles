local M = {}

M.codex_url = "https://chatgpt.com/backend-api/codex/responses"
M.auth_base_url = "https://auth.openai.com"
M.device_start_url = M.auth_base_url .. "/api/accounts/deviceauth/usercode"
M.device_poll_url = M.auth_base_url .. "/api/accounts/deviceauth/token"
M.token_url = M.auth_base_url .. "/oauth/token"
M.device_verification_url = M.auth_base_url .. "/codex/device"
M.device_redirect_uri = M.auth_base_url .. "/deviceauth/callback"
M.oauth_client_id = "app_EMoamEEZ73f0CkXaXp7hrann"
M.default_model = "gpt-5.6-luna"
-- The Codex backend currently expects the same originator as Pi's installed
-- openai-codex SSE adapter; this names the protocol client, not an executable.
M.originator = "pi"
M.account_claim = "https://api.openai.com/auth.chatgpt_account_id"
M.account_claim_container = "https://api.openai.com/auth"

function M.user_agent()
  local uname = vim.uv.os_uname()
  local platform = type(uname.sysname) == "string" and uname.sysname:lower() or "unknown"
  local release = type(uname.release) == "string" and uname.release or "unknown"
  local architecture = type(uname.machine) == "string" and uname.machine or "unknown"
  return string.format("pi (%s %s; %s)", platform, release, architecture)
end

local function curl_quote(value)
  return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\r", "\\r"):gsub("\n", "\\n") .. '"'
end

local function url_encode(value)
  return (value:gsub("[^%w%-_%.~]", function(byte)
    return string.format("%%%02X", string.byte(byte))
  end))
end

local function form_encode(fields)
  local values = {}
  for _, field in ipairs(fields) do
    table.insert(values, url_encode(field[1]) .. "=" .. url_encode(field[2]))
  end
  return table.concat(values, "&")
end

function M.build_request(prompt, model)
  assert(type(prompt) == "string" and prompt ~= "", "prompt must be a non-empty string")

  return {
    url = M.codex_url,
    body = {
      model = model or M.default_model,
      store = false,
      stream = true,
      instructions = "Return one concise conventional commit message and nothing else.",
      input = {
        {
          role = "user",
          content = {
            { type = "input_text", text = prompt },
          },
        },
      },
      text = { verbosity = "low" },
      include = { "reasoning.encrypted_content" },
      tool_choice = "auto",
      parallel_tool_calls = true,
    },
  }
end

function M.build_curl_config(request, credential)
  assert(type(request) == "table" and type(request.body) == "table", "request is required")
  assert(type(credential) == "table" and type(credential.access) == "string" and credential.access ~= "", "access token is required")
  assert(type(credential.account_id) == "string" and credential.account_id ~= "", "account ID is required")

  local headers = {
    "Authorization: Bearer " .. credential.access,
    "chatgpt-account-id: " .. credential.account_id,
    "originator: " .. M.originator,
    "User-Agent: " .. M.user_agent(),
    "OpenAI-Beta: responses=experimental",
    "Accept: text/event-stream",
    "Content-Type: application/json",
  }
  return M.build_post_config(request.url, headers, vim.json.encode(request.body))
end

function M.build_post_config(url, headers, body)
  assert(type(url) == "string" and url:match("^https://"), "HTTPS URL is required")
  assert(type(headers) == "table" and type(body) == "string", "headers and body are required")

  local lines = {
    "url = " .. curl_quote(url),
    'request = "POST"',
  }
  for _, header in ipairs(headers) do
    table.insert(lines, "header = " .. curl_quote(header))
  end
  table.insert(lines, "data = " .. curl_quote(body))
  return table.concat(lines, "\n") .. "\n"
end

function M.build_curl_command(request, credential)
  return {
    argv = {
      "curl",
      "--silent",
      "--show-error",
      "--no-buffer",
      "--config",
      "-",
      "--write-out",
      "\n__DIRECT_CODEX_HTTP_STATUS__:%{http_code}\n",
    },
    stdin = M.build_curl_config(request, credential),
  }
end

function M.build_oauth_curl_command(url, fields)
  assert(type(fields) == "table", "OAuth form fields are required")
  return {
    argv = {
      "curl",
      "--silent",
      "--show-error",
      "--no-buffer",
      "--config",
      "-",
      "--write-out",
      "\n__DIRECT_CODEX_HTTP_STATUS__:%{http_code}\n",
    },
    stdin = M.build_post_config(url, { "Content-Type: application/x-www-form-urlencoded" }, form_encode(fields)),
  }
end

function M.build_device_start_command()
  return M.build_post_command(M.device_start_url, {
    client_id = M.oauth_client_id,
  })
end

function M.build_device_poll_command(device_auth_id, user_code)
  assert(type(device_auth_id) == "string" and device_auth_id ~= "", "device authorization ID is required")
  assert(type(user_code) == "string" and user_code ~= "", "user code is required")
  return M.build_post_command(M.device_poll_url, {
    ["device_auth_id"] = device_auth_id,
    ["user_code"] = user_code,
  })
end

function M.build_token_exchange_command(authorization_code, code_verifier)
  assert(type(authorization_code) == "string" and authorization_code ~= "", "authorization code is required")
  assert(type(code_verifier) == "string" and code_verifier ~= "", "code verifier is required")
  return M.build_oauth_curl_command(M.token_url, {
    { "grant_type", "authorization_code" },
    { "client_id", M.oauth_client_id },
    { "code", authorization_code },
    { "code_verifier", code_verifier },
    { "redirect_uri", M.device_redirect_uri },
  })
end

function M.build_refresh_command(refresh_token)
  assert(type(refresh_token) == "string" and refresh_token ~= "", "refresh token is required")
  return M.build_oauth_curl_command(M.token_url, {
    { "grant_type", "refresh_token" },
    { "refresh_token", refresh_token },
    { "client_id", M.oauth_client_id },
  })
end

function M.build_post_command(url, body)
  return {
    argv = {
      "curl",
      "--silent",
      "--show-error",
      "--no-buffer",
      "--config",
      "-",
      "--write-out",
      "\n__DIRECT_CODEX_HTTP_STATUS__:%{http_code}\n",
    },
    stdin = M.build_post_config(url, { "Content-Type: application/json" }, vim.json.encode(body)),
  }
end

function M.split_curl_response(stdout)
  local body, status = (stdout or ""):match("^(.*)\n__DIRECT_CODEX_HTTP_STATUS__:(%d%d%d)\n?$")
  if not body or not status then
    return nil, nil
  end
  return body, tonumber(status)
end

function M.decode_jwt_account_id(access_token)
  if type(access_token) ~= "string" then
    return nil
  end
  local payload = access_token:match("^[^.]+%.([^.]+)%.[^.]+$")
  if not payload then
    return nil
  end
  payload = payload:gsub("-", "+"):gsub("_", "/")
  payload = payload .. string.rep("=", (4 - #payload % 4) % 4)
  local ok, decoded = pcall(vim.base64.decode, payload)
  if not ok then
    return nil
  end
  local parsed_ok, claims = pcall(vim.json.decode, decoded)
  if not parsed_ok or type(claims) ~= "table" then
    return nil
  end
  local account_id = claims[M.account_claim]
  if type(account_id) ~= "string" then
    local auth = claims[M.account_claim_container]
    account_id = type(auth) == "table" and auth.chatgpt_account_id or nil
  end
  return type(account_id) == "string" and account_id ~= "" and account_id or nil
end

-- This only constructs the user-directed browser action. It is called only
-- after :DirectCodexLogin has explicitly started the device authorization.
function M.build_open_command(authorization_url)
  assert(type(authorization_url) == "string" and authorization_url:match("^https://"), "HTTPS authorization URL is required")
  return { argv = { "open", authorization_url } }
end

function M.parse_sse(text)
  local events = {}
  for block in (text .. "\n\n"):gmatch("(.-)\r?\n\r?\n") do
    local data = {}
    for line in block:gmatch("[^\r\n]+") do
      local value = line:match("^data:%s?(.*)$")
      if value and value ~= "[DONE]" then
        table.insert(data, value)
      end
    end
    if #data > 0 then
      local ok, decoded = pcall(vim.json.decode, table.concat(data, "\n"))
      if ok and type(decoded) == "table" then
        table.insert(events, decoded)
      end
    end
  end
  return events
end

function M.response_text(events)
  local chunks = {}
  local fallback
  for _, event in ipairs(events) do
    if event.type == "response.output_text.delta" and type(event.delta) == "string" then
      table.insert(chunks, event.delta)
    elseif (event.type == "response.completed" or event.type == "response.done") and type(event.response) == "table" then
      for _, item in ipairs(event.response.output or {}) do
        for _, content in ipairs(item.content or {}) do
          if content.type == "output_text" and type(content.text) == "string" then
            fallback = (fallback or "") .. content.text
          end
        end
      end
    end
  end
  local text = #chunks > 0 and table.concat(chunks) or fallback
  return type(text) == "string" and text ~= "" and text or nil
end

local function safe_error_value(value)
  if type(value) ~= "string" or #value == 0 or #value > 80 or not value:match("^[%w_.%-]+$") then
    return nil
  end
  return value
end

function M.error_metadata(body)
  local metadata = {}
  local ok, decoded = pcall(vim.json.decode, body or "")
  if not ok or type(decoded) ~= "table" then
    return metadata
  end
  local error_value = type(decoded.error) == "table" and decoded.error or decoded
  metadata.code = safe_error_value(error_value.code)
  metadata.category = safe_error_value(error_value.type) or safe_error_value(error_value.category)
  return metadata
end

function M.response_metadata(events)
  local metadata = { event_count = #events, completed = false }
  for _, event in ipairs(events) do
    if event.type == "response.completed" or event.type == "response.done" then
      metadata.completed = true
      metadata.status = event.response and event.response.status or nil
    elseif event.type == "error" or event.type == "response.failed" then
      metadata.failed = true
      local error_value = type(event.error) == "table" and event.error
        or type(event.response) == "table" and event.response.error
        or event
      metadata.code = safe_error_value(event.code) or safe_error_value(error_value and error_value.code)
      metadata.category = safe_error_value(error_value and error_value.type) or safe_error_value(event.type)
    end
  end
  return metadata
end

return M
