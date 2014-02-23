# $Header: c:/cvs/repo/github/bfz/zips/Makefile,v 1.7 2014-02-23 05:05:50 a Exp $
GCC_VER := $(shell gcc -v 2>&1 | perl -nle 'print "$$1" if m/Target:.(\S+)/')
ifneq ($(GCC_VER),mingw32)
  $(warning run set-mingw.bat to setup codeblock mingw compiler)
endif

vs9bin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/vs9)
vc6bin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/vc6)
gccbin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/gcc)
cb12bin:=$(abspath bin/$(dir $(lastword $(MAKEFILE_LIST)))/cb12)
oldbin:=c:/bin14

binall:=$(vs9bin) $(vc6bin) $(gccbin) $(cb12bin) $(oldbin)

CTMP=$(shell cygpath -wam $$TMP)
bb=--blowfish --blowfish
bb=--blowfish

test-ab-log::
	make test-ab > ab.log 2>&1
	dos2unix ab.log

test-ab::
	echo Testing with zip/unzip from different compilers
	seq 10 20000 > $(CTMP)/a.txt
	seq 1 30 > $(CTMP)/b.txt
	for bina in $(binall) ;do \
	  test -f $$bina/zip.exe || continue ;\
	  echo "{{{ A $$(basename $$bina)/zip" ;\
	  for binb in $(binall) ;do \
	    test -f $$binb/unzip.exe || continue ;\
	    rm -f $(CTMP)/ab.zip ;\
	    echo "{{{ B Comparing $$(basename $$bina)/zip and $$(basename $$binb)/unzip" ;\
	    echo $$bina/zip   $(bb) -Duro -P pass $(CTMP)/ab.zip $(CTMP)/a.txt ;\
	         $$bina/zip   $(bb) -Duro -P pass $(CTMP)/ab.zip $(CTMP)/a.txt ;\
	    echo $$binb/unzip $(bb) -vt   -P pass $(CTMP)/ab.zip || true ;\
	         $$binb/unzip $(bb) -vt   -P pass $(CTMP)/ab.zip || true ;\
	    echo "}}} B Compared $$(basename $$binb)" ;\
	  done ;\
	  echo "}}} A $$(basename $$bina)/zip" ;\
	done ;\
	echo "# vim:fdm=marker:fmr={{{,}}}:fen " ;\

gcc::
	mkdir -p $(gccbin)
	cd zip30   && make -f win32/makefile.gcc NOASM=1
	cd unzip60 && make -f win32/makefile.gcc NOASM=1
	echo cp -vp zip30/*.exe $(gccbin)/
	cp -vp zip30/*.exe $(gccbin)/
	cp -vp unzip60/*.exe $(gccbin)/
	$(gccbin)/zip -v | grep -i blowfish
	$(gccbin)/unzip -v | grep -i blowfish
	make test

gcc-clean::
	@echo == cleaning gcc files
	cd zip30       && make -f win32/makefile.gcc clean
	cd unzip60     && make -f win32/makefile.gcc clean

tags::
	cd zip30   && ctags -R . &
	cd unzip60 && ctags -R . &
