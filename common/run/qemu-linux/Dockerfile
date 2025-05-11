FROM alpine:latest

# Copy the run script
COPY run.sh /outputs/run-qemu.sh
RUN chmod +x /outputs/run-qemu.sh

ENTRYPOINT ["/bin/sh", "-c", "cp /outputs/run-qemu.sh /host/build/$1"]
