ARG REPO=alpine
ARG IMAGE=3.19.1@sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0
ARG NIM_REPO=exercism/nim-docker-base
ARG NIM_IMAGE=68a971c28c2f5bd44915c1bd24cfd2a5856e5704@sha256:bc998636985028f4d0770f5aaed81cde64ffb429c43e90a36d2e7db54cd259c8
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
