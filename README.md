# QtPhantomJS
A repository for the combined modules required to build phantom JS with MSVC 2015

## Requirements
The following are required to be able to use the available build script:
- python 2.7 **(NOT VERSION 3.x)**
- Perl (ActivePerl can be downloaded from here: [https://www.activestate.com/activeperl/downloads])
- Microsoft Visual C build tools (version depends on branch)
- cygwin (with dos2unix, make, bash; required to build ICU library from source; ensure this is not added to the PATH environment variable as the build script will add it as required)
- Tcl library (ActiveTcl can be downloaded from here: [https://www.activestate.com/activetcl/downloads])

> Ensure all required libraries add their bin folders to the PATH environment variable (except for Cygwin).

## Scripts
The following scripts can be used to build the required version of QtPhantomJS.
- build.bat - normal build **(Currently Not Implemented)**
- static_build.bat - statically compiled and linked
- static_runtime_build.bat - statically compiled and linked with static runtime linkage **(Currently Not Implemented)**

## Usage
To run the build open a command prompt and execute the following command:
```batch
path\to\build\script\static_build.bat
```
 or
Drag the build script onto the command prompt window and hit 'Enter'
