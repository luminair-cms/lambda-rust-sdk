# Lightweight base image for building and deploying Rust services to AWS Lambda
# - Provides latest stable Rust toolchain with clippy and rustfmt
# - Installs cargo-lambda
# - Includes a minimal AWS CLI v2 (for STS/get-caller-identity using OIDC token)
# - Designed to be used in CI (GitHub Actions / Bitbucket Pipelines) for build + deploy

FROM debian:bookworm-slim

ARG USER=rust
ARG UID=1000
ARG RUSTUP_HOME=/usr/local/rustup
ARG CARGO_HOME=/usr/local/cargo
ARG PATH="$CARGO_HOME/bin:$PATH"

# Install essential packages for building and fetching tooling
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        ca-certificates \
        gnupg \
        build-essential \
        pkg-config \
        libssl-dev \
        libudev-dev \
        musl-tools \
        git \
        unzip \
        jq \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g ${UID} ${USER} || true \
    && useradd -m -u ${UID} -g ${UID} -s /bin/bash ${USER}

# Install rustup + stable toolchain and components (clippy, rustfmt)
ENV RUSTUP_HOME=${RUSTUP_HOME}
ENV CARGO_HOME=${CARGO_HOME}
ENV PATH=${CARGO_HOME}/bin:${PATH}

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh \
    && chmod +x /tmp/rustup-init.sh \
    && /tmp/rustup-init.sh -y --no-modify-path --default-toolchain stable || true

# Use rustup to ensure toolchain and components installed (run as root so files are owned by root then chown later)
RUN ${CARGO_HOME}/bin/rustup set profile minimal || true \
    && ${CARGO_HOME}/bin/rustup toolchain install stable --component clippy rustfmt || true

# Install cargo-lambda via cargo (safer and avoids relying on specific release asset names)
RUN ${CARGO_HOME}/bin/cargo install --locked cargo-lambda

# Install minimal AWS CLI v2 (bundled installer) - only install `aws` binary
RUN curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp/awscliv2 \
    && /tmp/awscliv2/aws/install -i /usr/local/aws-cli -b /usr/local/bin \
    && rm -rf /tmp/awscliv2 /tmp/awscliv2.zip

# Give ownership of cargo/rustup to the non-root user
RUN chown -R ${USER}:${USER} ${CARGO_HOME} ${RUSTUP_HOME} /home/${USER}

# Switch to non-root user
USER ${USER}
WORKDIR /home/${USER}

# Default entrypoint: print versions
ENTRYPOINT ["sh", "-lc", "rustc --version && cargo --version && cargo-lambda --version && aws --version"]
