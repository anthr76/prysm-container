
FROM docker.io/library/ubuntu:focal-20220113 as builder

ARG COMPONENT
# renovate: datasource=github-releases depName=prysmaticlabs/prysm
ENV PRYSM_VERSION=v2.0.6

ENV \
  DEBCONF_NONINTERACTIVE_SEEN=true \
  DEBIAN_FRONTEND="noninteractive" \
  USE_BAZEL_VERSION=4.2.2

RUN apt-get -qq update \
    && apt-get install -y libtinfo5 apt-transport-https libssl-dev python3 libgmp-dev curl gnupg git golang \
    && go get github.com/bazelbuild/bazelisk \
    && export PATH=$PATH:$(go env GOPATH)/bin \
    && git clone https://github.com/prysmaticlabs/prysm \
    && cd prysm \
    && git checkout ${PRYSM_VERSION} \
    && bazelisk build //$COMPONENT:$COMPONENT --config=release

FROM gcr.io/distroless/static:nonroot as runner

ARG COMPONENT

COPY --from=builder /prysm/bazel-bin/cmd/${COMPONENT}/${COMPONENT}_/${COMPONENT} /prysm
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

USER nonroot:nonroot

VOLUME ["/data"]

ENTRYPOINT [ "/prysm" ]

LABEL org.opencontainers.image.title="Prysm ${COMPOENT}" \
      org.opencontainers.image.source="https://github.com/prysmaticlabs/prysm" \
      org.opencontainers.image.authors="Anthony Rabbito <hello@anthonyrabbito.com>"
