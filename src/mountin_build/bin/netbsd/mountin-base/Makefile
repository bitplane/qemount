NOLIBCSANITIZER=
NOSANITIZER=

.include <bsd.own.mk>
.include "${NETBSDSRCDIR}/distrib/common/Makefile.distrib"

WARNS=1
DBG+=-Os

CRUNCHGEN_FLAGS+=-V DBG="${DBG}"
CRUNCHGEN_FLAGS+=-V LDSTATIC="-static" -V NOPIE=
CRUNCHGEN_FLAGS+=-V NOLIBCSANITIZER= -V NOSANITIZER= -V NOMAN=

CRUNCHBIN=mountin-rescue
SMALLPROG=1
LISTS=${.CURDIR}/list

.include "${DISTRIBDIR}/common/Makefile.crunch"

realall: ${CRUNCHBIN}

.include <bsd.prog.mk>
