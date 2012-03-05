#!/bin/sh -e

copy()
{
	file="$1"

	echo "copying \`${MKDIR}/${file}' file..."

	cat "${TOPDIR}/${file}" > "${MKDIR}/${file}"
}

build()
{
	mkfile="$1"

	echo "building \`${MKDIR}/${mkfile}' file..."

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
	cat << EOF

ifneq (\$(wildcard \$(DOTMKDIR)/${mkfile%.*}-local.mk),)
	include \$(DOTMKDIR)/${mkfile%.*}-local.mk
endif

EOF
	echo
	cat "${SRCDIR}/${mkfile}"
	echo
	cat "${SRCDIR}/default-tail.mk"
	cat << EOF

endif # ndef ${mkfile}
EOF

	exec 1>&9
	exec 9>&-
}

MKDIR="mk"
TOPDIR="`dirname "${0}"`"
TOPDIR="`cd "${TOPDIR}"; pwd`"
SRCDIR="${TOPDIR}/src"

if [ $# -eq 1 ]; then
	MKDIR="${1}/${MKDIR}"
fi

mkdir -p "${MKDIR}"

copy LICENSE
copy README
copy VERSION

build build.mk
build subdir.mk
build qmake.mk

echo "dotmk is now installed under the \`${MKDIR}' directory."
