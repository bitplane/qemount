#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

# Build a minimal RPM with the template files
mkdir -p /tmp/rpmbuild/BUILD /tmp/rpmbuild/RPMS /tmp/rpmbuild/SOURCES \
         /tmp/rpmbuild/SPECS /tmp/rpmbuild/SRPMS /tmp/rpmbuild/BUILDROOT

cat > /tmp/rpmbuild/SPECS/basic.spec << 'SPEC'
Name: basic
Version: 1.0
Release: 1
Summary: Test package
License: Public Domain
BuildArch: noarch

%description
Test RPM for format detection.

%install
cp -a /tmp/template/* %{buildroot}/

%files
/*
SPEC

rpmbuild --define "_topdir /tmp/rpmbuild" \
         --buildroot /tmp/rpmbuild/BUILDROOT \
         -bb /tmp/rpmbuild/SPECS/basic.spec

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/rpmbuild/RPMS/noarch/*.rpm "/host/build/$OUTPUT_PATH"
