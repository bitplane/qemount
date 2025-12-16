---
title: CPU Architecture
type: category
path: arch
---

# CPU Architecture

Digital computing machines, being digital, operate on 0s and 1s; the offs and
ons of digital switches. Which things they switch depends on the layout of the
computer's circuits. The machine's code, numbers that boss the circuits 
about, were decided by the architects of the system. For this reason, the set of
instruction numbers - the instruction set - of a type of Central Processing
Unit (CPU) is known as its architecture.

QEMU is a CPU emulator, it lets your computer run another computer as if
it's a program. If the computer has a different architecture, QEMU will spend a
lot of time translating and less time doing useful work.

Where possible, Qemount will try to access your files using a [guest](guest)
that can both read your data, and is the same architecture as your own computer.
This won't always be safe or possible. When it isn't, we'll trade speed for
compatibility. Sometimes, you'll get neither.

