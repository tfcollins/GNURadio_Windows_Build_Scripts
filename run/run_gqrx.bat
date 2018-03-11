@echo off
echo setting gnuradio environment

REM --- Set Python environment ---
set PYTHONHOME=%~dp0..\gr-python27
set PYTHONPATH=%~dp0..\gr-python27\Lib\site-packages;%~dp0..\gr-python27\dlls;%~dp0..\gr-python27\libs;%~dp0..\gr-python27\lib;%~dp0..\lib\site-packages;%~dp0..\gr-python27\Lib\site-packages\pkgconfig;%~dp0..\gr-python27\Lib\site-packages\gtk-2.0\glib;%~dp0..\gr-python27\Lib\site-packages\gtk-2.0;%~dp0..\gr-python27\Lib\site-packages\wx-3.0-msw;%~dp0..\gr-python27\Lib\site-packages\sphinx;%~dp0..\gr-python27\Lib\site-packages\lxml-3.4.4-py2.7-win.amd64.egg

set PATH=%~dp0;%~dp0..\gr-python27\dlls;%~dp0..\gr-python27;%PATH%

REM --- Set GRC environment ---
set GRC_BLOCKS_PATH=%~dp0..\share\gnuradio\grc\blocks

REM --- Set UHD environment ---
set UHD_PKG_DATA_PATH=%~dp0..\share\uhd;%~dp0..\share\uhd\images
set UHD_IMAGES_DIR=%~dp0..\share\uhd\images
set UHD_RFNOC_DIR=%~dp0..\share\uhd\rfnoc\

CALL gqrx.exe %1 %2 %3 %4