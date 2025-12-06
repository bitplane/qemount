FROM alpine:latest

# Copy the run script
COPY run.sh /outputs/run-netbsd.sh
RUN chmod +x /outputs/run-netbsd.sh

ENTRYPOINT ["/bin/sh", "-c", "cp /outputs/run-netbsd.sh /host/build/$1"]
