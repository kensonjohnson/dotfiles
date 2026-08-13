local source = debug.getinfo(1, "S").source:sub(2)
vim.opt.rtp:append(vim.fn.fnamemodify(source, ":p:h:h"))

local function assert_true(value, message)
  assert(value, message or "assertion failed")
end

local factory_calls, generated_prompts, generation_options = 0, {}, {}
local client_options, storage_options, login_options
local client = {
  generate = function(_, prompt, options)
    table.insert(generated_prompts, prompt)
    table.insert(generation_options, options)
    return "fix: use direct Codex"
  end,
  login_async = function(_, options, callback)
    login_options = options
    callback(true)
    return true
  end,
  status = function()
    return { backend = "macos-keychain", bridge_installed = true, credential_state = "not-inspected" }
  end,
  logout = function()
    return true
  end,
}

package.loaded["commit-generator.codex"] = {
  new = function(options)
    factory_calls = factory_calls + 1
    client_options = options
    return client
  end,
}
package.loaded["commit-generator.codex.storage"] = {
  new = function(options)
    storage_options = options
    return { backend = options.backend }
  end,
}

local generator = require("commit-generator")
assert_true(generator.config.ai.login_timeout == 15 * 60 * 1000, "device login default must be fifteen minutes")
assert_true(generator.config.ai.reasoning == "low", "direct Codex reasoning must default to low")
generator.setup({
  ai = {
    model = "test-codex-model",
    reasoning = "low",
    timeout = 1234,
    login_timeout = 5678,
    storage = { backend = "auto" },
  },
})
assert_true(factory_calls == 0, "direct client must be created lazily")
assert_true(vim.fn.exists(":CommitGeneratorLogin") == 2)
assert_true(vim.fn.exists(":CommitGeneratorStatus") == 2)
assert_true(vim.fn.exists(":CommitGeneratorLogout") == 2)

local changes = { added = { "README.md" }, modified = {}, deleted = {}, renamed = {}, diff_content = "" }
local context = { conventional_commits = true, has_tests = false }
assert_true(generator.generate_ai_message(changes, context, true) == "fix: use direct Codex")
assert_true(factory_calls == 1, "direct client should be created on first generation")
assert_true(client_options.model == "test-codex-model")
assert_true(client_options.reasoning == "low")
assert_true(storage_options.backend == "auto")
assert_true(generation_options[1].timeout_ms == 1234)
assert_true(generated_prompts[1]:find("Return only the subject line", 1, true))

local original_context = generator.detect_repo_context
generator.detect_repo_context = function()
  return context
end
local preview_options = generator.generate_multiple_options(changes)
assert_true(preview_options[1].source == "AI" and preview_options[1].message == "fix: use direct Codex")

local notifications = {}
local original_notify = vim.notify
vim.notify = function(message, level)
  table.insert(notifications, { message = message, level = level })
end
client.generate = function()
  return nil, { code = "not-authenticated", message = "no stored direct-Codex credential" }
end
generator.generate_rule_based_message = function()
  return "docs: update documentation"
end
assert_true(generator.generate_message(changes, nil, true) == "docs: update documentation")
assert_true(generator.generate_message(changes, "ai", true) == "chore: update files")
assert_true(notifications[#notifications].message:find("Direct Codex generation failed", 1, true))

vim.cmd("CommitGeneratorLogin")
assert_true(login_options.timeout_ms == 5678, "login must use its configured device-flow deadline")
vim.cmd("CommitGeneratorStatus")
vim.cmd("CommitGeneratorLogout")
assert_true(notifications[#notifications - 2].message == "Direct Codex login completed")
assert_true(notifications[#notifications - 1].message:find("credential not%-inspected"))
assert_true(notifications[#notifications].message == "Direct Codex credential removed")
vim.notify = original_notify
generator.detect_repo_context = original_context

local generator_source = table.concat(vim.fn.readfile(vim.fn.fnamemodify(source, ":p:h:h") .. "/lua/commit-generator.lua"), "\n")
assert_true(not generator_source:find("call_pi", 1, true), "Pi dispatch must be removed")
assert_true(not generator_source:find('executable("pi")', 1, true), "Pi executable check must be removed")

print("commit-generator direct Codex integration tests: ok")
