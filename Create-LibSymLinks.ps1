# Developer Util - Creates SymLinks to the $/X4DESO/lib/ folders 
# folder within all of the addons. For packaging purposes we only
# symlink the libs which each AddOn actually requires.
function createLibrarySymLink([string] $addOnName, [string] $libraryName) {
    $cwd = (Get-Location).Path
    $libraryPath = [System.IO.Path]::GetFullPath("$cwd/lib/$libraryName")
    $addOnPath = [System.IO.Path]::GetFullPath("$cwd/$addOnName")
    $addOnLibraryPath = "$addOnPath/lib/$libraryName"
    Write-Information "$cwd"
    Write-Information "$libraryPath"
    Write-Information "$addOnPath"
    Write-Information "$addOnLibraryPath"
    if (![System.IO.Directory]::Exists("$addOnPath")) {
        Write-Warning "Cannot find '$addOnName', skipping."
    } elseif (![System.IO.Directory]::Exists("$libraryPath")) {
        Write-Warning "Cannot find '$libraryName', skipping."
    } elseif ([System.IO.Directory]::Exists("$addOnLibraryPath")) {
        Write-Warning "Already exists '$addOnName/lib/$libraryName', skipping."
    } else {
        if (![System.IO.Directory]::Exists("$addOnPath/lib")) {
            mkdir "$addOnPath/lib" 1>> $null
        }
        New-Item -ItemType SymbolicLink -Path "$addOnLibraryPath" -Target "$libraryPath" 1>> $null
        Write-Host "Created SymLink for '$addOnName' to '$libraryName'"
    }
}

# TODO: for each AddOn, inspect toc/txt file and derive the 
#        list of libraries required for each. (instead of hardcoding
#        them like this, here.)

createLibrarySymLink "X4D_Bank" "LibStub"

createLibrarySymLink "X4D_Chat" "LibStub"

createLibrarySymLink "X4D_Core" "badgerman"
createLibrarySymLink "X4D_Core" "kikito"
createLibrarySymLink "X4D_Core" "LibAddonMenu-2.0"
createLibrarySymLink "X4D_Core" "LibStub"

createLibrarySymLink "X4D_LibAntiSpam" "LibStub"
createLibrarySymLink "X4D_LibAntiSpam" "utf8"

createLibrarySymLink "X4D_Loot" "LibStub"

createLibrarySymLink "X4D_Mail" "LibStub"

createLibrarySymLink "X4D_MiniMap" "LibStub"

createLibrarySymLink "X4D_UI" "LibStub"

createLibrarySymLink "X4D_Vendors" "LibStub"

createLibrarySymLink "X4D_XP" "LibStub"

createLibrarySymLink "X4D_Quest" "LibStub"
