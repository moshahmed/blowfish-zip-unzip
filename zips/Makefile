clean::
	cd unzip60     && make clean && make tags
	cd zip30       && make clean && make tags
	cd minizip-aes && make clean && make tags

gcc::
	@echo Use set-mingw.bat
	mkdir -p bin/gcc
	cd zip30   && make -f win32/makefile.gcc
	cd unzip60 && make -f win32/makefile.gcc
	cp -vp zip30/*.exe bin/gcc/
	cp -vp unzip60/*.exe bin/gcc/
	bin/gcc/zip -v | grep -i blowfish
	bin/gcc/unzip -v | grep -i blowfish
	bin/gcc/zip   --blowfish -Duro -P pass x.zip bin/gcc/*.exe
	        zip              -Duro -P pass x.zip Makefile
	@echo ========== Plain unzip will say 'incorrect password' for exe
	bin/gcc/unzip            -vt   -P pass x.zip || true
	@echo ========== blowfish unzip will say OK for exe
	bin/gcc/unzip            -vt   -P pass x.zip || true
	bin/gcc/unzip --blowfish -vt   -P pass x.zip || true
	@echo == cleaning
	cd zip30   && make -f win32/makefile.gcc clean
	cd unzip60 && make -f win32/makefile.gcc clean
