ifdef SUBDIR
SUBDIRS+=		$(SUBDIR)
endif


# subdirectories

define SUBDIR_template
DEFAULT_TARGETS+=	$(1)
.PHONY: $(1)
$(1):
	@$$(MAKE) -C $(1) all

INSTALL_TARGETS+=	$(1)_install
$(1)_install:
	@$$(MAKE) -C $(1) install

CLEAN_TARGETS+=	$(1)_clean
$(1)_clean:
	@$$(MAKE) -C $(1) clean

DISTCLEAN_TARGETS+=	$(1)_distclean
$(1)_distclean:
	@$$(MAKE) -C $(1) distclean
endef

$(foreach subdir,$(SUBDIRS),$(eval $(call SUBDIR_template,$(subdir))))
