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

gpgotp::
	echo aws1:MZXW633PN5XW 6MZX   > $@.txt
	echo aws2:ZZXW6 33PN5XW6MZX  >> $@.txt
	echo aws3:MZXW6 33PN5XW 6MZX >> $@.txt
	gpg -o $@.gpg --passphrase fkey --batch --yes -qc $@.txt
	gpg           --passphrase fkey --batch --yes -qd $@.gpg | grep aws1
	python $@.py aws1 $@.gpg fkey
	rm $@.txt $@.gpg

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
