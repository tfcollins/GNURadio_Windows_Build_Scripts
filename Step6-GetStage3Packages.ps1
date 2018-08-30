#
# Step6_GetStage3Packages.ps1
#
# GNURadio Windows Build System
# Geof Nieboer

# script setup
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# setup helper functions
if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
if (Test-Path $mypath\Setup.ps1) {
	. $mypath\Setup.ps1 -Force
} else {
	. $root\scripts\Setup.ps1 -Force
}

# ____________________________________________________________________________________________________________
#
# gr-iio
#

GetPackage https://github.com/analogdevicesinc/gr-iio.git -Stage3 -branch attr-block
#GetPatch airspy_vs2015.7z airspy/libairspy/vc -Stage3


# ____________________________________________________________________________________________________________
#
# airspy
#
GetPackage https://github.com/airspy/host.git airspy -Stage3
GetPatch airspy_vs2015.7z airspy/libairspy/vc -Stage3

# ____________________________________________________________________________________________________________
#
# bladeRF
#
GetPackage https://github.com/Nuand/bladeRF.git -Stage3

# ____________________________________________________________________________________________________________
#
# rtl-sdr
#
GetPackage git://git.osmocom.org/rtl-sdr.git -Stage3

# ____________________________________________________________________________________________________________
#
# hackRF
#
GetPackage https://github.com/mossmann/hackrf.git -Stage3

# ____________________________________________________________________________________________________________
#
# osmosdr
#
GetPackage git://git.osmocom.org/gr-osmosdr -Stage3
GetPackage git://git.osmocom.org/osmo-sdr -Stage3

# ____________________________________________________________________________________________________________
#
# gr-iqbal
#
# upstream: https://github.com/osmocom/gr-iqbal.git
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gr-iqbal.7z -Stage3

# ____________________________________________________________________________________________________________
#
# gr-benchmark
#
GetPackage https://github.com/osh/gr-benchmark.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-acars2
#
# use this version instead of the original repo at antoinet unlike the fix gets merged
#
GetPackage https://github.com/gnieboer/gr-acars2.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-adsb
#
GetPackage https://github.com/wnagele/gr-adsb.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-air-modes
#
# using a fork until some cmake updates are included (push request sent)
# GetPackage https://github.com/bistromath/gr-air-modes.git -Stage3
GetPackage https://github.com/gnieboer/gr-air-modes.git -Stage3


# ____________________________________________________________________________________________________________
#
# gr-fosphor
#
# awaiting merge requests to go back to upstream repo instead of my fork
#
GetPackage https://github.com/gnieboer/gr-fosphor.git -Stage3
GetPackage https://github.com/glfw/glfw.git -Stage3

# ____________________________________________________________________________________________________________
#
# gqrx
#
GetPackage https://github.com/csete/gqrx/archive/v$gqrx_version.zip -Stage3

# ____________________________________________________________________________________________________________
#
# Armadillo
#
GetPackage https://downloads.sourceforge.net/project/arma/armadillo-7.800.1.tar.xz -Stage3


# ____________________________________________________________________________________________________________
#
# gflags
#
GetPackage https://github.com/gflags/gflags.git -Stage3

# ____________________________________________________________________________________________________________
#
# glog
#
GetPackage https://github.com/google/glog.git -Stage3

# ____________________________________________________________________________________________________________
#
# GNUTLS (binaries!)
#
GetPackage ftp://ftp.gnutls.org/gcrypt/gnutls/w32/gnutls-3.5.8-w64.zip gnutls -Stage3 -AddFolderName

# ____________________________________________________________________________________________________________
#
# gr-inspector
#
GetPackage https://github.com/gnuradio/gr-inspector.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-specest
#
GetPackage https://github.com/gnieboer/gr-specest.git -Stage3 -branch "msvc_fixes"

# ____________________________________________________________________________________________________________
#
# gr-cdma
#
GetPackage https://github.com/anastas/gr-cdma.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-rds
#
GetPackage https://github.com/bastibl/gr-rds.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-ais
#
# Awaiting incorporation of pull request
#
GetPackage https://github.com/gnieboer/gr-ais.git -Stage3 -branch "msvc-fixes"

# ____________________________________________________________________________________________________________
#
# gr-display
#
GetPackage https://github.com/dl1ksv/gr-display.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-ax25
#
GetPackage https://github.com/dl1ksv/gr-ax25.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-radar
#
# Awaiting incorporation of pull request
#
GetPackage https://github.com/gnieboer/gr-radar.git -Stage3 -branch "msvc_fixes"

# ____________________________________________________________________________________________________________
#
# gr-paint
#
GetPackage https://github.com/drmpeg/gr-paint.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-mapper
#
# Awaiting incorporation of pull request
#
GetPackage https://github.com/gnieboer/gr-mapper.git -Stage3 -branch "msvc_fixes"

# ____________________________________________________________________________________________________________
#
# gr-nacl
#
# Awaiting incorporation of pull request
#
GetPackage https://github.com/gnieboer/gr-nacl.git -Stage3 -branch "msvc_fixes"

# ____________________________________________________________________________________________________________
#
# gr-eventstream
#
#
GetPackage https://github.com/osh/gr-eventstream.git -Stage3

# ____________________________________________________________________________________________________________
#
# gr-burst
#
# Minor change from main repo
#
GetPackage https://github.com/gnieboer/gr-burst.git -Stage3 -branch "msvc_fixes"

# ____________________________________________________________________________________________________________
#
# gr-lte
#
GetPackage https://github.com/gnieboer/gr-lte.git -Stage3 -branch "msvc_fixes"

# ____________________________________________________________________________________________________________
#
# OpenLTE
#
GetPackage https://downloads.sourceforge.net/project/openlte/openlte_v$openlte_version.tgz -Stage3

# The below are all packages that will not currently build but are 'in work' for inclusion at a later date
# please feel free to give them a shot.
if ($false)
{

	# ____________________________________________________________________________________________________________
	#
	# libosmocore
	#
	GetPackage https://github.com/osmocom/libosmocore.git -Stage3

	# ____________________________________________________________________________________________________________
	#
	# GNSS-SDR
	#
	GetPackage https://github.com/gnss-sdr/gnss-sdr.git -Stage3

	# ____________________________________________________________________________________________________________
	#
	# gr-gsm
	#
	GetPackage https://github.com/ptrkrysik/gr-gsm.git -Stage3
}
# ____________________________________________________________________________________________________________
#
# gnuradio
#
SetLog "Retrieve GNURadio"
Write-Host -NoNewline "cloning GNURadio..."
if (!(Test-Path $root/src-stage3/src)) {
		cd $root/src-stage3
		mkdir src 2>&1 >> $log
	}
if (!(Test-Path $root/src-stage3/src/gnuradio)) {
	cd $root/src-stage3/src
    $ErrorActionPreference = "Continue"
    # most packages we just get the most recent commit when coming from git
    # however, since this is the one most users might want to modify, we'll get more.
	git clone --depth=150 --no-single-branch --recursive https://github.com/gnuradio/gnuradio.git 2>&1 >> $log
	cd gnuradio
  git checkout maint-3.7
	git pull --recurse-submodules=on
	#git submodule update
	cd ..
} else {
	"gnuradio already present";
}
if (!(Test-Path $root/src-stage3/src/gnuradio/volk/CMakeLists.txt)) {
	# volk submodule did not come across.  This is likely due to a problem with our git repo getting
	# out of sync with the volk tree.  So we'll just download $volk_version release as a backup
	cd $root/src-stage3/src/gnuradio
    $count = 0
    do {
        Try
		{
			wget https://github.com/gnieboer/volk/archive/v$volk_version.zip -OutFile volk.zip
            $count = 999
		}
		Catch [System.IO.IOException]
		{
			Write-Host -NoNewline "failed, retrying..."
			$count ++
		}
    } while ($count -lt 5)
    if ($count -ne 999) {
        Write-Host ""
        Write-Host -BackgroundColor Black -ForegroundColor Red "Error Downloading File, retries exceeded, aborting..."
        Exit
    }
	$destination = "$root/$destdir"
	[io.compression.zipfile]::ExtractToDirectory("$root/src-stage3/src/gnuradio/volk.zip", "$root/src-stage3/src/gnuradio") >> $Log
	Remove-Item volk -Force -Recurse
	Rename-Item volk-$volk_version volk -Force
	Remove-Item volk.zip -Force
	if (!(Test-Path $root/src-stage3/src/gnuradio/volk/CMakeLists.txt)) {
		Write-Host -BackgroundColor Black -ForegroundColor Red "FATAL ERROR: Volk was not downloaded properly, GNURadio cannot build"
		Exit
	}
}

$ErrorActionPreference = "Stop"

"complete"

cd $root/scripts

""
"COMPLETED STEP 6: GNURadio and OOT package source code has been downloaded"
""
