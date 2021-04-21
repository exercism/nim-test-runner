ARG REPO=alpine
ARG IMAGE=3.13.5@sha256:def822f9851ca422481ec6fee59a9966f12b351c62ccb9aca841526ffaa9f748
FROM ${REPO}:${IMAGE} AS builder
COPY bin/install_nim.sh /build/
# We can't reliably pin the versions here, so we ignore the linter warning.
# See https://gitlab.alpinelinux.org/alpine/abuild/-/issues/9996
# hadolint ignore=DL3018
RUN apk add --no-cache --virtual=.build-deps \
      curl \
      gcc \
      musl-dev \
      tar \
      xz \
    && sh /build/install_nim.sh \
    && apk del .build-deps

FROM ${REPO}:${IMAGE} AS builder2
# hadolint ignore=DL3018
RUN apk add --no-cache \
      gcc \
      musl-dev
COPY --from=builder /nim/ /nim/
RUN ln -s /nim/bin/nim /bin/nim
COPY src/runner.nim /build/
COPY src/unittest_json.nim /build/
RUN nim c -d:release -d:lto -d:strip /build/runner.nim

FROM ${REPO}:${IMAGE}
# hadolint ignore=DL3018
RUN apk add --no-cache \
      gcc \
      musl-dev \
      pcre
COPY --from=builder /nim/ /nim/
RUN ln -s /nim/bin/nim /bin/nim
WORKDIR /opt/test-runner/
COPY --from=builder2 /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
