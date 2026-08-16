FROM python:3.12-slim

RUN pip install --no-cache-dir build==1.3.0 flit_core==3.12.0 twine==7.0.0

COPY --chmod=755 build.sh /build.sh

ENTRYPOINT ["/build.sh"]
