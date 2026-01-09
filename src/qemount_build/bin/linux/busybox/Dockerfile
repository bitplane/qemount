ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
ADD build.sh /build.sh
ADD merge_config.py /merge_config.py
ADD busybox.config /busybox.config
RUN chmod +x /build.sh
