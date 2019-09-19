---
--- Parses a version string such as "1", "1.2", or "1.2.3" returning
--- each constituent part (referred to as "major", "minor" and
--- "patch".)
---
local function ParseVersionString(s)
    if (s == nil or (type(s) ~= "string" and type(s) ~= "number") or tonumber("0"..s) == 0) then
        return 0,0,0
    end
    if (type(s) == "number") then
        s = "0."..s..".0"
    end
    local major, minor, patch = nil, nil, nil
    for match in (s.."."):gmatch('(%d-)%.') do
        local s = tostring(match)
        if (s:len() > 0) then
            if (major == nil) then
                major = tonumber(s)
            elseif (minor == nil) then
                minor = tonumber(s)
            else
                patch = tonumber(s)
            end
        end
    end
    return major or 0, minor or 0, patch or 0
end

---
--- Determines if the actual version string is semantically the
--- same as the expected version string. A version is said to be
--- semantically similar when the majors are identical, and the
--- expected minor+patch is less than or equal to the actual
--- minor+patch.
---
--- As per SEMVER typical constraints, specifying an expected
--- version that is GREATER than actual version will cause the
--- check to fail.
--- 
local function DoesVersionSatisfy(expectedVersion, actualVersion)
    local expectedMajor, expectedMinor, expectedPatch = ParseVersionString(expectedVersion)
    local actualMajor, actualMinor, actualPatch = ParseVersionString(actualVersion)
    return (expectedMajor == nil or expectedMajor == actualMajor)
        and (expectedMinor == nil or expectedMinor <= actualMinor)
        and (expectedPatch == nil or expectedPatch <= actualPatch)
end

-- stub self
local X4D_LIBSTUB_VERSION = "#VERSION#"
local LibStub = _G["LibStub"]
local legacyLibStub = LibStub
if (not LibStub or not DoesVersionSatisfy(X4D_LIBSTUB_VERSION, LibStub.version)) then
    LibStub = {
        version = X4D_LIBSTUB_VERSION,
        libs = {}
    }
    if (legacyLibStub and legacyLibStub.libs and legacyLibStub.minors) then
        -- assume LibStub has been used once already and pull over existing state
        for id,version in legacyLibStub:IterateLibraries() do
            LibStub.libs[id] = {
                id = id,
                ref = legacyLibStub(id),
                version = version
            }
        end
    end
    function LibStub:NewLibrary(id, version)
        assert(type(id) == "string", "Bad argument `id` to `NewLibrary` (string expected)")
        local exists = self.libs[id]
        local major, minor, patch = ParseVersionString(version)
        if (exists) then
            local existsMajor, existsMinor, existsPatch = ParseVersionString(exists.version)
            if (existsMajor >= major and existsMinor >= minor and existsPatch >= patch) then
                return nil 
            end
        end
        self.libs[id] = {
            id = id, 
            ref = {},
            version = version
        }
        return self.libs[id].ref
    end
    function LibStub:GetLibrary(id, version, silent)
        local lib = self.libs[id]
		if (not lib and not silent) then
			error("Cannot find library `"..id.."` in container.")
        end
        if (lib and version) then
            DoesVersionSatisfy(version, lib.version)
        end
		return lib.ref, lib.version
    end
    function LibStub:ParseVersionString(version)
        return ParseVersionString(version)
    end
    function LibStub:IterateLibraries()
        local list = {}
        for id,lib in pairs(self.libs) do
            list[id] = lib.version
        end
        return pairs(list)
    end
    setmetatable(LibStub, { __call = LibStub.GetLibrary })
    LibStub.minor = 3
    _G["LibStub"] = LibStub
end
