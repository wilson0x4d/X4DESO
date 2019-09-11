$cwd = (Get-Location).Path
$commitHash = (git rev-parse HEAD).SubString(0, 7)
$dateStamp = (Get-Date).ToString("yyyMMdd")
$distPath = [System.IO.Path]::Combine($cwd, "dist")
$tempPath = [System.IO.Path]::Combine($distPath, "tmp")

# remove dist (pre-clean)
if ([System.IO.Directory]::Exists($distPath)) {
    Remove-Item -Force -Recurse $distPath | Out-Null
}
New-Item -ItemType Directory $distPath | Out-Null

function textReplaceAllFiles([string] $path, [string] $expando, [string] $replacement) {
    $files = [System.IO.Directory]::GetFiles($path, "*.*")
    foreach ($file in $files) {        
        (Get-Content -Path $file -ReadCount 0) -join "`n" -replace $expando, $replacement | Set-Content -Path "$file"
    }
    $directories = [System.IO.Directory]::GetDirectories($path)
    foreach ($directory in $directories) {
        textReplaceAllFiles "$directory" $expando $replacement
    }
}

function injectLibraries([string] $addOnName, [string] $libraryName) {
    $libraryPath = [System.IO.Path]::GetFullPath("$cwd/lib/$libraryName")
    if (![System.IO.Directory]::Exists("$libraryPath")) {
        Write-Warning "Cannot find '$libraryName', skipping!"
        return
    } 
    $addOnPath = [System.IO.Path]::GetFullPath("$cwd/dist/tmp/$addOnName")
    if (![System.IO.Directory]::Exists("$addOnPath/lib")) {
        mkdir "$addOnPath/lib" 1>> $null
    }
    $addOnLibraryPath = "$addOnPath/lib/$libraryName"
    if ([System.IO.Directory]::Exists($addOnLibraryPath)) {
        Remove-Item -Recurse -Force -Path $addOnLibraryPath
    }
    Copy-Item -Recurse -Force "$libraryPath" "$addOnLibraryPath"
    Write-Debug " '$libraryPath'->'$addOnLibraryPath'"
}

function createModuleArchive($moduleName, $packageVersion) {

    # construct module (temp)
    Copy-Item -Recurse -Force "$cwd/$moduleName" "$tempPath/$moduleName" | Out-Null
    Copy-Item -Force "$cwd/LICENSE.md" "$tempPath/$moduleName/LICENSE.md" | Out-Null

    if ($env:appveyor_build_version) {
        textReplaceAllFiles "$tempPath/$moduleName" "#VERSION#" "$env:appveyor_build_version"
    }
    $packageName = "$moduleName-$packageVersion.zip"

    # allocate library dependencies (this is only necessary for build server)
    # TODO: this could be a dictionary of arrays, or even better, parse from the txt/toc of each AddOn
    if ($moduleName -eq "X4D_Bank") {
        injectLibraries "X4D_Bank" "LibStub"
    }
    if ($moduleName -eq "X4D_Chat") {
        injectLibraries "X4D_Chat" "LibStub"
    }
    if ($moduleName -eq "X4D_Core") {
        injectLibraries "X4D_Core" "badgerman"
        injectLibraries "X4D_Core" "kikito"
        injectLibraries "X4D_Core" "LibAddonMenu-2.0"
        injectLibraries "X4D_Core" "LibStub"
    }
    if ($moduleName -eq "X4D_LibAntiSpam") {
        injectLibraries "X4D_LibAntiSpam" "LibStub"
        injectLibraries "X4D_LibAntiSpam" "utf8"
    }
    if ($moduleName -eq "X4D_Loot") {
        injectLibraries "X4D_Loot" "LibStub"
    }
    if ($moduleName -eq "X4D_Mail") {
        injectLibraries "X4D_Mail" "LibStub"
    }
    if ($moduleName -eq "X4D_MiniMap") {
        injectLibraries "X4D_MiniMap" "LibStub"
    }
    if ($moduleName -eq "X4D_UI") {
        injectLibraries "X4D_UI" "LibStub"
    }
    if ($moduleName -eq "X4D_Vendors") {
        injectLibraries "X4D_Vendors" "LibStub"
    }
    if ($moduleName -eq "X4D_XP") {
        injectLibraries "X4D_XP" "LibStub"
    }
    if ($moduleName -eq "X4D_Quest") {
        injectLibraries "X4D_Quest" "LibStub"
    }

    # create archive (final)
    Compress-Archive -Path "$tempPath/$moduleName/*" -DestinationPath "$distPath/$packageName" -CompressionLevel Optimal

    if ([System.IO.File]::Exists("$distPath/$packageName")) {
        Write-Output $packageName
    }
}

if ($env:appveyor_build_version) {
    $packageVersion = "$env:appveyor_build_version"
}
else {
    $packageVersion = "$dateStamp-$commitHash"
}


# package each module as a separate AddOn
Get-ChildItem "X4D_*" | ForEach-Object { createModuleArchive $_.Name $packageVersion }

# create an "All-in-One" package (primary redist)
Copy-Item -Force "$cwd/LICENSE.md" "$tempPath/LICENSE.md" | Out-Null
Copy-Item -Force "$cwd/README.md" "$tempPath/README.md" | Out-Null
Compress-Archive "$tempPath/X4D_*" -DestinationPath "$distPath/X4D_AllInOne-$packageVersion.zip" -CompressionLevel Optimal
Compress-Archive "$temppath/*.md" -Update -DestinationPath "$distPath/X4D_AllInOne-$packageVersion.zip" -CompressionLevel Optimal
Write-Output "X4D_AllInOne-$packageVersion.zip"

# remove temp (post-clean)
if ([System.IO.Directory]::Exists($tempPath)) {
    Remove-Item -Recurse -Force -Path $tempPath
}
