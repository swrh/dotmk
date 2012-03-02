ifeq ($(wildcard mk/subdir.mk),)

.DEFAULT: all
all: mk/subdir.mk
	$(MAKE) $@

%: mk/subdir.mk
	@[ "$@" = "Makefile" ] || $(MAKE) $@

mk/subdir.mk:
	../install.sh .

else

SUBDIRS=		\
			simple \
			simple-other \
			simple-more-than-one-source-file \
			no-srcs-main \
			no-srcs \
			no-srcs-any \
			pkg-config \
			overloading \
			relative-objdir \

.PHONY: distclean_mk
distclean_mk:
	$(RM) -r mk

include mk/subdir.mk

distclean: distclean_mk

endif
