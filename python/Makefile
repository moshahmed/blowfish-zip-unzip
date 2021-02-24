help::  ; @make -qps | grep -Pi "^\w\S*:" | sort

molock::
	echo 'user1="aws:JBSWY3DPEHPK3PXP"' > $@.1.tmp
	python $@.py -v -f $@.1.tmp  $@.2.tmp enc fkey
	python $@.py -v -f $@.2.tmp  $@.3.tmp dec fkey
	python $@.py -v -g $@.2.tmp  user1        fkey
	python $@.py -v -t $@.2.tmp  user1 aws    fkey
	tail -n +1 *.tmp
	rm *.tmp
