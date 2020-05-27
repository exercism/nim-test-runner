FROM nimlang/nim:latest-alpine-slim AS builder
COPY src/runner.nim /build/
RUN nim c -d:release /build/runner.nim

FROM nimlang/nim:latest-alpine-slim
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
