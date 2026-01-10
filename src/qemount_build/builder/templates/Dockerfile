FROM docker.io/library/alpine:latest

RUN apk add --no-cache tar

# Copy template directories
COPY basic/ /templates/basic/

# Copy and set up build script
COPY build.sh /build.sh
RUN chmod +x /build.sh

ENTRYPOINT ["/build.sh"]
