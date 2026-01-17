FROM python:3.12-slim

COPY requirements.txt /build/
RUN pip install --no-cache-dir -r /build/requirements.txt

COPY compile.py /build/
COPY build.sh /build/
RUN chmod +x /build/build.sh

WORKDIR /build
ENTRYPOINT ["/build/build.sh"]
