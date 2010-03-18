PROG=foo

include ../mk/build.mk

.IGNORE: $(PROG)

all: test
test:
	[ ! -f foo ]
	[ ! -f any.o ]
	[ ! -f any.lo ]
