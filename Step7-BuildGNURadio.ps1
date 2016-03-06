#
# Step7BuildGNURadio.ps1
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

# prep for cmake
	if (!(Test-Path $root/src-stage3/build)) {
		cd $root/src-stage3
		mkdir build
	} 

function BuildGNURadio {
	$configuration = $args[0]
	if ($configuration -match "Release") {$buildtype = "RELEASE"; $pythonexe = "python.exe"} else {$buildtype = "DEBUG"; $pythonexe = "python_d.exe"}
	if ($configuration -match "AVX") {$DLLconfig="ReleaseDLL-AVX2"} else {$DLLconfig = $configuration + "DLL"}
	# prep for cmake
	SetLog "60-Build GNURadio $configuration"
	if (!(Test-Path $root/src-stage3/build/$configuration)) {
		cd $root/src-stage3/build
		mkdir $configuration
	} 
	cd $root/src-stage3/build/$configuration

	$env:PATH = "$root/build/$configuration/lib;$pythonroot/Dlls;" + $oldPath

	$ErrorActionPreference = "Continue"
	cmake ../../src/gnuradio `
		-G "Visual Studio 14 2015 Win64" `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DQA_PYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DPYTHON_LIBRARY="$pythonroot\Libs\python27.lib" `
		-DPYTHON_INCLUDE_DIR="$pythonroot\include"  `
		-DQT_QMAKE_EXECUTABLE="$root\src-stage1-dependencies\Qt4\build\$DLLconfig\bin\qmake.exe" `
		-DSWIG_DIR="$root\bin" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration/" `
		-DENABLE_MSVC_AVX2_ONLY_MODE="OFF" `
		-DSPHINX_EXECUTABLE="$pythonroot/Scripts/sphinx-build.exe" `
		-DCMAKE_BUILD_TYPE="$buildtype" `
		-Wno-dev
	$ErrorActionPreference = "Stop"
	# current errors to investigate:
	#
	# xgetbv not detected, overruling avx
	# cvtpi32_ps not detected, overruling avx
	# only SSE2 and generic machines detected
	# incorrectly detects compiler (vs 10.0)
	# doesn't find MSVC-ASM ? (nasm)
	# python lxml not found							(fixed, built lxml with all static dependencies)
	# python pygtk not found						(fixed, loaded piles of dlls into build directory) 
	# portaudio not found							(fixed, moved portaudio libs to lib, TODO submit pull request to search for portaudio_x64 if dynamically linking)
	# python wx not found							(fixed, move wx dlls to lib)

	Write-Host -NoNewline "Build GNURadio $configuration..."
	if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = "/arch:AVX2"} else {$platform = "x64"; $env:_CL_ = ""}
	if ($configuration -match "Release") {$boostconfig = "Release"; $pythonexe = "python.exe"} else {$boostconfig = "Debug"; $pythonexe = "python_d.exe"}
	Write-Host -NoNewline "building..."
	# TODO relwithDebInfo isn't working at the moment
	msbuild .\gnuradio.sln /m /p:"configuration=Release;platform=x64" 2>&1 >> $Log 
	Write-Host -NoNewline "staging install..."
	msbuild .\INSTALL.vcxproj /m  /p:"configuration=Release;platform=x64" 2>&1 >> $Log 
	Write-Host -NoNewline "moving add'l libraries..."
	cp $root/build/$configuration/lib/*.dll $root\src-stage3\staged_install\$configuration\bin\
	Write-Host -NoNewline "moving python..."
	Move-Item -Path $pythonroot $root/src-stage3/staged_install/$configuration
	if ($pythonroot -match "avx2") {Rename-Item $root/src-stage3/staged_install/$configuration/gr-python27-avx2 $root/src-stage3/staged_install/$configuration/gr-python27}
	if ($pythonroot -match "debug") {Rename-Item $root/src-stage3/staged_install/$configuration/gr-python27-debug $root/src-stage3/staged_install/$configuration/gr-python27}
	"complete"
}

# AVX2 build
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
BuildGNURadio "Release-AVX2"

# Release build
$pythonroot = "$root\src-stage2-python\gr-python27"
BuildGNURadio "Release"

# Debug build
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
BuildGNURadio "Debug"