# Developer Util - Creates SymLinks from the 'X4DESO' repository
# root (ie. current working directory) to the default ESO AddOns
# folder. Relevant folder path parts are created if they do not
# already exist. If this does not allow the game to load X4DESO 
# then the game is not reading from the default (profile-level)
# AddOns folder.
function createAddOnSymLink($addOnName) {
    $cwd = (Get-Location).Path
    $addOnsLiveFolder = "$env:USERPROFILE/documents/Elder Scrolls Online/live/AddOns";
    if (![System.IO.Directory]::Exists($addOnsLiveFolder)) {
        mkdir $addOnsLiveFolder 1>> $null
    }
    if (![System.IO.Directory]::Exists("$addOnsLiveFolder/$addOnName")) {
        $symLinkTargetPath = [System.IO.Path]::GetFullPath("$cwd/$addOnName")
        if (![System.IO.Directory]::Exists("$symLinkTargetPath")) {
            Write-Warning "Cannot find addon folder '$symLinkTargetPath', skipping."
        }
        else {
            New-Item -ItemType SymbolicLink -Path "$addOnsLiveFolder/$addOnName" -Target "$symLinkTargetPath" 1>> $null
            Write-Host "Created SymLink for '$addOnName'"
        }
    }
    else {
        Write-Warning "Folder/Link already exists for '$addOnName', skipping."
    }
}

createAddOnSymLink "X4D_Bank"
createAddOnSymLink "X4D_Chat"
createAddOnSymLink "X4D_Core"
createAddOnSymLink "X4D_LibAntiSpam"
createAddOnSymLink "X4D_Loot"
createAddOnSymLink "X4D_Mail"
createAddOnSymLink "X4D_MiniMap"
createAddOnSymLink "X4D_UI"
createAddOnSymLink "X4D_Vendors"
createAddOnSymLink "X4D_XP"
createAddOnSymLink "X4D_Quest"
