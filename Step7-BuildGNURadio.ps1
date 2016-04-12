#
# Step7BuildGNURadio.ps1
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

# prep for cmake
if (!(Test-Path $root/src-stage3/build)) {
	cd $root/src-stage3
	mkdir build >> $null
} 

if (!(Test-Path $root/src-stage3/staged_install)) {
	cd $root/src-stage3
	mkdir staged_install >> $null
} 

function BuildGNURadio {
	$configuration = $args[0]
	if ($configuration -match "Release") {$buildtype = "relwithDebInfo"; $pythonexe = "python.exe"} else {$buildtype = "DEBUG"; $pythonexe = "python_d.exe"}
	if ($configuration -match "AVX") {$DLLconfig="ReleaseDLL-AVX2"} else {$DLLconfig = $configuration + "DLL"}
	# prep for cmake
	SetLog "Build GNURadio $configuration"
	if (!(Test-Path $root/src-stage3/staged_install/$configuration)) {
		cd $root/src-stage3/staged_install
		mkdir $configuration
	} 
	if (!(Test-Path $root/src-stage3/build/$configuration)) {
		cd $root/src-stage3/build
		mkdir $configuration
	} 
	cd $root/src-stage3/build/$configuration

	$env:PATH = "$root/build/$configuration/lib;$pythonroot/Dlls;" + $oldPath

	$ErrorActionPreference = "Continue"
	# Always use the DLL version of Qt to avoid errors about parent being on a different thread.
	# ENABLE_MSVC_AVX2_ONLY_MODE is a switch to use in the future if we want to mod the GNURadio cmake files, not currently used (and generates a warning as a result)
	cmake ../../src/gnuradio `
		-G "Visual Studio 14 2015 Win64" `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DQA_PYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DPYTHON_LIBRARY="$pythonroot\Libs\python27.lib" `
		-DPYTHON_INCLUDE_DIR="$pythonroot\include"  `
		-DQT_QMAKE_EXECUTABLE="$root/build/$configuration/bin/qmake.exe" `
		-DSWIG_EXECUTABLE="$root\bin\swig.exe" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration/" `
		-DENABLE_MSVC_AVX2_ONLY_MODE="OFF" `
		-DSPHINX_EXECUTABLE="$pythonroot/Scripts/sphinx-build.exe" `
		-DCMAKE_BUILD_TYPE="$buildtype" `
		-Wno-dev
	$ErrorActionPreference = "Stop"
	# current errors to investigate:
	#
	# xgetbv not detected, overruling avx			(fixed, sent patch to volk)
	# cvtpi32_ps not detected, overruling avx		(fixed, sent patch to volk)
	# only SSE2 and generic machines detected		(fixed, sent patch to volk)
	# incorrectly detects compiler (vs 10.0)
	# doesn't find MSVC-ASM ? (nasm)
	# python lxml not found							(fixed, built lxml with all static dependencies)
	# python pygtk not found						(fixed, loaded piles of dlls into build directory) 
	# portaudio not found							(fixed, moved portaudio libs to lib, TODO submit pull request to search for portaudio_x64 if dynamically linking)
	# python wx not found							(fixed, move wx dlls to lib)

	Write-Host -NoNewline "Build GNURadio $configuration..."
	if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = "/arch:AVX2"} else {$platform = "x64"; $env:_CL_ = ""}
	if ($configuration -match "Release") {$boostconfig = "Release"; $pythonexe = "python.exe"} else {$boostconfig = "Debug"; $pythonexe = "python_d.exe"}
	$env:_LINK_ = " /DEBUG /opt:ref,icf"
	Write-Host -NoNewline "building..."
	msbuild .\gnuradio.sln /m /p:"configuration=$buildtype;platform=x64" 2>&1 >> $Log 
	Write-Host -NoNewline "staging install..."
	msbuild INSTALL.vcxproj  /m  /p:"configuration=$buildtype;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log 
	Write-Host -NoNewline "moving add'l libraries..."
	cp $root/build/$configuration/lib/*.dll $root\src-stage3\staged_install\$configuration\bin\
	Write-Host -NoNewline "moving python..."
	Copy-Item -Force -Recurse -Path $pythonroot $root/src-stage3/staged_install/$configuration
	if ((Test-Path $root/src-stage3/staged_install/$configuration/gr-python27) -and (($pythonroot -match "avx2") -or ($pythonroot -match "debug"))) 
	{
		del -Recurse -Force $root/src-stage3/staged_install/$configuration/gr-python27
	}
	if ($pythonroot -match "avx2") {Rename-Item $root/src-stage3/staged_install/$configuration/gr-python27-avx2 $root/src-stage3/staged_install/$configuration/gr-python27}
	if ($pythonroot -match "debug") {Rename-Item $root/src-stage3/staged_install/$configuration/gr-python27-debug $root/src-stage3/staged_install/$configuration/gr-python27}
	Copy-Item -Force -Path $root\src-stage3\src\run_gr.bat $root/src-stage3/staged_install/$configuration/bin
	Copy-Item -Force -Path $root\src-stage3\src\run_GRC.bat $root/src-stage3/staged_install/$configuration/bin
	$env:_LINK_ = ""
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

cd $root/scripts 

""
"COMPLETED STEP 7: Core GNURadio has been built from source"
""

if ($false)
{

	#these are just here for quicker debugging

	ResetLog

	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	$configuration = "Release-AVX2"

	$pythonroot = "$root\src-stage2-python\gr-python27"
	$configuration = "Release"

	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	$configuration = "Debug"
}