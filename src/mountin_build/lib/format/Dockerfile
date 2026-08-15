FROM python:3.12-slim

COPY requirements.txt /build/
RUN pip install --no-cache-dir -r /build/requirements.txt

COPY compile.py /build/
COPY --chmod=755 build.sh /build/build.sh

WORKDIR /build
ENTRYPOINT ["/build/build.sh"]
