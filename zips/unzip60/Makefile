# Makefile to build and test blowfish-zip-unzip with vs9 on windows xp + cygwin
# $Header: c:/cvs/repo/src/zips/unzip61/Makefile,v 1.33 2014-01-27 15:34:30 a Exp $

# Check for msvc9 compiler.
CL_VER := $(shell cl.exe /? 2>&1 | perl -nle 'print "$$1" if m/Version.(\d+)/')
ifeq ($(CL_VER),)
  $(error run set-vs9.bat or set-vc6 to setup msvc compiler)
endif

IS_VC9 := $(shell echo "$(CL_VER)==15" | bc)
ifneq ($(IS_VC9),1)
  $(warn Use set-vs9.bat msvc compile, found $(CL_VER))
endif

vs9exe::
	devenv win32/vs9/unzip.sln /Build "Debug|Win32" /Project unzip
	cp ./win32/vs9/unzip__Win32_Debug/unzip.exe $$TMP/bf-unzip.exe
	$$TMP/bf-unzip.exe | grep -i Blowfish

nmake::
	nmake -f win32/makefile

clean::
	rm -rfv *.exe *.obj obj/
	rm -rfv win32/{vc6,vs9}/{*.opt,*.ncb,*.plg,*.suo}
	rm -rfv win32/vc6/{Debug,Release}
	rm -rfv win32/vs9/*_Win32_*/

msdev:
	@echo run mosh.cmd to set env
	msdev ./win32/vc6/unzip.dsw &

debug::
ifeq (0,${MAKELEVEL})
	cd ../zip30/ && make vs9exe
endif
	@set -xv ;\
	make vs9exe ;\
	cd $$TMP ;\
	echo "===== unzip will print INCORRECT" ;\
	unzip.exe      -vtP x b.zip ;\
	echo "===== bf-unzip will print OK" ;\
	./bf-unzip.exe --blowfish -vtP x b.zip ;\
	ls -l ?.* ;\
	echo "NOW devenv > debug > unzip -vtP x b.zip in $$TMP"

regr:
	cd ../zip30 && make regr

tags::
	ctags --exclude=*.i -R . ../zip30 &

