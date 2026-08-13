local source = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fn.fnamemodify(source, ":p:h:h")

local function assert_true(value, message)
  assert(value, message or "assertion failed")
end

local specs = dofile(config_dir .. "/lua/plugins/git.lua")
local commit_generator, neogit
for _, spec in ipairs(specs) do
  if spec.name == "commit-generator" then
    commit_generator = spec
  elseif spec[1] == "NeogitOrg/neogit" then
    neogit = spec
  end
end

assert_true(commit_generator ~= nil, "commit-generator must have an independent plugin spec")
assert_true(commit_generator.dir == vim.fn.stdpath("config"))
assert_true(commit_generator.lazy == true)
assert_true(commit_generator.ft == "gitcommit")
assert_true(vim.deep_equal(commit_generator.cmd, {
  "CommitGeneratorLogin",
  "CommitGeneratorStatus",
  "CommitGeneratorLogout",
  "GenerateCommitMsg",
}))
assert_true(neogit ~= nil)

local neogit_setup, commit_generator_setup = 0, 0
local configured_generator
package.loaded["neogit"] = {
  setup = function()
    neogit_setup = neogit_setup + 1
  end,
}
package.loaded["commit-generator"] = {
  setup = function(config)
    commit_generator_setup = commit_generator_setup + 1
    configured_generator = config
  end,
}

neogit.config()
assert_true(neogit_setup == 1)
assert_true(commit_generator_setup == 0, "loading Neogit must not configure commit-generator")

commit_generator.config()
assert_true(commit_generator_setup == 1)
assert_true(configured_generator.ai.model == "gpt-5.6-luna")
assert_true(configured_generator.ai.reasoning == "none")
assert_true(configured_generator.ai.storage.backend == "auto")
assert_true(configured_generator.format.conventional_commits == true)

print("git plugin lazy-loading tests: ok")
