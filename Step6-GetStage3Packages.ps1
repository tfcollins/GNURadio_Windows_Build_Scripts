#
# Step6_GetStage3Packages.ps1
#
# GNURadio Windows Build System
# Geof Nieboer

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
. $mypath\Setup.ps1 -Force

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
# gr-fosphor
#
GetPackage http://git.osmocom.org/gr-fosphor/ -Stage3
GetPackage https://github.com/glfw/glfw.git -Stage3

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
GetPackage https://github.com/osmocom/gr-iqbal -Stage3 

# gnuradio
SetLog "Retrieve GNURadio"
if (!(Test-Path $root/src-stage3/src)) {
		cd $root/src-stage3
		mkdir src
	} 
if (!(Test-Path $root/src-stage3/src/gnuradio)) {
	cd src
	git clone --recursive https://github.com/gnieboer/gnuradio.git 2>&1 >> $log 
} else {
	"gnuradio already present";
}

