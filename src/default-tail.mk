.PHONY: all install uninstall clean distclean
all: $(DEFAULT_TARGETS)
install: $(INSTALL_TARGETS)
uninstall: $(UNINSTALL_TARGETS)
clean: $(CLEAN_TARGETS)
distclean: $(DISTCLEAN_TARGETS)

.DEFAULT_GOAL:=		all
