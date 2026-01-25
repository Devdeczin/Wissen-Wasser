# --- ESTÁGIO 1: COMPILAÇÃO ---
FROM nimlang/nim:latest-alpine as builder

# Erro Comum 1: Falta de bibliotecas para SSL e compilação C
# O Nim compila para C, então precisa do build-base (gcc, make, etc)
RUN apk add --no-cache openssl-dev build-base git

WORKDIR /app

# Copiamos tudo para garantir que a estrutura de pastas exista
COPY . .

# Erro Comum 2: Nimble não encontra pacotes ou falha no download
# Instalamos o Jester separadamente para garantir. 
# Se você usa outras libs (como jsonbin), adicione aqui.
RUN nimble install -y jester

# Erro Comum 3: Resolução de caminhos (Path)
# Compilamos a partir da raiz para que o Nim entenda a hierarquia dos arquivos.
# O parâmetro -p garante que ele encontre a pasta 'other' mesmo com caminhos relativos.
RUN nimble install -y jester && \
    nim c -d:ssl -d:release --mm:orc --threads:on \
    --path:_src/backend/nim/other \
    --path:_src/backend/nim/ww \
    --out:server \
    _src/backend/nim/ww/routes.nim

# --- ESTÁGIO 2: EXECUÇÃO (Runtime) ---
FROM alpine:latest

# Erro Comum 4: Binário não roda por falta de libs de suporte
# O Alpine é muito enxuto, precisamos devolver o que o SSL e o C precisam
RUN apk add --no-cache openssl ca-certificates libgcc libstdc++

WORKDIR /app

# Copiamos o binário do estágio anterior
COPY --from=builder /app/server /app/server

# Erro Comum 5: Frontend não encontrado
# O Jester procura a pasta definida em staticDir. Se o binário está na raiz, 
# a pasta frontend também deve estar na raiz.
COPY --from=builder /app/_src/frontend /app/frontend

# Permissão de execução
RUN chmod +x /app/server

# Variável de ambiente para a porta (o Render costuma usar 10000 ou 8080)
EXPOSE 5000

# Rodamos o servidor
CMD ["./server"]