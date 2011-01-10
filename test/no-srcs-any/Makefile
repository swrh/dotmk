PROG=foo

DISABLE_TARGET=install

include ../mk/build.mk

.IGNORE: $(PROG)

all: test
test:
	[ ! -f foo ]
	[ ! -f any.o ]
	[ ! -f any.lo ]
