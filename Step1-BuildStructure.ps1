
#setup
$root = $env:grwinbuildroot 
if (!$root) {$root = "C:\gr-build"}
cd $root

Add-Type -assembly "system.io.compression.filesystem"

# build basic directories
New-Item -ItemType Directory -Force -Path $root
New-Item -ItemType Directory -Force -Path "C:\gr-build\bin"

# Check for binary dependencies
# CMake (to build gnuradio)
# ActivePerl (to build OpenSSL)
# get Git

# get 7zip command line
cd $root/bin
wget http://www.7-zip.org/a/7za920.zip -OutFile 7za920.zip
$BackupPath = "$root/bin/7za920.zip"
$destination = "$root/bin"
[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
del license.txt
del readme.txt
del 7-zip.chm
del 7za920.zip
set-alias sz "$root\bin\7za.exe"  