
FROM docker.io/library/ubuntu:18.04 as builder

ARG COMPONENT
# renovate: datasource=github-releases depName=prysmaticlabs/prysm
ENV PRYSM_VERSION=v2.0.5

RUN apt update \
    && apt install -y apt-transport-https libssl-dev libgmp-dev curl gnupg git python \
    && curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg \
    && mv bazel.gpg /etc/apt/trusted.gpg.d/ \
    && echo "deb [arch=$(dpkg --print-architecture)] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
    && apt update \
    && apt install -y bazel-4.2.2 \
    && ln -s /usr/bin/bazel-4.2.2 /usr/bin/bazel \
    && git clone https://github.com/prysmaticlabs/prysm \
    && cd prysm \
    && git checkout ${PRYSM_VERSION} \
    && bazel build //$COMPONENT:$COMPONENT --config=release

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
