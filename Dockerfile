FROM nimlang/nim:latest AS builder

COPY src/runner.nim /test-runner/
WORKDIR /test-runner/
RUN nim c runner.nim

FROM nimlang/nim:latest-slim
WORKDIR /opt/test-runner/
COPY --from=builder /test-runner/runner bin/
COPY bin/run.sh bin/
COPY src/unittest_json.nim src/unittest_json.nim
RUN chmod +x bin/run.sh
ENTRYPOINT ["/opt/test-runner/bin/run.sh", "bob", "/mnt/exercism-iteration/", "/mnt/out/"]