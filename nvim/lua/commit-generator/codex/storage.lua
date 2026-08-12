local M = {}

M.backend = "macos-keychain"

local bridge_error_categories = {
  ["invalid-request"] = "bridge-process",
  ["keychain-failure"] = "keychain",
  ["not-found"] = "keychain",
}

local function cache_root()
  local xdg_cache = vim.env.XDG_CACHE_HOME
  if type(xdg_cache) == "string" and xdg_cache ~= "" then
    return xdg_cache .. "/commit-generator-codex"
  end
  local home = vim.env.HOME or vim.fn.expand("~")
  return home .. "/Library/Caches/commit-generator-codex"
end

local function source_path()
  local source = debug.getinfo(1, "S").source:sub(2)
  local lua_root = vim.fn.fnamemodify(source, ":p:h:h:h:h")
  return lua_root .. "/native/commit-generator-codex-keychain.swift"
end

--- Resolve the bridge source relative to this module, including symlinked configs.
function M.bridge_source_path()
  return source_path()
end

local function bridge_path()
  return cache_root() .. "/keychain-bridge"
end

local function safe_bridge_error(response)
  if type(response) == "table" and type(response.error) == "string" then
    return bridge_error_categories[response.error] or "bridge-process"
  end
  return "bridge-process"
end

local function copy_argv(argv)
  local copy = {}
  for index, value in ipairs(argv) do
    copy[index] = value
  end
  return copy
end

--- Build the Swift Keychain bridge outside the repository only when a credential
--- operation needs it. The compiler receives no credential data.
local function ensure_bridge(system)
  local source = source_path()
  local binary = bridge_path()
  if vim.fn.executable(binary) == 1 and vim.fn.getftime(source) <= vim.fn.getftime(binary) then
    return binary
  end
  if vim.fn.has("mac") ~= 1 or vim.fn.filereadable(source) ~= 1 then
    return nil, "bridge-unavailable"
  end

  local directory = vim.fn.fnamemodify(binary, ":h")
  vim.fn.mkdir(directory, "p", "0700")
  if vim.fn.setfperm(directory, "rwx------") ~= 1 then
    return nil, "bridge-build"
  end
  local temporary = binary .. "." .. tostring(vim.uv.os_getpid())
  local result = system({ "/usr/bin/xcrun", "--sdk", "macosx", "swiftc", "-O", "-framework", "Security", source, "-o", temporary }, {
    text = true,
  }):wait()
  if result.code ~= 0 or result.signal ~= 0 then
    vim.fn.delete(temporary)
    return nil, "bridge-build"
  end
  if vim.fn.setfperm(temporary, "rwx------") ~= 1 then
    vim.fn.delete(temporary)
    return nil, "bridge-build"
  end
  if vim.uv.fs_rename(temporary, binary) == nil then
    vim.fn.delete(temporary)
    return nil, "bridge-build"
  end
  return binary
end

function M.new(opts)
  opts = opts or {}
  local requested_backend = opts.backend or "auto"
  assert(requested_backend == "auto" or requested_backend == M.backend, "unsupported credential storage backend")
  local system = opts.system or vim.system
  local resolve_bridge = opts.resolve_bridge or function()
    return ensure_bridge(system)
  end

  local function invoke(operation, value)
    local bridge, bridge_err = resolve_bridge()
    if not bridge then
      return nil, bridge_err or "bridge-unavailable"
    end
    local request = { op = operation }
    if value ~= nil then
      request.value = vim.base64.encode(value)
    end
    local result = system(copy_argv({ bridge }), {
      text = true,
      stdin = vim.json.encode(request),
    }):wait()
    if result.code ~= 0 or result.signal ~= 0 then
      return nil, "bridge-process"
    end
    local ok, response = pcall(vim.json.decode, result.stdout or "")
    if not ok or type(response) ~= "table" or response.ok ~= true then
      return nil, safe_bridge_error(response)
    end
    return response
  end

  return {
    backend = M.backend,
    get = function()
      local response, err = invoke("get")
      if not response then
        return nil, err
      end
      if type(response.value) ~= "string" then
        return nil, "Keychain bridge returned an invalid response"
      end
      local ok, value = pcall(vim.base64.decode, response.value)
      if not ok or type(value) ~= "string" then
        return nil, "Keychain bridge returned an invalid response"
      end
      return value
    end,
    put = function(self_or_value, value)
      value = value or self_or_value
      assert(type(value) == "string", "credential must be a string")
      local response, err = invoke("set", value)
      return response and true or nil, err
    end,
    delete = function()
      local response, err = invoke("delete")
      return response and true or nil, err
    end,
    status = function()
      return {
        backend = M.backend,
        bridge_installed = vim.fn.executable(bridge_path()) == 1,
        credential_state = "not-inspected",
      }
    end,
  }
end

return M
