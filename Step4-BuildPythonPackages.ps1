#
# GNURadio Windows Build System
# Step4_BuildPythonPackages.ps1
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#
# This module builds the various python packages above the essentials included
# in the build originally.  We are building two versions, one for AVX2 only
# and one for release.
# TODO build one for the debug binaries.

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

$pythonexe = "python.exe"
$pythondebugexe = "python_d.exe"

break

#__________________________________________________________________________________________
# sip
$ErrorActionPreference = "Continue"
SetLog "30-sip"
Write-Host -NoNewline "building sip..."
cd $root\src-stage1-dependencies\sip-4.17

Function MakeSip
{
	$type = $args[0]
	Write-Host -NoNewline "$type"
	$flags = if ($type -match "Debug") {"-u"} else {""}
	$flags += if ($type -match "Dll") {""} else {" -k"}
	$debugext = if ($type -match "Debug") {"_d"} else {""}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 " + $oldcl} else {$env:CL = $oldCL}
	& $pythonroot\python$debugext.exe configure.py $flags -p win32-msvc2015 2>&1 >> $Log
	nmake 2>&1 >> $Log
	New-Item -ItemType Directory -Force -Path ./build/x64/$type 2>&1 >> $Log
	cd siplib
	if ($type -match "Dll") {
		copy sip$debugext.pyd ../build/x64/$type/sip$debugext.pyd
		copy sip$debugext.exp ../build/x64/$type/sip$debugext.exp
		if ($type -match "Debug") {
			copy sip$debugext.pdb ../build/x64/$type/sip$debugext.pdb
			copy sip$debugext.ilk ../build/x64/$type/sip$debugext.ilk
		}
	}
	copy sip$debugex.lib ../build/x64/$type/sip$debugext.lib
	copy sip.h ../build/x64/$type/sip.h
	cd ../sipgen
	copy sip.exe ../build/x64/$type/sip.exe
	cd ..
	copy sipconfig.py ./build/x64/$type/sipconfig.py
	copy sipdistutils.py build/x64/$type/sipdistutils.py
	if ($type -match "Dll") {nmake install 2>&1 >> $Log}
	nmake clean 2>&1 >> $Log
	Write-Host -NoNewline "-done..."
}

$pythonroot = "$root\src-stage2-python\gr-python27-debug"
MakeSip "DebugDLL"
MakeSip "Debug"
$pythonroot = "$root\src-stage2-python\gr-python27"
MakeSip "Release"
MakeSip "ReleaseDLL"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
MakeSip "Release-AVX2"
MakeSip "ReleaseDLL-AVX2"
$ErrorActionPreference = "Stop"


#__________________________________________________________________________________________
# PyQt
#
# building libraries separate from the actual install into Python
#
$ErrorActionPreference = "Continue"
SetLog "31-PyQt"
cd $root\src-stage1-dependencies\PyQt4
$env:QMAKESPEC = "win32-msvc2015"
Write-Host -NoNewline "building PyQT..."

function MakePyQt 
{
	$type = $args[0]
	Write-Host -NoNewline "$type"
	if ($type -match "Debug") {$thispython = $pythondebugexe} else {$thispython = $pythonexe}
	$flags = if ($type -match "Debug") {"-u"} else {""}
	$flags += if ($type -match "Dll") {""} else {" -k"}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 " + $oldcl} else {$env:CL = "/wd4577 " + $oldCL}
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$type\bin;" + $oldpath

	& $pythonroot\$thispython configure.py $flags --destdir "build\x64\$type" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg -b build/x64/$type/bin -d build/x64/$type/package -p build/x64/$type/plugins --sipdir build/x64/$type/sip 2>&1 >> $log

	# BUG FIX
	"all: ;" > .\pylupdate\Makefile
	"install : ;" >> .\pylupdate\Makefile
	"clean : ;" >> .\pylupdate\Makefile

	nmake 2>&1 >> $log
	nmake install 2>&1 >> $log
	nmake clean 2>&1 >> $log
	$env:CL = $oldcl
	Write-Host -NoNewline "-done..."
}

$pythonroot = "$root\src-stage2-python\gr-python27-debug"
MakePyQt "DebugDLL"
MakePyQt "Debug"
$pythonroot = "$root\src-stage2-python\gr-python27"
MakePyQt "Release"
MakePyQt "ReleaseDLL"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
MakePyQt "Release-AVX2"
MakePyQt "ReleaseDLL-AVX2"
$ErrorActionPreference = "Stop"
"complete"

#__________________________________________________________________________________________
# setup python

Function SetupPython
{
	$configuration = $args[0]
	"installing python packages for $configuration"
	if ($configuration -match "Debug") { $d = "d" } else {$d = ""}

	$configuration="ReleaseDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27"
	SetLog "99-Test"

	#__________________________________________________________________________________________
	# PyQt4
	#
	Write-Host -NoNewline "configuring PyQt4..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyQt4
	$flags = if ($configuration -match "Debug") {"-u"} else {""}
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 " + $oldcl} else {$env:CL = "/wd4577 " + $oldCL}
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$configuration\bin;" + $oldpath
	$env:QMAKESPEC = "win32-msvc2015"

	& $pythonroot\$pythonexe configure.py $flags --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg  2>&1 >> $log
	
	# BUG FIX
	"all: ;" > .\pylupdate\Makefile
	"install : ;" >> .\pylupdate\Makefile
	"clean : ;" >> .\pylupdate\Makefile 

	Write-Host -NoNewline "building..."
	Exec {nmake} 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	Exec {nmake install} 2>&1 >> $log
	$env:Path = $oldpath
	$env:CL = $oldcl
	$env:LINK = $oldlink
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# Cython
	#
	Write-Host -NoNewline "installing Cython..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\Cython-0.23.4
	& $pythonroot/$pythonexe setup.py install  2>&1 >> $log
	Write-Host -NoNewline "creating wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
	move dist/Cython-0.23.4-cp27-cp27$dm-win_amd64.whl dist/Cython-0.23.4-cp27-cp27$dm-win_amd64.$configuration.whl -Force
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# Nose
	# Nose is a python-only package can be installed automatically
	# used for testing numpy/scipy etc only, not in gnuradio directly
	#
	Write-Host -NoNewline "installing Nose using pip..."
	$ErrorActionPreference = "Continue" # pip will "error" if there is a new version available
	& $pythonroot/Scripts/pip.exe install nose 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# numpy
	# mkl_libs site.cfg lines generated with the assistance of:
	# https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor
	#
	Write-Host -NoNewline "configuring numpy..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\numpy-1.10.4
	# $static indicates if the MKL/OpenBLAS libraries will be linked statically into numpy/scipy or not.  numpy/scipy themselves will be built as DLLs/pyd's always
	$static = $true
	if ($Config.BuildNumpyWithMKL) {
		# Build with MKL
		if ($static -eq $false) {
			"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
			"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -eq "ReleaseDLL-AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -eq "DebugDLL") {
				"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
		} else {
			"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
			"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"mkl_libs = mkl_intel_lp64, mkl_core, mkl_intel_thread, libiomp5md" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -eq "ReleaseDLL-AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -eq "DebugDLL") {
				"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
		}
	} else {
		# TODO Build scipy with OpenBLAS
	}
	$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
	& $pythonroot/$pythonexe setup.py config --compiler=msvc2015  2>&1 >> $log
	Write-Host -NoNewline "building..."
	& $pythonroot/$pythonexe setup.py build 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "creating wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/numpy-1.10.4-cp27-cp27${d}m-win_amd64.whl dist/numpy-1.10.4-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 
	"done"

	#__________________________________________________________________________________________
	# scipy
	#
	if ($hasIFORT) {
		Write-Host -NoNewline "configuring scipy..."
		cd $root\src-stage1-dependencies\scipy
		$env:Path = "${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\bin\intel64;" + $oldPath 
		$env:LIB = "${env:IFORT_COMPILER16}compiler\lib\intel64_win;" + $oldLib
	
		if ($Config.BuildNumpyWithMKL) {
			# Build with MKL
			if ($static -eq $false) {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = $env:IFORT_COMPILER16\compiler\lib\intel64_win;$env:IFORT_COMPILER16\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = mkl_rt, mkl_lapack95_lp64,mkl_blas95_lp64" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -eq "ReleaseDLL-AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -eq "DebugDLL") {
					"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			} else {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = ${env:IFORT_COMPILER16}compiler\lib\intel64_win;${env:IFORT_COMPILER16}mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_sequential,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_sequential,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -eq "ReleaseDLL-AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -eq "DebugDLL") {
					"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			}
		} else {
			# TODO Build scipy with OpenBLAS
		}
		$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
		# clean doesn't really get it all...
		del build/*.* -Recurse 2>&1 >> $log
		& $pythonroot/$pythonexe setup.py clean  2>&1 >> $log
		& $pythonroot/$pythonexe setup.py config --fcompiler=intelvem --compiler=msvc  2>&1 >> $log
		Write-Host -NoNewline "building..."
		& $pythonroot/$pythonexe setup.py build --compiler=msvc --fcompiler=intelvem 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install  2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		move dist/scipy-0.17.0-cp27-cp27$dm-win_amd64.whl dist/scipy-0.17.0-cp27-cp27$dm-win_amd64.$configuration.whl -Force
		$ErrorActionPreference = "Stop"
	} else {
		# TODO can't compile scipy without a fortran compiler, and gfortran won't work here
		# because we can't mix MSVC and gfortran libraries
		# So if we get here, we need to use the binary .whl instead
	}
	"done"

	#__________________________________________________________________________________________
	# PyQwt5
	# requires Python, Qwt, Qt, PyQt, and Numpy
	#
	Write-Host -NoNewline "configuring PyQwt5..."
	$ErrorActionPreference = "Continue" 
	# qwt_version_info will look for QtCore4.dll, never Qt4Core4d.dll so point it to the ReleaseDLL regardless of the desired config
	if ($configuration -eq "DebugDLL") {$QtVersion = "ReleaseDLL"} else {$QtVersion = $configuration}
	$env:Path = "$root\src-stage1-dependencies\Qt4\build\$QtVersion\bin;$root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\lib;" + $oldpath
	$envLib = $oldlib
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 /wd4577 " + $oldcl} else {$env:CL = "/wd4577 " + $oldCL}
	cd $root\src-stage1-dependencies\PyQwt5-master
	cd configure
	# CALL "../../%1/Release/Python27/python.exe" configure.py %DEBUG% --extra-cflags=%FLAGS% %DEBUG% -I %~dp0..\qwt-5.2.3\build\include -L %~dp0..\Qt-4.8.7\lib -L %~dp0..\qwt-5.2.3\build\lib -l%QWT_LIB%
	if ($configuration -eq "DebugDLL") {
		& $pythonroot/$pythonexe configure.py --debug --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib   -l qtcored4      -L $root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\lib\qwtd" -j4 --sip-include-dirs ..\..\sip-4.17\build\x64\Debug --sip-include-dirs ..\..\PyQt4\sip 2>&1 >> $log
	} elseif ($configuration -eq "ReleaseDLL") {
		& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib -l qtcore4       -L $root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Debug-Release\lib\qwt"  -j4 --sip-include-dirs ..\..\sip-4.17\build\x64\Release 2>&1 >> $log
	} else {
		& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -Ox -arch:AVX2 -wd4577" -I $root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Release-AVX2\include  -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib -l qtcore4  -L $root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Release-AVX2\lib  -l"$root\src-stage1-dependencies\Qwt-5.2.3\build\x64\Release-AVX2\lib\qwt"   -j4 --sip-include-dirs ..\..\sip-4.17\build\x64\Release-AVX2 2>&1 >> $log
	}
	nmake clean
	Write-Host -NoNewline "building..."
	Exec {nmake} 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	Exec {nmake install} 2>&1 >> $log
	#& $pythonroot/$pythonexe setup.py build 2>&1 >> $log
	#Write-Host -NoNewline "installing..."
	#& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "creating winstaller..."
	cd ..
	& $pythonroot/$pythonexe setup.py bdist_wininst   2>&1 >> $log
	move dist/PyQwt-5.2.1.win-amd64.exe dist/PyQwt-5.2.1.win-amd64.$configuration.exe -Force
	# TODO these move fail for lack of a wheel-compatible setup
	# & $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
	# cd dist
	# & $pythonroot/Scripts/wheel.exe convert PyQwt-5.2.1.win-amd64.DebugDLL.exe
	$env:Path = $oldpath
	$env:CL = $oldCL
	$ErrorActionPreference = "Stop"
	"done"
}

$pythonexe = "python.exe"
SetLog("32-Setting up Python")
$pythonroot = "$root\src-stage2-python\gr-python27"
SetupPython "ReleaseDLL"
SetLog("33-Setting up AVX2 Python")
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
SetupPython "ReleaseDLL-AVX2"
SetLog("34-Setting up debug Python")
$pythonexe = "python_d.exe"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
SetupPython "DebugDLL"