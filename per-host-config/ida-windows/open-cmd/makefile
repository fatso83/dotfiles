open: open.o getopt.o cygwin-1.5-adapter.o
	ld -o open *.o -lc -lcygwin -lkernel32 -luser32 -lgdi32 -lshell32

cygwin-1.5-adapter.o: cygwin-1.5-adapter.c
	gcc -c cygwin-1.5-adapter.c

open.o: open.cpp 
	gcc -c open.cpp

getopt.o: getopt.c
	gcc -c getopt.c

install: open
	cp open ${HOME}/bin

clean:
	rm *.o open
