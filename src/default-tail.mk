.PHONY: all install uninstall clean distclean
all: $(filter-out $(DISABLE_TARGETS),$(DEFAULT_TARGETS))
ifeq ($(filter install,$(DISABLE_TARGETS)),)
install: $(filter-out $(DISABLE_TARGETS),$(INSTALL_TARGETS))
endif
ifeq ($(filter uninstall,$(DISABLE_TARGETS)),)
uninstall: $(filter-out $(DISABLE_TARGETS),$(UNINSTALL_TARGETS))
endif
ifeq ($(filter clean,$(DISABLE_TARGETS)),)
clean: $(filter-out $(DISABLE_TARGETS),$(CLEAN_TARGETS))
endif
ifeq ($(filter distclean,$(DISABLE_TARGETS)),)
distclean: $(filter-out $(DISABLE_TARGETS),$(DISTCLEAN_TARGETS))
endif

.DEFAULT_GOAL:=		all
