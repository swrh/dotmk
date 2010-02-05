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
	sed -e 's/^/# /' LICENSE
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
}

MKDIR="mk"
SRCDIR="src"

cd "`dirname "${0}"`"

cleandir "${MKDIR}"

build build.mk
build subdir.mk
