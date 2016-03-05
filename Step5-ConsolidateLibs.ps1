#
# GNURadio Windows Build System
# Step5_ConsolidateLibs.ps1
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

$pythonexe = "python.exe"
$pythondebugexe = "python_d.exe"

break

cd $root

SetLog "40-Consolidate Libraries"
New-Item -ItemType Directory -Force -Path $root/build 2>&1 >> $log

Function Consolidate {
	$configuration = $args[0]
	New-Item -ItemType Directory -Force -Path $root/build/$configuration 2>&1 >> $log
	Write-Host "Starting Consolidation for $configuration"
	# set up various variables we'll need
	if ($configuration -match "AVX2") {$platform = "avx2"} else {$platform = "x64"}
	if ($configuration -match "Debug") {$baseconfig = "Debug"} else {$baseconfig = "Release"}
	if ($configuration -match "AVX2") {$configDLL = "ReleaseDLL-AVX2"} else {$configDLL = $configuration + "DLL"}
	if ($configuration -match "Debug") {$d = "d"} else {$d = ""}

	# move boost
	Write-Host -NoNewline "Consolidating Boost..."
	if ($configuration -match "AVX2") {$platform = "avx2"} else {$platform = "x64"}
	if ($configuration -match "Debug") {$baseconfig = "Debug"} else {$baseconfig = "Release"}
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/boost/build/$platform/$baseconfig/lib/boost*.dll $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/boost/build/$platform/$baseconfig/lib/boost*.lib $root/build/$configuration/lib/ 2>&1 >> $log
	robocopy "$root/src-stage1-dependencies/boost/build/$platform/$baseconfig/include/boost-1_60/" "$root/build/$configuration/include/" /e 2>&1 >> $log
	"complete"

	# move Qt
	Write-Host -NoNewline "Consolidating Qt..."
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/lib/QtCore4.* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/lib/QtGui4.* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/lib/QtOpenGL4.* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/include/QtOpenGL* $root/build/$configuration/include/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/include/QtCore* $root/build/$configuration/include/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/include/QtGui* $root/build/$configuration/include/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt4/build/$configDLL/include/Qt $root/build/$configuration/include/ 2>&1 >> $log
	"complete"

	# move Qwt
	Write-Host -NoNewline "Consolidating Qwt..."
	if ($configuration -match "AVX2") {$qwtdir = "Release-AVX2"} else {$qwtdir = "Debug-Release"}
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/qwt 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qwt-5.2.3/build/x64/$qwtdir/lib/qwt5$d.* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qwt-5.2.3/build/x64/$qwtdir/include/* $root/build/$configuration/include/qwt/ 2>&1 >> $log
	"complete"

	# move SDL
	Write-Host -NoNewline "Consolidating SDL..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/sdl 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-1.2.15/VisualC/x64/$configuration/SDL.dll $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-1.2.15/VisualC/x64/$configuration/SDL.lib $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-1.2.15/VisualC/x64/$configuration/SDL.exp $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-1.2.15/VisualC/x64/$configuration/SDL.pdb $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-1.2.15/include/*.h $root/build/$configuration/include/sdl/ 2>&1 >> $log
	"complete"

	# cppunit
	Write-Host -NoNewline "Consolidating cppunit..."
	cp -Recurse -Force $root/src-stage1-dependencies/cppunit-1.12.1/src/x64/$baseconfig/lib/cppunit.* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/cppunit-1.12.1/include/cppunit $root/build/$configuration/include/ 2>&1 >> $log
	"complete"

	# gsl
	Write-Host -NoNewline "Consolidating gsl..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/gsl 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/gsl-1.16/build.vc14/x64/$configuration/dll/* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/gsl-1.16/gsl/*.h $root/build/$configuration/include/gsl/ 2>&1 >> $log
	"complete"

	# fftw3f
	Write-Host -NoNewline "Consolidating fftw3..."
	cp -Recurse -Force $root/src-stage1-dependencies/fftw-3.3.5/msvc/x64/$configuration/libfftwf-3.3.lib $root/build/$configuration/lib/libfftw3f.lib 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/fftw-3.3.5/api/fftw3.h $root/build/$configuration/include/ 2>&1 >> $log
	"complete"

	# libsodium
	Write-Host -NoNewline "Consolidating libsodium..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/gsl 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libsodium/bin/x64/$baseconfig/v140/dynamic/* $root/build/$configuration/lib/ 2>&1 >> $log
	"complete"

	# libzmq
	Write-Host -NoNewline "Consolidating libzmq..."
	cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/x64/$baseconfig/v140/dynamic/libzmq.* $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libzmq/include/*.h $root/build/$configuration/include/ 2>&1 >> $log
	"complete"

	# uhd
	Write-Host -NoNewline "Consolidating UHD..."
	cp -Recurse -Force $root/src-stage1-dependencies/uhd/dist/$configuration/bin/uhd.dll $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/uhd/dist/$configuration/lib/uhd.lib $root/build/$configuration/lib/ 2>&1 >> $log
	cp -Recurse -Force $root/src-stage1-dependencies/uhd/dist/$configuration/include/* $root/build/$configuration/include/ 2>&1 >> $log
	"complete"
}

Consolidate "Release"
Consolidate "Release-AVX2"
Consolidate "Debug"

