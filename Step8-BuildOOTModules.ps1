#
# Step8_BuildOOTModules.ps1
#


# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

# ____________________________________________________________________________________________________________
#
# libosmosdr
#
New-Item -Force -ItemType Directory $root/src-stage3/oot_code/osmo-sdr/software/libosmosdr/build/Release
cd $root/src-stage3/oot_code/osmo-sdr/software/libosmosdr/build
$ErrorActionPreference = "Continue"
& cmake ../
$ErrorActionPreference = "Stop"

function BuildDrivers 
{
	$configuration = $args[0]
	# ____________________________________________________________________________________________________________
	#
	# airspy
	#
	SetLog "airspy"
	Write-Host -NoNewline "building airspy..."
	cd $root/src-stage3/oot_code/airspy/libairspy/vc
	Write-Host -NoNewline "$configuration..."
	msbuild .\airspy_2015.sln /m /p:"configuration=$configuration;platform=x64" >> $Log
	"complete"
	
	# ____________________________________________________________________________________________________________
	#
	# bladeRF
	#

	# ____________________________________________________________________________________________________________
	#
	# rtl-sdr
	#

	# ____________________________________________________________________________________________________________
	#
	# hackRF
	#
}

BuildDrivers "Debug"
BuildDrivers "Release"
BuildDrivers "Release-AVX2"

# ____________________________________________________________________________________________________________
#
# gr-osmosdr
# 
New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-osmosdr/build
cd $root/src-stage3/oot_code/gr-osmosdr/build
$ErrorActionPreference = "Continue"
& cmake ../ `
	-DCMAKE_PREFIX_PATH="$root/src-stage3/staged_install/Release" `
	-DPYTHON_LIBRARY="$root/src-stage3/staged_install/Release/gr-python27/libs/python27.lib" `
	-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/Release/gr-python27/libs/python27_d.lib" `
	-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/Release/gr-python27/python.exe" `
	-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/Release/gr-python27/include" `
	-DLIBAIRSPY_INCLUDE_DIRS="..\libairspy\src" `
	-DLIBAIRSPY_LIBRARIES="..\libairspy\x64\Release\airspy.lib" `
	-DBLADERF_INCLUDE_DIRS=""  `
	-DBLADERF_LIBRARIES="" `
	-DHACKRF_INCLUDE_DIRS=""  `
	-DHACKRF_LIBRARIES="" `
	-DLIBRTLSTR_INCLUDE_DIRS=""  `
	-DLIBRTLSDR_LIBRARIES="" `
	-DLIBOSMOSDR_INCLUDE_DIRS=""  `
	-DLIBOSMOSDR_LIBRARIES="" 
	-DENABLE_DOXYGEN=1
& nmake -C docs 
& nmake install
& ldconfig

# ____________________________________________________________________________________________________________
#
# UHD
#
# This was previously built, but now we want to install it properly over top of the GNURadio install
#

break

