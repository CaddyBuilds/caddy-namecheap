# Caddy Namecheap
> A fully integrated Caddy Docker image featuring Namecheap DNS-01 ACME validation

Deploy a hassle-free Caddy server with built-in support for Namecheap DNS-01 ACME challenges. Streamline your SSL certificate management and ensure your server stays secure without manual updates, making it an effortless and reliable solution.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
  - [Using the Pre-built Docker Image](#using-the-pre-built-docker-image)
- [Sample Caddyfile](#sample-caddyfile)
  - [Global Configuration (Use DNS Challenge for All Sites)](#global-configuration-use-dns-challenge-for-all-sites)
  - [Per-site Configuration](#per-site-configuration)
- [Configuration](#configuration)
  - [Creating Namecheap API Credentials](#creating-namecheap-api-credentials)
  - [ACME DNS Challenge Configuration](#acme-dns-challenge-configuration)
- [Tags](#tags)
  - [Default or slim?](#default-or-slim)
  - [Why `alpine` tags point to the same image](#why-alpine-tags-point-to-the-same-image)
- [Platform Support](#platform-support)
  - [Alpine](#alpine)
  - [Raspberry Pi Support](#raspberry-pi-support)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage-1)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Automated Builds**: Automatically checks for new Caddy releases and builds Docker images.
- **Continuous Integration**: Utilizes GitHub Actions for seamless CI/CD.
- **Namecheap DNS Integration**: Integrates Namecheap DNS for automatic SSL certificate management.
- **Multi-Platform Support**: Builds images for multiple architectures, including `amd64`, `arm64`, `arm/v7` (Raspberry Pi), `ppc64le`, and `s390x` , ensuring compatibility across a wide range of devices and systems.
- **Module Update Detection**: Rebuilds when the Namecheap DNS module gets new commits, not only on Caddy releases.
- **Base Image Tracking**: Rebuilds when the official Caddy image is republished for base OS or Go fixes.
- **Slim Variant**: `slim` tags carry one Caddy binary on an Alpine base, about 45% smaller to download.
- **Fork-Friendly**: Image names are derived from your GitHub repository; edit one line in the Dockerfile to change the modules.
- **Manual Trigger**: Allows manual triggering of the build process.
- **Open Source**: Contributions are welcome under the MIT License.

## Usage

### Using the Pre-built Docker Image

To use the pre-built Docker image, pull it from the GitHub Container Registry:

```sh
docker pull ghcr.io/caddybuilds/caddy-namecheap:latest
docker pull caddybuilds/caddy-namecheap:latest
# alpine
docker pull ghcr.io/caddybuilds/caddy-namecheap:alpine
docker pull caddybuilds/caddy-namecheap:alpine
```
You can use the image in your Docker setup. Here is an example `docker-compose.yml` file:
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
      - NAMECHEAP_CLIENT_IP=your_client_ip

volumes:
  caddy_data:
    external: true
  caddy_config:
```
Defining the data volume as [external](https://docs.docker.com/compose/compose-file/compose-file-v3/#external) makes sure `docker-compose down` does not delete the volume. You may need to create it manually using `docker volume create caddy_data`.

Replace `your_namecheap_api_key`, `your_namecheap_username`, and `your_client_ip` with your actual Namecheap API credentials.

## Sample Caddyfile
Here is a sample Caddyfile configuration to get you started. This configuration sets up the ACME DNS challenge provider to use Namecheap and serves a simple static site.

### Global Configuration (Use DNS Challenge for All Sites)
In this configuration, the ACME DNS challenge provider is set globally, so it applies to all sites served by Caddy.

```
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace "example.com" below with your
# domain name.

{
  # Set the ACME DNS challenge provider to use Namecheap for all sites
  acme_dns namecheap {
    api_key {env.NAMECHEAP_API_KEY}
    user {env.NAMECHEAP_API_USER}
    api_endpoint https://api.namecheap.com/xml.response
    client_ip {env.NAMECHEAP_CLIENT_IP}
  }
}

example.com {

    # Set this path to your site's directory.
    root * /usr/share/caddy

    # Enable the static file server.
    file_server

    # Another common task is to set up a reverse proxy:
    # reverse_proxy localhost:8080

    # Or serve a PHP site through php-fpm:
    # php_fastcgi localhost:9000

    encode gzip

    tls {
      # No need to specify dns here, it's already set globally
    }
}

another-example.com {
    root * /usr/share/caddy
    file_server
    encode gzip

    tls {
        # No need to specify dns here, it's already set globally
    }
}
```
### Per-site Configuration
```
example.com {
  
    # Set this path to your site's directory.
    root * /usr/share/caddy

    # Enable the static file server.
    file_server

    # Another common task is to set up a reverse proxy:
    # reverse_proxy localhost:8080

    # Or serve a PHP site through php-fpm:
    # php_fastcgi localhost:9000

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

another-example.com {
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

To use the Namecheap DNS challenge provider, you'll need to create API credentials in your Namecheap account. Follow these steps:

1. **Log in to Namecheap**:
   - Go to the Namecheap dashboard at [namecheap.com](https://www.namecheap.com) and log in with your account credentials.

2. **Enable API Access**:
   - Navigate to "Account" > "Profile" > "Tools" > "API Access".
   - Follow the instructions to enable API access for your account.
   - Note that Namecheap may require that you whitelist your public IP address.

3. **Get API Credentials**:
   - Once API access is enabled, you'll be able to see your API Key.
   - You will need:
     - **API Key**: Your API key from the Namecheap dashboard.
     - **Username**: Your Namecheap username.
     - **Client IP**: Your public IP address that has been whitelisted with Namecheap.

4. **Set Environment Variables**:
   - In your deployment environment, set the following environment variables:
     - `NAMECHEAP_API_KEY`: Your Namecheap API key.
     - `NAMECHEAP_API_USER`: Your Namecheap username.
     - `NAMECHEAP_CLIENT_IP`: Your client IP address (optional if Namecheap can automatically detect it).

For example, in a Docker environment, you can set these environment variables in your `docker-compose.yml` file:

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
      - NAMECHEAP_CLIENT_IP=your_client_ip

volumes:
  caddy_data:
    external: true
  caddy_config:
```
Defining the data volume as [external](https://docs.docker.com/compose/compose-file/compose-file-v3/#external) makes sure `docker-compose down` does not delete the volume. You may need to create it manually using `docker volume create caddy_data`.

Replace `your_namecheap_api_key`, `your_namecheap_username`, and `your_client_ip` with your actual credentials.

### ACME DNS Challenge Configuration
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
This configuration sets up the provider to use the Namecheap DNS module with the API credentials provided as environment variables. It ensures that your Caddy server can automatically issue and renew SSL certificates using DNS-01 challenges via Namecheap.

This setup is the same as specifying the provider in the [tls directive's ACME issuer](https://caddyserver.com/docs/caddyfile/directives/tls#acme) configuration.

[Sample Caddyfile](#sample-caddyfile)

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

## Platform Support

The `caddybuilds/caddy-namecheap` image is built to support multiple platforms, ensuring compatibility across a wide range of devices and systems. The supported platforms include:

- **linux/amd64**: Standard x86_64 architecture, commonly used in desktop and server environments.
- **linux/arm64**: ARM 64-bit architecture, used in many modern servers and high-end ARM devices.
- **linux/arm/v7**: ARM 32-bit architecture, widely used in devices like Raspberry Pi.
- **linux/ppc64le**: 64-bit PowerPC Little Endian architecture.
- **linux/s390x**: 64-bit IBM System z architecture.

### Alpine

Both images are built on [Alpine Linux](https://alpinelinux.org/): the default through the official Caddy image, slim through caddy-base. The `alpine` and `<version>-alpine` tags are aliases of the default tags and resolve to the same digest.

### Raspberry Pi Support

This Docker image is optimized for Raspberry Pi, allowing you to deploy Caddy with Namecheap DNS integration on these popular single-board computers. Whether you are using a Raspberry Pi 3 or the latest Raspberry Pi 4, this image provides the necessary support for seamless operation.

To use the image on a Raspberry Pi, ensure you are running a compatible operating system (such as Raspberry Pi OS) and have Docker installed. You can then pull the image and run it as you would on any other system:

```sh
docker pull ghcr.io/caddybuilds/caddy-namecheap:latest
```
# How It Works

The pipeline is shared with the other CaddyBuilds images through [caddy-base](https://github.com/CaddyBuilds/caddy-base):

1. **Daily release check**: a scheduled workflow looks for new [Caddy releases](https://github.com/caddyserver/caddy/releases) and waits until the official image has every required platform.
2. **Module update detection**: the latest commit of each module in the `Dockerfile` is tracked in `module-versions.json`; new commits trigger a rebuild.
3. **Base image tracking**: if the official image is republished for base OS or Go fixes, the image is rebuilt on top of it.
4. **Multi-platform build**: the image is built for all supported architectures and pushed to GitHub Container Registry and, optionally, Docker Hub. Each release lists why it was built or rebuilt.
5. **Failure notifications**: a failed build opens a GitHub issue.

# Building Your Own Docker Image
If you prefer to build your own Docker image, follow these steps:

## Prerequisites

- GitHub account
- DockerHub account (if you wish to push the image to DockerHub as well)
- GitHub Secrets configured:
  - `GITHUB_TOKEN` (automatically available in GitHub Actions)
  - `DOCKERHUB_USERNAME` (optional, if you want to push to DockerHub)
  - `DOCKERHUB_TOKEN` (optional, if you want to push to DockerHub)

## Setup Instructions

1. **[Fork this repository](https://github.com/caddybuilds/caddy-namecheap/fork)** to your GitHub account.

2. **Clone the forked repository** to your local machine:
   ```sh
   git clone https://github.com/YOUR_GITHUB_USERNAME/caddy-namecheap.git
   cd caddy-namecheap
   ```

3. **Set up GitHub Secrets**:
   - Go to your repository on GitHub.
   - Navigate to `Settings` > `Secrets and variables` > `Actions`.
   - Add the following secrets:
     - `GITHUB_TOKEN`: This is automatically available in GitHub Actions.
     - `DOCKERHUB_USERNAME`: Your DockerHub username (optional).
     - `DOCKERHUB_TOKEN`: Your DockerHub access token (optional).

4. **Customize the image** (if needed):
   - Add or change modules in the `--with` lines of the `Dockerfile`. The daily check reads the module list from there.
   - `caddy-image.json` holds the image title, description and the module ID verified after each build.
   - The workflows in `.github/workflows/` call the shared [caddy-base](https://github.com/CaddyBuilds/caddy-base) workflows, which handle the release check, the multi-platform build, tagging and releases.

5. **Commit and push any changes** (if you made customizations):
   ```sh
   git add .
   git commit -m "Customize workflow"
   git push origin main
   ```

6. **Manually trigger the workflow** (optional):
   - Go to the `Actions` tab in your GitHub repository.
   - Select the `Build and Push Docker Image` workflow.
   - Click the `Run workflow` button to trigger the build process manually.

7. **Monitor the workflow**:
   - You can monitor the progress and logs of the workflow in the `Actions` tab of your GitHub repository.

8. **Docker image**:
   - Once the workflow completes successfully, the Docker image will be available in the GitHub Container Registry under your repository.
   - You can pull the image using:
     ```sh
     docker pull ghcr.io/YOUR_GITHUB_USERNAME/caddy-namecheap:latest
     ```

## Usage

You can use the built Docker image in your projects. Here is an example of how to use it in a `docker-compose.yml` file:

```yaml
services:
  caddy:
    image: ghcr.io/YOUR_GITHUB_USERNAME/caddy-namecheap:latest
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
      - NAMECHEAP_CLIENT_IP=your_client_ip

volumes:
  caddy_data:
    external: true
  caddy_config:
```
Defining the data volume as [external](https://docs.docker.com/compose/compose-file/compose-file-v3/#external) makes sure `docker-compose down` does not delete the volume. You may need to create it manually using `docker volume create caddy_data`.

Replace `YOUR_GITHUB_USERNAME` with your GitHub username and your Namecheap API credentials.

## Contributing

Feel free to open issues or submit pull requests if you have any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.