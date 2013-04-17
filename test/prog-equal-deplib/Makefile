PROG=c
SRCS=main.c
DEPLIBS=c

ifneq ($(DOTMK),y)

.PHONY: all
all:
	$(MAKE) DOTMK=y
	touch $(SRCS)
	$(MAKE) DOTMK=y

.PHONY: clean distclean
clean distclean:
	$(MAKE) DOTMK=y $@

else

include ../mk/build.mk

endif
