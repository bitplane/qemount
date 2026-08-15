FROM builder/disk/9front

COPY --chmod=755 mkresearchunix.py build.sh /usr/local/bin/
COPY fixture.rc /usr/local/share/mountin/research-unix/fixture.rc

ENTRYPOINT ["/usr/local/bin/build.sh"]
