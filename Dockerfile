ARG REPO=alpine
ARG IMAGE=3.13.5@sha256:def822f9851ca422481ec6fee59a9966f12b351c62ccb9aca841526ffaa9f748
FROM ${REPO}:${IMAGE} AS base
# We can't reliably pin the package versions on Alpine, so we ignore the linter warning.
# See https://gitlab.alpinelinux.org/alpine/abuild/-/issues/9996
# hadolint ignore=DL3018
RUN apk add --no-cache \
      gcc \
      musl-dev

FROM base AS nim_builder
COPY bin/install_nim.sh /build/
# hadolint ignore=DL3018
RUN apk add --no-cache --virtual=.build-deps \
      curl \
      tar \
      xz \
    && sh /build/install_nim.sh \
    && apk del .build-deps

FROM base AS runner_builder
COPY --from=nim_builder /nim/ /nim/
COPY src/runner.nim /build/
COPY src/unittest_json.nim /build/
RUN /nim/bin/nim c -d:release -d:lto -d:strip /build/runner.nim

FROM ${REPO}:${IMAGE}
COPY --from=nim_builder /nim/ /nim/
# hadolint ignore=DL3018
RUN apk add --no-cache \
      gcc \
      musl-dev \
      pcre \
    && ln -s /nim/bin/nim /usr/local/bin/nim \
    && printf '\nRemoving some unneeded large files:\n' \
    && rm -v /usr/bin/lto-dump \
    && find / -path '/usr/libexec/gcc/x86_64-alpine-linux-musl/*/lto*' -exec rm -v {} + \
    && find / -path '/usr/lib/libgphobos.so*' -exec rm -v {} +
WORKDIR /opt/test-runner/
COPY --from=runner_builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
