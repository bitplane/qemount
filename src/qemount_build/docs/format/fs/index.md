---
title: Filesystems
priority: 250
---

# Filesystems

* 🗄️ a system for storing and organizing files.

Filesystems are traditionally a database that takes up a fixed amount of space,
written directly to a slice of a [disk](disk) called a [partition](pt). But they
can also span multiple partitions, disks, or some other abstract "volume" of
space. Originally, a filing system was just a directory where everyone would
dump their files. This got too messy, so they made special files - called
subdirectories - that were lists of other files. This was known as a
hierarchical filesystem, and the folder icon 📂 was used as a metaphor for
these sub-dirs.

Eventually we got features like user permissions, links between files, special
kinds of files and so on. Programmers have invented many, many types of
filesystem over the years, each with their own special database formats,
features, problems and a place and time in history. They've got quite complex,
too.

## Mounting

Opening a filesystem is generally done by "mounting" it. This is where you take
an existing directory and ask your computer to stick a program (called a
filesystem driver) over the top of it. When you look inside this dir, the
program generates what's inside this "mount point".

Bugs in these programs can destroy your files or crash your computer, so they
usually have to be trusted by the computer's operating system, which means you
generally need to beg for permission to use one. Plus you need the program
itself, written for your computer, and to trust it. Qemount exists to work
around two of these problems: it runs a tiny [virtual computer](guest) that's
the right sort of machine for the job, using battle-tested driver software
that is old and usually stable. But it also lets you run dangerous and unstable
ones too - without crashing your computer.

## Exotic Filesystems

Nowadays a filesystem can be almost anything anywhere, and almost anything can
be accessed as if it's a filesystem. Whether it should or not is a different
question.

Some kinds of files, like [archives](arc) of other files and folders probably
should, and so should online "cloud" storage. There's an "everything is a file"
mentality in the UNIX world that's both a blessing and a curse.

Qemount exposes you to both of these.
