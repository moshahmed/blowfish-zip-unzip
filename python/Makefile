.EXPORT_ALL_VARIABLES=1

help::  ; @make -qps | grep -Pi "^\w\S*:" | sort

VENV:=$(shell [ -d .venv ] && echo 1)
ifndef VENV
  $(error "Need .venv, to setup VIRTUAL_ENV run:     virtualenv .venv")
endif

ifeq ($(OS),Windows_NT)
  ifeq ($(VIRTUAL_ENV), )
      $(error "Need VIRTUAL_ENV, run:   .venv\scripts\activate.bat")
  endif
  # PYTHON=.venv/Scripts/python.exe
  PYTHON=$(VIRTUAL_ENV)/bin/python
else
  ifeq ($(VIRTUAL_ENV), )
      $(error "Need VIRTUAL_ENV, run:   source .venv/bin/activate")
  endif
  PYTHON=$(VIRTUAL_ENV)/bin/python
  SHELL=bash
endif

#@ PYTHON
py-ver::
	@echo PYTHON=$(PYTHON)
	@echo VIRTUAL_ENV=$(VIRTUAL_ENV)
	@$(PYTHON) --version

py-req::
	@$(PYTHON) -m pip freeze > requirements36.txt

tags::
	ctags \
	  --exclude=.git \
	  --exclude=.venv \
	  --exclude=.vscode  \
	  --exclude=.idea \
	  --exclude=__pycache__    \
	  -R .

#@ Programs
test::
	# python py-onetimepass.py
	# python py-gauth.py
	echo 'aws1/2021-03-12:JBSW-Y3DP-EHPK-3PXP' | python py-onetimepass.py aws1 -
	echo 'aws1/2021-03-12:JBSW-Y3DP-EHPK-3PXP' | python py-gauth.py aws1 -
	echo 'aws1/2021-03-12:JBSW-Y3DP-EHPK-3PXP' | python py-otp.py   aws1 -

motp::
	echo 'user1="aws1:JBSWY3DPEHPK3PXP"' > $@.1.tmp
	echo '       aws2:JBSW Y3DP EHPK 3PXP' >> $@.1.tmp
	echo '       aws3:ZZZZ Y3DP EHPK 3PXP' >> $@.1.tmp
	python $@.py -v --fileenc $@.1.tmp  $@.2.tmp fkey
	python $@.py -v --filedec $@.2.tmp  $@.3.tmp fkey
	python $@.py -v --keydec  $@.2.tmp  user1        fkey
	python $@.py -v --totp    $@.2.tmp  aws          fkey
	# more *.tmp | cat -
	tail -n +1 *.tmp
	rm *.tmp

GPG=gpg
FKEY= --passphrase fkey --batch --yes
SEEDS= junk \n JBSW-Y3DP-EHPK-3PXP \n aws1:JBSW-Y3DP-EHPK-3PXP \n aws2:ZZXW6-33PN5X-W6MZX \n

py-otp::
	@$(GPG) --version | grep GnuPG
	echo -e "$(SEEDS)" |\
        $(GPG) -c  $(FKEY) -o $@.gpg
	$(GPG) -qd $(FKEY)    $@.gpg |\
        python py-otp.py aws1 -
	@rm $@.gpg


gpg-otp::
	echo aws1:MZXW633PN5XW 6MZX   > $@.txt
	echo aws2:ZZXW6 33PN5XW6MZX  >> $@.txt
	echo aws3:MZXW6 33PN5XW 6MZX >> $@.txt
	gpg -o $@.gpg --passphrase fkey --batch --yes -qc $@.txt
	gpg           --passphrase fkey --batch --yes -qd $@.gpg | grep aws1
	python $@.py aws1 $@.gpg fkey
	rm $@.txt $@.gpg

gpg-grep::
	echo line1  >  tmp.txt
	echo line2 >>  tmp.txt
	gpg -o tmp.gpg --passphrase xyz --batch --yes -qc tmp.txt
	gpg            --passphrase xyz --batch --yes -qd tmp.gpg | grep line2
	rm   tmp.txt
	python gpg-grep.py l.*2 xyz tmp.gpg
	rm tmp.gpg
