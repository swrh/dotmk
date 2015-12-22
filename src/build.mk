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

# General functions.

# function: append_with_colon
# description: append a string to a variable separating them by a colon
# parameter 1: name of the variable to be edited
# parameter 2: string to append to the variable
define append_with_colon
	ifneq ($$($(1)),)
		$(1):=	$$($(1)):
	endif
	$(1):=		$$($(1))$(2)
endef

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

# pkg-config - C/C++ compiler
# Substitute every whitespace on "PKG_CONFIG_PATH" with colons.
pkgconfig_path:=
$(foreach dir,$(PKG_CONFIG_PATH),$(eval $(call append_with_colon,pkgconfig_path,$(dir))))
PKG_CONFIG_PATH:=	$(pkgconfig_path)

ifneq ($(DEPPKGCONFIG),)
# Use `:=' (simply expanded variables) to assign "pkg-config" settings to avoid
# multiple unnecessary execution.
pkgconfig_cflags:=	$(shell PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" pkg-config --cflags $(DEPPKGCONFIG))
CFLAGS+=		$(pkgconfig_cflags)
CXXFLAGS+=		$(pkgconfig_cflags)
pkgconfig_ldflags:=	$(shell PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" pkg-config --libs $(DEPPKGCONFIG))
LDFLAGS+=		$(pkgconfig_ldflags)
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
AR=			$(CROSS_COMPILE)ar
AWK=			awk
CC=			$(CROSS_COMPILE)gcc
CTAGS=			ctags
CXX=			$(CROSS_COMPILE)g++
INSTALL=		install
MKDEP=			mkdep
RANLIB=			$(CROSS_COMPILE)ranlib
RM=			rm -f

# Directories.
PREFIX?=		/usr/local

LINK.o=			$(CC)

# Empty goals.
.PHONY: no not empty null
no not empty null:


# misc functions

dotmk_PROGNAME=		$(notdir $(1))

dotmk_LIBNAME=		$(notdir $(if $(filter %.so,$(1)),$(patsubst %.so,%,$(1)),$(patsubst %.a,%,$(1))))
dotmk_LIBTYPE=		$(if $(filter %.a,$(1)),a,so)
dotmk_LIBFILE=		$(patsubst ./%,%,$(dir $(1)))lib$(call dotmk_LIBNAME,$(1)).$(call dotmk_LIBTYPE,$(1))

dotmk_BINSTR=		$(if $(filter p:%,$(1)),$(patsubst p:%,%,$(1)),$(patsubst l:%,%,$(1)))
dotmk_BINNAME=		$(if $(filter p:%,$(1)),$(call dotmk_PROGNAME,$(call dotmk_BINSTR,$(1))),$(call dotmk_LIBNAME,$(call dotmk_BINSTR,$(1))))


# global variables

ifneq ($(LIB),)
LIBS+=						$(LIB)
ifneq ($(SRCS),)
$(call dotmk_LIBNAME,$(LIB))_SRCS+=		$(SRCS)
endif
ifneq ($(OBJS),)
$(call dotmk_LIBNAME,$(LIB))_OBJS+=		$(OBJS)
endif
ifneq ($(DEPFILES),)
$(call dotmk_LIBNAME,$(LIB))_DEPFILES+=		$(DEPFILES)
endif
ifneq ($(CLEANFILES),)
$(call dotmk_LIBNAME,$(LIB))_CLEANFILES+=	$(CLEANFILES)
endif
endif

ifneq ($(PROG),)
PROGS+=						$(PROG)
ifneq ($(SRCS),)
$(call dotmk_PROGNAME,$(PROG))_SRCS+=		$(SRCS)
endif
ifneq ($(OBJS),)
$(call dotmk_PROGNAME,$(PROG))_OBJS+=		$(OBJS)
endif
ifneq ($(DEPFILES),)
$(call dotmk_PROGNAME,$(PROG))_DEPFILES+=	$(DEPFILES)
endif
ifneq ($(CLEANFILES),)
$(call dotmk_PROGNAME,$(PROG))_CLEANFILES+=	$(CLEANFILES)
endif
endif

ifneq ($(DISABLE_TARGET),)
DISABLE_TARGETS+=				$(DISABLE_TARGET)
endif


# binaries

define BIN_template
$(call dotmk_BINNAME,$(1))_LINKER=	$(CC)

ifneq ($(OBJDIR),)
$(call dotmk_BINNAME,$(1))_OBJPREFIX=	$(OBJDIR)/
endif

ifneq ($($(call dotmk_BINNAME,$(1))_DEPPKGCONFIG),)
# Use `:=' (simply expanded variables) to assign "pkg-config" settings to avoid
# multiple unnecessary execution.
$(call dotmk_BINNAME,$(1))_pkgconfig_cflags:=	$$(shell PKG_CONFIG_PATH="$$(PKG_CONFIG_PATH)" pkg-config --cflags $($(call dotmk_BINNAME,$(1))_DEPPKGCONFIG))
$(call dotmk_BINNAME,$(1))_CFLAGS+=	$$($(call dotmk_BINNAME,$(1))_pkgconfig_cflags)
$(call dotmk_BINNAME,$(1))_CXXFLAGS+=	$$($(call dotmk_BINNAME,$(1))_pkgconfig_cflags)
$(call dotmk_BINNAME,$(1))_pkgconfig_ldflags:=	$$(shell PKG_CONFIG_PATH="$$(PKG_CONFIG_PATH)" pkg-config --libs $($(call dotmk_BINNAME,$(1))_DEPPKGCONFIG))
$(call dotmk_BINNAME,$(1))_LDFLAGS+=	$$($(call dotmk_BINNAME,$(1))_pkgconfig_ldflags)
endif

MKDEPARGS+=		$$($(call dotmk_BINNAME,$(1))_CXXFLAGS)

define BIN_SRC_template

# Read ".depend" file to append dependencies to each object target.
ifneq ($(wildcard .depend),)
	# Using $(MAKE) to read file dependencies is VEEEEEEEEEEERY slow. Please use $(AWK).
	#$$(1)_depend=	$$$$(shell OBJ="$$(notdir $$$$(patsubst %.cpp,%.o,$$$$(1)))"; echo -e ".PHONY: $$$$$$$${OBJ}\\n$$$$$$$${OBJ}:\\n\\t@echo $$$$$$$$^\\n" | make -f - -f .depend)
	# Faster, but less compatible.
	$$(1)_depend=	$$$$(shell exec $(AWK) -v OBJ=$$(notdir $$(patsubst %.cpp,%.o,$$(1))) '{ if (/^[^ \t]/) obj = 0; if ($$$$$$$$1 == OBJ":") { obj = 1; $$$$$$$$1 = ""; } else if (!obj) next; if (/\\$$$$$$$$/) sub(/\\$$$$$$$$/, " "); else sub(/$$$$$$$$/, "\n"); printf("%s", $$$$$$$$0); }' .depend)
endif

ifneq ($$(1),$$(patsubst %.cpp,%.o,$$(1)))

$(call dotmk_BINNAME,$(1))_LINKER=	$(CXX)

MKDEPARGS+=		$$($$(1)_CXXFLAGS)

ifndef $$(1)_CXXFLAGS
$$(1)_CXXFLAGS+=	$$($(call dotmk_BINNAME,$(1))_CXXFLAGS) $$(CXXFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.cpp,%.o,$$(1))): $$(1) $$$$($$(1)_DEPFILES) $$$$($$(1)_depend)
	@[ -d $$$$(dir $$$$@) ] || { echo 'mkdir -p $$$$(dir $$$$@)'; mkdir -p $$$$(dir $$$$@); }
	$(CXX) $$$$($$(1)_CXXFLAGS) $$($(call dotmk_BINNAME,$(1))_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(call dotmk_BINNAME,$(1))_OBJS+=		$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.cpp,%.o,$$(1)))
$(call dotmk_BINNAME,$(1))_CLEANFILES+=	$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.cpp,%.o,$$(1)))

CXX_SRCS+=		$$(1)

else ifneq ($$(1),$$(patsubst %.S,%.o,$$(1)))

MKDEPARGS+=		$$($$(1)_CFLAGS)

ifndef $$(1)_CFLAGS
$$(1)_CFLAGS+=		$$($(call dotmk_BINNAME,$(1))_CFLAGS) $$(CFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.S,%.o,$$(1))): $$(1) $$$$($$(1)_DEPFILES) $$$$($$(1)_depend)
	@[ -d $$$$(dir $$$$@) ] || { echo 'mkdir -p $$$$(dir $$$$@)'; mkdir -p $$$$(dir $$$$@); }
	$(CC) $$$$($$(1)_CFLAGS) $$($(call dotmk_BINNAME,$(1))_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(call dotmk_BINNAME,$(1))_OBJS+=		$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.S,%.o,$$(1)))
$(call dotmk_BINNAME,$(1))_CLEANFILES+=	$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.S,%.o,$$(1)))

S_SRCS+=		$$(1)

else

MKDEPARGS+=		$$($$(1)_CFLAGS)

ifndef $$(1)_CFLAGS
$$(1)_CFLAGS+=		$$($(call dotmk_BINNAME,$(1))_CFLAGS) $$(CFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.c,%.o,$$(1))): $$(1) $$$$($$(1)_DEPFILES) $$$$($$(1)_depend)
	@[ -d $$$$(dir $$$$@) ] || { echo 'mkdir -p $$$$(dir $$$$@)'; mkdir -p $$$$(dir $$$$@); }
	$(CC) $$$$($$(1)_CFLAGS) $$($(call dotmk_BINNAME,$(1))_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(call dotmk_BINNAME,$(1))_OBJS+=		$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.c,%.o,$$(1)))
$(call dotmk_BINNAME,$(1))_CLEANFILES+=	$$($(call dotmk_BINNAME,$(1))_OBJPREFIX)$$(subst /,_,$$(patsubst %.c,%.o,$$(1)))

C_SRCS+=		$$(1)

endif

_$$(1)=			x

endef

ifndef $(call dotmk_BINNAME,$(1))_SRCS
ifneq ($(wildcard $(call dotmk_BINNAME,$(1)).cpp),)
$(call dotmk_BINNAME,$(1))_SRCS=	$(call dotmk_BINNAME,$(1)).cpp
else ifneq ($(wildcard $(call dotmk_BINNAME,$(1)).c),)
$(call dotmk_BINNAME,$(1))_SRCS=	$(call dotmk_BINNAME,$(1)).c
else ifneq ($(wildcard $(call dotmk_BINNAME,$(1)).S),)
$(call dotmk_BINNAME,$(1))_SRCS=	$(call dotmk_BINNAME,$(1)).S
else ifneq ($(wildcard main.cpp),)
$(call dotmk_BINNAME,$(1))_SRCS=	main.cpp
else ifneq ($(wildcard main.c),)
$(call dotmk_BINNAME,$(1))_SRCS=	main.c
else ifneq ($(wildcard main.S),)
$(call dotmk_BINNAME,$(1))_SRCS=	main.S
endif
endif

$$(foreach src,$$($(call dotmk_BINNAME,$(1))_SRCS),$$(eval $$(call BIN_SRC_template,$$(src))))

MKDEPARGS+=		$$($(call dotmk_BINNAME,$(1))_INCDIRS:%=-I%)
CTAGSARGS+=		$$($(call dotmk_BINNAME,$(1))_INCDIRS)

endef

$(foreach bin,$(addprefix l:,$(LIBS)) $(addprefix p:,$(PROGS)),$(eval $(call BIN_template,$(bin))))

MKDEPARGS+=		$(INCDIRS:%=-I%)
CTAGSARGS+=		$(INCDIRS)

# libraries

define LIB_template

ifeq ($$($(call dotmk_LIBNAME,$(1))_INSTDIR),)
$(call dotmk_LIBNAME,$(1))_INSTDIR=		$(if $(INSTDIR),$(INSTDIR),$(PREFIX)/lib)
endif

ifeq ($$(subst -rpath,,$$($(call dotmk_LIBNAME,$(1))_LDFLAGS) $$(LDFLAGS)),$$($(call dotmk_LIBNAME,$(1))_LDFLAGS) $$(LDFLAGS))
$(call dotmk_LIBNAME,$(1))_LDFLAGS+=		-Wl,-rpath,$$($(call dotmk_LIBNAME,$(1))_INSTDIR)
endif

DEFAULT_TARGETS+=	$(call dotmk_LIBFILE,$(1))
ifeq ($(call dotmk_LIBTYPE,$(1)),a)
$(call dotmk_LIBFILE,$(1)): $$($(call dotmk_LIBNAME,$(1))_OBJS) $$($(call dotmk_LIBNAME,$(1))_DEPFILES)
	@[ -d $$(dir $$@) ] || { echo 'mkdir -p $$(dir $$@)'; mkdir -p $$(dir $$@); }
	$(AR) $(ARFLAGS) $(call dotmk_LIBFILE,$(1)) $$($(call dotmk_LIBNAME,$(1))_OBJS)
else
$(call dotmk_LIBFILE,$(1)): $$($(call dotmk_LIBNAME,$(1))_OBJS) $$($(call dotmk_LIBNAME,$(1))_DEPFILES)
	@[ -d $$(dir $$@) ] || { echo 'mkdir -p $$(dir $$@)'; mkdir -p $$(dir $$@); }
	$$($(call dotmk_LIBNAME,$(1))_LINKER) $$($(call dotmk_LIBNAME,$(1))_OBJS) $$($(call dotmk_LIBNAME,$(1))_LIBDIRS:%=-L%) $$(foreach lib,$$($(call dotmk_LIBNAME,$(1))_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) -shared $$($(call dotmk_LIBNAME,$(1))_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@
endif

$(call dotmk_LIBNAME,$(1)): $(call dotmk_LIBFILE,$(1))

CLEAN_TARGETS+=		$(call dotmk_LIBNAME,$(1))_clean
$(call dotmk_LIBNAME,$(1))_clean:
	$(RM) $(call dotmk_LIBFILE,$(1)) $$($(call dotmk_LIBNAME,$(1))_CLEANFILES)

INSTALL_TARGETS+=	$(call dotmk_LIBNAME,$(1))_install
$(call dotmk_LIBNAME,$(1))_install: $(call dotmk_LIBFILE,$(1))
	$(INSTALL) -c -D $(call dotmk_LIBFILE,$(1)) $$($(call dotmk_LIBNAME,$(1))_INSTDIR)/$$(notdir $(call dotmk_LIBFILE,$(1)))

UNINSTALL_TARGETS+=	$(call dotmk_LIBNAME,$(1))_uninstall
$(call dotmk_LIBNAME,$(1))_uninstall:
	$(RM) $$($(call dotmk_LIBNAME,$(1))_INSTDIR)/$$(notdir $(call dotmk_LIBFILE,$(1)))
endef

$(foreach lib,$(LIBS),$(eval $(call LIB_template,$(lib))))


# programs

define PROG_template
ifeq ($$($(notdir $(1))_INSTDIR),)
$(notdir $(1))_INSTDIR=		$(if $(INSTDIR),$(INSTDIR),$(PREFIX)/bin)
endif

DEFAULT_TARGETS+=	$(1)
$(1): $$($(notdir $(1))_OBJS) $$($(notdir $(1))_DEPFILES)
	@[ -d $$(dir $$@) ] || { echo 'mkdir -p $$(dir $$@)'; mkdir -p $$(dir $$@); }
	$$($(notdir $(1))_LINKER) $$($(notdir $(1))_OBJS) $$($(notdir $(1))_LIBDIRS:%=-L%) $$(foreach lib,$$($(notdir $(1))_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(notdir $(1))_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@

CLEAN_TARGETS+=	$(notdir $(1))_clean
$(notdir $(1))_clean:
	$(RM) $(1) $$($(notdir $(1))_CLEANFILES)

INSTALL_TARGETS+=	$(notdir $(1))_install
$(notdir $(1))_install: $(1)
	$(INSTALL) -c -D $(1) $$($(notdir $(1))_INSTDIR)/$$(notdir $(1))

UNINSTALL_TARGETS+=	$(notdir $(1))_uninstall
$(notdir $(1))_uninstall:
	$(RM) $$($(notdir $(1))_INSTDIR)/$$(notdir $(1))
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

ifneq ($(DISTCLEANFILES),)
DISTCLEAN_TARGETS+=	dotmk_distclean
.PHONY: dotmk_distclean
dotmk_distclean:
	$(RM) -r $(DISTCLEANFILES)
endif

.PHONY: tags
tags:
	$(CTAGS) -R $(CTAGSARGS) $(C_SRCS) $(CXX_SRCS)
