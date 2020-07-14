FROM nimlang/nim:1.2.4-alpine-slim@sha256:9afaf7c89c44e5200620e3697e15330de32dbc7ac0fd3f0c99ed13cf185b9c30 \
     AS builder
COPY src/runner.nim /build/
COPY src/unittest_json.nim /build/
RUN nim c -d:release /build/runner.nim

FROM nimlang/nim:1.2.4-alpine-slim@sha256:9afaf7c89c44e5200620e3697e15330de32dbc7ac0fd3f0c99ed13cf185b9c30
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
