local ffi = require("ffi")

---@class env.raw.bsd: env.raw.posix
local env = require("env.raw.posix")

ffi.cdef([[
	ssize_t readlink(const char* path, char* buf, size_t bufsiz);
	int uname(char* buf);
	int sysctl(const int* name, unsigned int namelen, void* oldp, size_t* oldlenp, const void* newp, size_t newlen);
]])

local BUF_SIZE = 4096

--- Returns the kernel name, such as "FreeBSD" or "OpenBSD", or nil if uname(3) fails.
---@return string?
local function sysname()
	local buf = ffi.new("char[?]", BUF_SIZE)
	if ffi.C.uname(buf) ~= 0 then
		return nil
	end

	return ffi.string(buf)
end

--- Reads a procfs link to the executable. readlink(2) does not terminate its
--- result, so the length it returns bounds the string.
---@param link string
---@return string?
local function readlink(link)
	local buf = ffi.new("char[?]", BUF_SIZE)
	local len = ffi.C.readlink(link, buf, BUF_SIZE)
	if len < 0 then
		return nil
	end

	return ffi.string(buf, len)
end

local PROCFS_LINKS = {
	"/proc/curproc/file", -- FreeBSD, DragonFly
	"/proc/curproc/exe", -- NetBSD
	"/proc/self/exe", -- GNU/kFreeBSD, a BSD userland over a Linux kernel
}

---@return string?
local function procfsExecPath()
	for _, link in ipairs(PROCFS_LINKS) do
		local path = readlink(link)
		if path ~= nil and path ~= "" then
			return path
		end
	end

	return nil
end

---@param mib integer[]
---@return fun(): string?
local function sysctlExecPath(mib)
	local name = ffi.new("int[4]", mib)

	return function()
		local buf = ffi.new("char[?]", BUF_SIZE)
		local len = ffi.new("size_t[1]", BUF_SIZE)

		if ffi.C.sysctl(name, 4, buf, len, nil, 0) == 0 then
			local path = ffi.string(buf)
			if path ~= "" then
				return path
			end
		end

		-- Fallback
		return procfsExecPath()
	end
end

local execPathMethods = {
	FreeBSD = sysctlExecPath({ 1, 14, 12, -1 }),
	DragonFly = sysctlExecPath({ 1, 14, 9, -1 }),
	NetBSD = sysctlExecPath({ 1, 48, -1, 5 }),
	OpenBSD = procfsExecPath,
}

env.execPath = execPathMethods[sysname()] or procfsExecPath

return env
