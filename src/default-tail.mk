.PHONY: all install clean distclean
all: $(DEFAULT_TARGETS)
install: $(INSTALL_TARGETS)
clean: $(CLEAN_TARGETS)
distclean: $(DISTCLEAN_TARGETS)

.DEFAULT_GOAL:=		all
