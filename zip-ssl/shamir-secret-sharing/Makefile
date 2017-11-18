CFLAGS = \
  -std=c99 \
  -W -Wall -Wextra \
  -O3 \
  -D_GNU_SOURCE=1 -DNOMLOCK=1 \

all::
	make clean
	make exe
	make test

exe::
	gcc -o ssss-split.exe $(CFLAGS) *.c -lgmp
	cp -fv ssss-split.exe ssss-combine.exe

test::
	@date | \
	  ./ssss-split -q -t 30 -n 50  | \
	  head -30 | \
	  ./ssss-combine -q -t 30 \

clean::
	-rm -v ssss-*.exe
