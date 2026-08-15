#ifndef DRAGONFLY_LINUX_HOST_AOUT_H
#define DRAGONFLY_LINUX_HOST_AOUT_H

#include <stdint.h>

#define OMAGIC 0407
#define NMAGIC 0410
#define ZMAGIC 0413
#define QMAGIC 0314
#define MID_ZERO 0
#define DRAGONFLY_LDPGSZ 4096

struct exec {
    uint32_t a_midmag;
    uint32_t a_text;
    uint32_t a_data;
    uint32_t a_bss;
    uint32_t a_syms;
    uint32_t a_entry;
    uint32_t a_trsize;
    uint32_t a_drsize;
};

#define N_GETMAGIC(header) ((header).a_midmag & 0xffff)
#define N_SETMAGIC(header, magic, machine, flags) \
    ((header).a_midmag = (((flags) & 0x3f) << 26) \
        | (((machine) & 0x03ff) << 16) | ((magic) & 0xffff))
#define N_ALIGN(header, value) \
    (N_GETMAGIC(header) == ZMAGIC || N_GETMAGIC(header) == QMAGIC \
        ? ((value) + DRAGONFLY_LDPGSZ - 1) \
            & ~(unsigned long)(DRAGONFLY_LDPGSZ - 1) \
        : (value))
#define N_BADMAG(header) \
    (N_GETMAGIC(header) != OMAGIC && N_GETMAGIC(header) != NMAGIC \
        && N_GETMAGIC(header) != ZMAGIC && N_GETMAGIC(header) != QMAGIC)

#endif
