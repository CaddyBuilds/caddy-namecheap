# Build stage: runs on the build host and cross-compiles for the target platform.
# Go cross-compiles natively, so the slow compile step needs no QEMU emulation.
# Caddy version to build. CI always passes the exact version; the default lets a plain
# `docker build .` build the latest Caddy 2.
ARG CADDY_VERSION=2
FROM --platform=$BUILDPLATFORM caddy:${CADDY_VERSION}-builder AS builder
ARG TARGETOS TARGETARCH TARGETVARIANT

# Modules built into the image. This is the only list: the daily check reads it too.
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} CGO_ENABLED=0 XCADDY_PRINT_VERSION=0 \
    xcaddy build \
    --with github.com/caddy-dns/namecheap

# Default image: the official image for the target platform with the custom-built binary
FROM caddy:${CADDY_VERSION} AS default
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
