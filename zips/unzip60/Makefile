# Makefile to build and test blowfish-zip-unzip with vs9 on windows xp + cygwin
# $Header: c:/cvs/repo/github/bfz/zips/unzip60/Makefile,v 1.1 2014-02-04 11:24:52 a Exp $

# Check for msvc9 compiler.
CL_VER := $(shell cl.exe /? 2>&1 | perl -nle 'print "$$1" if m/Version.(\d+)/')
ifeq ($(CL_VER),)
  $(error run set-vs9.bat or set-vc6 to setup msvc compiler)
endif

IS_VC9 := $(shell echo "$(CL_VER)==15" | bc)
ifneq ($(IS_VC9),1)
  $(warn Use set-vs9.bat msvc compile, found $(CL_VER))
endif

vs9bin=$(shell cygpath -wam ../bin/$(dir $(lastword $(MAKEFILE_LIST)))/vs9)
gccbin=$(shell cygpath -wam ../bin/$(dir $(lastword $(MAKEFILE_LIST)))/gcc)
CTMP=$(shell cygpath -wam $$TMP)
bb=--blowfish --blowfish

vs9exe::
	@echo =========================================
	devenv win32/vs9/unzip.sln /Build "Debug|Win32" /Project unzip
	@echo =========================================
	cp -vp ./win32/vs9/unzip__Win32_Debug/unzip.exe $(vs9bin)/
	@echo =========================================
	$(vs9bin)/unzip.exe | grep -i Blowfish
ifeq (0,${MAKELEVEL})
	cd ../zip30/ && make vs9exe
endif

gcc::
	nmake -f win32/makefile

clean::
	rm -rfv *.exe *.obj obj/
	rm -rfv win32/{vc6,vs9}/{*.opt,*.ncb,*.plg,*.suo}
	rm -rfv win32/vc6/{Debug,Release}
	rm -rfv win32/vs9/*_Win32_*/
	rm -rfv win32/cb12/{Debug,Release}/

	@echo run mosh.cmd to set env
	msdev ./win32/vc6/unzip.dsw &

debug::
	@echo make debug
ifeq (0,${MAKELEVEL})
	cd ../zip30/ && make vs9exe
endif
	make vs9exe
	@echo =========================================
	@echo "#  === unzip must print INCORRECT"
	unzip.exe      -vtP pass $(CTMP)/b.zip || true
	@echo =========================================
	@echo "#  === $(vs9bin)/unzip must print OK"
	$(vs9bin)/unzip.exe $(bb) -vtP pass $(CTMP)/b.zip || true

