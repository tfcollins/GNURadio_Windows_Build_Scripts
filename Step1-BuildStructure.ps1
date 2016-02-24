
#setup
"Performing initial setup"
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

Write-Host -NoNewline "Setting up directories..." 
# build basic directories
$Log = "$root/logs/01-Setup.txt"
New-Item -ItemType Directory -Force -Path $root > $null
New-Item -ItemType Directory -Force -Path $root\logs > $null
New-Item -ItemType Directory -Force -Path "$root\bin" > $Log
New-Item -ItemType Directory -Force -Path "$root\build" >> $Log
New-Item -ItemType Directory -Force -Path "$root\include" >> $Log
New-Item -ItemType Directory -Force -Path "$root\packages" >> $Log
New-Item -ItemType Directory -Force -Path "$root\scripts" >> $Log
"Complete"

Write-Host -NoNewline "Retrieving 7-Zip..."
# get 7zip command line (no install required)
cd $root/bin
if (!(Test-Path -Path 7za.exe)) {
	wget http://www.7-zip.org/a/7za920.zip -OutFile 7za920.zip >> $Log
	$BackupPath = "$root/bin/7za920.zip"
	$destination = "$root/bin"
	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
	del license.txt
	del readme.txt
	del 7-zip.chm
	del 7za920.zip
}
set-alias sz "$root\bin\7za.exe"  
cd $root
"Complete"
