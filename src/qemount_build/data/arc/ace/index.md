---
format: arc/ace
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/arc/basic.ace
---

# ACE Test Archive

Test archive in ACE format, built with Commandline ACE 2.6 (Marcel Lemke /
e-merge GmbH) running under Wine. The distributed ace26.exe is itself
an ACE self-extracting archive - we extract it at build time using the
acefile Python library and use the Win32 console build (ACE32.EXE).
