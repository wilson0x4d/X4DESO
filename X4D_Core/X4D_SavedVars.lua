local X4D_SavedVars = LibStub:NewLibrary('X4D_SavedVars', 1.0);
if (not X4D_SavedVars) then
	return;
end

--[[

* "Wrappers for New / NewAccountWide"
* Defaults are only applied if MISSING, and only the specific default values which are missing.
* Optionally "Force Defaults" on version change, instead of automatically performed. 
* Raise event when SavedVars are loaded (one for account wide, another for per-character)

["ZO_SavedVars"] = table: 3D0972A0

]]