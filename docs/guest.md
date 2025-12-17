---
title: Guest Operating Systems
type: category
path: guest
---

# Guest OSes

* 🖥️ a computer in your computer

A guest operating system is a computer that runs inside [QEMU](qemu), a machine
emulator, on your machine (the host). The guests have been [built](build-system)
to be as small as possible, but no smaller: to have enough features to open the
sorts of [files](disk), [filesystems](fs) and [archives](arc) that they are best
at dealing with.

Qemount works by detecting your file's type, choosing the best guest, then
attaching your file as if it's a hard drive. The guest is instructed to
[mount the filesystem](fs), and a small program running inside
[transports](transport) the data through what it believes to be an old-fashioned
serial port.

Qemount's [library](lib) sits on the other end of this virtual serial port and
passes the data to the [client](client), which allows you to access the data.

Guests contain some tools for copying data, creating filesystems and archives,
and poking about inside the files.
