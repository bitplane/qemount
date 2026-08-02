#!/bin/sh
set -eu

rm -rf \
    /.DocumentRevisions-V100 \
    /.Spotlight-V100 \
    /.TemporaryItems \
    /.Trashes \
    /.fseventsd \
    /Applications/Xcode.app \
    /Library/Documentation \
    /Library/Receipts \
    /usr/include \
    /usr/lib/zsh \
    /usr/libexec/as \
    /usr/local \
    /usr/lib/clang \
    /usr/share/aclocal \
    /usr/share/dict \
    /usr/share/doc \
    /usr/share/gtk-doc \
    /usr/share/info \
    /usr/share/man \
    /usr/share/terminfo \
    /usr/share/vim

rm -f \
    /.DS_Store \
    /bin/zsh \
    /usr/bin/bitcode_strip \
    /usr/bin/ccmake \
    /usr/bin/clang \
    /usr/bin/cmake \
    /usr/bin/cmakexbuild \
    /usr/bin/cpack \
    /usr/bin/ctest \
    /usr/bin/codesign_allocate \
    /usr/bin/cmpdylib \
    /usr/bin/curl \
    /usr/bin/dbclient \
    /usr/bin/dropbearconvert \
    /usr/bin/dropbearkey \
    /usr/bin/dyldinfo \
    /usr/bin/gnumake \
    /usr/bin/infocmp \
    /usr/bin/install_name_tool \
    /usr/bin/ld \
    /usr/bin/libtool \
    /usr/bin/lipo \
    /usr/bin/llvm-cov \
    /usr/bin/llvm-dsymutil \
    /usr/bin/llvm-dwarfdump \
    /usr/bin/llvm-nm \
    /usr/bin/llvm-objdump \
    /usr/bin/llvm-profdata \
    /usr/bin/llvm-size \
    /usr/bin/make \
    /usr/bin/nano \
    /usr/bin/ninja \
    /usr/bin/nm-classic \
    /usr/bin/nmedit \
    /usr/bin/otool-classic \
    /usr/bin/pagestuff \
    /usr/bin/redo_prebinding \
    /usr/bin/screen \
    /usr/bin/size-classic \
    /usr/bin/strings \
    /usr/bin/strip \
    /usr/bin/tic \
    /usr/bin/trace \
    /usr/bin/vim \
    /usr/bin/xz \
    /usr/lib/libLTO.dylib \
    /usr/lib/libtapi.dylib \
    /usr/libexec/DeveloperTools/codesign_allocate \
    /usr/sbin/dropbear \
    /usr/sbin/sshd \
    /usr/sbin/zic

sed -i '' \
    -e '/pd_nano/d' \
    -e '/fsck -fy/d' \
    -e '/dropbear -REBj/d' \
    -e '/^[[:space:]]*\/usr\/bin\/reset[[:space:]]*$/d' \
    /sbin/pd_env

find /System/Library/Frameworks -type d \
    \( -name Headers -o -name PrivateHeaders \) \
    -prune -exec rm -rf '{}' ';'
find /usr/lib -type f \( -name '*.a' -o -name '*.la' \) -delete

sync
du -sk /System /bin /private /sbin /usr

dd if=/dev/zero of=/private/var/qemount.zero bs=1048576 || true
rm -f /private/var/qemount.zero
sync

/sbin/mount -ur /
printf 'QEMOUNT_%s\n' PROVISIONED
