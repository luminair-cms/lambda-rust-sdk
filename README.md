## Docker base image for Rust Lambda build & deploy

## Build the image

```bash
# from repo root
docker build -t luminair/lambda-rust-sdk:latest .
```

Push to a registry

```bash
docker tag luminair/lambda-rust-sdk:latest ghcr.io/your-org/lambda-rust-sdk:latest
docker push ghcr.io/your-org/lambda-rust-sdk:latest
```