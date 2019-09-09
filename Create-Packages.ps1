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

function createModuleArchive($moduleName) {
    $packageName = "$moduleName-$dateStamp-$commitHash.zip"

    # construct module (temp)
    Copy-Item -Recurse "$cwd/$moduleName" "$tempPath/$moduleName" | Out-Null
    Copy-Item -Force "$cwd/LICENSE.md" "$tempPath/$moduleName/LICENSE.md" | Out-Null

    # create archive (final)
    Compress-Archive -Path "$tempPath/$moduleName/*" -DestinationPath "$distPath/$packageName" -CompressionLevel Optimal

    if ([System.IO.File]::Exists("$distPath/$packageName")) {
        Write-Output $packageName
    }
}

Get-ChildItem "X4D_*" | ForEach-Object { createModuleArchive $_.Name }

Copy-Item -Force "$cwd/LICENSE.md" "$tempPath/LICENSE.md" | Out-Null
Copy-Item -Force "$cwd/README.md" "$tempPath/README.md" | Out-Null
Compress-Archive "$tempPath/X4D_*" -DestinationPath "$distPath/X4D_AllInOne-$dateStamp-$commitHash.zip" -CompressionLevel Optimal
Compress-Archive "$temppath/*.md" -Update -DestinationPath "$distPath/X4D_AllInOne-$dateStamp-$commitHash.zip" -CompressionLevel Optimal
Write-Output "X4D_AllInOne-$dateStamp-$commitHash.zip"

# remove temp (post-clean)
if ([System.IO.Directory]::Exists($tempPath)) {
    Remove-Item -Recurse -Force -Path $tempPath
}
