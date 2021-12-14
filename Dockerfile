ARG REPO=alpine
ARG IMAGE=3.14.2@sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a
ARG NIM_REPO=nimlang/nim
ARG NIM_IMAGE=1.6.0-alpine-regular@sha256:30b04b034c2487fc426ea30d2e698262db5bc5a66668b51f83de15e1b06f9424
FROM ${REPO}:${IMAGE} AS base
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
RUN /nim/bin/nim c -d:release -d:lto -d:strip /build/runner.nim

FROM ${REPO}:${IMAGE}
COPY --from=nim_builder /nim/bin/nim /nim/bin/nim
COPY --from=nim_builder /nim/lib/ /nim/lib/
# hadolint ignore=DL3018
RUN apk add --no-cache \
      musl-dev \
      pcre \
    && apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing \
      tcc \
    && ln -s /nim/bin/nim /usr/local/bin/nim
WORKDIR /opt/test-runner/
COPY --from=runner_builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
