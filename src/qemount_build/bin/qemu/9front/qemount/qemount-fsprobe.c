#include <u.h>
#include <libc.h>

enum {
	Dirsize = 16,
	V6inodesize = 32,
	Vinodesize = 64,
};

static ushort
get16(uchar *p)
{
	return p[0] | p[1]<<8;
}

static ulong
get24(uchar *p)
{
	return p[0] | p[1]<<8 | p[2]<<16;
}

static ulong
get32(uchar *p)
{
	return p[0] | p[1]<<8 | p[2]<<16 | (ulong)p[3]<<24;
}

static int
readat(int fd, void *buf, long count, vlong offset)
{
	if(seek(fd, offset, 0) != offset)
		return -1;
	return readn(fd, buf, count) == count ? 0 : -1;
}

static int
rootentries(int fd, vlong length, ulong block, ulong blocksize, ushort root)
{
	uchar entries[2*Dirsize];
	vlong offset;

	if(block < 2 || block >= length/blocksize)
		return 0;
	offset = (vlong)block*blocksize;
	if(offset > length-sizeof entries)
		return 0;
	if(readat(fd, entries, sizeof entries, offset) < 0)
		return 0;
	return get16(entries) == root
		&& entries[2] == '.' && entries[3] == 0
		&& get16(entries+Dirsize) == root
		&& entries[Dirsize+2] == '.'
		&& entries[Dirsize+3] == '.'
		&& entries[Dirsize+4] == 0;
}

static int
isv6(int fd, vlong length)
{
	uchar inode[V6inodesize];
	ulong size, block;
	ushort mode;

	if(readat(fd, inode, sizeof inode, 2*512) < 0)
		return 0;
	mode = get16(inode);
	size = inode[5]<<16 | get16(inode+6);
	block = get16(inode+8);
	return (mode & 0160000) == 0140000
		&& size >= 2*Dirsize && size%Dirsize == 0
		&& size <= length
		&& rootentries(fd, length, block, 512, 1);
}

static int
isv(int fd, vlong length, ulong blocksize)
{
	uchar inode[Vinodesize];
	ulong size, block;
	vlong offset;
	ushort mode;

	offset = 2*(vlong)blocksize + Vinodesize;
	if(readat(fd, inode, sizeof inode, offset) < 0)
		return 0;
	mode = get16(inode);
	size = get32(inode+8);
	block = get24(inode+12);
	return (mode & 0160000) == 0040000
		&& size >= 2*Dirsize && size%Dirsize == 0
		&& size <= length
		&& rootentries(fd, length, block, blocksize, 2);
}

void
main(int argc, char **argv)
{
	Dir *dir;
	int fd, v6, v32, v10;

	if(argc != 2){
		fprint(2, "usage: %s file\n", argv0);
		exits("usage");
	}
	if((fd = open(argv[1], OREAD)) < 0)
		sysfatal("open: %r");
	if((dir = dirfstat(fd)) == nil)
		sysfatal("stat: %r");
	v6 = isv6(fd, dir->length);
	v32 = isv(fd, dir->length, 512);
	v10 = isv(fd, dir->length, 4096);
	free(dir);
	close(fd);

	if(v6+v32+v10 != 1)
		exits("unknown or ambiguous");
	if(v6)
		print("v6\n");
	else if(v32)
		print("32v\n");
	else
		print("v10\n");
	exits(nil);
}
