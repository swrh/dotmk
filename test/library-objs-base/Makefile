LIBS=./foo.so
foo.so_SRCS=bar.c
foo_SRCS=foo.c

CFLAGS+=-DPIC -fPIC

include ../mk/build.mk

all: test
test:
	[ ! -f bar.o ]
	[ -f foo.o ]
