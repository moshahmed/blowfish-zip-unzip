# $Header: c:/cvs/repo/github/bfz/zips/Makefile,v 1.9 2015-04-15 15:32:11 a Exp $

# What: This makefile is for testing exe from different compilers
#       and compiling with gcc.
# For vs9:

GCC_VER := $(shell gcc -v 2>&1 | perl -nle 'print "$$1" if m/Target:.(\S+)/')

# Note: For caseinsensitive m//i in Makefile, use shell
# $(findstring $(shell echo 'BC' | tr '[:upper:]' '[:lower:]'), 'abcd').
ifneq (,$(findstring mingw32,$(GCC_VER)))
  $(warning GCC_VER=$(GCC_VER))
else
  $(warning run set-mingw.bat to setup codeblock mingw compiler)
endif

vs9bin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/vs9)
vc6bin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/vc6)
gccbin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/gcc)
cb12bin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/cb12)
oldbin:=c:/bin14

binall:=$(vs9bin) $(vc6bin) $(gccbin) $(cb12bin) $(oldbin)

bin1=$(vs9bin)
bin2=$(gccbin)

CTMP=$(shell cygpath -wam $$TMP)
bb=--blowfish --blowfish
bb=--blowfish

test-ab-log::
	make test-ab > ab.log 2>&1
	dos2unix ab.log
	grep -i error ab.log

test-ab::
	echo Testing with zip/unzip from different compilers
	seq 10 20000 > $(CTMP)/a.txt
	seq 1 30 > $(CTMP)/b.txt
	# bina/zip and binb/unzip
	for bina in $(binall) ;do \
	    randu=$$(( $$RANDOM % 20 + 1 )) ;\
	    mkpass="$$(mkpass.exe 1 $$randu $$randu 1 || \
		       echo $$RANDOM.$$RANDOM.$$RANDOM)" ;\
	  if [[ ! -f $$bina/unzip.exe ]]; then \
		echo "Missing $$bina/zip.exe" ;\
		continue ;\
	  fi;\
	  echo "{{{ A $$(basename $$bina)/zip" ;\
	  for binb in $(binall) ;do \
	    if [[ ! -f $$binb/unzip.exe ]]; then \
		echo  "Missing $$binb/unzip.exe" ;\
		continue ;\
	    fi; \
	    rm -f $(CTMP)/ab.zip ;\
	    echo "{{{ B Comparing $$(basename $$bina)/zip and $$(basename $$binb)/unzip" ;\
	    echo $$bina/zip   $(bb) -Duro -P $$mkpass $(CTMP)/ab.zip $(CTMP)/a.txt ;\
	         $$bina/zip   $(bb) -Duro -P $$mkpass $(CTMP)/ab.zip $(CTMP)/a.txt ;\
	    echo $$binb/unzip $(bb) -vt   -P $$mkpass $(CTMP)/ab.zip ;\
	        -$$binb/unzip $(bb) -vt   -P $$mkpass $(CTMP)/ab.zip ;\
	    echo "}}} B Compared $$(basename $$binb)" ;\
	  done ;\
	  echo "}}} A $$(basename $$bina)/zip" ;\
	done ;\
	echo "# vim:fdm=marker:fmr={{{,}}}:fen " ;\

gcc::
	mkdir -p $(gccbin)
	cd zip30   && make -f win32/makefile.gcc NOASM=1
	cd unzip60 && make -f win32/makefile.gcc NOASM=1
	@echo Now copying: cp -vp zip30/*.exe $(gccbin)/
	cp -vp zip30/*.exe $(gccbin)/
	cp -vp unzip60/*.exe $(gccbin)/
	$(gccbin)/zip -v | grep -i blowfish
	$(gccbin)/unzip -v | grep -i blowfish
	make test-ab-log
	#make gcc-clean

gcc-clean::
	@echo == cleaning gcc files
	cd zip30       && make -f win32/makefile.gcc clean
	cd unzip60     && make -f win32/makefile.gcc clean

cp-vc6::
	@echo For vc6 exe, rebuild all with msdev
	@if [[ ! -e zip30/win32/vc6/Debug/zip.exe ]] ;then \
	  echo 'msdev ./unzip60/win32/vc6/unzip.dsw' ;\
	  echo 'msdev ./zip30/win32/vc6/zip.dsw' ;\
	else \
	  mkdir -p bin/vc6 ;\
	  cp -vpf ./unzip60/win32/vc6/Debug/unzip.exe bin/vc6/ ;\
	  cp -vpf ./zip30/win32/vc6/Debug/zip.exe     bin/vc6/ ;\
	fi ;\

cp-vs9::
	@echo For vs9 exe, rebuild all with devenv
	@if [[ ! -e zip30/win32/vs9/zip___Win32_Debug/zip.exe ]] ;then \
	  echo 'devenv zip30/win32/vs9/zip.sln /Build "Debug|Win32" /Project zip' ;\
	  echo 'devenv unzip60/win32/vs9/unzip.sln /Build "Debug|Win32" /Project unzip' ;\
	else \
	  mkdir -p bin/vs9 ;\
	  cp -vpf ./unzip60/win32/vs9/unzip__Win32_Debug/unzip.exe bin/vs9/ ;\
	  cp -vpf ./zip30/win32/vs9/zip___Win32_Debug/zip.exe      bin/vs9/ ;\
	fi ;\

tags::
	cd zip30   && ctags -R . &
	cd unzip60 && ctags -R . &
