## Docker base image for Rust Lambda build & deploy

## Build the image

```bash
# from repo root
docker build -t luminair-cmd/lambda-rust-sdk:latest .
```

Push to a registry

```bash
docker tag luminair-cmd/lambda-rust-sdk:latest ghcr.io/your-org/lambda-rust-sdk:latest
docker push ghcr.io/luminair-cms/lambda-rust-sdk:latest
```

## github actions, pushing docker image

https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images

## github actions

https://github.com/docker/metadata-action