@ECHO OFF
SET "WD=%~dp0"
PUSHD %WD%
	git clean -xfdf
	git submodule foreach --recursive git clean -xfdf
	git reset --hard
	git submodule foreach --recursive git reset --hard
	git submodule update --init --recursive
POPD