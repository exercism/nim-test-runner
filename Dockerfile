FROM nimlang/nim:latest-alpine-slim AS builder
COPY src/runner.nim /tmp/
RUN nim c -d:release /tmp/runner.nim

FROM nimlang/nim:latest-alpine-slim
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /tmp/runner bin/
COPY . .
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
