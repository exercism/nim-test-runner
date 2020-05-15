FROM nimlang/nim:latest-slim AS builder

COPY src/runner.nim /test-runner/
WORKDIR /test-runner/
RUN nim c runner.nim

FROM nimlang/nim:latest-alpine-slim
RUN apk add --no-cache pcre
WORKDIR /opt/test-runner/
COPY --from=builder /test-runner/runner bin/
COPY . .
ENTRYPOINT nim c -r --styleCheck:error --hint[Processing]:off --hint[CC]:off -d:repoSolutions tests/trunner.nim
