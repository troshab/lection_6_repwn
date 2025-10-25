
FROM debian:12-slim
RUN useradd -u 10001 -m ctf && apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY build/ /app/
RUN mkdir -p /app/lib && \
    cp /lib/x86_64-linux-gnu/libc.so.6 /app/lib/ && \
    cp /lib64/ld-linux-x86-64.so.2 /app/lib/ || true
USER 10001:10001
ENTRYPOINT ["/bin/sh","-c","/app/stage$STAGE_BIN < /dev/stdin > /dev/stdout 2>&1"]
