#
# Step10_GetStage3Packages.ps1
#
# GNURadio Windows Build System
# Geof Nieboer

#setup
$root = $env:grwinbuildroot 
if (!$root) {$root = "C:\gr-build"}
cd $root

Add-Type -assembly "system.io.compression.filesystem"

# Retrieve packages needed for Stage 1
cd $root/src-stage3-gnuradio

# gnuradio
if (!(Test-Path $root/src-stage3-gnuradio/src)) {
		cd $root/src-stage3-gnuradio
		mkdir src
	} 
if (!(Test-Path $root/src-stage3-gnuradio/src/gnuradio)) {
	cd src
	git clone --recursive https://github.com/gnieboer/gnuradio.git 2>&1 | write-host 
} else {
	"gnuradio already present";
}