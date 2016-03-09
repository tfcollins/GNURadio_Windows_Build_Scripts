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
# in the build originally.  We are building three versions, one for AVX2 only
# and one for release and one for debug

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

$pythonexe = "python.exe"
$pythondebugexe = "python_d.exe"

#break

#__________________________________________________________________________________________
# sip
$ErrorActionPreference = "Continue"
SetLog "sip"
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
"complete"

#__________________________________________________________________________________________
# PyQt
#
# building libraries separate from the actual install into Python
#
$ErrorActionPreference = "Continue"
SetLog "PyQt"
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
	if ($configuration -match "Debug") { $debug = "--debug" } else {$debug = ""}

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
	# TODO This is not working properly on the debug build... essentially it is linking against
	#      python27 instead of python27_d
	Write-Host -NoNewline "installing Cython..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\Cython-0.23.4
	if ($configuration -match "Debug") {$env:_CL_ = "-DPy_DEBUG"}
	& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
	Write-Host -NoNewline "creating wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
	$env:_CL_ = ""
	move dist/Cython-0.23.4-cp27-cp27${d}m-win_amd64.whl dist/Cython-0.23.4-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
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
	& $pythonroot/$pythonexe setup.py build $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "creating wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/numpy-1.10.4-cp27-cp27${d}m-win_amd64.whl dist/numpy-1.10.4-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 
	$ErrorActionPreference = "Stop"
	"done"
	
	#__________________________________________________________________________________________
	# scipy
	#
	if ($hasIFORT) {
		Write-Host -NoNewline "configuring scipy..."
		$ErrorActionPreference = "Continue"
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
		& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --fcompiler=intelvem 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install  2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		move dist/scipy-0.17.0-cp27-cp27${d}m-win_amd64.whl dist/scipy-0.17.0-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
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
	nmake clean 2>&1 >> $log
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

	#__________________________________________________________________________________________
	# PyOpenGL
	# requires Python
	# python-only package so no need to rename the wheels since there is only one
	#
	Write-Host -NoNewline "installing PyOpenGL..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyOpenGL-3.1.0
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# PyOpenGL-accelerate
	# requires Python, PyOpenGL
	#
	Write-Host -NoNewline "installing PyOpenGL-accelerate..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\PyOpenGL-accelerate-3.1.0
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
	& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/PyOpenGL_accelerate-3.1.0-cp27-cp27${d}m-win_amd64.whl dist/PyOpenGL_accelerate-3.1.0-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# pkg-config
	# both the binary (using pkg-config-lite to avoid dependency issues) and the python wrapper
	#
	Write-Host -NoNewline "building pkg-config..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\pkgconfig-1.1.0
	& $pythonroot/$pythonexe setup.py build  $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	# yes, this copies the same file three times, but since it's conceptually linked to 
	# the python wrapper, I kept this here for ease of maintenance
	cp $root\src-stage1-dependencies\pkg-config-lite-0.28-1\bin\pkg-config.exe $root\bin -Force 
	New-Item -ItemType Directory -Force $pythonroot\lib\pkgconfig
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# py2cairo
	# requires pkg-config
	# uses wierd setup python script called WAF which has an archive embedded in it which
	# creates files that then fail to work.  So we need to extract them and then patch them
	# and run again.
	# TODO ensure pkgconfig-light is downloaded to the gr-build/bin directory
	Write-Host -NoNewline "configuring py2cairo..."
	cd $root\src-stage1-dependencies\py2cairo-1.10.0
	$env:path = "$root\bin;$root\src-stage1-dependencies\x64\bin;" + $oldPath
	$ErrorActionPreference = "Continue" 
	$env:CL = $oldCL
	# HACK the below will fail, but will run the command to unpack the rest of the library
	# what we really should do here is run just the python needed to unpack the library
	# and not intentionally run code that will error out
	& $pythonroot/$pythonexe waf configure --nocache --out=build --prefix=build/x64/$configuration  2>&1 >> $log
	Copy-Item -Force msvc.py .\waf-1.6.3-3c3129a3ec8fb4a5bbc7ba3161463b22\waflib\Tools\msvc.py 2>&1 >> $log
	Copy-Item -Force python.py .\waf-1.6.3-3c3129a3ec8fb4a5bbc7ba3161463b22\waflib\Tools\python.py 2>&1 >> $log
	# now it will work
	& $pythonroot/$pythonexe waf configure --nocache --out=build --prefix=build/x64/$configuration  2>&1 >> $log
	Write-Host -NoNewline "building..."
	$oldInclude = $env:INCLUDE
	$env:INCLUDE = "$root/src-stage1/dependencies/x64/include;" + $oldInclude 
	$env:LIB = "$root/src-stage1-dependencies/cairo/build/x64/Release;$root/src-stage1-dependencies/cairo/build/x64/ReleaseDLL;$pythonroot/libs;" + $oldlib 
	$env:_CL_ = "/MD /I$root/src-stage1-dependencies/x64/include /DCAIRO_WIN32_STATIC_BUILD" 
	$env:_LINK_ = "/DEFAULTLIB:cairo /DEFAULTLIB:pixman-1 /DEFAULTLIB:freetype /LIBPATH:$root/src-stage1-dependencies/x64/lib /LIBPATH:$pythonroot/libs"
	& $pythonroot/$pythonexe waf build --nocache --out=build --prefix=build/x64/$configuration --includedir=$root\src-stage1\dependencies\x64\include 2>&1 >> $log
	$env:_LINK_ = ""
	$env:_CL_ = ""
	$env:LIB = $oldLib
	$env:INCLUDE = $oldInclude 
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe waf install --nocache --out=build --prefix=build/x64/$configuration 2>&1 >> $log
	cp -Recurse -Force build/x64/$configuration/lib/python2.7/site-packages/cairo $pythonroot\lib\site-packages 2>&1 >> $log
	cp -Force $root\src-stage1-dependencies\py2cairo-1.10.0\pycairo.pc $pythonroot\lib\pkgconfig\
	& $pythonroot/$pythonexe waf clean  2>&1 >> $log
	"done..."

	#__________________________________________________________________________________________
	# Pygobject
	# requires Python
	#
	# VERSION WARNING: higher than 2.28 does not have setup.py so do not try to use
	#
	Write-Host -NoNewline "building Pygobject..."
	$ErrorActionPreference = "Continue" 
	cd $root\src-stage1-dependencies\Pygobject-2.28.6
	$env:PATH = "$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;" + $oldpath
	$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
	if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
	& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --enable-threading  2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install  2>&1 >> $Log
	Write-Host -NoNewline "creating exe..."
	& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
	Write-Host -NoNewline "crafting wheel from exe..."
	New-Item -ItemType Directory -Force -Path .\dist\gtk-2.0 2>&1 >> $Log
	cd dist
	& $pythonroot/Scripts/wheel.exe convert pygobject-2.28.6.win-amd64-py2.7.exe 2>&1 >> $Log
	move gtk-2.0/pygobject-cp27-none-win_amd64.whl gtk-2.0/pygobject-cp27-none-win_amd64.$configuration.whl -Force
	cd ..
	$env:_CL_ = $null
	$env:PATH = $oldPath
	$env:PKG_CONFIG_PATH = $null
	$ErrorActionPreference = "Stop" 
	"done"

	#__________________________________________________________________________________________
	# PyGTK
	# requires Python, Pygobject
	#
	# TODO need to update pkgconfig.7z on server!!!
	# TODO also need to set the bindings manually (what did I mean by this??)

	Write-Host -NoNewline "building PyGTK..."
	cd $root\src-stage1-dependencies\pygtk-2.24.0-win
	if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
	$env:PATH = "$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;$pythonroot/Scripts;$pythonroot;" + $oldpath
	$env:_CL_ = "/I$root/src-stage1-dependencies/x64/lib/gtk-2.0/include /I$root/src-stage1-dependencies/py2cairo-1.10.0/src " + $env:_CL_
	$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
	$ErrorActionPreference = "Continue" 
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $Log
	& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --enable-threading 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $Log
	Write-Host -NoNewline "building exe..."
	& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
	New-Item -ItemType Directory -Force -Path .\dist\gtk-2.0 2>&1 >> $Log
	cd dist
	Write-Host -NoNewline "crafting wheel from exe..."
	& $pythonroot/Scripts/wheel.exe convert pygtk-2.24.0.win-amd64-py2.7.exe 2>&1 >> $Log
	move gtk-2.0/pygtk-cp27-none-win_amd64.whl gtk-2.0/pygtk-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $Log
	cd ..
	$env:_CL_ = $null
	$env:PATH = $oldPath
	$env:PKG_CONFIG_PATH = $null
	$ErrorActionPreference = "Stop" 
	"done"

	#__________________________________________________________________________________________
	# wxpython
	#
	# v3.0.2 is not VC140 compatible, so the patch fixes those things
	# TODO submit changes to source tree
	# TODO wxpython/include/msvc/wx/setup.h cahnges need to be added to patch file
	#
	# TODO so the debug build is not working because of it's looking for the wrong file to link to
	# (debug vs non-debug).  So the workaround is to build wx in release even when python is
	# being built in debug.
	#

	Write-Host -NoNewline "prepping wxpython..."
	cd $root\src-stage1-dependencies\wxpython\wxPython
	$canbuildwxdebug = $false
	$wxdebug = ($canbuildwxdebug -and $d -eq "d")
	$env:WXWIN="$root\src-stage1-dependencies\wxpython"
	if ($configuration -match "AVX2") {$env:_CL_ = " /DwxMSVC_VERSION_AUTO /D_UNICODE /DUNICODE /DMSLU /arch:AVX2 "} else {$env:_CL_ = " /DWXWIN=.. /DMSLU /D_UNICODE /DUNICODE /DwxMSVC_VERSION_AUTO "}
	if ($wxdebug) {
		$env:_CL_ = " /I$root/src-stage1-dependencies/wxpython/lib/vc140_dll/mswud /D__WXDEBUG__ /D_DEBUG  " + $env:_CL_ 
		$wxdebugstring = "--debug"
	} else {
		$env:_CL_ = " /I$root/src-stage1-dependencies/wxpython/lib/vc140_dll/mswu " + $env:_CL_
		$wxdebugstring = ""
	}
	$env:_CL_ = "/I$root/src-stage1-dependencies/wxpython/include/msvc " + $env:_CL_
	$env:PATH = "$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;$pythonroot/Scripts;$pythonroot" + $oldpath
	$ErrorActionPreference = "Continue"
	del -recurse .\build\*.*
	& $pythonroot\$pythonexe build-wxpython.py --clean 2>&1 >> $Log
	& $pythonroot\$pythonexe build-wxpython.py --build_dir=../build  --force_config --install $wxdebugstring 2>&1 >> $Log
	#Write-Host -NoNewline "configing..."
	#& $pythonroot\$pythonexe setup.py clean 2>&1 >> $Log
	#& $pythonroot\$pythonexe setup.py config MONOLITHIC=1 2>&1 >> $Log
	#Write-Host -NoNewline "building..."
	#& $pythonroot\$pythonexe setup.py build $wxdebugstring MONOLITHIC=1 2>&1 >> $Log
	#Write-Host -NoNewline "installing..."
	#& $pythonroot\$pythonexe setup.py install 2>&1 >> $Log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot\$pythonexe setup.py bdist_wininst UNICODE=1 BUILD_BASE=build 2>&1 >> $Log
	cd dist
	& $pythonroot/Scripts/wheel.exe convert wxpython-3.0.2.0.win-amd64-py2.7.exe 2>&1 >> $Log
	del wxpython-3.0.2.0.win-amd64-py2.7.exe
	move wx-3.0-cp27-none-win_amd64.whl wx-3.0-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $Log
	move .\wxPython-common-3.0.2.0.win-amd64.exe .\wxPython-common-3.0.2.0.win-amd64.$configuration.exe -Force 2>&1 >> $Log
	$ErrorActionPreference = "Stop" 
	$env:_CL_ = $null
	$env:PATH = $oldPath
	"done"

	#__________________________________________________________________________________________
	# cheetah
	#
	# will download and install Markdown automatically
	Write-Host -NoNewline "building cheetah..."
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\Cheetah-2.4.4
	& $pythonroot/$pythonexe setup.py build  $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
	move dist/Cheetah-2.4.4-cp27-cp27${d}m-win_amd64.whl dist/Cheetah-2.4.4-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# sphinx
	#
	# will also download/install a large number of dependencies
	# pytz, babel, colorama, snowballstemmer, sphinx-rtd-theme, six, Pygments, docutils, Jinja2, alabaster, sphinx
	# all are python only packages
	Write-Host -NoNewline "installing sphinx using pip..."
	$ErrorActionPreference = "Continue" # pip will "error" if there is a new version available
	& $pythonroot/Scripts/pip.exe install -U sphinx 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	"done"

	#__________________________________________________________________________________________
	# lxml
	#
	# this was a royal pain to get to statically link the dependent libraries
	# but now there are no dependencies, just install the wheel
	Write-Host -NoNewline "configuring lxml..."
	$ErrorActionPreference = "Continue"
	$xsltconfig = ($configuration -replace "DLL", "")
	cd $root\src-stage1-dependencies\lxml
	if ($type -match "AVX2") {$env:CL = "/Ox /arch:AVX2 " + $oldcl} else {$env:CL = $oldCL}
	$env:_CL_ = "/I$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/include/libxml2 /I$root/src-stage1-dependencies/gettext-msvc/libiconv-1.14 /I$root/src-stage1-dependencies/libxslt/build/$xsltconfig/include "
	$env:_LINK_ = "/LIBPATH:$root/src-stage1-dependencies/libxslt/build/$xsltconfig/lib /LIBPATH:$root/src-stage1-dependencies/zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$xsltconfig /LIBPATH:$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib /LIBPATH:$root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig"
	$oldinclude = $env:INCLUDE
	$oldlibrary = $env:LIBRARY
	$env:LIBRARY = "$root/src-stage1-dependencies/lxml/libs/$xsltconfig;$root/src-stage1-dependencies/libxslt/build/$xsltconfig/lib;$root/src-stage1-dependencies/zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$xsltconfig;$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib;$root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig"
	$env:INCLUDE = "$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/include/libxml2;$root/src-stage1-dependencies/gettext-msvc/libiconv-1.14;$root/src-stage1-dependencies/libxslt/build/$xsltconfig/include;$root/src-stage1-dependencies/lxml/src/lxml/includes"
	cp -Force $root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib $root/src-stage1-dependencies/lxml/libs/$xsltconfig/xml2.lib
	cp -Force $root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig/libiconv.lib $root/src-stage1-dependencies/lxml/libs/$xsltconfig/iconv_a.lib
	& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
	del -Recurse -Force build 
	Write-Host -NoNewline "building..."
	& $pythonroot/$pythonexe setup.py build --static $debug 2>&1 >> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel --static 2>&1 >> $log
	move dist/lxml-3.5.0-cp27-cp27${d}m-win_amd64.whl dist/lxml-3.5.0-cp27-cp27${d}m-win_amd64.$xsltconfig.whl -Force 2>&1 >> $log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$env:LIBRARY = $oldlibrary
	$env:INCLUDE = $oldinclude
	$ErrorActionPreference = "Stop"
	"done"

	"finished installing python packages for $configuration"
}

$pythonexe = "python.exe"
SetLog("Setting up Python")
$pythonroot = "$root\src-stage2-python\gr-python27"
SetupPython "ReleaseDLL"
SetLog("Setting up AVX2 Python")
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
SetupPython "ReleaseDLL-AVX2"
SetLog("Setting up debug Python")
$pythonexe = "python_d.exe"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
SetupPython "DebugDLL"
break

# these are just here for quick debugging

ResetLog

$configuration = "ReleaseDLL"
$pythonroot = "$root\src-stage2-python\gr-python27"
$pythonexe = "python.exe"
$d = ""
$debug = ""

$configuration = "ReleaseDLL-AVX2"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
$pythonexe = "python.exe"
$d = ""
$debug = ""

$configuration = "DebugDLL"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
$pythonexe = "python_d.exe"
$d = "d"
$debug = "--debug"