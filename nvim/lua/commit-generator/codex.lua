--- Unsupported standalone ChatGPT/Codex subscription client for commit generation.
---
--- It owns a dedicated macOS Keychain record and never reads or invokes an AI
--- harness. OpenAI may change this observed protocol; recover by updating the
--- confined protocol module or select the rule-based generator in ticket 04.
local client = require("commit-generator.codex.client")

local M = {}

--- Create an independently authenticated direct-Codex client.
--- @param opts? table {model?: string, reasoning?: string, storage?: table, system?: function}
--- @return table client login/status/logout/generate methods
function M.new(opts)
  return client.new(opts)
end

return M
