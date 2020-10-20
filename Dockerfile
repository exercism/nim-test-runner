FROM nimlang/nim:1.4.0-alpine-slim@sha256:36c84bab9f2020e462604fff06860bebd95310ea065d35d4cc8c755ea30694ae \
     AS builder
COPY src/runner.nim /build/
RUN nim c -d:release /build/runner.nim

FROM nimlang/nim:1.4.0-alpine-slim@sha256:36c84bab9f2020e462604fff06860bebd95310ea065d35d4cc8c755ea30694ae
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
