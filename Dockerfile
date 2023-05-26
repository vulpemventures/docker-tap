FROM golang:1.20.3-alpine as builder

# Pass a tag, branch or a commit using build-arg.  This allows a docker
# image to be built from a specified Git state.  The default image
# will use the Git tip of master by default.
ARG checkout="v0.2.0"
ARG git_url="https://github.com/lightninglabs/taproot-assets"

ENV CGO_ENABLED=0

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
&&  git clone $git_url /go/src/github.com/lightninglabs/taproot-assets \
&&  cd /go/src/github.com/lightninglabs/taproot-assets \
&&  git checkout $checkout \
&&  make install

# Start a new, final image.
FROM alpine as final

# Define a root volume for data persistence.
VOLUME /root/.tapd

# Add utilities for quality of life and SSL-related reasons
RUN apk --no-cache add \
    bash \
    jq \
    ca-certificates \
    curl

# Copy the binaries from the builder image.
COPY --from=builder /go/bin/tapd /bin/
COPY --from=builder /go/bin/tapcli /bin/

# Expose tap ports
EXPOSE 10029
EXPOSE 8089

# Specify the start command and entrypoint as the tap daemon.
ENTRYPOINT ["tapd"]
