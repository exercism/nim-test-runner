ARG NIM_IMAGE=nimlang/nim:1.4.4-alpine-slim@sha256:5c82efe7f3afffe4781f3f127d28c21ecb705dc964cc5434fee98feafd63d2d7
FROM ${NIM_IMAGE} AS builder
COPY src/runner.nim /build/
COPY src/unittest_json.nim /build/
RUN nim c -d:release -d:lto -d:strip /build/runner.nim

FROM ${NIM_IMAGE}
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
