#ifndef DRAGONFLY_LINUX_HOST_ELF32_H
#define DRAGONFLY_LINUX_HOST_ELF32_H

#include <elf.h>

#define IS_ELF(header) \
    ((header).e_ident[EI_MAG0] == ELFMAG0 \
        && (header).e_ident[EI_MAG1] == ELFMAG1 \
        && (header).e_ident[EI_MAG2] == ELFMAG2 \
        && (header).e_ident[EI_MAG3] == ELFMAG3)

#endif
