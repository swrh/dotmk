PKG_CONFIG_PATH=$(CURDIR) $(CURDIR)/pkgconfig $(CURDIR)

PROGS=foo
LIBS=bar
DEPPKGCONFIG=x11

foo_SRCS=fu.c foo.c
foo_DEPPKGCONFIG=--define-variable=prefix=$(CURDIR) bar

bar_SRCS=bar.c
bar_INCDIRS=include

include ../mk/build.mk
