ifdef DEBUG
	ifeq ($(DEBUG),)
		dotmk_DEBUG=n
	else ifeq ($(DEBUG),n)
		dotmk_DEBUG=n
	else ifeq ($(DEBUG),no)
		dotmk_DEBUG=n
	else ifeq ($(DEBUG),N)
		dotmk_DEBUG=n
	else ifeq ($(DEBUG),NO)
		dotmk_DEBUG=n
	else
		dotmk_DEBUG=y
	endif
else
	dotmk_DEBUG=n
endif

# C compiler.
CFLAGS+=		-Wall -Wunused
ifeq ($(dotmk_DEBUG),y)
CFLAGS+=		-O0 -ggdb3 -DDEBUG
else
CFLAGS+=		-O2 -DNDEBUG
endif

# C++ compiler.
CXXFLAGS+=		-Wall -Wunused
ifeq ($(dotmk_DEBUG),y)
CXXFLAGS+=		-O0 -ggdb3 -DDEBUG
else
CXXFLAGS+=		-O2 -DNDEBUG
endif

# Linker.
#ifeq ($(dotmk_DEBUG),y)
#LDFLAGS+=		
#else
#LDFLAGS+=		
#endif

# Archiver.
ARFLAGS=		rcs

# Commands.
AR=			ar
AWK=			awk
CC=			gcc
CP=			cp
CTAGS=			ctags
CXX=			g++
INSTALL=		install
LIBTOOL=		libtool
MKDEP=			mkdep
MKDIR=			mkdir
RM=			rm -f
TEST=			test
TOUCH=			touch
WGET=			wget

# Directories.
PREFIX=			/usr/local

LINK.o=			$(LIBTOOL) $(CC)
LINK.lo=		$(LIBTOOL) $(CC)

# Empty goals.
.PHONY: no not empty null
no not empty null:


# global variables

ifdef LIB
LIBS+=			$(LIB)
$(LIB)_SRCS+=		$(SRCS)
$(LIB)_OBJS+=		$(OBJS)
endif

ifdef PROG
PROGS+=			$(PROG)
$(PROG)_SRCS+=		$(SRCS)
$(PROG)_OBJS+=		$(OBJS)
endif


# binaries

define BIN_template
$(1)_LINK=		$(CC)

ifneq ($(OBJDIR),)
$(1)_OBJPREFIX=		$(OBJDIR)/
endif

define BIN_SRC_template

# Read ".depend" file to append dependencies to each object target.
ifneq ($(wildcard .depend),)
	# Using $(MAKE) to read file dependencies is VEEEEEEEEEEERY slow. Please use $(AWK).
	#$$(1)_depend=	$$$$(shell OBJ="$$(notdir $$$$(patsubst %.cpp,%.o,$$$$(1)))"; echo -e ".PHONY: $$$$$$$${OBJ}\\n$$$$$$$${OBJ}:\\n\\t@echo $$$$$$$$^\\n" | make -f - -f .depend)
	# Faster, but less compatible.
	$$(1)_depend=	$$$$(shell exec $(AWK) -v OBJ=$$(notdir $$(patsubst %.cpp,%.o,$$(1))) '{ if (/^[^ \t]/) obj = 0; if ($$$$$$$$1 == OBJ":") { obj = 1; $$$$$$$$1 = ""; } else if (!obj) next; if (/\\$$$$$$$$/) sub(/\\$$$$$$$$/, " "); else sub(/$$$$$$$$/, "\n"); printf("%s", $$$$$$$$0); }' .depend)
endif

ifneq ($$(1),$$(patsubst %.cpp,%.lo,$$(1)))

$(1)_LINK=		$(CXX)

ifndef $$(1)_CXXFLAGS
$$(1)_CXXFLAGS+=	$$($(1)_CXXFLAGS) $$(CXXFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(1)_OBJPREFIX)$$(patsubst %.cpp,%.lo,$$(1)): $$(1) $$$$($$(1)_DEPS) $$$$($$(1)_depend)
	[ -d '$(dir $@)' ] || mkdir -pv '$(dir $@)'
	$(LIBTOOL) --mode=compile $(CXX) $$$$($$(1)_CXXFLAGS) $$($(1)_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(1)_OBJS+=		$$($(1)_OBJPREFIX)$$(patsubst %.cpp,%.lo,$$(1))
$(1)_CLEANFILES+=	$$($(1)_OBJPREFIX)$$(patsubst %.cpp,%.lo,$$(1))

CXX_SRCS+=		$$(1)

else

ifndef $$(1)_CFLAGS
$$(1)_CFLAGS+=		$$($(1)_CFLAGS) $$(CFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(1)_OBJPREFIX)$$(patsubst %.c,%.lo,$$(1)): $$(1) $$$$($$(1)_DEPS) $$$$($$(1)_depend)
	[ -d '$(dir $@)' ] || mkdir -pv '$(dir $@)'
	$(LIBTOOL) --mode=compile $(CC) $$$$($$(1)_CFLAGS) $$($(1)_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(1)_OBJS+=		$$($(1)_OBJPREFIX)$$(patsubst %.c,%.lo,$$(1))
$(1)_CLEANFILES+=	$$($(1)_OBJPREFIX)$$(patsubst %.c,%.lo,$$(1))

C_SRCS+=		$$(1)

endif

_$$(1)=			x

endef

$$(foreach src,$$($(1)_SRCS),$$(eval $$(call BIN_SRC_template,$$(src))))

MKDEPARGS+=		$$($(1)_INCDIRS:%=-I%)
CTAGSARGS+=		$$($(1)_INCDIRS)

endef

$(foreach bin,$(LIBS) $(PROGS),$(eval $(call BIN_template,$(bin))))

MKDEPARGS+=		$(INCDIRS:%=-I%)
CTAGSARGS+=		$(INCDIRS)

# libraries

define LIB_template
ifeq ($$(dir $(1)),./)
$(1)_LIBFILE:=		lib$$(notdir $(1)).la
else
$(1)_LIBFILE:=		$$(dir $(1))lib$$(notdir $(1)).la
endif

ifeq ($$($(1)_INSTDIR),)
$(1)_INSTDIR=		$(if $(INSTDIR),$(INSTDIR),$(PREFIX)/lib)
endif

ifeq ($$(subst -rpath,,$$($(1)_LDFLAGS) $$(LDFLAGS)),$$($(1)_LDFLAGS) $$(LDFLAGS))
$(1)_LDFLAGS+=		-rpath $$($(1)_INSTDIR)
endif

DEFAULT_TARGETS+=	$$($(1)_LIBFILE)
$$($(1)_LIBFILE): $$($(1)_OBJS)
	$(LIBTOOL) --mode=link $$($(1)_LINK) $$^ $$($(1)_LIBDIRS:%=-L%) $$(foreach lib,$$($(1)_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(1)_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@

$(1): $$($(1)_LIBFILE)

CLEAN_TARGETS+=		$(1)_clean
$(1)_clean:
	$(LIBTOOL) --mode=clean $(RM) $$($(1)_LIBFILE) $$($(1)_CLEANFILES)

INSTALL_TARGETS+=	$(1)_install
$(1)_install:
	$(LIBTOOL) --mode=install $(INSTALL) -c -D $$($(1)_LIBFILE) $$($(1)_INSTDIR)/$$(notdir $$($(1)_LIBFILE))

UNINSTALL_TARGETS+=	$(1)_uninstall
$(1)_uninstall:
	$(LIBTOOL) --mode=uninstall $(RM) $$($(1)_INSTDIR)/$$(notdir $$($(1)_LIBFILE))
endef

$(foreach lib,$(LIBS),$(eval $(call LIB_template,$(lib))))


# programs

define PROG_template
ifeq ($$($(1)_INSTDIR),)
$(1)_INSTDIR=		$(if $(INSTDIR),$(INSTDIR),$(PREFIX)/lib)
endif

DEFAULT_TARGETS+=	$(1)
$(1): $$($(1)_OBJS)
	$(LIBTOOL) --mode=link $$($(1)_LINK) $$^ $$($(1)_LIBDIRS:%=-L%) $$(foreach lib,$$($(1)_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(1)_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@

CLEAN_TARGETS+=	$(1)_clean
$(1)_clean:
	$(LIBTOOL) --mode=clean $(RM) $(1) $$($(1)_CLEANFILES)

INSTALL_TARGETS+=	$(1)_install
$(1)_install:
	$(LIBTOOL) --mode=install $(INSTALL) -c -D $(1) $$($(1)_INSTDIR)/$$(notdir $(1))

UNINSTALL_TARGETS+=	$(1)_uninstall
$(1)_uninstall:
	$(LIBTOOL) --mode=uninstall $(RM) $$($(1)_INSTDIR)/$$(notdir $(1))
endef

$(foreach prog,$(PROGS),$(eval $(call PROG_template,$(prog))))


# rules

ifneq ($(CXX_SRCS),)
MKDEPARGS+=		$(CXXFLAGS)
else ifneq ($(C_SRCS),)
MKDEPARGS+=		$(CFLAGS)
endif
MKDEPARGS+=		$(CXX_SRCS) $(C_SRCS)

.PHONY: dep
dep:
	$(MKDEP) $(MKDEPARGS)

DISTCLEAN_TARGETS+=	$(CLEAN_TARGETS) dep_distclean
.PHONY: dep_distclean
dep_distclean:
	$(RM) .depend

.PHONY: tags
tags:
	$(CTAGS) -R $(CTAGSARGS) $(C_SRCS) $(CXX_SRCS)

-include .depend
