FROM nimlang/nim:1.6.14-alpine as builder

RUN apk add --no-cache gcc musl-dev openssl-dev openssl

WORKDIR /app

COPY . .

RUN nim c -d:release -d:ssl --threads:off --opt:speed -o:server _src/backend/nim/ww/routes.nim

FROM alpine:latest
RUN apk add --no-cache openssl ca-certificates libssl1.1
WORKDIR /app
COPY --from=builder /app/server .

RUN mkdir -p flows

EXPOSE 5000

CMD ["./server"]