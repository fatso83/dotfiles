all: millis

millis: millis.c
	cc millis.c -o millis

clean: 
	rm millis

install: all
	@mkdir ${HOME}/bin 2>/dev/null;	\
		mv ./millis ${HOME}/bin/ \
		&& echo "Installed millis in ${HOME}/bin"

