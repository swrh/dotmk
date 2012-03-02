PROG=foo
OBJDIR=objdir
SRCS=../relative-objdir/bar.c

include ../mk/build.mk

all: test
test:
	[ ! -f relative-objdir/bar.o ]
