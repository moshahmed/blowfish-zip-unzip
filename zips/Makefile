# $Header: c:/cvs/repo/github/bfz/zips/Makefile,v 1.5 2014-02-04 11:55:03 a Exp $
GCC_VER := $(shell gcc -v 2>&1 | perl -nle 'print "$$1" if m/Target:.(\S+)/')
ifneq ($(GCC_VER),mingw32)
  $(error run set-mingw.bat to setup codeblock mingw compiler)
endif

vs9bin=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/vs9)
gccbin=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/gcc)
cb12bin=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/cb12)
CTMP=$(shell cygpath -wam $$TMP)
bb=--blowfish --blowfish

gcc::
	mkdir -p bin/gcc
	cd zip30   && make -f win32/makefile.gcc
	cd unzip60 && make -f win32/makefile.gcc
	echo cp -vp zip30/*.exe $(gccbin)/
	cp -vp zip30/*.exe bin/gcc/
	cp -vp unzip60/*.exe bin/gcc/
	bin/gcc/zip -v | grep -i blowfish
	bin/gcc/unzip -v | grep -i blowfish
	make test

gcc-clean::
	@echo == cleaning gcc files
	cd zip30       && make -f win32/makefile.gcc clean
	cd unzip60     && make -f win32/makefile.gcc clean

tags::
	cd zip30   && ctags -R . &
	cd unzip60 && ctags -R . &
