#!/bin/sh -ex

build()
{
	mkfile="$1"

	exec 9>&1
	exec 1>"${MKDIR}/${mkfile}"

	cat << EOF
# ${mkfile}
#
EOF
	sed -e 's/^/# /' "${TOPDIR}/LICENSE"
	cat << EOF

ifndef ${mkfile}
${mkfile}=		y

EOF
	cat "${SRCDIR}/default-head.mk"
	echo
	cat "${SRCDIR}/${mkfile}"
	echo
	cat "${SRCDIR}/default-tail.mk"
	cat << EOF

endif # ndef ${mkfile}
EOF

	exec 1>&9-
}

cleandir()
{
	dir="${1}"

	find "${dir}" -mindepth 1 -maxdepth 1 -and ! -name .gitignore -print0 | xargs -0 rm -fr
	mkdir -p "${MKDIR}"
}

automakefile()
{
	makefile="Makefile"
	prog="`basename "${PWD}"`"

	exec 9>&1
	exec 1>"${makefile}"

	cat << EOF
# ${makefile}

PROGS=	${prog}

${prog}_SRCS=	\\
EOF

	tmpfile="`mktemp "/tmp/${0##*/}-$$.XXXXXX"`"
	find . -name '*.c' -or -iname '*.cpp' -or -iname '*.cxx' -or -iname '*.c++' > "${tmpfile}"
	head -n -1 < "${tmpfile}" | sed -e 's/^/\t/;s/$/ \\/'
	tail -n 1 < "${tmpfile}" | sed -e 's/^/\t/'

	for incdir in ./include; do
		[ -d "${incdir}" ] || continue
		echo "${incdir}"
	done > "${tmpfile}"

	if [ -s "${tmpfile}" ]; then
		echo
		echo "${prog}_INCDIRS=	\\"
		head -n -1 < "${tmpfile}" | sed -e 's/^/\t/;s/$/ \\/'
		tail -n 1 < "${tmpfile}" | sed -e 's/^/\t/'
	fi

	cat << EOF

include ${MKDIR}/build.mk
EOF
	exec 1>&9-

	rm -f "${tmpfile}"

	cat "${makefile}"
}

MKDIR="mk"
TOPDIR="`dirname "${0}"`"
SRCDIR="${TOPDIR}/src"

cleandir "${MKDIR}"

build build.mk
build subdir.mk

[ -f Makefile ] || automakefile
