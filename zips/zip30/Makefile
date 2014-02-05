# Makefile to build and test blowfish-zip-unzip with vs9 on windows xp + cygwin
# $Header: c:/cvs/repo/github/bfz/zips/zip30/Makefile,v 1.1 2014-02-04 11:24:57 a Exp $

CL_VER := $(shell cl.exe /? 2>&1 | perl -nle 'print "$$1" if m/Version.(\d+)/')
ifeq ($(CL_VER),)
  $(error run set-vs9.bat or set-vc6 to setup msvc compiler)
endif

vs9bin=$(shell cygpath -wam ../bin/$(dir $(lastword $(MAKEFILE_LIST)))/vs9)
gccbin=$(shell cygpath -wam ../bin/$(dir $(lastword $(MAKEFILE_LIST)))/gcc)
CTMP=$(shell cygpath -wam $$TMP)
# make a long password and also save it in c:/tmp/pass.txt
password_long:=$(shell passlen=$$((1+$$RANDOM %100+1)); echo $$(ps |md5sum | tr -dc 0-9a-z | head -c $${passlen}) > $$TMP/pass.txt; cat $$TMP/pass.txt )
bb=--blowfish --blowfish

vs9exe::
	@echo =========================================
	devenv win32/vs9/zip.sln /Build "Debug|Win32" /Project zip
	@echo =========================================
	cp -vp ./win32/vs9/zip___Win32_Debug/zip.exe $(vs9bin)/
	@echo =========================================
	$(vs9bin)/zip.exe -h | grep -i blowfish
ifeq (0,${MAKELEVEL})
	cd ../unzip60/ && make vs9exe
endif

clean::
	rm -rfv *.exe *.obj obj/ bin/*.ilk
	rm -rfv win32/{vc6,vs9}*/{*.opt,*.ncb,*.plg,*.suo}
	rm -rfv win32/{vc6,vs9}*/{*_Win32_*,Debug,Release}
	rm -fv  win32/zip.aps
	rm -rfv win32/cb12/{Debug,Release}/

msdev::
	@echo msdev $$(find | grep dsw)
	@echo devenv $$(find | grep sln)

debug::
	make vs9exe
	@echo =========================================
	rm -fv $(CTMP)/?.txt $(CTMP)/?.zip
	seq  1 10 > $(CTMP)/x.txt
	seq 10 20 > $(CTMP)/y.txt
	@echo =========================================
	$(vs9bin)/zip.exe $(bb) -Deruo -P pass $(CTMP)/b.zip $(CTMP)/x.txt
	@echo =========================================
	$(gccbin)/zip.exe $(bb) -Deruo -P pass $(CTMP)/b.zip $(CTMP)/y.txt
	@echo =========================================
	echo "Now vs9 Devenv > debug > zip $(bb) -oP pass $(CTMP)/b.zip $(CTMP)/*.txt in $(CTMP)"
ifeq (0,${MAKELEVEL})
	cd ../unzip60/ && make vs9exe && make debug
endif


multipass::
	@echo Creating $(CTMP)/multipass.zip with multiple-passwords
	rm -vf $(CTMP)/{multipass.zip,x.txt,y.txt}
	seq 1 5 > $(CTMP)/x.txt
	seq 1 6 > $(CTMP)/y.txt
	$(vs9bin)/zip -P pass1x $(CTMP)/multipass.zip $(CTMP)/x.txt
	$(vs9bin)/zip -P pass2y $(CTMP)/multipass.zip $(CTMP)/y.txt
	$(vs9bin)/unzip -vtoP pass1x $(CTMP)/multipass.zip
	$(vs9bin)/unzip -vtoP pass2y $(CTMP)/multipass.zip

make_text_data::
	mkdir -p $(CTMP)/seq1 ;\
	if [[ -d $(CTMP)/seq1/ ]] ;then \
	  for i in {20..30} ;do \
	      seq 1 $$i > $(CTMP)/seq1/$$i.txt ;\
	  done ;\
	fi ;\

make_bin_data:
	set -xv ;\
	mkdir -p $(CTMP)/seq1 ;\
	for i in {20..30} ;do \
	    file=$(CTMP)/seq1/file-$$i.txt ;\
	    size=$$(($$RANDOM % 100000)) ;\
	    dd bs=1 count=$$size if=/dev/urandom of=$$file || break ;\
	done \

regr::
	@echo Making large number of files and large password
	rm -rfv $(CTMP)/*.exe $(CTMP)/seq12.zip $(CTMP)/pass.txt $(CTMP)/seq2
	cd ../unzip60 ; make vs9exe
	make vs9exe
	make make_bin_data
	make make_text_data
	$(vs9bin)/zip.exe $(bb) -Deruo -P $(password_long) $(CTMP)/seq12.zip $(CTMP)/seq1
	        unzip.exe           -vtoP $(password_long) $(CTMP)/seq12.zip || true
	$(vs9bin)/unzip.exe $(bb)   -vtoP $(password_long) $(CTMP)/seq12.zip
	$(vs9bin)/unzip.exe $(bb) -jod $(CTMP)/seq2 -P $(password_long) $(CTMP)/seq12.zip
	diff -rq $(CTMP)/seq1 $(CTMP)/seq2

tags::
	ctags -R . &

