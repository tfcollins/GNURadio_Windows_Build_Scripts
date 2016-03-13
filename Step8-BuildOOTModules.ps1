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
	if ($configuration -match "AVX2") {$arch="/arch:AVX2"; $buildconfig="Release"} else {$arch=""; $buildconfig=$configuration}
	# ____________________________________________________________________________________________________________
	#
	# airspy
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "airspy $configuration"
	Write-Host -NoNewline "building $configuration airspy..."
	cd $root/src-stage3/oot_code/airspy/libairspy/vc
	msbuild .\airspy_2015.sln /m /p:"configuration=$configuration;platform=x64" >> $Log
	"complete"
	
	# ____________________________________________________________________________________________________________
	#
	# bladeRF
	#
	# links to libusb dynamically and pthreads statically
	# Note this will give an error on build because it tries to copy pthreadVC2.dll even though it doesn't exists since statically linking.
	# This -one- error can be ignored
	#
	SetLog "bladeRF $configuration"
	Write-Host -NoNewline "configuring $configuration bladeRF..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/bladeRF/host/build/$configuration  2>&1 >> $Log
	cd $root/src-stage3/oot_code/bladeRF/host/build/$configuration
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DLIBUSB_HEADER_FILE="$root/build/$configuration/include/libusb.h" `
		-DLIBUSB_VERSION="1.0.20" `
		-DLIBUSB_SKIP_VERSION_CHECK=TRUE `
		-DENABLE_BACKEND_LIBUSB=TRUE `
		-DLIBPTHREADSWIN32_PATH="$root/build/$configuration" `
		-DLIBPTHREADSWIN32_LIB_COPYING="$root/build/$configuration/lib/COPYING.lib" `
		-DPTHREAD_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-Wno-dev `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " 2>&1 >> $Log
	Write-Host -NoNewline "building bladeRF..."
	msbuild .\bladeRF.sln /m /p:"configuration=$buildconfig;platform=x64"  2>&1 >> $Log
	"complete"

	# ____________________________________________________________________________________________________________
	#
	# rtl-sdr
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "rtl-sdr $configuration"
	Write-Host -NoNewline "configuring $configuration rtl-sdr..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/rtl-sdr/build/$configuration  2>&1 >> $Log
	cd $root/src-stage3/oot_code/rtl-sdr/build/$configuration 
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DTHREADS_PTHREADS_WIN32_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DTHREADS_PTHREADS_INCLUDE_DIR="$root/build/$configuration/include" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DLIBUSB_INCLUDE_DIR="$root/build/$configuration/include/" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" 2>&1 >> $Log
	Write-Host -NoNewline "building rtl-sdr..."
	msbuild .\rtlsdr.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	"complete"

	# ____________________________________________________________________________________________________________
	#
	# hackRF
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "HackRF $configuration"
	Write-Host -NoNewline "configuring $configuration HackRF..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/hackrf/build/$configuration  2>&1 >> $Log
	cd $root/src-stage3/oot_code/hackrf/build/$configuration 
	cmake ../../host/ `
		-G "Visual Studio 14 2015 Win64" `
		-DLIBUSB_INCLUDE_DIR="$root/build/$configuration/include/" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DTHREADS_PTHREADS_INCLUDE_DIR="$root/build/$configuration/include" `
		-DTHREADS_PTHREADS_WIN32_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" 2>&1 >> $Log
	Write-Host -NoNewline "building hackRF..."
	msbuild .\hackrf_all.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	"complete"

	# ____________________________________________________________________________________________________________
	#
	# osmo-sdr
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "osmo-sdr $configuration"
	Write-Host -NoNewline "configuring $configuration osmo-sdr..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/osmo-sdr/build/$configuration  2>&1 >> $Log
	cd $root/src-stage3/oot_code/osmo-sdr/build/$configuration 
	cmake ../../software/libosmosdr/ `
		-G "Visual Studio 14 2015 Win64" `
		-DLIBUSB_INCLUDE_DIR="$root/build/$configuration/include/" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" 2>&1 >> $Log
	Write-Host -NoNewline "building osmo-sdr..."
	msbuild .\osmosdr.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	"complete"
}

BuildDrivers "Debug"
BuildDrivers "Release"
BuildDrivers "Release-AVX2"

# ____________________________________________________________________________________________________________
#
# gr-osmosdr
# 
$configuration="Release"; $buildconfig="Release"  # TODO temp debug code
New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-osmosdr/build/$configuration
cd $root/src-stage3/oot_code/gr-osmosdr/build/$configuration
$ErrorActionPreference = "Continue"
& cmake ../../ `
	-G "Visual Studio 14 2015 Win64" `
	-DCMAKE_PREFIX_PATH="$root/src-stage3/staged_install/Release" `
	-DPYTHON_LIBRARY="$root/src-stage3/staged_install/Release/gr-python27/libs/python27.lib" `
	-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/Release/gr-python27/libs/python27_d.lib" `
	-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/Release/gr-python27/python.exe" `
	-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/Release/gr-python27/include" `
	-DLIBAIRSPY_INCLUDE_DIRS="..\libairspy\src" `
	-DLIBAIRSPY_LIBRARIES="..\libairspy\x64\Release\airspy.lib" `
	-DLIBBLADERF_INCLUDE_DIRS="$root\src-stage3\oot_code\bladeRF\host\libraries\libbladeRF\include\libbladerf.h"  `
	-DLIBBLADERF_LIBRARIES="$root\src-stage3\oot_code\bladeRF\host\build\$configuration\output\$buildconfig\bladeRF.lib" `
	-DLIBHACKRF_INCLUDE_DIRS="$root\src-stage3\oot_code\hackrf\host\libhackrf\src\hackrf.h"  `
	-DLIBHACKRF_LIBRARIES="$root\src-stage3\oot_code\hackrf\build\$configuration\libhackrf\src\$buildconfig\hackrf.lib" `
	-DLIBRTLSDR_INCLUDE_DIRS="$root\src-stage3\oot_code\rtl-sdr\include\rtl-sdr.h"  `
	-DLIBRTLSDR_LIBRARIES="$root\src-stage3\oot_code\rtl-sdr\build\$configuration\src\$buildconfig\rtlsdr.lib" `
	-DLIBOSMOSDR_INCLUDE_DIRS="$root\src-stage3\oot_code\osmo-sdr\software\libosmosdr\include"  `
	-DLIBOSMOSDR_LIBRARIES="$root\src-stage3\oot_code\osmo-sdr\build\$configuration\src\$buildconfig\osmosdr.lib" `
	-DENABLE_DOXYGEN=1
msbuild .\gr-osmosdr.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
& nmake install
& ldconfig

# ____________________________________________________________________________________________________________
#
# UHD
#
# This was previously built, but now we want to install it properly over top of the GNURadio install
#

break

$configuration = "Debug"
$configuration = "Release"
$configuration = "Release-AVX2"