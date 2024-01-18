# This dockerfile builds the API and runs it on a minimal container with the Datastore adaptor

FROM docker.io/library/rust:latest as builder

# Install CA Certs for Hyper
RUN apt-get install -y --no-install-recommends ca-certificates
RUN update-ca-certificates

WORKDIR /usr/src/app
COPY . .
COPY --from=docker.io/library/rust:latest /usr/local/cargo /usr/local/cargo
# Will build and cache the binary and dependent crates in release mode
RUN \
    #--mount=type=cache,target=/usr/local/cargo,from=docker.io/library/rust:latest,source=/usr/local/cargo \
    --mount=type=cache,target=target \
    cargo build --release --features sql-adaptor && mv ./target/release/crabfit-api ./api

# Runtime image
FROM debian:bookworm-slim

# Run as "app" user
RUN useradd -ms /bin/bash app
RUN apt-get update && apt-get upgrade && apt-get install -y --no-install-recommends libssl-dev

USER app
WORKDIR /app

# Get compiled binaries from builder's cargo install directory
COPY --from=builder /usr/src/app/api /app/api
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Run the app
EXPOSE 3000
CMD ./api
