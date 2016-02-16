# GNURadio Windows Build System
# Geof Nieboer

#setup
$root = $env:grwinbuildroot 
if (!$root) {$root = "C:\gr-build"}
cd $root
set-alias sz "$root\bin\7za.exe"  
Add-Type -assembly "system.io.compression.filesystem"

# Check for binary dependencies
if (-not (test-path "$root\bin\7za.exe")) {throw "7-zip (7za.exe) needed in bin folder"} 

# check for git/tar
if (-not (test-path "$env:ProgramFiles\Git\usr\bin\tar.exe")) {throw "Git For Windows must be installed"} 
set-alias tar "$env:ProgramFiles\Git\usr\bin\tar.exe"  

# setup helper function
function getPackage
{
	$toGet = $args[0]
	$newname = $args[1]
	$archiveName = [io.path]::GetFileNameWithoutExtension($toGet)
	$archiveExt = [io.path]::GetExtension($toGet)
	$isTar = [io.path]::GetExtension($archiveName)
	if ($isTar -eq ".tar") {
		$archiveExt = $isTar + $archiveExt
		$archiveName = [io.path]::GetFileNameWithoutExtension($archiveName)  
	}
	if ($archiveExt -eq ".git") {
		# the source is a git repo, so make a shallow clone
		# no need to store anything in the packages dir
		if (!(Test-Path $root\src-stage1-dependencies\$archiveName)) {
			cd $root\src-stage1-dependencies	
			git clone --depth=1 $toGet  2>&1 | write-host
		} else {
			"$archiveName already present"
		}
	} else {
		# source is a compressed package
		# store it in the packages dir so we can reuse it if we
		# clean the whole install
		if (!(Test-Path $root/packages/$archiveName)) {
			mkdir $root/packages/$archiveName
		}
		if (!(Test-Path $root/packages/$archiveName/$archiveName$archiveExt)) {
			cd $root/packages/$archiveName
			wget $toGet -OutFile "$archiveName$archiveExt"
		} else {
			"$archiveName already present"
		}
		if (!(Test-Path $root\src-stage1-dependencies\$archiveName)) {
			$archive = "$root/packages/$archiveName/$archiveName$archiveExt"
			cd "$root\src-stage1-dependencies"
			if ($archiveExt -eq ".7z") {
				sz x -y $archive 2>&1 | write-host
			} elseif ($archiveExt -eq ".zip") {
				$destination = "$root/src-stage1-dependencies"
				[io.compression.zipfile]::ExtractToDirectory($archive, $destination)
			} elseif ($archiveExt -eq ".tar.gz" ) {
				tar zxf $archive 2>&1 | write-host 
			} elseif ($archiveExt -eq ".tar.xz" -or $archiveExt -eq ".tgz") {
				sz x -y $archive 
				sz x -aoa -ttar -o"$root\src-stage1-dependencies" "$archiveName.tar"
				del "$archiveName.tar"
			} else {
				throw "Unknown file extension on $archiveName$archiveExt"
			}
		}
	}
	if ($newname -ne $null) {
		ren $root\src-stage1-dependencies\$archiveName $root\src-stage1-dependencies\$newname
	}
}

# Patches are overlaid on top of the main source for gnuradio-specific adjustments
function getPatch
{
	$toGet = $args[0]
	$whereToPlace = $args[1]
	$archiveName = [io.path]::GetFileNameWithoutExtension($toGet)
	$archiveExt = [io.path]::GetExtension($toGet)
	$isTar = [io.path]::GetExtension($archiveName)
	if ($isTar -eq ".tar") {
		$archiveExt = $isTar + $archiveExt
		$archiveName = [io.path]::GetFileNameWithoutExtension($archiveName)  
	}
	$url = "http://www.gcndevelopment.com/gnuradio/downloads/sources/" + $toGet 
	if (!(Test-Path $root/packages/patches)) {
		mkdir $root/packages/patches
	}
	cd $root/packages/patches
	wget $url -OutFile $toGet
	$archive = "$root/packages/patches/$toGet"
	$destination = "$root/src-stage1-dependencies/$whereToPlace"
	if ($archiveExt -eq ".7z") {
		New-Item -path $destination -type directory -force
		cd $destination 
		sz x -y $archive 2>&1 | write-host
	} elseif ($archiveExt -eq ".zip") {
		New-Item -path $destination -type directory -force
		[io.compression.zipfile]::ExtractToDirectory($archive, $destination)
	} elseif ($archiveExt -eq ".tar.gz") {
		New-Item -path $destination -type directory -force
		cd $destination 
		tar zxf $archive 2>&1 | write-host 
	} elseif ($archiveExt -eq ".tar.xz") {
		New-Item -path $destination -type directory -force
		cd $destination 
		sz x -y $archive 
		sz x -aoa -ttar "$archiveName.tar"
		del "$archiveName.tar"
	} else {
		throw "Unknown file extension on $archiveName$archiveExt"
	}
}

# Retrieve packages needed for Stage 1
cd $root/src-stage1-dependencies

#libzmq
getPackage https://github.com/zeromq/libzmq.git

# libpng
getPackage ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.21.tar.xz
getPatch libpng-1.6.21-vs2015.7z libpng-1.6.21\projects\vstudio-vs2015

# SDL 1.2.15
getPackage  https://libsdl.org/release/SDL-1.2.15.zip
getPatch sdl-1.2.15-vs2015.7z SDL-1.2.15\VisualC

# portaudio v19
GetPackage http://portaudio.com/archives/pa_stable_v19_20140130.tgz
GetPatch portaudio_vs2015.7z portaudio/build/msvc
# asio SDK for portaudio
# folder will already exist
if (!(Test-Path $root/packages/portaudio/asiosdk2.3.zip)) {
	cd $root/packages/portaudio
	wget http://www.steinberg.net/sdk_downloads/asiosdk2.3.zip -OutFile asiosdk2.3.zip
} else {
	"ASIO SDK already present"
}
if (!(Test-Path $root/src-stage1-dependencies/portaudio/src/hostapi/asio/asiosdk)) {
	$archive = "$root/packages/portaudio/asiosdk2.3.zip"
	$destination = "$root/src-stage1-dependencies/portaudio/src/hostapi/asio"
	[io.compression.zipfile]::ExtractToDirectory($archive, $destination)
	cd $destination
	ren asiosdk2.3 asiosdk
}

# cppunit 1.12.1
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/cppunit-1.12.1.7z
#if (!(Test-Path $root/packages/cppunit-1.12.1)) {
#	mkdir $root/packages/cppunit-1.12.1
#}
#if (!(Test-Path $root/packages/cppunit-1.21.1/cppunit-1.12.1.7z)) {
#	cd $root/packages/cppunit-1.12.1
#	wget http://www.gcndevelopment.com/gnuradio/downloads/sources/cppunit-1.12.1.7z -OutFile cppunit-1.12.1.7z
#} else {
#	"cppunit-1.12.1 already present"
#}
#if (!(Test-Path $root/src-stage1-dependencies/cppunit-1.12.1)) {
#	cd $root/src-stage1-dependencies
#	$archive = "$root/packages/cppunit-1.12.1/cppunit-1.12.1.7z"
#	$destination = "$root/src-stage1-dependencies/cppunit-1.12.1"
#	cd $root/src-stage1-dependencies/
#	sz x $archive
#}

# fftw3.3.5
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/fftw-3.3.5.7z
#if (!(Test-Path $root/packages/fftw-3.3.5)) {
#	mkdir $root/packages/fftw-3.3.5
#}
#if (!(Test-Path $root/packages/fftw-3.3.5/fftw-3.3.5.7z)) {
#	cd $root/packages/fftw-3.3.5
#	wget http://www.gcndevelopment.com/gnuradio/downloads/sources/fftw-3.3.5.7z -OutFile fftw-3.3.5.7z
#} else {
#	"FFTW3 already present"
#}
#if (!(Test-Path $root/src-stage1-dependencies/fftw-3.3.5)) {
#	cd $root/src-stage1-dependencies
#	$archive = "$root/packages/fftw-3.3.5/fftw-3.3.5.7z"
#	$destination = "$root/src-stage1-dependencies/fftw-3.3.5"
#	cd $root/src-stage1-dependencies/
#	sz x $archive
#}

#python
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/libraries/python27/python2710-x64-Source.zip
GetPatch python-pcbuild.vc14.zip python27/Python-2.7.10
#if (!(Test-Path $root/packages/python27)) {
#	mkdir $root/packages/python27
#}
#if (!(Test-Path $root/packages/python27/python2710-x64-Source.zip)) {
#	cd $root/packages/python27
#	wget http://www.gcndevelopment.com/gnuradio/downloads/libraries/python27/python2710-x64-Source.zip -OutFile python2710-x64-Source.zip
#} else {
#	"python already present"
#}
#if (!(Test-Path $root/packages/python27/python-pcbuild.vc14.zip)) {
#	cd $root/packages/python27
#	wget http://www.gcndevelopment.com/gnuradio/downloads/sources/python-pcbuild.vc14.zip -OutFile pcbuild.vc14.zip
#} else {
#	"python already present"
#}
#if (!(Test-Path $root/src-stage1-dependencies/python27)) {
#	cd $root/src-stage1-dependencies
#	$BackupPath = "$root/packages/python27/python2710-x64-Source.zip"
#	$destination = "$root/src-stage1-dependencies/python27"
#	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
#	$BackupPath = "$root/packages/python27/pcbuild.vc14.zip"
#	$destination = "$root/src-stage1-dependencies/python27/Python-2.7.10"
#	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
#}

# zlib
GetPackage https://github.com/gnieboer/zlib.git
#if (!(Test-Path $root/src-stage1-dependencies/zlib)) {
#		cd $root/src-stage1-dependencies
#		git clone --depth=1 https://github.com/gnieboer/zlib.git 2>&1 | write-host 
#	} else {
#		"zlib already present";
#	}

#libsodium
GetPackage https://github.com/gnieboer/libsodium.git 
#if (!(Test-Path $root/src-stage1-dependencies/libsodium)) {
#		cd $root/src-stage1-dependencies
#	git clone https://github.com/gnieboer/libsodium.git 2>&1 | write-host 
#	} else {
#		"libsodium already present";
#	}

#GSL
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gsl-vs2015-3276.zip gsl-1.15
#if (!(Test-Path $root/packages/GSL)) {
#	mkdir $root/packages/GSL
#}
#if (!(Test-Path $root/packages/GSL/gsl-vs2015-3276.zip)) {
#	cd $root/packages/GSL
#	wget http://www.gcndevelopment.com/gnuradio/downloads/sources/gsl-vs2015-3276.zip -OutFile gsl-vs2015-3276.zip
#} else {
#	"GSL already present"
#}
#if (!(Test-Path $root/src-stage1-dependencies/gsl-1.16)) {
#	cd $root/src-stage1-dependencies
#	$BackupPath = "$root/packages/GSL/gsl-vs2015-3276.zip"
#	$destination = "$root/src-stage1-dependencies/gsl-1.16"
#	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
#}

#openssl
$openssl_version = "1.0.2f"
if (!(Test-Path $root/packages/openssl)) {
	mkdir $root/packages/openssl 
}
if (!(Test-Path $root/packages/openssl/openssl-$openssl_version.tar.gz)) {
	cd $root/packages/openssl
	wget ftp://ftp.openssl.org/source/openssl-$openssl_version.tar.gz -OutFile openssl-$openssl_version.tar.gz
} 
if (!(Test-Path $root/packages/openssl/openssl-vs14.zip)) {
	cd $root/packages/openssl
	wget http://www.gcndevelopment.com/gnuradio/downloads/sources/openssl-vs14.zip -OutFile openssl-vs14.zip
} 
if (!(Test-Path $root/src-stage1-dependencies/openssl)) {
	cd $root/src-stage1-dependencies
	$BackupPath = "../packages/openssl/openssl-$openssl_version.tar.gz"
	$destination = "$root/src-stage1-dependencies"
	tar zxf $BackupPath 2>&1 | write-host 
	ren openssl-$openssl_version openssl
}
if (!(Test-Path $root/src-stage1-dependencies/openssl/openssl.vcxproj)) {
	cd $root/src-stage1-dependencies
	$BackupPath = "$root/packages/openssl/openssl-vs14.zip"
	$destination = "$root/src-stage1-dependencies/openssl"
	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
}

# Qt
if (!(Test-Path $root/packages/Qt4)) {
	mkdir $root/packages/Qt4 
}
if (!(Test-Path $root/packages/Qt4/qt-everywhere-opensource-src-4.8.7.zip)) {
	cd $root/packages/Qt4
	wget http://download.qt.io/archive/qt/4.8/4.8.6/qt-everywhere-opensource-src-4.8.7.zip
} 

if (!(Test-Path $root/src-stage1-dependencies/Qt4)) {
	cd $root/src-stage1-dependencies
	$BackupPath = "$root/packages/Qt4/qt-everywhere-opensource-src-4.8.7.zip"
	$destination = "$root/src-stage1-dependencies"
	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
	ren qt-everywhere-opensource-src-4.8.7 Qt4
}

# Boost
if (!(Test-Path $root/packages/boost)) {
	mkdir $root/packages/boost 
}
if (!(Test-Path $root/packages/boost/boost_1_60_0.zip)) {
	cd $root/packages/boost
	wget "http://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.zip" -OutFile boost_1_60_0.zip  -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox
} 
if (!(Test-Path $root/src-stage1-dependencies/boost)) {
	cd $root/src-stage1-dependencies
	$BackupPath = "$root/packages/boost/boost_1_60_0.zip"
	$destination = "$root/src-stage1-dependencies"
	[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)
	ren boost_1_60_0 boost
}

# cleanup

# return to original directory
cd $root/scripts