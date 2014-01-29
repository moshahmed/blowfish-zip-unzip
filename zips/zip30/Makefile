# Makefile to build and test blowfish-zip-unzip with vs9 on windows xp + cygwin
# $Header: c:/cvs/repo/src/zips/zip30/Makefile,v 1.45 2014-01-29 14:55:45 a Exp $

CL_VER := $(shell cl.exe /? 2>&1 | perl -nle 'print "$$1" if m/Version.(\d+)/')
ifeq ($(CL_VER),)
  $(error run set-vs9.bat or set-vc6 to setup msvc compiler)
endif

vs9exe::
	devenv win32/vs9/zip.sln /Build "Debug|Win32" /Project zip
	cp ./win32/vs9/zip___Win32_Debug/zip.exe $$TMP/bf-zip.exe
	$$TMP/bf-zip.exe -h | grep -i blowfish

keep::
	cp -vp $$TMP/bf*zip.exe ../bin/

clean::
	rm -rfv *.exe *.obj obj/ bin/*.ilk
	rm -rfv win32/{vc6,vs9}*/{*.opt,*.ncb,*.plg,*.suo}
	rm -rfv win32/{vc6,vs9}*/{*_Win32_*,Debug,Release}
	rm -fv  win32/zip.aps

msdev::
	@echo msdev $$(find | grep dsw)
	@echo devenv $$(find | grep sln)

debug::
	@set -xv ;\
	make vs9exe
	cd $$TMP ;\
	rm -fv ?.txt ?.zip ;\
	seq  1 10 > x.txt ;\
	seq 10 20 > y.txt ;\
	 ./bf-zip.exe --blowfish -Deruo -P x b.zip x.txt y.txt ;\
	echo "NOW devenv > debug > zip -oP x b.zip *.txt in $$TMP"
ifeq (0,${MAKELEVEL})
	cd ../unzip60/ && make vs9exe && make debug
endif

multipass::
	@echo Creating $$TMP/b.zip with multiple-passwords
	cd $$TMP ;\
	rm -vf b.zip ;\
	./bf-zip -P x b.zip x.txt ;\
	./bf-zip -P y b.zip y.txt ;\
	./bf-unzip -vtoP x $$TMP/b.zip ;\
	./bf-unzip -vtoP y $$TMP/b.zip ;\

make_text_data::
	mkdir -p $$TMP/seq1 ;\
	if [[ -d $$TMP/seq1/ ]] ;then \
	  for i in {20..50} ;do \
	      seq 1 $$i > $$TMP/seq1/$$i.txt ;\
	  done ;\
	fi ;\

make_bin_data:
	set -xv ;\
	mkdir -p $$TMP/seq1 ;\
	for i in {20..50} ;do \
	    file=$$TMP/seq1/file-$$i.txt ;\
	    size=$$(($$RANDOM % 100000)) ;\
	    dd bs=1 count=$$size if=/dev/urandom of=$$file || break ;\
	done \

passwd::
	@passlen=$$((1+$$RANDOM %100)) ;\
	pass=$$(ps |md5sum | tr -dc 0-9a-z | head -c $${passlen}) ;\
	echo passlen=$$passlen pass=$$pass

regr::
	set -xv ;\
	rm -fv $$TMP/*.exe $$TMP/seq12.zip ;\
	(cd ../unzip61 ; make vs9exe );\
	make vs9exe ;\
	make make_bin_data ;\
	make make_text_data ;\
	cd $$TMP/ ;\
	passlen=$$((1+$$RANDOM %100)) ;\
	pass=$$(ps |md5sum | tr -dc 0-9a-z | head -c $${passlen}) ;\
	./bf-zip.exe -blowfish -Deruo -P $$pass seq12.zip seq1 ;\
	     unzip.exe -vtoP $$pass seq12.zip ;\
	./bf-unzip.exe -vtoP $$pass seq12.zip ;\
	./bf-unzip.exe -jod seq2 -P $$pass seq12.zip ;\
	diff -rq seq1 seq2

tags::
	ctags -R . &

gcc::
	@echo Use set-mingw.bat
	echo make -f win32/makefile.gcc [clean]
