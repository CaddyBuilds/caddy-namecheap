# Build stage
ARG CADDY_VERSION
FROM caddy:${CADDY_VERSION}-builder AS builder

# Modules built into the image. This is the only list: the daily check reads it too.
RUN xcaddy build \
    --with github.com/caddy-dns/namecheap

# Default image: the official image with the custom-built binary
FROM caddy:${CADDY_VERSION} AS default
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
