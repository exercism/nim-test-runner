ARG REPO=alpine
ARG IMAGE=3.15.3@sha256:1e014f84205d569a5cc3be4e108ca614055f7e21d11928946113ab3f36054801
ARG NIM_REPO=exercism/nim-docker-base
ARG NIM_IMAGE=ce4f3bef335e8625e71f1035685d30fc86b6f753@sha256:840e5e0e5a0d28625e7ed03a0d55c64be402ffdf0e6320c9110da8983ea5a60d
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
