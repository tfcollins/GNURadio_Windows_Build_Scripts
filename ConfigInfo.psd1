#
# ConfigInfo.psd1
#
@{
	VersionInfo = @{
		gnuradio = '3.7.11' 
		volk = '1.3'
		libpng = '1.6.29'
		openssl = '1.0.2j'
		qwt = '5.2.3'
		qwt6 = '6.1.3'
		SDL = '1.2.15'
		cppunit = '1.12.1'
		sip = '4.17'
		PyQt = '4.11.4'
		PyQt5 = '5.6'
		Cython = '0.23.4'
		numpy = '1.12.0'
		scipy = '0.18.1'
		lapack = '3.6.0'
		OpenBLAS  = '0.2.17'
		pyopengl = '3.1.0'
		py2cairo = '1.10.0'
		cheetah = '2.4.4'
		gsl = '1.16'
		boost = '1.60.0'
		boost_ = '1_60_0'
		pthreads = '2-9-1'
		UHD = '003_010_001_001'
		pyzmq = '14.7.0'
		lxml = '3.6.0'
		libxslt = '1.1.29'
		pkgconfig = '1.1.0'
		log4cpp = '1.1.1'
		gqrx = '2.6.1'
		libusb = '1.0.21'   
		fftw = '3.3.6-pl2'      
		matplotlib = '2.0.0'
		PIL = '1.1.7'
		bitarray = '0.8.1'
		mbedtls = '2.4.2'
		openlte = '00-20-04'
		wxpython = '3.0.2.0'# Changing to 3.1+ will require other code changes
		pygobject = '2.28.6'# Changing to 2.29+ will require other code changes (but don't because 2.29 doesn't have the same setup.py)
		pygtk = '2.24.0'    # Changing to 2.25+ will require other code changes
		pygtk_git = '2_24_0_WINDOWS'    # Changing to 2.25+ will require other code changes
		qt = '4.8.7'        # This isn't actually used.  4.8.7 is hardcoded but 4.8.7 is the last 4.x version to the change to Qt5 will change much more
		python = '2.7.10'   # This isn't actually used.  2.7.10 is hardcoded 
		dp = '1.2'        # dependency pack version
		# TODO The following libraries are currently downloaded from current git snapshot.  This should be replaced by specific release tags
		# PyQwt (5.2.1, abandoned, no releases marked)
		# zlib (1.2.8 but should rarely change)
		# libsodium (but is forked on github.com/gnieboer/libsodium)
		# libzmq (repo doesn't use tags to mark releases)
	}
	# While most of the GTK stack can be built internally, it was not 100% complete when hexchat's port using VS 2015 was discovered
	# which has already been more thoroughly tested, so while the already accomplished code is still in place,
	# it is disabled for the moment
	BuildGTKFromSource = $false
}