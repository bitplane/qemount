FROM docker.io/library/alpine:latest

# Install tar
RUN apk add --no-cache tar

COPY . /build/

RUN chmod +x /build/build.sh

ENTRYPOINT ["/build/build.sh"]
