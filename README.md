# Caddy Namecheap

[![Build](https://github.com/caddybuilds/caddy-namecheap/actions/workflows/check-caddy-release.yml/badge.svg)](https://github.com/caddybuilds/caddy-namecheap/actions/workflows/check-caddy-release.yml)
[![License: MIT](https://img.shields.io/github/license/caddybuilds/caddy-namecheap)](LICENSE)

> A fully integrated Caddy Docker image featuring Namecheap DNS-01 ACME validation

Automated, multi-platform Docker builds of [Caddy](https://caddyserver.com/) with the [Namecheap](https://www.namecheap.com/) DNS module baked in.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Included Modules](#included-modules)
- [Usage](#usage)
  - [Docker Pull](#docker-pull)
  - [Caddyfile Examples](#caddyfile-examples)
    - [Global DNS Configuration](#global-dns-configuration)
    - [Per-Site DNS Configuration](#per-site-dns-configuration)
- [Configuration](#configuration)
  - [Creating Namecheap API Credentials](#creating-namecheap-api-credentials)
  - [ACME DNS Challenge](#acme-dns-challenge)
- [Tags](#tags)
  - [Default or slim?](#default-or-slim)
  - [Why `alpine` tags point to the same image](#why-alpine-tags-point-to-the-same-image)
  - [Why did a digest change?](#why-did-a-digest-change)
- [Platform Support](#platform-support)
  - [Alpine](#alpine)
  - [Raspberry Pi](#raspberry-pi)
- [Troubleshooting](#troubleshooting)
  - [API Requests Rejected](#api-requests-rejected)
  - [Testing with the Sandbox](#testing-with-the-sandbox)
  - [Verifying Modules](#verifying-modules)
  - [Official Resources](#official-resources)
- [How It Works](#how-it-works)
- [Building Your Own Image](#building-your-own-image)
  - [Prerequisites](#prerequisites)
  - [Setup Instructions](#setup-instructions)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Automated Builds** -- Daily checks for new Caddy releases with automatic image builds.
- **Module Update Detection** -- Tracks upstream module commits and rebuilds when they change.
- **Base Image Tracking** -- Rebuilds when the base image is republished with OS or Go toolchain fixes.
- **Namecheap DNS-01 Integration** -- Automatic SSL certificate management via DNS challenges.
- **Multi-Platform** -- Supports `amd64`, `arm64`, `arm/v7` (Raspberry Pi), `ppc64le`, and `s390x`.
- **Alpine-Based** -- Built on the official Caddy image, which uses Alpine Linux. A `slim` variant drops the stock binary.
- **Fork-Friendly** -- Image names derived automatically from your GitHub repository.

## Quick Start

Pull the image and set up a `docker-compose.yml`:

```yaml
services:
  caddy:
    image: ghcr.io/caddybuilds/caddy-namecheap:latest
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - $PWD/Caddyfile:/etc/caddy/Caddyfile
      - $PWD/site:/srv
      - caddy_data:/data
      - caddy_config:/config
    environment:
      - NAMECHEAP_API_KEY=your_namecheap_api_key
      - NAMECHEAP_API_USER=your_namecheap_username
      - NAMECHEAP_CLIENT_IP=your_public_ip

volumes:
  caddy_data:
    external: true
  caddy_config:
```

> Defining the data volume as [external](https://docs.docker.com/compose/compose-file/compose-file-v3/#external) ensures `docker-compose down` does not delete it. Create it manually with `docker volume create caddy_data`.

Replace the three values with your Namecheap API key, username and the public IP you whitelisted. See [Creating Namecheap API Credentials](#creating-namecheap-api-credentials) for setup instructions, and [Caddyfile Examples](#caddyfile-examples) for configuration samples.

## Included Modules

This module is compiled into Caddy at build time using [xcaddy](https://github.com/caddyserver/xcaddy). No additional installation is needed.

| Module | Purpose | Repository |
|--------|---------|------------|
| `caddy-dns/namecheap` | DNS-01 ACME challenge provider for Namecheap | [caddy-dns/namecheap](https://github.com/caddy-dns/namecheap) |

## Usage

### Docker Pull

```sh
docker pull ghcr.io/caddybuilds/caddy-namecheap:latest
docker pull caddybuilds/caddy-namecheap:latest
# slim
docker pull ghcr.io/caddybuilds/caddy-namecheap:slim
docker pull caddybuilds/caddy-namecheap:slim
```

See [Quick Start](#quick-start) for a full docker-compose setup and [Tags](#tags) for every tag.

### Caddyfile Examples

#### Global DNS Configuration

Set the ACME DNS challenge provider globally so it applies to all sites (full file: [`Caddyfile_global`](Caddyfile_global)):

```
{
  acme_dns namecheap {
    api_key {env.NAMECHEAP_API_KEY}
    user {env.NAMECHEAP_API_USER}
    api_endpoint https://api.namecheap.com/xml.response
    client_ip {env.NAMECHEAP_CLIENT_IP}
  }
}

example.com {
    root * /usr/share/caddy
    file_server
    encode gzip
}

another-example.com {
    reverse_proxy localhost:8080
}
```

#### Per-Site DNS Configuration

Configure the DNS challenge individually per site (full file: [`Caddyfile_per_site`](Caddyfile_per_site)):

```
example.com {
    root * /usr/share/caddy
    file_server
    encode gzip

    tls {
        dns namecheap {
            api_key {env.NAMECHEAP_API_KEY}
            user {env.NAMECHEAP_API_USER}
            api_endpoint https://api.namecheap.com/xml.response
            client_ip {env.NAMECHEAP_CLIENT_IP}
        }
    }
}
```

## Configuration

### Creating Namecheap API Credentials

The Namecheap DNS provider needs API access on your account:

1. **Log in to Namecheap** at [namecheap.com](https://www.namecheap.com).

2. **Enable API access**:
   - Go to "Account" > "Profile" > "Tools" > "API Access" and turn it on. Namecheap only enables API access for accounts that meet its [API requirements](https://www.namecheap.com/support/api/intro/).

3. **Whitelist your public IP**:
   - Add the public IP address of the machine running Caddy to the API whitelist. Requests from other addresses are rejected.

4. **Collect the credentials**:
   - **API key**: shown on the API Access page.
   - **Username**: your Namecheap username.
   - **Client IP**: the whitelisted public IP.

5. **Set the environment variables**:
   - `NAMECHEAP_API_KEY`, `NAMECHEAP_API_USER` and `NAMECHEAP_CLIENT_IP`. See [Quick Start](#quick-start) for the docker-compose example. If `client_ip` is left out of the Caddyfile, the module detects the public IP itself.

### ACME DNS Challenge

To configure the [ACME DNS challenge](https://caddyserver.com/docs/automatic-https#dns-challenge) provider for all ACME transactions, add the following to your Caddyfile:

```
{
   acme_dns namecheap {
       api_key {env.NAMECHEAP_API_KEY}
       user {env.NAMECHEAP_API_USER}
       api_endpoint https://api.namecheap.com/xml.response
       client_ip {env.NAMECHEAP_CLIENT_IP}
   }
}
```

This is equivalent to specifying the provider in the [tls directive's ACME issuer](https://caddyserver.com/docs/caddyfile/directives/tls#acme) configuration. See [Caddyfile Examples](#caddyfile-examples) for full samples.

## Tags

The image is available on [GitHub Container Registry](https://github.com/caddybuilds/caddy-namecheap/pkgs/container/caddy-namecheap) and Docker Hub. There are two images, default and slim, each under a few tags:

| Tags | Image |
|------|-------|
| `latest`, `<version>`, `<major>.<minor>`, `<major>` | Default |
| `alpine`, `<version>-alpine`, `<major>.<minor>-alpine`, `<major>-alpine` | Default (same image, see below) |
| `slim`, `<version>-slim`, `<major>.<minor>-slim`, `<major>-slim` | Slim |

`<version>` pins a release (e.g. `docker pull ghcr.io/caddybuilds/caddy-namecheap:2.11.7`), `<major>.<minor>` follows the latest patch (e.g. `2.11`) and `<major>` the latest release (e.g. `2`). Slim tags exist from `2.11.7` onward.

### Default or slim?

Both run the same Caddy binary with the same modules. They differ only in the image underneath.

| | Default | Slim |
|---|---|---|
| Built on | The official [Caddy image](https://hub.docker.com/_/caddy) | [caddy-base](https://github.com/CaddyBuilds/caddy-base#the-caddy-base-image): the official image without its Caddy binary |
| Download size (amd64) | about 43 MB | about 24 MB |
| Caddy binaries inside | Two: the stock one stays in a lower layer, ours replaces it on top | One: ours |
| Rebuilt for base fixes when | The official Caddy image is republished | Alpine is republished (caddy-base rebuilds, then slim follows) |

Everything else is the same: Alpine, packages, default Caddyfile, `/data` and `/config`, ports, command, platforms, and permission to bind ports 80 and 443 as a non-root user.

Use **slim** for a smaller image. Use **default** if you want to stay on the Docker Official Image exactly as Caddy ships it.

### Why `alpine` tags point to the same image

This follows the official Caddy image. On Linux, `caddy:latest`, `caddy:2.11.7` and `caddy:2.11.7-alpine` are all the same Alpine image. The plain tags also include Windows builds, which is the only reason both exist. We only build Linux images, so the `-alpine` tags are aliases: a setup that uses `caddy:2.11.7-alpine` can switch to `caddy-namecheap:2.11.7-alpine` without changing anything else.

### Why did a digest change?

Images are rebuilt without a new Caddy version when the module gets new commits or a base image is republished with OS or Go fixes (the official Caddy image for the default tags, caddy-base for `slim`). Each rebuild is logged under **Rebuilds** in that version's [GitHub Release](https://github.com/caddybuilds/caddy-namecheap/releases), and the reason is stored in the image labels:

```sh
docker inspect --format '{{ index .Config.Labels "caddy-build.reason" }}: {{ index .Config.Labels "caddy-build.details" }}' ghcr.io/caddybuilds/caddy-namecheap:latest
```

## Platform Support

The image is built for the following platforms:

- **linux/amd64** -- Standard x86_64 (desktops, servers)
- **linux/arm64** -- ARM 64-bit (modern ARM servers, Apple Silicon via emulation)
- **linux/arm/v7** -- ARM 32-bit (Raspberry Pi 3+)
- **linux/ppc64le** -- 64-bit PowerPC Little Endian
- **linux/s390x** -- 64-bit IBM System z

### Alpine

Both images are built on [Alpine Linux](https://alpinelinux.org/): the default through the official Caddy image, slim through caddy-base. Alpine uses musl libc instead of glibc, which may cause compatibility issues with some software. Additional tools (git, bash, etc.) are not included by default.

### Raspberry Pi

The `linux/arm/v7` build supports Raspberry Pi 3 and later. No special configuration is needed beyond having Docker installed on a compatible OS (such as Raspberry Pi OS).

## Troubleshooting

### API Requests Rejected

If certificate requests fail with an authentication or IP error from Namecheap:

- Check that the IP Caddy sends as `client_ip` is on your API whitelist. Behind NAT or a changing IP, the public IP may differ from what you expect.
- Check that API access is still enabled on your account.

### Testing with the Sandbox

Namecheap recommends testing against its sandbox first. Use a [sandbox account](https://www.sandbox.namecheap.com/) and point the module at the sandbox endpoint:

```
api_endpoint https://api.sandbox.namecheap.com/xml.response
```

### Verifying Modules

To confirm the Namecheap module is loaded:

```sh
docker run --rm ghcr.io/caddybuilds/caddy-namecheap:latest caddy list-modules | grep dns.providers.namecheap
```

### Official Resources

- [caddy-dns/namecheap](https://github.com/caddy-dns/namecheap)
- [Namecheap API introduction](https://www.namecheap.com/support/api/intro/)
- [Caddy ACME DNS challenge docs](https://caddyserver.com/docs/automatic-https#dns-challenge)

## How It Works

The build pipeline is fully automated via GitHub Actions and shared with the other CaddyBuilds images through [caddy-base](https://github.com/CaddyBuilds/caddy-base). This repo holds only what is specific to this image: the `Dockerfile` (module list), `caddy-image.json` (title, description, verified module) and two thin workflows that call the shared ones.

1. **Daily release check** -- A scheduled workflow queries the GitHub API for new [Caddy releases](https://github.com/caddyserver/caddy/releases) and verifies the official Docker image is available with all required platforms before triggering a build.

2. **Module update detection** -- The pipeline reads the module list from the `Dockerfile` and tracks each module's latest commit SHA in `module-versions.json`. If any module has new commits, a rebuild is triggered even without a new Caddy release.

3. **Base image tracking** -- Docker Official Images republish existing Caddy versions for base OS and Go toolchain fixes, and caddy-base is rebuilt when Alpine is republished. The check compares each base image with when ours was built, and rebuilds if the base is newer.

4. **Multi-platform build** -- The shared workflow builds the default and slim images for all supported architectures. Images are pushed to GitHub Container Registry (primary) and optionally Docker Hub.

5. **Fork-friendly** -- Image names are derived from the `GITHUB_REPOSITORY` environment variable, so forks produce correctly named images without any configuration changes.

6. **Failure notifications** -- If a build fails, a GitHub issue is automatically created for visibility.

## Building Your Own Image

### Prerequisites

- GitHub account
- Docker Hub account (optional, for pushing to Docker Hub)
- GitHub Secrets configured:
  - `GITHUB_TOKEN` (automatically available in GitHub Actions)
  - `DOCKERHUB_USERNAME` (optional)
  - `DOCKERHUB_TOKEN` (optional)
  - `DOCKERHUB_REPOSITORY_NAME` (optional, to customize the Docker Hub repository name)

### Setup Instructions

1. **[Fork this repository](https://github.com/caddybuilds/caddy-namecheap/fork)** to your GitHub account.

2. **Set up GitHub Secrets** (optional, for Docker Hub):
   - Navigate to `Settings` > `Secrets and variables` > `Actions`.
   - Add `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, and optionally `DOCKERHUB_REPOSITORY_NAME`.

3. **Enable GitHub Actions**:
   - Go to the `Actions` tab. If prompted, click "I understand my workflows, go ahead and enable them".

4. **Customize the modules** (optional):
   - Add or change `--with` lines in the `Dockerfile`; the daily check follows the list from there. Adjust the title and description in `caddy-image.json` if you like.

5. **Trigger a build** (optional):
   - In the `Actions` tab, select `Build and Push Docker Image` and click `Run workflow`. The optional note is recorded in the release notes.

6. **Pull your image**:
   ```sh
   docker pull ghcr.io/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME:latest
   ```

Use the image in your docker-compose setup as shown in the [Quick Start](#quick-start), replacing the image name with your own.

## Contributing

Feel free to open issues or submit pull requests if you have any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
