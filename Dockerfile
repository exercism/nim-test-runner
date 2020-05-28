FROM nimlang/nim:1.2.0-alpine-slim@sha256:8859f05f8d0a24a20c79362fd1c61f6d04111e4f7df472b2d9e55f3178b75b49 \
     AS builder
COPY src/runner.nim /build/
RUN nim c -d:release /build/runner.nim

FROM nimlang/nim:1.2.0-alpine-slim@sha256:8859f05f8d0a24a20c79362fd1c61f6d04111e4f7df472b2d9e55f3178b75b49
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
