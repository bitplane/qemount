# Instructions for LLMs

## Guest approach

QEMU creates some hardware. The `-m` flag, when passed to the runner script is
resolved inside the guest. `sh` mode gives us a debug shell for experimenting,
so the hardware config needs to be identical or we lose debugging capability.

## Branches are the enemy

Branches in general are our enemy. Programming special cases in, or any
divergences between guest conventions should be discussed first and heavily
documented. And they'll probably be refused. We simplify as we go without losing
functionality.

