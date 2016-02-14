
#setup
$root = $env:grwinbuildroot 
if (!$root) {$root = "C:\gr-build"}
cd $root

Add-Type -assembly "system.io.compression.filesystem"

# build basic directories
New-Item -ItemType Directory -Force -Path $root
New-Item -ItemType Directory -Force -Path "C:\gr-build\bin"

# Check for binary dependencies

# ensure we are using 64-bit windows
if (${env:ProgamFiles(x86)} = $null) {throw "It appears you are using 32-bit windows.  This build requires 64-bit windows"}
$myprog = "${Env:ProgramFiles(x86)}"

# check for visual studio
if (!(Test-Path "$myprog\Microsoft Visual Studio 14.0\VC\")) {throw 	"Error: Visual Studio 2015 must be installed."}

# check for CMake (to build gnuradio)
if (!(Test-Path  "$myprog\Cmake\bin\cmake.exe")) {throw 	"Error: CMake must be installed."}

# check for ActivePerl (to build OpenSSL)
if (!(test-path "$env:ProgramFiles\perl64\bin\perl.exe")) {throw "ActivePerl 64-bit must be installed"} 

# check for Git
if (!(test-path "$env:ProgramFiles\Git\usr\bin\tar.exe")) {throw "Git For Windows must be installed"} 

# get 7zip command line (no install required)
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