FROM docker.io/python:3.11-slim

RUN pip install --no-cache-dir amitools

COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
