# wissen-wasser/_src/backend/nim/ww/other/remote_storage.nim
import httpclient, json, strutils, os, tables
import types, ../ww/dotww, config

const MAPPING_FILE = "../../../flows/mapping.json"
var idMap = newTable[string, string]()

# Carrega o mapa do disco ao iniciar
if fileExists(MAPPING_FILE):
    try:
        let data = parseJson(readFile(MAPPING_FILE))
        for key, val in data.getFields():
            idMap[key] = val.getStr()
    except: echo "Erro ao carregar mapping.json"

proc saveMapping() =
    let j = newJObject()
    for k, v in idMap: j[k] = %v
    writeFile(MAPPING_FILE, $j)

proc syncToRemote*(doc: WwDocument) =
    let apiKey = conf.jsonbinApiKey
    if apiKey.len == 0: return

    let client = newHttpClient()
    client.headers = newHttpHeaders({
        "X-Master-Key": apiKey,
        "Content-Type": "application/json"
    })

    let inkIdStr = $doc.header.inkid
    let body = %*{ "content": doc.body.content, "inkid": inkIdStr }

    try:
        var url = "https://api.jsonbin.io/v3/b"
        var method = HttpPost
        
        if idMap.hasKey(inkIdStr):
            url = url / idMap[inkIdStr]
            method = HttpPut

        let response = client.request(url, httpMethod = method, body = $body)
        
        if response.status.startsWith("2"):
            if method == HttpPost:
                let resJson = parseJson(response.body)
                idMap[inkIdStr] = resJson["metadata"]["id"].getStr()
                saveMapping() # Persiste a associação
            echo "Sincronizado: ", inkIdStr
    except: echo "Erro de rede JSONBin"
    finally: client.close()

# Função para buscar da nuvem quando o arquivo local sumir
proc fetchFromRemote*(inkIdStr: string): string =
    if not idMap.hasKey(inkIdStr): return ""
    
    let client = newHttpClient()
    client.headers = newHttpHeaders({"X-Master-Key": conf.jsonbinApiKey})
    try:
        let url = "https://api.jsonbin.io/v3/b/" & idMap[inkIdStr] & "/latest"
        let response = client.get(url)
        if response.status.startsWith("2"):
            let data = parseJson(response.body)
            return data["record"]["content"].getStr()
    except: discard
    finally: client.close()
    return ""