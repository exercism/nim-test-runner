ARG REPO=alpine
ARG IMAGE=3.17.0@sha256:c0d488a800e4127c334ad20d61d7bc21b4097540327217dfab52262adc02380c
ARG NIM_REPO=exercism/nim-docker-base
ARG NIM_IMAGE=d20bcc5694e0a04ef2db5afe60654e5d323f28da@sha256:b550604c5b3eb1a83250594ab99a1495d3f07820d340f4d17e4c8eb7050b50e5
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
RUN /nim/bin/nim c --threads:off -d:release -d:lto -d:strip /build/runner.nim

FROM ${REPO}:${IMAGE}
COPY --from=nim_builder /nim/ /nim/
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
