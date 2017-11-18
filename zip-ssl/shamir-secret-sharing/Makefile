CFLAGS = \
  -std=c99 \
  -W -Wall -Wextra \
  -O3 \
  -D_GNU_SOURCE=1 -DNOMLOCK=1 \

all::
	make clean
	gcc -o ssss-split.exe $(CFLAGS) *.c -lgmp
	cp -fv ssss-split.exe ssss-combine.exe

test::
	date | ./ssss-split -t 3 -n 5

clean::
	-rm -v ssss-*.exe
