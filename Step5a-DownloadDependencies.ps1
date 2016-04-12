#
# GNURadio Windows Build System
# Step5a_DownloadDependencies.ps1
#
# Geof Nieboer
#
# Downloads pre-built binaries from www.gcndevelopment.com and places in the correct directory
# including custom versions of python with packages already installed
#
# Note that all these packages were built from source with VS 2015 and may not be installed in the
# traditional manner, so it is generally not recommended to use these libraries, particularly python,
# outside of this integrated environment.  
#
# Individual libraries are available at www.gcndevelopment.com/gnuradio/downloads.htm
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
. $mypath\Setup.ps1 -Force

cd $root

SetLog "Download dependencies"

GetPatch gnuradio_dependency_pack_v$dp_version.7z ../

Function buildQtConf
{
	$configuration = $args[0]
	"[Paths]\n" > $root/build/$configuration/bin/qt.conf
	"Prefix = $root/build/$configuration" >> $root/build/$configuration/bin/qt.conf
	"complete"
}

buildQtConf "Release"
buildQtConf "Debug"
buildQtConf "Release-AVX2"

cd $root/scripts