#ifndef DRAGONFLY_LINUX_HOST_ELF_H
#define DRAGONFLY_LINUX_HOST_ELF_H

#include <elf.h>

typedef Elf64_Ehdr Elf_Ehdr;
typedef Elf64_Half Elf_Half;
typedef Elf64_Off Elf_Off;
typedef Elf64_Shdr Elf_Shdr;
typedef Elf64_Xword Elf_Size;
typedef Elf64_Sym Elf_Sym;

#define IS_ELF(header) \
    ((header).e_ident[EI_MAG0] == ELFMAG0 \
        && (header).e_ident[EI_MAG1] == ELFMAG1 \
        && (header).e_ident[EI_MAG2] == ELFMAG2 \
        && (header).e_ident[EI_MAG3] == ELFMAG3)

#endif
