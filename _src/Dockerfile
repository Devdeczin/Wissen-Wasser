FROM nimlang/nim:latest-alpine as builder
WORKDIR /app
COPY . .

# O segredo é o caminho correto para o routes.nim
RUN cd _src/backend/nim/ww && nim c -d:ssl -d:release --threads:off routes.nim

FROM alpine:latest
RUN apk add --no-cache openssl ca-certificates
WORKDIR /app

# O binário compilado chama-as 'routes' e fica dentro da pasta onde foi compilado
COPY --from=builder /app/_src/backend/nim/ww/routes /app/server
COPY --from=builder /app/frontend /app/frontend
# A pasta flows pode não existir ainda no git, o Docker pode reclamar. 
# Se der erro na linha abaixo, comente-a com #
COPY --from=builder /app/flows /app/flows 

EXPOSE 5000
CMD ["./server"]