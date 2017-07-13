@ECHO OFF

REM ###########################################
REM ##### start of configuration section ######
REM ###########################################

SET "CYGWIN_INSTALL_DIR=C:\Cygwin64\bin"
SET "TCL_INSTALL_DIR=C:\ActiveTcl"

REM ##########################################
REM ###### end of configuration section ######
REM ##########################################

SET "INITIAL_DIR=%CD%"
SET "WD=%~dp0"
SET "PATH=%WD%;%PATH%"
PUSHD %WD%
    CALL :LAUNCH_VISUAL_STUDIO || GOTO :ERROR

    CALL :CONFIGURE_PATHS || GOTO :ERROR

	CALL :DEPLOY_NEW_FILES || GOTO :ERROR

	CALL :APPLY_PATCHES || GOTO :ERROR

    IF EXIST output RMDIR /S /Q "%WD%output" || GOTO :ERROR
    MKDIR output || GOTO :ERROR

    CALL :BUILD_SQLITE || GOTO :ERROR

    CALL :BUILD_ZLIB || GOTO :ERROR

    CALL :BUILD_LIBXML || GOTO :ERROR

    CALL :BUILD_OPENSSL || GOTO :ERROR

    CALL :BUILD_ICU || GOTO :ERROR

    CALL :BUILD_QTBASE || GOTO :ERROR

    CALL :BUILD_QWEBKIT || GOTO :ERROR

    REM CALL :BUILD_PHANTOMJS || GOTO :ERROR

	REM CALL :PACKAGE_OUTPUT || GOTO :ERROR
POPD
ECHO Build process completed
GOTO:EOF
:ERROR:
ECHO Build Failed
cd %INITIAL_DIR%
EXIT /B 1



:LAUNCH_VISUAL_STUDIO:
ECHO Launching VS2015 Environment...
SET "PROG32_ROOT=%programfiles%"
IF "%programfiles(x86)%" NEQ "" SET "PROG32_ROOT=%programfiles(x86)%"
SET "VS2015=%PROG32_ROOT%\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
IF [%VisualStudioVersion%] NEQ [14.0] (
    "%VS2015%" x86
)
GOTO:EOF



:CONFIGURE_PATHS:
ECHO Mapping Tcl...
SET "PATH=%PATH%;%TCL_INSTALL_DIR%\bin"
SET "LIB=%TCL_INSTALL_DIR%\lib;%LIB%"
SET "INCLUDE=%TCL_INSTALL_DIR%\include;%INCLUDE%"
ECHO Mapping Jom...
SET "PATH=%WD%tools\jom;%PATH%"
ECHO Mapping Patch...
SET "PATH=%WD%tools\patch\bin;%PATH%"
GOTO:EOF



:DEPLOY_NEW_FILES:
SETLOCAL EnableDelayedExpansion
SET "FILES_ROOT=%WD%\new_files"
PUSHD %FILES_ROOT%
    ECHO extracting new files...
	FOR /f %%A IN ('dir /s /b /a:-d *.*') DO (
		SET "FILE_TARGET=%%~dpA"
        SET "FILE_TARGET=!FILE_TARGET:\new_files\=\!"
		CALL xcopy "%%~A" "!FILE_TARGET!" /I /Q /Y || EXIT /B 1
	)
POPD
ENDLOCAL
GOTO:EOF



:APPLY_PATCHES:
SETLOCAL EnableDelayedExpansion
SET "PATCHES_ROOT=%WD%\patches"
PUSHD %PATCHES_ROOT%
    ECHO detecting patches...
	FOR /f %%A IN ('dir /s /b /a:-d *.patch') DO (
		SET "PATCH_TARGET=%%~dpnA"
        SET "PATCH_TARGET=!PATCH_TARGET:\patches\=\!"
		CALL patch "!PATCH_TARGET!" "%%~A" || EXIT /B 1
	)
POPD
ENDLOCAL
GOTO:EOF



:BUILD_SQLITE:
ECHO Building Sqlite...
CALL powershell -Command "Invoke-WebRequest https://www.sqlite.org/src/zip/sqlite.zip -OutFile sqlite.zip" || EXIT /B 1
CALL 7z x sqlite.zip -y || EXIT /B 1
DEL sqlite.zip || EXIT /B 1

SET "SQLITE_DIR=%WD%output\sqlite"
IF NOT EXIST %SQLITE_DIR% MKDIR %SQLITE_DIR%
PUSHD %SQLITE_DIR%
	CALL nmake /f "%WD%sqlite\Makefile.msc" libsqlite3.lib TOP="%WD%sqlite" NO_TCL=1 USE_CRT_DLL=1 LIBTCL=tcl86t.lib || EXIT /B 1

	IF NOT EXIST "%SQLITE_DIR%\libsqlite3.lib" (
        ECHO QtBase Build Failed - Missing libsqlite3.lib
        EXIT /B 1
    )
POPD
SET "PATH=%SQLITE_DIR%;%PATH%"
SET "LIB=%SQLITE_DIR%;%LIB%"
SET "INCLUDE=%SQLITE_DIR%;%INCLUDE%"
GOTO:EOF



:BUILD_ZLIB:
ECHO Building ZLib...
SET "ZLIB_BUILD_DIR=%WD%output\zlib"
SET "ZLIB_INCS=%ZLIB_BUILD_DIR%\include"
SET "ZLIB_LIBS=%ZLIB_BUILD_DIR%\lib"
SET "ZLIB_BINS=%ZLIB_BUILD_DIR%\bin"
PUSHD zlib
    CALL nmake /f win32/Makefile.msc clean || EXIT /B 1

    CALL nmake /f win32/Makefile.msc || EXIT /B 1

    REM copies zlib.lib & zdll.lib
    CALL xcopy "%WD%zlib\*.lib" "%ZLIB_LIBS%" /I /Q /Y || EXIT /B 1

    REM Copies zlib1.dll
    CALL xcopy "%WD%zlib\*.dll" "%ZLIB_BINS%" /I /Q /Y || EXIT /B 1

    REM Copies root header files
    CALL xcopy "%WD%zlib\*.h" "%ZLIB_INCS%" /I /Q /Y || EXIT /B 1

	IF NOT EXIST "%ZLIB_LIBS%\zlib.lib" (
        ECHO QtBase Build Failed - Missing zlib.lib
        EXIT /B 1
    )
POPD
SET "PATH=%ZLIB_BINS%;%PATH%"
SET "LIB=%ZLIB_LIBS%;%LIB%"
SET "INCLUDE=%ZLIB_INCS%;%INCLUDE%"
GOTO:EOF



:BUILD_LIBXML:
ECHO Building Libxml2...
SET "LIBXML_DIR=%WD%output\libxml2"
PUSHD libxml2\win32
    CALL cscript configure.js compiler=msvc prefix="%LIBXML_DIR%" iconv=no zlib=yes xml_debug=no static=yes || EXIT /B 1

    CALL nmake /f Makefile.msvc install || EXIT /B 1

	IF NOT EXIST "%LIBXML_DIR%\lib\libxml2_a.lib" (
        ECHO QtBase Build Failed - Missing libxml2_a.lib
        EXIT /B 1
    )
POPD
SET "PATH=%LIBXML_DIR%\bin;%PATH%"
SET "LIB=%LIBXML_DIR%\lib;%LIB%"
SET "INCLUDE=%LIBXML_DIR%\include\libxml2;%INCLUDE%"
GOTO:EOF



:BUILD_OPENSSL:
ECHO Building OpenSSL...
SET "OPENSSL_DIR=%WD%output\openssl"
SET "PATH=%PATH%;%WD%nasm"
PUSHD openssl
    CALL perl Configure VC-WIN32 no-asm no-shared --prefix="%OPENSSL_DIR%" --openssldir="%OPENSSL_DIR%\ssl" || EXIT /B 1

    CALL ms\do_ms.bat || EXIT /B 1

    CALL nmake -f ms\nt.mak || EXIT /B 1

    CALL nmake -f ms\nt.mak install || EXIT /B 1

	IF NOT EXIST "%OPENSSL_DIR%\lib\ssleay32.lib" (
        ECHO QtBase Build Failed - Missing ssleay32.lib
        EXIT /B 1
    )
POPD
SET "PATH=%OPENSSL_DIR%\bin;%PATH%"
SET "LIB=%OPENSSL_DIR%\lib;%LIB%"
SET "INCLUDE=%OPENSSL_DIR%\include;%INCLUDE%"
GOTO:EOF



:BUILD_ICU:
ECHO Building ICU...
SET "ICU_DIR=%WD%output\icu"
PUSHD icu\source
    SET "PATH=%PATH%;%CYGWIN_INSTALL_DIR%"

    FOR /F "delims=" %%a IN ('cygpath -p -u "%ICU_DIR%"') DO SET "INSTALL_DIR_CYGWIN=%%a"
    IF %ERRORLEVEL% NEQ 0 EXIT /B 1

    CALL dos2unix * || EXIT /B 1
    CALL dos2unix -f configure || EXIT /B 1

    CALL bash runConfigureICU Cygwin/MSVC -prefix="%INSTALL_DIR_CYGWIN%" --enable-static --disable-shared || EXIT /B 1

    CALL make || EXIT /B 1

    CALL make install || EXIT /B 1

    CALL SET "PATH=%%PATH:;%CYGWIN_INSTALL_DIR%=%%"

	IF NOT EXIST "%ICU_DIR%\lib\sicuin.lib" (
        ECHO QtBase Build Failed - Missing sicuin.lib
        EXIT /B 1
    )
POPD
SET "PATH=%ICU_DIR%\bin;%PATH%"
SET "LIB=%ICU_DIR%\lib;%LIB%"
SET "INCLUDE=%ICU_DIR%\include;%INCLUDE%"
GOTO:EOF



:BUILD_QTBASE:
ECHO Building Qt5...
SET "QT_DIR=%WD%output\qt\5.7.1"
PUSHD qt
    SET "PATH=%WD%qt\gnuwin32\bin;%PATH%"

    CALL configure -mp -static -release -strip -ltcg^
 -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -qt-freetype^
 -qt-sql-sqlite -qt-sql-odbc -icu -opengl desktop -largefile^
 -no-qml-debug -no-dbus -no-audio-backend -no-angle^
 -opensource -confirm-license -make libs -skip qtwebengine^
 -skip qtconnectivity -skip qtserialport -skip qtlocation^
 -skip qtsensors -skip qtgamepad -skip qtdoc -skip qtpurchasing^
 -nomake tools -nomake examples -nomake tests^
 -openssl-linked OPENSSL_LIBS="-lws2_32 -lgdi32 -ladvapi32 -lcrypt32 -luser32 -llibeay32 -lssleay32"^
 -prefix "%QT_DIR%" -platform win32-msvc2015 || EXIT /B 1

    CALL jom install || EXIT /B 1

    IF NOT EXIST "%QT_DIR%\lib\Qt5Widgets.lib" (
        ECHO QtBase Build Failed - Missing Qt5Widgets.lib
        EXIT /B 1
    )
POPD
SET "PATH=%QT_DIR%\bin;%PATH%"
SET "LIB=%QT_DIR%\lib;%LIB%"
SET "INCLUDE=%WD%qt\qtbase\src\3rdparty\libjpeg;%INCLUDE%"
SET "INCLUDE=%WD%qt\qtbase\src\3rdparty\libpng;%INCLUDE%"
SET "INCLUDE=%QT_DIR%\include;%INCLUDE%"
GOTO:EOF



:BUILD_QWEBKIT:
ECHO Building QtWebKit...
PUSHD qtwebkit
    CALL cmake^
 -DPORT="Qt" -DCMAKE_BUILD_TYPE=Release -Wno-dev -DDEVELOPER_MODE=OFF --no-warn-unused-cli^
 -DENABLE_3D_TRANSFORMS=ON -DENABLE_ACCELERATED_2D_CANVAS=ON -DENABLE_ALLINONE_BUILD=ON^
 -DENABLE_ES6_ARROWFUNCTION_SYNTAX=ON -DENABLE_ATTACHMENT_ELEMENT=OFF -DENABLE_BATTERY_STATUS=OFF^
 -DENABLE_CANVAS_PATH=ON -DENABLE_CANVAS_PROXY=OFF -DENABLE_CHANNEL_MESSAGING=ON^
 -DENABLE_ES6_CLASS_SYNTAX=ON -DENABLE_ES6_GENERATORS=ON -DENABLE_ES6_MODULES=OFF^
 -DENABLE_ES6_TEMPLATE_LITERAL_SYNTAX=ON -DENABLE_CSP_NEXT=OFF -DENABLE_CSS_DEVICE_ADAPTATION=OFF^
 -DENABLE_CSS_SHAPES=ON -DENABLE_CSS_GRID_LAYOUT=ON -DENABLE_CSS3_TEXT=OFF^
 -DENABLE_CSS3_TEXT_LINE_BREAK=OFF -DENABLE_CSS_BOX_DECORATION_BREAK=ON -DENABLE_TOOLS=OFF^
 -DENABLE_CSS_IMAGE_ORIENTATION=OFF -DENABLE_CSS_IMAGE_RESOLUTION=OFF -DENABLE_CSS_IMAGE_SET=ON^
 -DENABLE_CSS_REGIONS=ON -DENABLE_CSS_COMPOSITING=OFF -DENABLE_CUSTOM_ELEMENTS=OFF^
 -DENABLE_CUSTOM_SCHEME_HANDLER=OFF -DENABLE_DATALIST_ELEMENT=ON -DENABLE_DATA_TRANSFER_ITEMS=OFF^
 -DENABLE_DETAILS_ELEMENT=ON -DENABLE_DEVICE_ORIENTATION=OFF -DENABLE_DOM4_EVENTS_CONSTRUCTOR=ON^
 -DENABLE_DOWNLOAD_ATTRIBUTE=ON -DENABLE_FETCH_API=ON -DENABLE_FONT_LOAD_EVENTS=OFF^
 -DENABLE_FTPDIR=OFF -DENABLE_FULLSCREEN_API=ON -DENABLE_GAMEPAD=OFF -DENABLE_GEOLOCATION=OFF^
 -DENABLE_HIGH_DPI_CANVAS=OFF -DENABLE_ICONDATABASE=ON -DENABLE_INDEXED_DATABASE=ON^
 -DENABLE_INPUT_SPEECH=OFF -DENABLE_INPUT_TYPE_COLOR=ON -DENABLE_INPUT_TYPE_DATE=OFF^
 -DENABLE_INPUT_TYPE_DATETIME_INCOMPLETE=OFF -DENABLE_INPUT_TYPE_DATETIMELOCAL=OFF^
 -DENABLE_INPUT_TYPE_MONTH=OFF -DENABLE_INPUT_TYPE_TIME=OFF -DENABLE_INPUT_TYPE_WEEK=OFF^
 -DENABLE_INTL=ON -DENABLE_LEGACY_NOTIFICATIONS=OFF -DENABLE_LEGACY_VENDOR_PREFIXES=ON^
 -DENABLE_LEGACY_WEB_AUDIO=OFF -DENABLE_LINK_PREFETCH=ON -DENABLE_JIT=ON -DENABLE_MATHML=ON^
 -DENABLE_MEDIA_CAPTURE=OFF -DENABLE_MEDIA_SOURCE=OFF -DENABLE_MEDIA_STATISTICS=OFF^
 -DENABLE_MEDIA_STREAM=OFF -DENABLE_METER_ELEMENT=ON -DENABLE_MHTML=ON -DENABLE_MOUSE_CURSOR_SCALE=OFF^
 -DENABLE_NAVIGATOR_CONTENT_UTILS=OFF -DENABLE_NAVIGATOR_HWCONCURRENCY=ON -DENABLE_NETSCAPE_PLUGIN_API=OFF^
 -DENABLE_NOSNIFF=OFF -DENABLE_NOTIFICATIONS=ON -DENABLE_ORIENTATION_EVENTS=OFF -DENABLE_TEST_SUPPORT=OFF^
 -DENABLE_PERFORMANCE_TIMELINE=OFF -DENABLE_PROMISES=ON -DENABLE_PROXIMITY_EVENTS=OFF^
 -DENABLE_QUOTA=OFF -DENABLE_RESOLUTION_MEDIA_QUERY=OFF -DENABLE_RESOURCE_TIMING=OFF^
 -DENABLE_REQUEST_ANIMATION_FRAME=ON -DENABLE_SAMPLING_PROFILER=ON -DENABLE_SECCOMP_FILTERS=OFF^
 -DENABLE_SCRIPTED_SPEECH=OFF -DENABLE_SHADOW_DOM=OFF -DENABLE_STREAMS_API=ON -DENABLE_SUBTLE_CRYPTO=OFF^
 -DENABLE_SVG_FONTS=ON -DUSE_SYSTEM_MALLOC=OFF -DENABLE_TEMPLATE_ELEMENT=ON -DENABLE_WEBKIT2=OFF^
 -DENABLE_THREADED_COMPOSITOR=OFF -DENABLE_TEXT_AUTOSIZING=OFF -DENABLE_TOUCH_EVENTS=OFF^
 -DENABLE_TOUCH_SLIDER=OFF -DENABLE_TOUCH_ICON_LOADING=OFF -DENABLE_USER_TIMING=OFF^
 -DENABLE_VIBRATION=OFF -DENABLE_VIDEO=OFF -DENABLE_VIDEO_TRACK=OFF -DENABLE_WEBGL=ON^
 -DENABLE_WEBASSEMBLY=OFF -DENABLE_WEB_ANIMATIONS=OFF -DENABLE_WEB_AUDIO=OFF -DENABLE_WEB_REPLAY=OFF^
 -DENABLE_WEB_SOCKETS=ON -DENABLE_WEB_TIMING=ON -DENABLE_XSLT=OFF -DENABLE_FTL_JIT=OFF^
 -DENABLE_PRINT_SUPPORT=OFF -DENABLE_OPENGL=OFF -DENABLE_API_TESTS=OFF -DUSE_MEDIA_FOUNDATION=OFF^
 -DQT_BUNDLED_JPEG=ON -DQT_BUNDLED_PNG=ON -DQT_BUNDLED_ZLIB=OFF^
 -DSQLITE_LIBRARIES="%SQLITE_DIR%\libsqlite3.lib" -DSQLITE_INCLUDE_DIR="%SQLITE_DIR%"^
 -DLIBXML2_LIBRARIES="%LIBXML_DIR%\lib\libxml2_a.lib" -DLIBXML2_INCLUDE_DIR="%LIBXML_DIR%\include"^
 -DCMAKE_PREFIX_PATH="%QT_DIR%" -G "NMake Makefiles JOM" || EXIT /B 1

    ECHO Compiling QtWebKit...
	CALL jom install || EXIT /B 1

    IF NOT EXIST "%QT_DIR%\lib\Qt5WebKitWidgets.lib" (
        ECHO QtWebKit Build Failed - Missing Qt5WebKitWidgets.lib
        EXIT /B 1
    )
POPD
SET "INCLUDE=%WD%qtwebkit\Source;%INCLUDE%"
GOTO:EOF



:BUILD_PHANTOMJS:
ECHO Building PhantomJS...
PUSHD phantomjs
    SET "WEB_INSPECTOR_RESOURCES_DIR=%WD%qtwebkit\DerivedSources\WebInspectorUI"

    CALL qmake || EXIT /B 1

    CALL jom || EXIT /B 1

    IF NOT EXIST bin\phantomjs.exe (
        ECHO PhantomJS Build Failed - Missing phantomjs.exe
        EXIT /B 1
    )
POPD
GOTO:EOF



:PACKAGE_OUTPUT:
ECHO Packaging Output...
PUSHD phantomjs
    IF NOT EXIST package MKDIR package
    IF NOT EXIST package\bin MKDIR package\bin
    CALL xcopy bin\phantomjs.exe package\bin /I /Q /Y || EXIT /B 1
    CALL xcopy ChangeLog package /I /Q /Y || EXIT /B 1
    CALL xcopy LICENSE.BSD package /I /Q /Y || EXIT /B 1
    CALL xcopy README.md package /I /Q /Y || EXIT /B 1
    CALL xcopy third-party.txt package /I /Q /Y || EXIT /B 1
	CALL xcopy deploy\A2I.PhantomJS.nuspec package /I /Q /Y || EXIT /B 1
POPD
CALL 7z a phantomjs.zip .\phantomjs\package\* || EXIT /B 1
GOTO:EOF
