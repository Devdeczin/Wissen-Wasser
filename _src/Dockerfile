FROM nimlang/nim:latest-alpine as builder
WORKDIR /app
COPY . .

RUN nimble install -y jester && \
    cd backend/nim/ww && \
    nim c -d:ssl -d:release --threads:off routes.nim

FROM alpine:latest
RUN apk add --no-cache openssl ca-certificates
WORKDIR /app

COPY --from=builder /app/backend/nim/ww/routes /app/server
COPY --from=builder /app/frontend /app/frontend

EXPOSE 5000
CMD ["./server"]