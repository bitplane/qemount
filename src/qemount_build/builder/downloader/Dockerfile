FROM python:3.12-alpine

RUN apk add --no-cache git

COPY --chmod=755 download.py /usr/local/bin/download.py
ENTRYPOINT ["python3", "/usr/local/bin/download.py"]
