local M = {}

--- Configuration for commit message generation
M.config = {
	--- AI Configuration
	ai = {
		enabled = true,
		provider = "anthropic",
		api_key_env = "ANTHROPIC_API_KEY",
		model = "claude-haiku-4-5",
		max_tokens = 100,
		timeout = 5000,
	},

	--- Fallback behavior
	fallback = {
		use_rules = true,
		use_generic = true,
	},

	--- Message preferences
	format = {
		conventional_commits = true,
		max_length = 50,
		include_scope = true,
	},

	--- Universal file patterns for any repository
	patterns = {
		--- Core patterns that work everywhere
		docs = { "README.*", ".*%.md", ".*%.rst", "docs/.*", "documentation/.*" },
		tests = { ".*test.*", ".*spec.*", "__tests__/.*", "test/.*", "tests/.*", "spec/.*" },
		config = { ".*%.json", ".*%.yaml", ".*%.yml", ".*%.toml", ".*%.ini", "%.env.*", "config/.*" },
		ci = { "%.github/.*", "%.gitlab%-ci.*", "Dockerfile.*", "docker%-compose.*", "%.circleci/.*" },
		build = { "Makefile", "CMakeLists%.txt", "build%.gradle", "pom%.xml", "Cargo%.toml", "package%.json" },

		--- Language-specific patterns (detected automatically)
		javascript = { ".*%.js", ".*%.ts", ".*%.jsx", ".*%.tsx", ".*%.mjs", ".*%.cjs" },
		python = { ".*%.py", "requirements.*%.txt", "pyproject%.toml", "setup%.py", ".*%.pyi" },
		rust = { ".*%.rs", "Cargo%.toml", "Cargo%.lock" },
		go = { ".*%.go", "go%.mod", "go%.sum" },
		lua = { ".*%.lua" },
		java = { ".*%.java", ".*%.kt", ".*%.scala" },
		csharp = { ".*%.cs", ".*%.csproj", ".*%.sln" },
		cpp = { ".*%.cpp", ".*%.hpp", ".*%.c", ".*%.h", ".*%.cc", ".*%.cxx" },
		php = { ".*%.php", "composer%.json" },
		ruby = { ".*%.rb", "Gemfile", ".*%.gemspec" },
		swift = { ".*%.swift", "Package%.swift" },
		shell = { ".*%.sh", ".*%.bash", ".*%.zsh", ".*%.fish" },
	},

	--- Conventional commit types
	commit_types = {
		feat = "A new feature",
		fix = "A bug fix",
		docs = "Documentation only changes",
		style = "Changes that do not affect the meaning of the code",
		refactor = "Code change that neither fixes a bug nor adds a feature",
		perf = "Code change that improves performance",
		test = "Adding missing tests or correcting existing tests",
		build = "Changes that affect the build system or external dependencies",
		ci = "Changes to CI configuration files and scripts",
		chore = "Other changes that don't modify src or test files",
		revert = "Reverts a previous commit",
	},
}

--- Detect repository context for better commit message generation
--- @return table repo_context Repository characteristics
function M.detect_repo_context()
	local context = {
		language = nil,
		framework = nil,
		project_type = nil,
		has_tests = false,
		conventional_commits = false,
	}

	--- Detect primary language
	context.language = M.detect_primary_language()

	--- Detect framework/library
	context.framework = M.detect_framework()

	--- Detect project type
	context.project_type = M.detect_project_type()

	--- Check for test files
	context.has_tests = M.has_test_files()

	--- Check if repo uses conventional commits
	context.conventional_commits = M.uses_conventional_commits()

	return context
end

--- Detect the primary programming language of the repository
--- @return string|nil Primary language
function M.detect_primary_language()
	local language_files = {
		javascript = { "package.json", "*.js", "*.ts", "*.jsx", "*.tsx" },
		python = { "requirements.txt", "pyproject.toml", "setup.py", "*.py" },
		rust = { "Cargo.toml", "*.rs" },
		go = { "go.mod", "*.go" },
		java = { "pom.xml", "build.gradle", "*.java" },
		csharp = { "*.csproj", "*.sln", "*.cs" },
		php = { "composer.json", "*.php" },
		ruby = { "Gemfile", "*.rb" },
		swift = { "Package.swift", "*.swift" },
		cpp = { "CMakeLists.txt", "Makefile", "*.cpp", "*.c" },
		lua = { "*.lua" },
	}

	for language, files in pairs(language_files) do
		for _, pattern in ipairs(files) do
			if vim.fn.glob(pattern) ~= "" then
				return language
			end
		end
	end

	return nil
end

--- Detect framework or major library being used
--- @return string|nil Framework name
function M.detect_framework()
	--- Check package.json for JS frameworks
	if vim.fn.filereadable("package.json") == 1 then
		local package_content = vim.fn.readfile("package.json")
		local package_str = table.concat(package_content, "\n")

		if package_str:match('"react"') then
			return "react"
		end
		if package_str:match('"vue"') then
			return "vue"
		end
		if package_str:match('"angular"') then
			return "angular"
		end
		if package_str:match('"next"') then
			return "nextjs"
		end
		if package_str:match('"express"') then
			return "express"
		end
		if package_str:match('"fastify"') then
			return "fastify"
		end
	end

	--- Check for Python frameworks
	if vim.fn.filereadable("requirements.txt") == 1 or vim.fn.filereadable("pyproject.toml") == 1 then
		local files = vim.fn.glob("requirements*.txt", false, true)
		table.insert(files, "pyproject.toml")

		for _, file in ipairs(files) do
			if vim.fn.filereadable(file) == 1 then
				local content = table.concat(vim.fn.readfile(file), "\n")
				if content:match("django") then
					return "django"
				end
				if content:match("flask") then
					return "flask"
				end
				if content:match("fastapi") then
					return "fastapi"
				end
			end
		end
	end

	--- Check for Rust frameworks
	if vim.fn.filereadable("Cargo.toml") == 1 then
		local content = table.concat(vim.fn.readfile("Cargo.toml"), "\n")
		if content:match("axum") then
			return "axum"
		end
		if content:match("actix") then
			return "actix"
		end
		if content:match("rocket") then
			return "rocket"
		end
	end

	return nil
end

--- Detect project type
--- @return string Project type
function M.detect_project_type()
	if vim.fn.isdirectory("src") == 1 or vim.fn.isdirectory("lib") == 1 then
		return "library"
	elseif vim.fn.filereadable("Dockerfile") == 1 then
		return "service"
	elseif vim.fn.isdirectory("public") == 1 or vim.fn.isdirectory("static") == 1 then
		return "web"
	elseif vim.fn.filereadable("main.go") == 1 or vim.fn.filereadable("main.rs") == 1 then
		return "cli"
	elseif vim.fn.filereadable("Brewfile") == 1 or vim.fn.filereadable(".zshrc") == 1 then
		return "dotfiles"
	else
		return "application"
	end
end

--- Check if repository has test files
--- @return boolean Has tests
function M.has_test_files()
	local test_patterns = { "*test*", "*spec*", "test/", "tests/", "__tests__/" }

	for _, pattern in ipairs(test_patterns) do
		if vim.fn.glob(pattern, false, true)[1] then
			return true
		end
	end

	return false
end

--- Check if repository uses conventional commits
--- @return boolean Uses conventional commits
function M.uses_conventional_commits()
	--- Check recent commit messages for conventional format
	local result = vim.fn.system("git log --oneline -10 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		return false
	end

	local conventional_count = 0
	local total_count = 0

	for line in result:gmatch("[^\r\n]+") do
		total_count = total_count + 1
		if line:match("^%w+ [a-z]+%(.*%):%s") or line:match("^%w+ [a-z]+:%s") then
			conventional_count = conventional_count + 1
		end
	end

	--- If more than 50% of recent commits are conventional, assume the repo uses it
	return total_count > 0 and (conventional_count / total_count) > 0.5
end

--- Analyze staged changes using git diff
--- @return table changes Table containing added, modified, deleted files and diff content
function M.analyze_changes()
	local name_status = vim.fn.system("git diff --cached --name-status")
	if vim.v.shell_error ~= 0 then
		vim.notify("Error: No staged changes found", vim.log.levels.WARN)
		return nil
	end

	local changes = {
		added = {},
		modified = {},
		deleted = {},
		renamed = {},
		diff_content = "",
	}

	--- Parse file changes
	for line in name_status:gmatch("[^\r\n]+") do
		local status, file = line:match("^(%S+)%s+(.+)$")
		if status and file then
			if status == "A" then
				table.insert(changes.added, file)
			elseif status == "M" then
				table.insert(changes.modified, file)
			elseif status == "D" then
				table.insert(changes.deleted, file)
			elseif status:match("^R") then
				local old_file, new_file = file:match("^(.+) -> (.+)$")
				if old_file and new_file then
					table.insert(changes.renamed, { old = old_file, new = new_file })
				end
			end
		end
	end

	--- Get actual diff content for AI analysis
	local diff_result = vim.fn.system("git diff --cached")
	if vim.v.shell_error == 0 then
		changes.diff_content = diff_result
	end

	return changes
end

--- Generate AI-powered commit message using Anthropic API
--- @param changes table The changes from analyze_changes()
--- @param repo_context table Repository context
--- @param title_only boolean Whether to generate only the subject line
--- @return string|nil Generated commit message or nil if failed
function M.generate_ai_message(changes, repo_context, title_only)
	if not M.config.ai.enabled then
		return nil
	end

	local api_key = vim.fn.getenv(M.config.ai.api_key_env)
	if not api_key or api_key == vim.NIL or api_key == "" then
		vim.notify("Anthropic API key not found in " .. M.config.ai.api_key_env, vim.log.levels.WARN)
		return nil
	end

	local prompt = M.build_ai_prompt(changes, repo_context, title_only)
	local response = M.call_anthropic_api(prompt, api_key)

	if response then
		return M.parse_ai_response(response)
	end

	return nil
end
--- Build intelligent prompt for AI commit message generation
--- @param changes table The changes from analyze_changes()
--- @param repo_context table Repository context
--- @param title_only boolean Whether to generate only the subject line
--- @return string AI prompt
function M.build_ai_prompt(changes, repo_context, title_only)
	local prompt = "You are a senior developer writing a commit message.\n\n"

	--- Add repository context
	prompt = prompt .. "Repository Context:\n"
	if repo_context.language then
		prompt = prompt .. "- Language: " .. repo_context.language .. "\n"
	end
	if repo_context.framework then
		prompt = prompt .. "- Framework: " .. repo_context.framework .. "\n"
	end
	if repo_context.project_type then
		prompt = prompt .. "- Project Type: " .. repo_context.project_type .. "\n"
	end
	prompt = prompt .. "- Uses Conventional Commits: " .. (repo_context.conventional_commits and "Yes" or "No") .. "\n"
	prompt = prompt .. "- Has Tests: " .. (repo_context.has_tests and "Yes" or "No") .. "\n\n"

	--- Add file changes summary
	prompt = prompt .. "Files Changed:\n"
	if #changes.added > 0 then
		prompt = prompt .. "Added: " .. table.concat(changes.added, ", ") .. "\n"
	end
	if #changes.modified > 0 then
		prompt = prompt .. "Modified: " .. table.concat(changes.modified, ", ") .. "\n"
	end
	if #changes.deleted > 0 then
		prompt = prompt .. "Deleted: " .. table.concat(changes.deleted, ", ") .. "\n"
	end
	prompt = prompt .. "\n"

	--- Add diff content (truncated for API limits)
	if changes.diff_content and #changes.diff_content > 0 then
		local truncated_diff = M.truncate_diff(changes.diff_content, 2000)
		prompt = prompt .. "Changes:\n```diff\n" .. truncated_diff .. "\n```\n\n"
	end

	--- Add instructions based on title_only flag
	if title_only then
		prompt = prompt .. "Generate a concise commit message subject line that:\n"
		if repo_context.conventional_commits then
			prompt = prompt .. "1. Follows conventional commits format: type(scope): description\n"
		end
		prompt = prompt .. "2. Is under 50 characters\n"
		prompt = prompt .. "3. Uses present tense, imperative mood\n"
		prompt = prompt .. "4. Does not end with a period\n"
		prompt = prompt .. "5. Accurately describes what changed\n\n"
		
		prompt = prompt .. "Examples of good subject lines:\n"
		prompt = prompt .. "- feat(auth): add OAuth login flow\n"
		prompt = prompt .. "- fix(api): handle null user responses\n"
		prompt = prompt .. "- refactor(ui): extract reusable button component\n"
		prompt = prompt .. "- docs: update installation instructions\n"
		prompt = prompt .. "- test: add unit tests for user service\n\n"
		
		prompt = prompt .. "Return only the subject line, nothing else:"
	else
		prompt = prompt .. "Generate a commit message with both subject and body that:\n"
		if repo_context.conventional_commits then
			prompt = prompt .. "1. Follows conventional commits format: type(scope): description\n"
		end
		prompt = prompt .. "2. Has a concise subject line under 50 characters\n"
		prompt = prompt .. "3. Includes a blank line after the subject\n"
		prompt = prompt .. "4. Has a detailed body that objectively describes WHAT changed\n"
		prompt = prompt .. "5. Uses present tense, imperative mood\n"
		prompt = prompt .. "6. Subject line does not end with a period\n"
		prompt = prompt .. "7. Lists the specific changes, additions, modifications, or removals\n"
		prompt = prompt .. "8. Does NOT speculate about intent, motivation, or reasons (the 'why')\n\n"
		
		prompt = prompt .. "Examples of good messages:\n"
		prompt = prompt .. "feat(auth): add OAuth login flow\n\n"
		prompt = prompt .. "Add OAuth 2.0 authentication with Google provider.\n"
		prompt = prompt .. "Add login and logout endpoints.\n"
		prompt = prompt .. "Add user session management with JWT tokens.\n\n"
		
		prompt = prompt .. "fix(api): handle null user responses\n\n"
		prompt = prompt .. "Add null checks in user data response handler.\n"
		prompt = prompt .. "Add default values for missing profile fields.\n"
		prompt = prompt .. "Update error handling to catch null pointer exceptions.\n\n"
		
		prompt = prompt .. "refactor(database): restructure query builder\n\n"
		prompt = prompt .. "Extract query building logic into separate methods.\n"
		prompt = prompt .. "Move parameter validation to dedicated validator class.\n"
		prompt = prompt .. "Rename ambiguous method names for clarity.\n\n"
		
		prompt = prompt .. "Return only the commit message (subject + body), nothing else:"
	end
	return prompt
end

--- Call Anthropic API to generate commit message
--- @param prompt string The prompt to send
--- @param api_key string Anthropic API key
--- @return string|nil API response or nil if failed
function M.call_anthropic_api(prompt, api_key)
	local curl_cmd = {
		"curl",
		"-s",
		"-X",
		"POST",
		"https://api.anthropic.com/v1/messages",
		"-H",
		"Content-Type: application/json",
		"-H",
		"x-api-key: " .. api_key,
		"-H",
		"anthropic-version: 2023-06-01",
		"--max-time",
		tostring(math.floor(M.config.ai.timeout / 1000)),
		"-d",
		vim.fn.json_encode({
			model = M.config.ai.model,
			max_tokens = M.config.ai.max_tokens,
			messages = {
				{
					role = "user",
					content = prompt,
				},
			},
		}),
	}

	local result = vim.fn.system(curl_cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to call Anthropic API", vim.log.levels.ERROR)
		return nil
	end

	local ok, response = pcall(vim.fn.json_decode, result)
	if not ok then
		vim.notify("Failed to parse Anthropic API response", vim.log.levels.ERROR)
		return nil
	end

	if response.error then
		vim.notify("Anthropic API error: " .. (response.error.message or "Unknown error"), vim.log.levels.ERROR)
		return nil
	end

	return response
end

--- Parse AI response to extract commit message
--- @param response table API response
--- @return string|nil Commit message or nil if failed
function M.parse_ai_response(response)
	if response.content and response.content[1] and response.content[1].text then
		local message = response.content[1].text:gsub("^%s+", ""):gsub("%s+$", "")
		--- Remove any quotes or extra formatting
		message = message:gsub('^"', ""):gsub('"$', "")
		message = message:gsub("^'", ""):gsub("'$", "")
		return message
	end
	return nil
end

--- Truncate diff content to fit within API limits
--- @param diff string Full diff content
--- @param max_chars number Maximum characters to keep
--- @return string Truncated diff
function M.truncate_diff(diff, max_chars)
	if #diff <= max_chars then
		return diff
	end

	local truncated = diff:sub(1, max_chars)
	--- Try to end at a line boundary
	local last_newline = truncated:find("\n[^\n]*$")
	if last_newline then
		truncated = truncated:sub(1, last_newline)
	end

	return truncated .. "\n... (truncated)"
end

--- Categorize files based on patterns
--- @param files table List of file paths
--- @return table categories Table mapping category names to matching files
function M.categorize_files(files)
	local categories = {}

	for _, file in ipairs(files) do
		local matched = false
		for category, patterns in pairs(M.config.patterns) do
			for _, pattern in ipairs(patterns) do
				if file:match(pattern) then
					if not categories[category] then
						categories[category] = {}
					end
					table.insert(categories[category], file)
					matched = true
					break
				end
			end
			if matched then
				break
			end
		end

		if not matched then
			if not categories.other then
				categories.other = {}
			end
			table.insert(categories.other, file)
		end
	end

	return categories
end

--- Generate commit message with AI and fallback system
--- @param changes table The changes from analyze_changes()
--- @param force_method string|nil Force specific method: "ai", "rules", "generic"
--- @param title_only boolean Whether to generate only the subject line
--- @return string Generated commit message
function M.generate_message(changes, force_method, title_only)
	if not changes then
		return "chore: update files"
	end

	local repo_context = M.detect_repo_context()

	--- Try AI generation first (unless forced otherwise)
	if force_method ~= "rules" and force_method ~= "generic" then
		local ai_message = M.generate_ai_message(changes, repo_context, title_only)
		if ai_message then
			return ai_message
		end

		--- If AI was specifically requested but failed, notify user
		if force_method == "ai" then
			vim.notify("AI generation failed, no fallback available", vim.log.levels.ERROR)
			return "chore: update files"
		end
	end

	--- Fallback to rule-based generation (always title-only for rule-based)
	if M.config.fallback.use_rules and force_method ~= "generic" then
		local rule_message = M.generate_rule_based_message(changes, repo_context)
		if rule_message then
			return rule_message
		end
	end

	--- Final fallback to generic message (always title-only)
	if M.config.fallback.use_generic then
		return M.generate_generic_message(changes, repo_context)
	end

	return "chore: update files"
end
--- Generate commit message using rule-based approach
--- @param changes table The changes from analyze_changes()
--- @param repo_context table Repository context
--- @return string Generated commit message
function M.generate_rule_based_message(changes, repo_context)
	local all_files = {}
	vim.list_extend(all_files, changes.added)
	vim.list_extend(all_files, changes.modified)

	if #all_files == 0 and #changes.deleted > 0 then
		vim.list_extend(all_files, changes.deleted)
	end

	local categories = M.categorize_files(all_files)

	--- Generate message for single category
	if vim.tbl_count(categories) == 1 then
		local category, files = next(categories)
		return M.generate_single_category_message(category, files, changes, repo_context)
	end

	--- Generate message for multiple categories
	return M.generate_multi_category_message(categories, changes, repo_context)
end

--- Generate generic commit message as final fallback
--- @param changes table The changes from analyze_changes()
--- @param repo_context table Repository context
--- @return string Generated commit message
function M.generate_generic_message(changes, repo_context)
	local has_new_files = #changes.added > 0
	local has_deletions = #changes.deleted > 0
	local has_modifications = #changes.modified > 0

	local use_conventional = repo_context.conventional_commits

	if has_deletions and not has_new_files and not has_modifications then
		return use_conventional and "chore: remove unused files" or "remove unused files"
	elseif has_new_files and not has_modifications and not has_deletions then
		return use_conventional and "feat: add new files" or "add new files"
	elseif has_modifications and not has_new_files and not has_deletions then
		return use_conventional and "chore: update existing files" or "update existing files"
	else
		return use_conventional and "chore: update files" or "update files"
	end
end

--- Generate message for single category changes
--- @param category string The category name
--- @param files table List of files in this category
--- @param changes table The full changes object
--- @param repo_context table Repository context
--- @return string Generated commit message
function M.generate_single_category_message(category, files, changes, repo_context)
	local has_new_files = #changes.added > 0
	local has_deletions = #changes.deleted > 0
	local use_conventional = repo_context.conventional_commits

	local scope = M.determine_scope(category, files, repo_context)

	if category == "docs" then
		if has_new_files then
			return use_conventional and "docs: add documentation" or "add documentation"
		else
			return use_conventional and "docs: update documentation" or "update documentation"
		end
	elseif category == "tests" then
		if has_new_files then
			return use_conventional and "test: add new tests" or "add new tests"
		else
			return use_conventional and "test: update existing tests" or "update existing tests"
		end
	elseif category == "config" then
		if has_new_files then
			local msg = "add configuration"
			return use_conventional and (scope and "config(" .. scope .. "): " .. msg or "config: " .. msg) or msg
		else
			local msg = "update configuration"
			return use_conventional and (scope and "config(" .. scope .. "): " .. msg or "config: " .. msg) or msg
		end
	elseif category == "ci" then
		if has_new_files then
			return use_conventional and "ci: add CI configuration" or "add CI configuration"
		else
			return use_conventional and "ci: update CI configuration" or "update CI configuration"
		end
	elseif category == "build" then
		if has_new_files then
			return use_conventional and "build: add build configuration" or "add build configuration"
		else
			return use_conventional and "build: update build configuration" or "update build configuration"
		end
	else
		--- Language-specific handling
		if M.is_language_category(category) then
			if has_new_files then
				local msg = "add " .. category .. " files"
				return use_conventional and "feat: " .. msg or msg
			else
				local msg = "update " .. category .. " code"
				return use_conventional and "refactor: " .. msg or msg
			end
		end

		--- Generic fallback
		if has_deletions then
			return use_conventional and "chore: remove unused files" or "remove unused files"
		elseif has_new_files then
			return use_conventional and "feat: add new functionality" or "add new functionality"
		else
			return use_conventional and "chore: update files" or "update files"
		end
	end
end

--- Generate message for multiple category changes
--- @param categories table Categories with their files
--- @param changes table The full changes object
--- @param repo_context table Repository context
--- @return string Generated commit message
function M.generate_multi_category_message(categories, changes, repo_context)
	local primary_category = M.get_primary_category(categories)
	local has_new_files = #changes.added > 0
	local use_conventional = repo_context.conventional_commits

	if primary_category == "docs" then
		return use_conventional and "docs: update documentation and code" or "update documentation and code"
	elseif primary_category == "tests" then
		return use_conventional and "test: update tests and code" or "update tests and code"
	elseif primary_category == "config" then
		return use_conventional and "config: update configuration files" or "update configuration files"
	elseif primary_category == "ci" then
		return use_conventional and "ci: update CI and code" or "update CI and code"
	else
		if has_new_files then
			return use_conventional and "feat: add new features" or "add new features"
		else
			return use_conventional and "chore: update multiple components" or "update multiple components"
		end
	end
end

--- Determine scope for conventional commits
--- @param category string The category name
--- @param files table List of files in this category
--- @param repo_context table Repository context
--- @return string|nil Scope or nil
function M.determine_scope(category, files, repo_context)
	if not repo_context.conventional_commits then
		return nil
	end

	--- Try to extract scope from file paths
	for _, file in ipairs(files) do
		local parts = vim.split(file, "/")
		if #parts > 1 then
			--- Use directory name as scope
			local dir = parts[1]
			if dir ~= "." and dir ~= ".." then
				return dir
			end
		end
	end

	--- Use language as scope if applicable
	if repo_context.language and M.is_language_category(category) then
		return repo_context.language
	end

	return nil
end

--- Check if category is a programming language
--- @param category string Category name
--- @return boolean Is language category
function M.is_language_category(category)
	local language_categories = {
		"javascript",
		"python",
		"rust",
		"go",
		"java",
		"csharp",
		"cpp",
		"php",
		"ruby",
		"swift",
		"lua",
		"shell",
	}

	for _, lang in ipairs(language_categories) do
		if category == lang then
			return true
		end
	end

	return false
end

--- Get the primary category from multiple categories
--- @param categories table Categories with their files
--- @return string Primary category name
function M.get_primary_category(categories)
	local priority = { "plugins", "config", "docs", "tests", "shell", "brew" }

	for _, category in ipairs(priority) do
		if categories[category] then
			return category
		end
	end

	return next(categories) or "other"
end

--- Extract plugin name from file path
--- @param filepath string Path to plugin file
--- @return string Plugin name
function M.extract_plugin_name(filepath)
	local name = filepath:match("lua/plugins/(.+)%.lua$")
	if name then
		return name:gsub("-", " "):gsub("_", " ")
	end
	return "plugin"
end

--- Setup commands and keymaps
function M.setup(user_config)
	--- Merge user configuration with defaults
	if user_config then
		M.config = vim.tbl_deep_extend("force", M.config, user_config)
	end

	--- Create the GenerateCommitMsg command
	vim.api.nvim_create_user_command("GenerateCommitMsg", function(opts)
		local changes = M.analyze_changes()
		if not changes then
			return
		end

		local args = vim.split(opts.args or "", "%s+")
		local force_method = nil
		local action = "copy"
		local title_only = false

		--- Parse arguments
		for _, arg in ipairs(args) do
			if arg == "--ai-only" then
				force_method = "ai"
			elseif arg == "--rules" then
				force_method = "rules"
			elseif arg == "--generic" then
				force_method = "generic"
			elseif arg == "--insert" then
				action = "insert"
			elseif arg == "--preview" then
				action = "preview"
			elseif arg == "--title-only" then
				title_only = true
			end
		end

		local message = M.generate_message(changes, force_method, title_only)
		if action == "insert" then
			--- Insert into current buffer
			local lines = vim.split(message, "\n")
			vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
		elseif action == "preview" then
			--- Show preview with multiple options
			M.show_preview(changes)
		else
			--- Copy to clipboard and notify
			vim.fn.setreg("+", message)
			local method_info = force_method and " (" .. force_method .. ")" or ""
			local format_info = title_only and " (title only)" or ""
			vim.notify(
				"Commit message copied to clipboard" .. method_info .. format_info .. ": " .. message,
				vim.log.levels.INFO
			)
		end
	end, {
		nargs = "*",
		complete = function()
			return { "--insert", "--preview", "--ai-only", "--rules", "--generic", "--title-only" }
		end,
		desc = "Generate commit message based on staged changes",
	})

	--- Set up buffer-local keymaps for git commit buffers
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "gitcommit",
		callback = function()
			vim.keymap.set("n", "<leader>gm", ":GenerateCommitMsg --insert<CR>", {
				buffer = true,
				desc = "Generate and insert commit message (AI + fallback)",
			})
			vim.keymap.set("n", "<leader>gp", ":GenerateCommitMsg --preview<CR>", {
				buffer = true,
				desc = "Preview commit message options",
			})
			vim.keymap.set("n", "<leader>ga", ":GenerateCommitMsg --ai-only --insert<CR>", {
				buffer = true,
				desc = "Generate AI-only commit message",
			})
			vim.keymap.set("n", "<leader>gr", ":GenerateCommitMsg --rules --insert<CR>", {
				buffer = true,
				desc = "Generate rule-based commit message",
			})
			vim.keymap.set("n", "<leader>gt", ":GenerateCommitMsg --title-only --insert<CR>", {
				buffer = true,
				desc = "Generate title-only commit message",
			})
		end,
	})
end

--- Show preview with multiple commit message options
--- @param changes table The changes from analyze_changes()
function M.show_preview(changes)
	local options = M.generate_multiple_options(changes)

	vim.ui.select(options, {
		prompt = "Select commit message:",
		format_item = function(item)
			return item.message .. " (" .. item.source .. ")"
		end,
	}, function(choice)
		if choice then
			vim.fn.setreg("+", choice.message)
			vim.notify(
				"Commit message copied to clipboard (" .. choice.source .. "): " .. choice.message,
				vim.log.levels.INFO
			)
		end
	end)
end

--- Generate multiple commit message options from different sources
--- @param changes table The changes from analyze_changes()
--- @return table List of commit message options with sources
function M.generate_multiple_options(changes)
	local options = {}
	local repo_context = M.detect_repo_context()

	--- Try AI generation
	if M.config.ai.enabled then
		local ai_message = M.generate_ai_message(changes, repo_context)
		if ai_message then
			table.insert(options, { message = ai_message, source = "AI" })
		end
	end

	--- Add rule-based options
	local rule_message = M.generate_rule_based_message(changes, repo_context)
	if rule_message then
		table.insert(options, { message = rule_message, source = "Rules" })
	end

	--- Add generic fallback
	local generic_message = M.generate_generic_message(changes, repo_context)
	table.insert(options, { message = generic_message, source = "Generic" })

	--- Add some manual alternatives if we have AI or rule-based messages
	if #options > 1 then
		local base_message = options[1].message

		--- Create variations
		if base_message:match("^feat") then
			table.insert(options, { message = base_message:gsub("^feat", "add"), source = "Variant" })
		elseif base_message:match("^fix") then
			table.insert(options, { message = base_message:gsub("^fix", "resolve"), source = "Variant" })
		elseif base_message:match("^docs") then
			table.insert(options, { message = base_message:gsub("^docs", "update"), source = "Variant" })
		end
	end

	--- Ensure we have at least one option
	if #options == 0 then
		table.insert(options, { message = "chore: update files", source = "Fallback" })
	end

	return options
end

return M
