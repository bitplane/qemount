---
title: Archive Files
type: category
path: arc
---

# Archives

* 📦 a file containing other things for storage

Archives are files that contain other files and dirs, or just blobs of data, and
are all about bundling stuff together.

They're mostly organized for storage rather than not modification. Some are for
fast access, some long time archival - but almost none for ease of editing.
Many are compressed in a way that saves space, but are difficult to read without
knowing how they were compressed. Some are encrypted so you need a key to read
the contents. Some don't want the likes of you opening them.

Like [filesystems](fs), there's lots of types of archive, some of which even
have a good reason to exist. Others are on more shaky grounds.

Unlike filesystem drivers, you don't need administrator permission to use an
archival program to zip up your files, but you might need permission from the
copyright holder of the program decades later, the program might not exist any
more, it might not run on your computer either.

Qemount makes it possible to access a wide range of archive formats that
(apparently) nobody has ever heard of. They aren't filesystems, so don't
expect efficient write access, if you can even write to them in the first place.
