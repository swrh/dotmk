ifndef DOTMKDIR
	DOTMKDIR:=		$(dir $(lastword $(MAKEFILE_LIST)))

	dotmk_tmp:=		$(shell [ ! -d $(DOTMKDIR) ] || echo $(DOTMKDIR))
	ifeq ($(dotmk_tmp),)
		dotmk_tmp:=	$(error Couldn't determine DOTMKDIR variable automatically)
	endif

	ifeq ($(findstring else-if,$(.FEATURES)),)
		dotmk_tmp:=	$(error You need a newer version of GNU make to use `dotmk')
	endif

endif

include $(wildcard $(DOTMKDIR)/mk.d/*.mk)
