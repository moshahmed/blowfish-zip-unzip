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
  PYTHON=.venv/Scripts/python.exe
else
  ifeq ($(VIRTUAL_ENV), )
      $(error "Need VIRTUAL_ENV, run:   source .venv/bin/activate")
  endif
  PYTHON=$(VIRTUAL_ENV)/bin/python
  SHELL=bash
endif


motp::
	echo 'user1="aws:JBSWY3DPEHPK3PXP"' > $@.1.tmp
	python $@.py -v -f $@.1.tmp  $@.2.tmp enc fkey
	python $@.py -v -f $@.2.tmp  $@.3.tmp dec fkey
	python $@.py -v -g $@.2.tmp  user1        fkey
	python $@.py -v -t $@.2.tmp  user1 aws    fkey
	tail -n +1 *.tmp
	rm *.tmp

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
