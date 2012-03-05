QMAKE?=		qmake

ifdef PRO
PROS+=		$(PRO)
endif


# pro files

define PRO_template
DEFAULT_TARGETS+=	$(patsubst %.pro,%,$(notdir $(1)))
Makefile-$(notdir $(1)): $(1)
	@$$(QMAKE) -o Makefile-$(notdir $(1)) $(1)

.PHONY: $(patsubst %.pro,%,$(notdir $(1)))
$(patsubst %.pro,%,$(notdir $(1))): Makefile-$(notdir $(1))
	@$$(MAKE) -f Makefile-$(notdir $(1)) all

INSTALL_TARGETS+=	$(patsubst %.pro,%,$(notdir $(1)))_install
$(patsubst %.pro,%,$(notdir $(1)))_install: Makefile-$(notdir $(1))
	@$$(MAKE) -f Makefile-$(notdir $(1)) install

CLEAN_TARGETS+=	$(patsubst %.pro,%,$(notdir $(1)))_clean
$(patsubst %.pro,%,$(notdir $(1)))_clean: Makefile-$(notdir $(1))
	@$$(MAKE) -f Makefile-$(notdir $(1)) clean

DISTCLEAN_TARGETS+=	$(patsubst %.pro,%,$(notdir $(1)))_distclean
$(patsubst %.pro,%,$(notdir $(1)))_distclean: Makefile-$(notdir $(1))
	@$$(MAKE) -f Makefile-$(notdir $(1)) distclean
	@$$(RM) Makefile-$(notdir $(1))
endef

$(foreach pro,$(PROS),$(eval $(call PRO_template,$(pro))))
