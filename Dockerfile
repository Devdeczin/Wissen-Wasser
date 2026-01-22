FROM nimlang/nim:latest-alpine as builder
WORKDIR /app
COPY . .

RUN cd _src/backend/nim/ww && nim c -d:ssl -d:release --threads:off routes.nim

FROM alpine:latest
RUN apk add --no-cache openssl ca-certificates
WORKDIR /app

COPY --from=builder /app/_src/backend/nim/ww/routes /app/server
COPY --from=builder /app/frontend /app/frontend
COPY --from=builder /app/flows /app/flows

EXPOSE 5000
CMD ["./server"]