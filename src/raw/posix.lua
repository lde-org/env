local ffi = require("ffi")

ffi.cdef([[
	char* getenv(const char* name);
	int setenv(const char* name, const char* value, int overwrite);
	int unsetenv(const char* name);
	char* getcwd(char* buf, size_t size);
	int chdir(const char* path);
]])

---@class env.raw.posix: env.raw
---@field var fun(name: string): string?
---@field set fun(name: string, value: string?): boolean
---@field tmpdir fun(): string
---@field cwd fun(): string?
---@field chdir fun(dir: string): boolean
local env = {}

---@param name string
function env.var(name) ---@return string?
	local v = ffi.C.getenv(name)
	if v == nil then
		return nil
	end

	return ffi.string(v)
end

---@param name string
---@param value string
function env.set(name, value) ---@return boolean
	if value == nil then
		return ffi.C.unsetenv(name) == 0
	end
	return ffi.C.setenv(name, value, 1) == 0
end

function env.tmpdir()
	return env.var("TMPDIR") or "/tmp"
end

function env.cwd()
	local buf = ffi.new("char[?]", 4096)

	local result = ffi.C.getcwd(buf, 4096)
	if result == nil then
		return nil
	end

	return ffi.string(buf)
end

---@param dir string
function env.chdir(dir) ---@return boolean
	return ffi.C.chdir(dir) == 0
end

return env
