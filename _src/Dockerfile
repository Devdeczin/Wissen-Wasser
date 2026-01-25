# Estágio de Compilação
FROM nimlang/nim:latest-alpine as builder

RUN apk add --no-cache openssl-dev build-base

WORKDIR /app

COPY . .

RUN nimble install -y jester && \
    nim c -d:ssl -d:release --threads:off --out:_src/backend/nim/ww/server _src/backend/nim/ww/routes.nim

FROM alpine:latest
RUN apk add --no-cache openssl ca-certificates libgcc libstdc++

WORKDIR /app

COPY --from=builder /app/_src/backend/nim/ww/server /app/server
COPY --from=builder /app/_src/frontend /app/frontend

RUN chmod +x /app/server

EXPOSE 5000

CMD ["./server"]