FROM nimlang/nim:1.2.2-alpine-slim@sha256:1addf585b1f807991f375b4c9cc54df930b763af4155833087a8b84f7ac9c839 \
     AS builder
COPY src/runner.nim /build/
RUN nim c -d:release /build/runner.nim

FROM nimlang/nim:1.2.2-alpine-slim@sha256:1addf585b1f807991f375b4c9cc54df930b763af4155833087a8b84f7ac9c839
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
