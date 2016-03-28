#
# Step8_BuildOOTModules.ps1
#


# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

break

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
	msbuild .\airspy_2015.sln /m /p:"configuration=$configuration;platform=x64"  2>&1 >> $Log
	Write-Host -NoNewLine "installing..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/staged_install/$configuration/include/libairspy  2>&1 >> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/airspy.lib" "$root/src-stage3/staged_install/$configuration/lib" 2>&1 >> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/airspy.dll" "$root/src-stage3/staged_install/$configuration/bin" 2>&1 >> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/*.exe" "$root/src-stage3/staged_install/$configuration/bin" 2>&1 >> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/src/airspy.h" "$root/src-stage3/staged_install/$configuration/include/libairspy" 2>&1 >> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/src/airspy_commands.h" "$root/src-stage3/staged_install/$configuration/include/libairspy" 2>&1 >> $Log
	"complete"
	
	# ____________________________________________________________________________________________________________
	#
	# bladeRF
	#
	# links to libusb dynamically and pthreads statically
	# Note that to get this to build without a patch, we needed to place pthreads and libusb dll's in non-standard locations.
	# pthreads dll can actually be deleted afterwards since we statically link it in this build
	#
	SetLog "bladeRF $configuration"
	Write-Host -NoNewline "configuring $configuration bladeRF..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/bladeRF/host/build/$configuration  2>&1 >> $Log
	cd $root/src-stage3/oot_code/bladeRF/host/build/$configuration
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DLIBUSB_PATH="$root/build/$configuration" `
		-DLIBUSB_LIBRARY_PATH_SUFFIX="lib" `
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
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	Copy-Item -Force -Path "$root/src-stage3/staged_install/$configuration/lib/bladeRF.dll" "$root/src-stage3/staged_install/$configuration/bin"
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
	Write-Host -NoNewline "building..."
	msbuild .\rtlsdr.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
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
	Write-Host -NoNewline "building..."
	msbuild .\hackrf_all.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	# this installs hackrf libs to the bin dir, we want to move them
	Copy-Item -Force -Path "$root/src-stage3/staged_install/$configuration/bin/hackrf.lib" "$root/src-stage3/staged_install/$configuration/lib"
	Copy-Item -Force -Path "$root/src-stage3/staged_install/$configuration/bin/hackrf_static.lib" "$root/src-stage3/staged_install/$configuration/lib"
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
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	"complete"
	
	
	# ____________________________________________________________________________________________________________
	#
	# UHD
	#
	# This was previously built, but now we want to install it properly over top of the GNURadio install
	#
	robocopy "$root/src-stage1-dependencies/uhd/dist/$configuration" "$root/src-stage3/staged_install/$configuration" /e 2>&1 >> $log 

	# ____________________________________________________________________________________________________________
	#
	# gr-iqbal
	#
	# this doesn't add gnuradio-pmt.lib as a linker input, so we hack it manually
	# TODO submit issue to source (add gnuradio-pmt.lib as a linker input to gr-iqbal)
	#
	SetLog "gr-iqbal $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration gr-iqbal..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-iqbal/build/$configuration  2>&1 >> $Log
	cd $root/src-stage3/oot_code/gr-iqbal/build/$configuration 
	if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = " /arch:AVX2"} else {$platform = "x64"; $env:_CL_ = ""}
	if ($configuration -match "Release") {$boostconfig = "Release"} else {$boostconfig = "Debug"}
	$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG "
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 " `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/python.exe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DBOOST_LIBRARYDIR="$root\src-stage1-dependencies\boost\build\$platform\$boostconfig\lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch " `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DFFTW3F_LIBRARIES="$root/build/Release/lib/libfftw3f.lib" `
		-DLINK_LIBRARIES="gnuradio-pmt.lib"  `
		-Wno-dev 2>&1 >> $Log
	Write-Host -NoNewline "building gr-iqbal..."
	msbuild .\gr-iqbalance.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	"complete"
	


	# ____________________________________________________________________________________________________________
	#
	# gr-osmosdr
	# 
	# Note this must be built at the end, after all the other libraries are ready
	#
	# /EHsc is important or else you get boost::throw_exception linker errors
	# ENABLE_RFSPACE=False is because the latest gr-osmosdr has linux-only support for that SDR
	# /DNOMINMAX prevents errors related to std::min definition
	# 
	SetLog "gr-osmosdr $configuration"
	Write-Host -NoNewline "configuring $configuration gr-osmosdr..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-osmosdr/build/$configuration 2>&1 >> $Log
	cd $root/src-stage3/oot_code/gr-osmosdr/build/$configuration
	$ErrorActionPreference = "Continue"
	$env:LIB = "$root/build/$configuration/lib;" + $oldlib
	if ($configuration -match "AVX") {$SIMD="-DUSE_SIMD=""AVX"""} else {$SIMD=""}
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root/src-stage3/staged_install/Release" `
		-DCMAKE_INCLUDE_PATH="$root/build/$configuration/include" `
		-DCMAKE_LIBRARY_PATH="$root/build/$configuration/lib" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/python.exe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DLIBAIRSPY_INCLUDE_DIRS="..\libairspy\src" `
		-DLIBAIRSPY_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\airspy.lib" `
		-DLIBBLADERF_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBBLADERF_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\bladeRF.lib" `
		-DLIBHACKRF_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBHACKRF_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\hackrf.lib" `
		-DLIBRTLSDR_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBRTLSDR_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\rtlsdr.lib" `
		-DLIBOSMOSDR_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBOSMOSDR_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\osmosdr.lib" `
		-DCMAKE_CXX_FLAGS="/DNOMINMAX /D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB /I$root/build/$configuration/include /EHsc " `
		-DCMAKE_C_FLAGS="/DNOMINMAX /D_TIMESPEC_DEFINED $arch  /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB /EHsc " `
		$SIMD `
		-DENABLE_DOXYGEN="TRUE" `
		-DENABLE_RFSPACE="FALSE" 2>&1 >> $Log  # RFSPACE not building in current git pull (0.1.5git 164a09fc 3/13/2016), due to having linux-only headers being added
	
	Write-Host -NoNewline "building..."
	msbuild .\gr-osmosdr.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	"complete"

	# ____________________________________________________________________________________________________________
	#
	# glfw
	#
	#
	SetLog "glfw $configuration"
	Write-Host -NoNewline "configuring $configuration glfw..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/glfw/build/$configuration 2>&1 >> $Log
	cd $root/src-stage3/oot_code/glfw/build/$configuration
	if ($configuration -match "AVX2") { $env:_CL_ = " /arch:AVX2"} else {$env:_CL_ = ""}
	$ErrorActionPreference = "Continue"
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DBUILD_SHARED_LIBS="true"  2>&1 >> $Log
	Write-Host -NoNewline "building for shared..."
	msbuild .\glfw.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DBUILD_SHARED_LIBS="false"  2>&1 >> $Log
	Write-Host -NoNewline "building for static..."
	msbuild .\glfw.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	$env:_CL_ = ""
	"complete"
	 
	
	# ____________________________________________________________________________________________________________
	#
	# GNSS-SDR
	#
	# NOT WORKING
	#
	# Requires Armadillo
	#
	SetLog "gnss-sdr $configuration"
	Write-Host -NoNewline "configuring $configuration gnss-sdr..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gnss-sdr/build/$configuration 2>&1 >> $Log
	cd $root/src-stage3/oot_code/gnss-sdr/build/$configuration
	$ErrorActionPreference = "Continue"
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNUTLS_LIBRARY="../../../gnutls/lib/libgnutls.lib" `
		-DGNUTLS_INCLUDE_DIR="../../../gnutls/include" `
		-DGNUTLS_OPENSSL_LIBRARY="../../../gnutls/lib/libgnutls.lib" `
		-DBOOST_LIBRARYDIR="$root\src-stage1-dependencies\boost\build\$platform\$boostconfig\lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DENABLE_OSMOSDR="ON" `
		-DLAPACK="ON" `
		-Wno-dev 2>&1 >> $Log
	Write-Host -NoNewline "building..."
	msbuild .\gnss-sdr.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	"complete"

	# ____________________________________________________________________________________________________________
	#
	# gr-fosphor
	#
	# NOT WORKING
	#
	# need to macro out __attribute__, include gnuradio-pmt, and include glew64.lib
	# still not working though, gets an error and crashes, something in the way OpenGL is being initialized.  Tried to patch and failed, though I could get around
	# the crash in a standalone program with some manual inits.
	SetLog "gr-fosphor $configuration"
	if ($env:AMDAPPSDKROOT) {
		Write-Host -NoNewline "configuring $configuration gr-fosphor..."
		New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-fosphor/build/$configuration  2>&1 >> $Log
		cd $root/src-stage3/oot_code/gr-fosphor/build/$configuration 
		if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = " /arch:AVX2"} else {$platform = "x64"; $env:_CL_ = ""}
		if ($configuration -match "Debug") {$baseconfig = "Debug"} else {$baseconfig = "Release"}
		if ($configuration -match "AVX") {$DLLconfig="ReleaseDLL-AVX2"} else {$DLLconfig = $configuration + "DLL"}
		$env:_CL_ = $env:_CL_ + " -D_WIN32 -Zi -I""$env:AMDAPPSDKROOT/include"" "
		$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib ""$env:AMDAPPSDKROOT/lib/x86_64/glew64.lib"" /DEBUG /OPT:ref,icf "
		cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DBOOST_LIBRARYDIR="$root\src-stage1-dependencies\boost\build\$platform\$boostconfig\lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DOpenCL_LIBRARY="$env:AMDAPPSDKROOT/lib/x86_64/OpenCL.lib" `
			-DOpenCL_INCLUDE_DIR="$env:AMDAPPSDKROOT/include" `
			-DFREETYPE2_PKG_INCLUDE_DIRS="$root/src-stage1-dependencies/freetype/" `
			-DFREETYPE2_PKG_LIBRARY_DIRS="$root\src-stage1-dependencies\freetype\objs\vc2015\x64" `
			-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 " `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/python.exe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DQT_QMAKE_EXECUTABLE="$root\src-stage1-dependencies\Qt4\build\$DLLconfig\bin\qmake.exe" `
			-DGLFW3_PKG_INCLUDE_DIRS="$root\src-stage3\oot_code\glfw\include\" `
			-DGLFW3_PKG_LIBRARY_DIRS="$root\src-stage3\oot_code\glfw\build\$configuration\src\$baseconfig" `
			-Wno-dev 2>&1 >> $Log
		Write-Host -NoNewline "building gr-fosphor..."
		msbuild .\gr-fosphor.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
		cp $env:AMDAPPSDKROOT/bin/x86_64/glew64.dll $root/src-stage3/staged_install/$configuration/bin
		$env:_LINK_ = ""
		$env:_CL_ = ""
		"complete"
	} else {
		"Unable to build gr-fosphor, AMD APP SDK not found, skipping"
	}

	# ____________________________________________________________________________________________________________
	#
	# gqrx
	#
	# NOT WORKING
	#
	# Requires Qt5 apparently so we'd have to build that as well
	#
	SetLog "gqrx $configuration"
	Write-Host -NoNewline "configuring $configuration gqrx..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gqrx/build/$configuration 2>&1 >> $Log
	cd $root/src-stage3/oot_code/gqrx/build/$configuration
	$ErrorActionPreference = "Continue"
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DQT_QMAKE_EXECUTABLE="$root\src-stage1-dependencies\Qt4\build\$DLLconfig\bin\qmake.exe"
	
	Write-Host -NoNewline "building..."
	msbuild .\gqrx.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	"complete"

}

BuildDrivers "Release"
BuildDrivers "Release-AVX2"
BuildDrivers "Debug"

# debug shortcuts below
break

$configuration = "Debug"
$configuration = "Release"
$configuration = "Release-AVX2"

ResetLog