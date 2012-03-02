PROG=foo

PREFIX=.

include ../mk/build.mk

all: test
test:
	$(MAKE) install
	[ -f ./bin/foo ]
