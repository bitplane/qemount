#ifndef QEMOUNT_DRAGONFLY_HOST_ELF_HINTS_H
#define QEMOUNT_DRAGONFLY_HOST_ELF_HINTS_H

#include <stdint.h>

struct elfhints_hdr {
	uint32_t magic;
	uint32_t version;
	uint32_t strtab;
	uint32_t strsize;
	uint32_t dirlist;
	uint32_t dirlistlen;
	uint32_t spare[26];
};

#define ELFHINTS_MAGIC 0x746e6845
#define _PATH_ELF_HINTS "/var/run/ld-elf.so.hints"

#endif
