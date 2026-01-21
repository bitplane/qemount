FROM alpine:latest

RUN apk add --no-cache tar

# Copy template directories
COPY basic/ /templates/basic/

# Copy and set up build script
COPY --chmod=755 build.sh /build.sh

ENTRYPOINT ["/build.sh"]
