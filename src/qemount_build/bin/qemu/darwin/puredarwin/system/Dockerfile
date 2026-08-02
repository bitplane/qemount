ARG BUILDER
FROM ${BUILDER}

COPY patches-libdispatch-913 /patches-libdispatch-913
COPY patches-xnu-4570 /patches-xnu-4570
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
