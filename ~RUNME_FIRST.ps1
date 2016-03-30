# GNURadio Windows Build System
# Geof Nieboer
#
# RUNME_FIRST.ps1
#
$Global:root = Read-Host "Please choose an absolute root directory for this build <c:\gr-build>"
if (!$root) {$root = "C:/gr-build"}
if (!(Test-Path -isValid -LiteralPath $root)) {
    Write-Host "'$root' is not a valid path.  Exiting script."
    return
}
if (![System.IO.Path]::IsPathRooted($root)) {
    Write-Host "'$root' is not an absolute path.  Exiting script."
    return
}
# setup
"Performing initial setup"
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

ResetLog
Write-Host -NoNewline "Setting up directories..." 
# build basic directories
New-Item -ItemType Directory -Force -Path $root > $null
New-Item -ItemType Directory -Force -Path "$root\logs" > $null
SetupLog "Initial Configuration"
New-Item -ItemType Directory -Force -Path "$root\bin" >> $Log
New-Item -ItemType Directory -Force -Path "$root\build" >> $Log
New-Item -ItemType Directory -Force -Path "$root\include" >> $Log
New-Item -ItemType Directory -Force -Path "$root\packages" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage1-dependencies" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage2-python" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage3" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage4-installer" >> $Log
New-Item -ItemType Directory -Force -Path "$root\scripts" >> $Log
Copy-Item ./bin $root/bin -Recurse -Force >> $Log
Copy-Item ./wix $root/src-stage4-installer -Recurse -Force >> $Log
Copy-Item ./*.ps1 $root/scripts -Force >> $Log
Remove-Item $root/scripts/~RUNME_FIRST.ps1 >> $Log  # Don't need this file in the build tree after everything is there
cd $root/scripts

& Step1-UserPreferences.ps1