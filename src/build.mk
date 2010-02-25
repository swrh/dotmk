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
CFLAGS+=		-Wall -Wunused -fPIC -DPIC
ifeq ($(STRICTFLAGS),y)
CFLAGS+=		-std=gnu99 -Werror -Wshadow
endif
ifeq ($(dotmk_DEBUG),y)
CFLAGS+=		-O0 -ggdb3 -DDEBUG
else
CFLAGS+=		-O2 -DNDEBUG
endif

# C++ compiler.
CXXFLAGS+=		-Wall -Wunused -fPIC -DPIC
ifeq ($(STRICTFLAGS),y)
CXXFLAGS+=		-Werror -Wshadow
endif
ifeq ($(dotmk_DEBUG),y)
CXXFLAGS+=		-O0 -ggdb3 -DDEBUG
else
CXXFLAGS+=		-O2 -DNDEBUG
endif

# Linker.
ifeq ($(dotmk_DEBUG),y)
LDFLAGS+=		
else
LDFLAGS+=		
endif

# Archiver.
ARFLAGS=		rcs

# Commands.
AR=			ar
AWK=			awk
ifeq ($(CC),)
CC=			gcc
endif
CP=			cp
CTAGS=			ctags
ifeq ($(CXX),)
CXX=			g++
endif
INSTALL=		install
MKDEP=			mkdep
MKDIR=			mkdir
RM=			rm -f
TEST=			test
TOUCH=			touch
WGET=			wget

LINK.o=			$(CC)

# Empty goals.
.PHONY: no not empty null
no not empty null:

# override some global rules definitions
%.c: %.y
	yacc -d -o $@ $^
%.c: %.l
	lex -o $@ $^


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

define BIN_SRC_template

# Read ".depend" file to append dependencies to each object target.
ifneq ($(wildcard .depend),)
	# Using $(MAKE) to read file dependencies is VEEEEEEEEEEERY slow. Please use $(AWK).
	#$$(1)_depend=	$$$$(shell OBJ="$$(notdir $$$$(patsubst %.cpp,%.o,$$$$(1)))"; echo -e ".PHONY: $$$$$$$${OBJ}\\n$$$$$$$${OBJ}:\\n\\t@echo $$$$$$$$^\\n" | make -f - -f .depend)
	# Faster, but less compatible.
	$$(1)_depend=	$$$$(shell exec $(AWK) -v OBJ=$$(notdir $$(patsubst %.cpp,%.o,$$(1))) '{ if (/^[^ \t]/) obj = 0; if ($$$$$$$$1 == OBJ":") { obj = 1; $$$$$$$$1 = ""; } else if (!obj) next; if (/\\$$$$$$$$/) sub(/\\$$$$$$$$/, " "); else sub(/$$$$$$$$/, "\n"); printf("%s", $$$$$$$$0); }' .depend)
endif

ifneq ($$(1),$$(patsubst %.cpp,%.o,$$(1)))

$(1)_LINK=		$(CXX)

ifndef $$(1)_CXXFLAGS
$$(1)_CXXFLAGS+=	$$($(1)_CXXFLAGS) $$(CXXFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$(patsubst %.cpp,%.o,$$(1)): $$(1) $$$$($$(1)_DEPS) $$$$($$(1)_depend)
	$(CXX) $$$$($$(1)_CXXFLAGS) $$($(1)_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(1)_OBJS+=		$$(patsubst %.cpp,%.o,$$(1))
$(1)_CLEANFILES+=	$$(patsubst %.cpp,%.o,$$(1))

CXX_SRCS+=		$$(1)

else

ifndef $$(1)_CFLAGS
$$(1)_CFLAGS+=		$$($(1)_CFLAGS) $$(CFLAGS)
endif

# avoid defining a target more than one time
ifneq ($$$$(_$$(1)),x)
$$(patsubst %.c,%.o,$$(1)): $$(1) $$$$($$(1)_DEPS) $$$$($$(1)_depend)
	$(CC) $$$$($$(1)_CFLAGS) $$($(1)_INCDIRS:%=-I%) $$(INCDIRS:%=-I%) -c -o $$$$@ $$$$<
endif

$(1)_OBJS+=		$$(patsubst %.c,%.o,$$(1))
$(1)_CLEANFILES+=	$$(patsubst %.c,%.o,$$(1))

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
ifndef $(1)_LDFLAGS
$(1)_LDFLAGS+=		$$(LDFLAGS)
endif

# 20091214 flag: _STLIB defines if a static version of the library should be built
ifneq ($$($(1)_STLIB),n)
DEFAULT_TARGETS+=	lib$(1).a
STLIBS+=		lib$(1).a
endif
lib$(1).a: $$($(1)_OBJS)
	$(AR) $(ARFLAGS) $$@ $$^

# 20091214 flag: _SHLIB defines if a shared version of the library should be built
ifneq ($$($(1)_SHLIB),n)
DEFAULT_TARGETS+=	lib$(1).so
SHLIBS+=		lib$(1).so
endif

lib$(1).so: $$($(1)_OBJS)
	$$($(1)_LINK) $$^ $$($(1)_LIBDIRS:%=-L%) $$(foreach lib,$$($(1)_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(1)_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@ -shared

$(1): lib$(1).a lib$(1).so

CLEAN_TARGETS+=		$(1)_clean
$(1)_clean:
	$(RM) lib$(1).a lib$(1).so $$($(1)_CLEANFILES)
endef

$(foreach lib,$(LIBS),$(eval $(call LIB_template,$(lib))))


# programs

define PROG_template
ifndef $(1)_LDFLAGS
$(1)_LDFLAGS+=		$$(LDFLAGS)
endif

DEFAULT_TARGETS+=	$(1)
$(1): $$($(1)_OBJS)
	$$($(1)_LINK) $$^ $$($(1)_LIBDIRS:%=-L%) $$(foreach lib,$$($(1)_DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$($(1)_LDFLAGS) $$(LIBDIRS:%=-L%) $$(foreach lib,$$(DEPLIBS),$$(if $$(wildcard $$(lib)),$$(lib),-l$$(lib))) $$(LDFLAGS) $$(LDLIBS) -o $$@

CLEAN_TARGETS+=	$(1)_clean
$(1)_clean:
	$(RM) $(1) $$($(1)_CLEANFILES)
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
