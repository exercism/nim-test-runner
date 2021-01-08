FROM nimlang/nim:1.4.2-alpine-slim@sha256:45cb86ad7b494e381358ae378a04f072f096e11c4e54ed06abdba043fb2667c3 \
     AS builder
COPY src/runner.nim /build/
RUN nim c -d:release -d:lto -d:strip /build/runner.nim

FROM nimlang/nim:1.4.2-alpine-slim@sha256:45cb86ad7b494e381358ae378a04f072f096e11c4e54ed06abdba043fb2667c3
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /build/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/
ENTRYPOINT ["nim", "c", "-r", "--styleCheck:error", "--hint[Processing]:off", \
            "--hint[CC]:off", "-d:repoSolutions", "tests/trunner.nim"]
