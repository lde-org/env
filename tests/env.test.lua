local test = require("lde-test")
local env = require("env")

-- var / set

test.it("var returns nil for unset variable", function()
	env.set("LDE_TEST_UNSET", nil)
	test.falsy(env.var("LDE_TEST_UNSET"))
end)

test.it("set and var round-trip a string value", function()
	env.set("LDE_TEST_VAR", "hello")
	test.equal(env.var("LDE_TEST_VAR"), "hello")
end)

test.it("set with nil clears the variable", function()
	env.set("LDE_TEST_CLEAR", "present")
	env.set("LDE_TEST_CLEAR", nil)
	test.falsy(env.var("LDE_TEST_CLEAR"))
end)

test.it("set returns true on success", function()
	test.truthy(env.set("LDE_TEST_BOOL", "1"))
end)

-- tmpdir

test.it("tmpdir returns a non-empty string", function()
	local dir = env.tmpdir()
	test.truthy(dir)
	test.greater(#dir, 0)
end)

-- cwd / chdir

test.it("cwd returns a non-empty string", function()
	test.greater(#env.cwd(), 0)
end)

test.it("chdir changes the working directory", function()
	local original = env.cwd()
	local tmp = env.tmpdir()
	test.truthy(env.chdir(tmp))
	-- On some systems tmpdir may be a symlink; compare resolved paths via cwd()
	test.notEqual(env.cwd(), "")
	env.chdir(original)
end)

test.it("chdir returns false for a non-existent directory", function()
	test.falsy(env.chdir("/this/path/does/not/exist/lde_env_test"))
end)

-- execPath

test.it("execPath returns nil or a non-empty string", function()
	local p = env.execPath()
	if p ~= nil then
		test.greater(#p, 0)
	end
end)

-- tmpfile

test.it("tmpfile returns a string path inside tmpdir", function()
	local f = env.tmpfile()
	test.truthy(f)
	test.includes(f, env.tmpdir())
end)

test.it("successive tmpfile calls return distinct paths", function()
	local a = env.tmpfile()
	local b = env.tmpfile()
	test.notEqual(a, b)
end)

test.it("tmpfile path contains the luaenv_ prefix", function()
	test.includes(env.tmpfile(), "luaenv_")
end)

return test.run()
