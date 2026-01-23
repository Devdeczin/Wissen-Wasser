# wissen-wasser/_src/backend/nim/ww/config.nim
import os, strutils

type 
    Config* = object
        env*: string
        port*: int
        jsonbinApiKey*: string
        
    AppConfig* = object
        port*: int
        jsonbinApiKey*: string
        jsonbinIndexBinId*: string

let conf* = AppConfig(
    port: 5000,
    jsonbinApiKey: getEnv("JSONBIN_API_KEY", ""),
    jsonbinIndexBinId: getEnv("JSONBIN_INDEX_BIN_ID", "")
)

let isDev* = DEV_ENABLED or getEnv("WW_DEV", "0") == "1"

proc loadEnvManual(filename: string) =
    if not fileExists(filename): return
    for line in lines(filename):
        let trimmed = line.strip()
        if trimmed.len == 0 or trimmed.startsWith("#"): continue
        
        let parts = trimmed.split('=', 1)
        if parts.len == 2:
            putEnv(parts[0].strip(), parts[1].strip())

proc loadConfig*(): Config =
    let paths = [".env", "../.env", "../../.env", "../../../.env"]
    for p in paths:
        if fileExists(p):
            loadEnvManual(p)
            break

    result.env = getEnv("APP_ENV", "dev").toLowerAscii()
    result.port = parseInt(getEnv("PORT", "5000"))
    result.jsonbinApiKey = getEnv("JSONBIN_API_KEY")

    if result.jsonbinApiKey.len > 0:
        echo "jsonbinApiKey"

let conf* = loadConfig()