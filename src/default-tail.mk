.PHONY: all install clean distclean
all: $(DEFAULT_TARGETS)
install: $(INSTALL_TARGETS)
clean: $(CLEAN_TARGETS)
distclean: $(CLEAN_TARGETS) $(DISTCLEAN_TARGETS)

.DEFAULT_GOAL:=		all
