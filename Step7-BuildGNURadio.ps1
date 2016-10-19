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

$configmode = $args[0]
if ($configmode -eq $null) {$configmode = "all"}
$env:PYTHONPATH=""

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
	if ($configuration -match "AVX") {$DLLconfig="ReleaseDLL-AVX2"; $archflag="/arch:AVX2 /Ox /GS- /EHsc"} else {$DLLconfig = $configuration + "DLL"; $archflag="/EHsc"}

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
	if (Test-Path CMakeCache.txt) {Remove-Item -Force CMakeCache.txt} # Don't keep the old cache because if the user is fixing a config problem it may not re-check the fix

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
		-DCMAKE_CXX_FLAGS="$archflag" `
		-DCMAKE_C_FLAGS="$archflag" `
		-DENABLE_MSVC_AVX2_ONLY_MODE="OFF" `
		-DSPHINX_EXECUTABLE="$pythonroot/Scripts/sphinx-build.exe" `
		-DCMAKE_BUILD_TYPE="$buildtype" `
		-Wno-dev
	$ErrorActionPreference = "Stop"
	# current errors to investigate:
	#
	# incorrectly detects compiler (vs 10.0) nuisance only?
	# doesn't find MSVC-ASM ? (nasm) how would nasm be used?
	
	# before we build we need to trim from SWIG cmd.exe lines in the VS projects, as cmd.exe has a 8192 character limit, and some of the swig commands will likely be > 9000
	# the good news is that the includes are very repetitive so we can use a swizzy regex to get rid to them
	Write-Host -NoNewline "Fixing swig > 8192 char includes..."
	Function FixSwigIncludes
	{
		$filename = $args[0]
		(Get-Content -Path "$filename") `
			-replace '(-I[^ \n]+)[ ](?=.+?[ ]\1[ ])(?<=.+swig\.exe.+)', '' | Out-File -Encoding utf8 "$filename.temp" 
		Copy-Item -Force "$filename.temp" "$filename"
		Remove-Item "$filename.temp"	
	}
	FixSwigIncludes "$root\src-stage3\build\$configuration\gr-blocks\swig\blocks_swig5_gr_blocks_swig_a6e57.vcxproj"
	FixSwigIncludes "$root\src-stage3\build\$configuration\gr-blocks\swig\blocks_swig4_gr_blocks_swig_a6e57.vcxproj"
	"complete"

	# NOW we build gnuradio finally
	Write-Host -NoNewline "Build GNURadio $configuration..."
	if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = "/arch:AVX2"} else {$platform = "x64"; $env:_CL_ = ""}
	if ($configuration -match "Release") {$boostconfig = "Release"; $pythonexe = "python.exe"} else {$boostconfig = "Debug"; $pythonexe = "python_d.exe"}
	$env:_LINK_ = " /DEBUG /opt:ref,icf"
	$env:_CL_ = " /W1 "
	Write-Host -NoNewline "building..."
	msbuild .\gnuradio.sln /m /p:"configuration=$buildtype;platform=x64" 2>&1 >> $Log 
	Write-Host -NoNewline "staging install..."
	msbuild INSTALL.vcxproj  /m  /p:"configuration=$buildtype;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log 

	# Then combine it into a useable staged install with the dependencies it will need
	Write-Host -NoNewline "moving add'l libraries..."
	cp $root/build/$configuration/lib/*.dll $root\src-stage3\staged_install\$configuration\bin\
	"complete"

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
	Copy-Item -Force -Path $root\src-stage3\src\run_gqrx.bat $root/src-stage3/staged_install/$configuration/bin
	Copy-Item -Force -Recurse -Path $root\src-stage3\icons $root/src-stage3/staged_install/$configuration/share

	# ensure the GR build went well by checking for newmod package, and if found then build
	Validate  $root/src-stage3/staged_install/$configuration/share/gnuradio/modtool/gr-newmod/CMakeLists.txt
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/modtool/gr-newmod/build 
	cd $root/src-stage3/staged_install/$configuration/share/gnuradio/modtool/gr-newmod/build
	cmake ../ `
		-G "Visual Studio 14 2015 Win64" `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DQA_PYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration/" `
		-Wno-dev
	msbuild .\gr-howto.sln /m /p:"configuration=$buildtype;platform=x64" 2>&1 >> $Log
	msbuild INSTALL.vcxproj  /m  /p:"configuration=$buildtype;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	
	"complete"
}

# Release build
if ($configmode -eq "1" -or $configmode -eq "all") {
	$pythonroot = "$root\src-stage2-python\gr-python27"
	BuildGNURadio "Release"
}

# AVX2 build
if ($configmode -eq "2" -or $configmode -eq "all") {
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	BuildGNURadio "Release-AVX2"
}

# Debug build
# This will probably fail... it is known.
Try
{
	if ($configmode -eq "3" -or $configmode -eq "all") {
		$pythonroot = "$root\src-stage2-python\gr-python27-debug"
		BuildGNURadio "Debug"
	}
}
Catch
{
	""
	"Debug GNURadio build FAILED... aborting but continuing with other builds"
	""
}
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