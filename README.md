GNURadio_Windows_Build_Scripts

A series of Powershell scripts to automatically download,  build from source, and install GNURadio and -all- it's dependencies as 64-bit native binaries then package as an msi using Visual Studio 2015

INSTALLATION

git clone http://www.github.com/gnieboer/GNURadio_Windows_Build_Scripts
cd GNURadio_Windows_Build_Scripts
powershell
./~RUNME_FIRST.ps1

ISSUES

1- Ensure your anti-virus is off during installation... even Windows Defender.  PyQt4 may fail to create manifest files as a result

2- Right-click your powershell window, go to "Properties" and ensure QuickEdit and Insert Mode are NOT checked.  Otherwise when you click on the window, execution may pause without any indication as to why, leading you to believe the build has hung.


