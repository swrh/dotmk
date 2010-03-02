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
LIBS+=				$(LIB)
$(notdir $(LIB))_SRCS+=		$(SRCS)
$(notdir $(LIB))_OBJS+=		$(OBJS)
endif

ifdef PROG
PROGS+=				$(PROG)
$(notdir $(PROG))_SRCS+=	$(SRCS)
$(notdir $(PROG))_OBJS+=	$(OBJS)
endif


# binaries

define BIN_template
$(notdir $(1))_LINK=		$(CC)

ifneq ($(OBJDIR),)
$(notdir $(1))_OBJPREFIX=		$(OBJDIR)/
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

$(notdir $(1))_LINK=		$(CXX)

ifndef $$(1)_CXXFLAGS
$$(1)_CXXFLAGS+=	$$($(notdir $(1))_CXXFLAGS) $$(CXXFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(notdir $(1))_OBJPREFIX)$$(patsubst %.cpp,%.lo,$$(1)): $$(1) $$$$($$(1)_DEPS) $$$$($$(1)_depend)
	[ -d $$$$(dir $$$$@) ] || mkdir -pv $$$$(dir $$$$@)
	$(LIBTOOL) --mode=compile $(CXX) $$$$($$(1)_CXXFLAGS) $$($(notdir $(1))_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(notdir $(1))_OBJS+=		$$($(notdir $(1))_OBJPREFIX)$$(patsubst %.cpp,%.lo,$$(1))
$(notdir $(1))_CLEANFILES+=	$$($(notdir $(1))_OBJPREFIX)$$(patsubst %.cpp,%.lo,$$(1))

CXX_SRCS+=		$$(1)

else

ifndef $$(1)_CFLAGS
$$(1)_CFLAGS+=		$$($(notdir $(1))_CFLAGS) $$(CFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(notdir $(1))_OBJPREFIX)$$(patsubst %.c,%.lo,$$(1)): $$(1) $$$$($$(1)_DEPS) $$$$($$(1)_depend)
	@[ -d $$$$(dir $$$$@) ] || { echo 'mkdir -pv $$$$(dir $$$$@)'; mkdir -pv $$$$(dir $$$$@); }
	$(LIBTOOL) --mode=compile $(CC) $$$$($$(1)_CFLAGS) $$($(notdir $(1))_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(notdir $(1))_OBJS+=		$$($(notdir $(1))_OBJPREFIX)$$(patsubst %.c,%.lo,$$(1))
$(notdir $(1))_CLEANFILES+=	$$($(notdir $(1))_OBJPREFIX)$$(patsubst %.c,%.lo,$$(1))

C_SRCS+=		$$(1)

endif

_$$(1)=			x

endef

ifndef $(1)_SRCS
ifneq ($(wildcard $(1).cpp),)
$(1)_SRCS=		$(1).cpp
else
$(1)_SRCS=		$(1).c
endif
endif

$$(foreach src,$$($(notdir $(1))_SRCS),$$(eval $$(call BIN_SRC_template,$$(src))))

MKDEPARGS+=		$$($(notdir $(1))_INCDIRS:%=-I%)
CTAGSARGS+=		$$($(notdir $(1))_INCDIRS)

endef

$(foreach bin,$(LIBS) $(PROGS),$(eval $(call BIN_template,$(bin))))

MKDEPARGS+=		$(INCDIRS:%=-I%)
CTAGSARGS+=		$(INCDIRS)

# libraries

define LIB_template
ifeq ($$(dir $(1)),./)
$(notdir $(1))_LIBFILE:=		lib$$(notdir $(1)).la
else
$(notdir $(1))_LIBFILE:=		$$(dir $(1))lib$$(notdir $(1)).la
endif

ifeq ($$($(notdir $(1))_INSTDIR),)
$(notdir $(1))_INSTDIR=		$(if $(INSTDIR),$(INSTDIR),$(PREFIX)/lib)
endif

ifeq ($$(subst -rpath,,$$($(notdir $(1))_LDFLAGS) $$(LDFLAGS)),$$($(notdir $(1))_LDFLAGS) $$(LDFLAGS))
$(notdir $(1))_LDFLAGS+=		-rpath $$($(notdir $(1))_INSTDIR)
endif

DEFAULT_TARGETS+=	$$($(notdir $(1))_LIBFILE)
$$($(notdir $(1))_LIBFILE): $$($(notdir $(1))_OBJS)
	[ -d $$(dir $$@) ] || mkdir -pv $$(dir $$@)
	$(LIBTOOL) --mode=link $$($(notdir $(1))_LINK) $$^ $$($(notdir $(1))_LIBDIRS:%=-L%) $$(foreach lib,$$($(notdir $(1))_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(notdir $(1))_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@

$(1): $$($(notdir $(1))_LIBFILE)

CLEAN_TARGETS+=		$(notdir $(1))_clean
$(notdir $(1))_clean:
	$(LIBTOOL) --mode=clean $(RM) $$($(notdir $(1))_LIBFILE) $$($(notdir $(1))_CLEANFILES)

INSTALL_TARGETS+=	$(notdir $(1))_install
$(notdir $(1))_install: $$($(notdir $(1))_LIBFILE)
	$(LIBTOOL) --mode=install $(INSTALL) -c -D $$($(notdir $(1))_LIBFILE) $$($(notdir $(1))_INSTDIR)/$$(notdir $$($(notdir $(1))_LIBFILE))

UNINSTALL_TARGETS+=	$(notdir $(1))_uninstall
$(notdir $(1))_uninstall:
	$(LIBTOOL) --mode=uninstall $(RM) $$($(notdir $(1))_INSTDIR)/$$(notdir $$($(notdir $(1))_LIBFILE))
endef

$(foreach lib,$(LIBS),$(eval $(call LIB_template,$(lib))))


# programs

define PROG_template
ifeq ($$($(notdir $(1))_INSTDIR),)
$(notdir $(1))_INSTDIR=		$(if $(INSTDIR),$(INSTDIR),$(PREFIX)/bin)
endif

DEFAULT_TARGETS+=	$(1)
$(1): $$($(notdir $(1))_OBJS)
	@[ -d $$(dir $$@) ] || { echo 'mkdir -pv $$(dir $$@)'; mkdir -pv $$(dir $$@); }
	$(LIBTOOL) --mode=link $$($(notdir $(1))_LINK) $$^ $$($(notdir $(1))_LIBDIRS:%=-L%) $$(foreach lib,$$($(notdir $(1))_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(notdir $(1))_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@

CLEAN_TARGETS+=	$(notdir $(1))_clean
$(notdir $(1))_clean:
	$(LIBTOOL) --mode=clean $(RM) $(1) $$($(notdir $(1))_CLEANFILES)

INSTALL_TARGETS+=	$(notdir $(1))_install
$(notdir $(1))_install:
	$(LIBTOOL) --mode=install $(INSTALL) -c -D $(1) $$($(notdir $(1))_INSTDIR)/$$(notdir $(1))

UNINSTALL_TARGETS+=	$(notdir $(1))_uninstall
$(notdir $(1))_uninstall:
	$(LIBTOOL) --mode=uninstall $(RM) $$($(notdir $(1))_INSTDIR)/$$(notdir $(1))
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

DISTCLEAN_TARGETS+=	$(CLEAN_TARGETS)

DISTCLEAN_TARGETS+=	dep_distclean
.PHONY: dep_distclean
dep_distclean:
	$(RM) .depend

ifdef DISTCLEANFILES
DISTCLEAN_TARGETS+=	files_distclean
.PHONY: files_distclean
files_distclean:
	$(RM) -r $(DISTCLEANFILES)
endif

.PHONY: tags
tags:
	$(CTAGS) -R $(CTAGSARGS) $(C_SRCS) $(CXX_SRCS)
