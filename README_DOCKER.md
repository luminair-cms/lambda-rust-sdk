Docker base image for Rust Lambda build & deploy

This repository includes a Dockerfile that builds a base image intended for CI usage (GitHub Actions / Bitbucket Pipelines) that:

- Installs the latest stable Rust toolchain with `clippy` and `rustfmt` components
- Installs `cargo-lambda` for building and deploying Rust functions to AWS Lambda
- Installs a minimal AWS CLI v2 binary for obtaining STS credentials using OIDC tokens
- Uses a non-root `rust` user

Build the image

```bash
# from repo root
docker build -t luminair/rust-lambda-base:latest .
```

Push to a registry

```bash
docker tag luminair/rust-lambda-base:latest ghcr.io/your-org/rust-lambda-base:latest
docker push ghcr.io/your-org/rust-lambda-base:latest
```

Usage in Bitbucket Pipelines (OIDC)

Example snippet showing how to write the OIDC token to a file and use `aws sts get-caller-identity` to confirm access. `cargo-lambda deploy` will use environment credentials:

```yaml
image: ghcr.io/your-org/rust-lambda-base:latest

pipelines:
  default:
    - step:
      oidc: true
      script:
        - export AWS_REGION=ap-southeast-2
        - export AWS_ROLE_ARN=arn:aws:iam::222229272234:role/ODICAssumeRole
        - export AWS_WEB_IDENTITY_TOKEN_FILE=$(pwd)/web-identity-token
        - echo $BITBUCKET_STEP_OIDC_TOKEN > $(pwd)/web-identity-token
        - aws sts assume-role-with-web-identity --role-arn "$AWS_ROLE_ARN" --role-session-name "bitbucket-oidc" --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE --duration-seconds 900 | tee /tmp/assume.json
        - export AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId /tmp/assume.json)
        - export AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey /tmp/assume.json)
        - export AWS_SESSION_TOKEN=$(jq -r .Credentials.SessionToken /tmp/assume.json)
        - # now run cargo-lambda deploy (customize args as needed)
        - cargo lambda deploy --function my-function --iam-role $AWS_ROLE_ARN --region $AWS_REGION
```

Usage in GitHub Actions (OIDC)

You can use the platform OIDC token to assume a role and then run `cargo lambda deploy`.

Notes and caveats

- The image installs the full AWS CLI v2 to keep the implementation simple; if you'd like a smaller client, we can replace it with a tiny Go-based STS call or a minimal Python script.
- `cargo-lambda` binary installed targets musl-based builds; confirm `cargo-lambda` version and binary releases if you need a different target architecture.
- The Dockerfile uses Debian Bookworm slim as the base; we chose it for compatibility. If you prefer Alpine, we can create a variant (but tool installation differs).

Next steps

- Build and publish the image to your registry.
- Update CI workflows to reference the image.
- Optionally: add a multi-stage Dockerfile that builds the application inside the image and produces a small runtime image for lambda deployments.
