ARG NIM_REPO=exercism/nim-docker-base
ARG NIM_IMAGE=56de50f73092295436b31dcb45f081436159755f@sha256:240c8b22824c8b8a21541186e46f6eebe5ee2a774f89b35e48c2578ec92899fa
# target = alpine:latest
FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS base
# We can't reliably pin the package versions on Alpine, so we ignore the linter warning.
# See https://gitlab.alpinelinux.org/alpine/abuild/-/issues/9996
# hadolint ignore=DL3018
RUN apk add --no-cache \
      gcc \
      musl-dev

FROM ${NIM_REPO}:${NIM_IMAGE} AS nim_builder

FROM base AS runner_builder
COPY --from=nim_builder /nim/ /nim/
COPY src/runner.nim /build/
COPY src/unittest_json.nim /build/
RUN /nim/bin/nim c --threads:off -d:release -d:lto -d:strip /build/runner.nim

# target = alpine:latest
FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b
COPY --from=nim_builder /nim/ /nim/
# hadolint ignore=DL3018
RUN apk add --no-cache \
      jq \
      musl-dev \
      pcre \
    && apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing \
      tcc \
      tcc-libs-static \
    && ln -s /nim/bin/nim /usr/local/bin/nim
WORKDIR /opt/test-runner/
COPY --from=runner_builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
