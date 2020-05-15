FROM nimlang/nim:latest AS builder

COPY src/runner.nim /test-runner/
WORKDIR /test-runner/
RUN nim c runner.nim

FROM nimlang/nim:latest-slim
WORKDIR /opt/test-runner/
COPY --from=builder /test-runner/runner bin/
COPY . .
RUN chmod +x bin/run.sh
ENTRYPOINT nim c -r --styleCheck:error --hint[Processing]:off --hint[CC]:off tests/trunner.nim