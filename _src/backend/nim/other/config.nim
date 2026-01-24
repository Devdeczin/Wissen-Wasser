# wissen-wasser/_src/backend/nim/ww/config.nim
import os, strutils

type 
    AppConfig* = object
        port*: int
        jsonbinApiKey*: string
        jsonbinIndexBinId*: string

# Esta função DEVE ser chamada explicitamente para popular o ambiente
proc loadEnvManual*(filename: string) =
    if not fileExists(filename): return
    for line in lines(filename):
        let trimmed = line.strip()
        if trimmed.len == 0 or trimmed.startsWith("#"): continue
        let parts = trimmed.split('=', 1)
        if parts.len == 2:
            putEnv(parts[0].strip(), parts[1].strip())

# Função para buscar as configs já com o ambiente carregado
proc getAppConfig*(): AppConfig =
    result.port = parseInt(getEnv("PORT", "5000"))
    result.jsonbinApiKey = getEnv("JSONBIN_API_KEY", "")
    result.jsonbinIndexBinId = getEnv("JSONBIN_INDEX_BIN_ID", "")

# Deixamos como var para poder atualizar após carregar o .env
var conf* = AppConfig(port: 5000)

proc setupConfig*() =
    let dotEnvPath = getCurrentDir() / ".env"
    if fileExists(dotEnvPath):
        loadEnvManual(dotEnvPath)
        conf = getAppConfig()
        if conf.jsonbinApiKey.len > 0:
            echo "[OK] Chave carregada de: ", dotEnvPath
        else:
            echo "[ERRO] Arquivo lido, mas JSONBIN_API_KEY está vazia dentro dele."
    else:
        echo "[ERRO] .env não encontrado em: ", dotEnvPath