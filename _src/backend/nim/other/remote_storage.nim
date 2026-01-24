# wissen-wasser/_src/backend/nim/other/remote_storage.nim
import httpclient, json, strutils, os
import ../other/[types, config]

proc newClient(): HttpClient =
    var apiKey: string
    {.cast(gcsafe).}:
        apiKey = conf.jsonbinApiKey
    
    result = newHttpClient()
    result.headers = newHttpHeaders({
        "X-Master-Key": apiKey,
        "Content-Type": "application/json"
    })

proc fetchIndex*(): JsonNode =
    var binId: string
    {.cast(gcsafe).}:
        binId = conf.jsonbinIndexBinId

    if binId.len == 0:
        echo " [AVISO] JSONBIN_INDEX_BIN_ID não definido no .env"
        return %*{"inkIndex": {}}

    let c = newClient()
    try:
        let url = "https://api.jsonbin.io/v3/b/" & binId & "/latest"
        let r = c.get(url)
        if r.status.startsWith("2"):
            let data = parseJson(r.body)
            return data["record"]
        else:
            echo " [LOG] Índice não encontrado ou vazio. Criando novo."
            return %*{"inkIndex": {}}
    except:
        return %*{"inkIndex": {}}
    finally:
        c.close()

proc saveIndex(index: JsonNode) =
    var binId: string
    {.cast(gcsafe).}:
        binId = conf.jsonbinIndexBinId
    
    if binId.len == 0: return

    let c = newClient()
    try:
        discard c.put("https://api.jsonbin.io/v3/b/" & binId, $index)
        echo " [OK] Tabela de montagem remota (Índice) atualizada."
    except:
        echo " [ERRO] Falha ao salvar índice remoto."
    finally:
        c.close()

proc resolveBinId*(inkId: string): string =
    let index = fetchIndex()
    if index.hasKey("inkIndex") and index["inkIndex"].hasKey(inkId):
        return index["inkIndex"][inkId].getStr()
    ""

proc fetchFromRemote*(inkId: string): string =
    let binId = resolveBinId(inkId)
    if binId.len == 0: 
        echo " [DEBUG] InkID não mapeado no índice: ", inkId
        return ""

    let c = newClient()
    try:
        let url = "https://api.jsonbin.io/v3/b/" & binId & "/latest"
        let r = c.get(url)
        if r.status.startsWith("2"):
            let data = parseJson(r.body)
            # Priorizamos o campo 'content' para o Editor.js não se perder
            if data["record"].hasKey("content"):
                return data["record"]["content"].getStr()
            else:
                return $data["record"]
    except:
        echo " [ERRO] Falha ao ler bin remoto: ", binId
    finally:
        c.close()
    return ""

proc syncToRemote*(doc: WwDocument) =
    let inkId = $doc.header.inkid
    
    let c = newClient()
    # No Nim 1.6.X, usamos []= para modificar headers existentes
    c.headers["X-Bin-Name"] = inkId
    c.headers["X-Bin-Public"] = "false"

    let body = %*{
        "inkid": inkId,
        "content": doc.body.content,
        "updatedAt": $doc.header.updatedAt
    }

    var index = fetchIndex()
    if not index.hasKey("inkIndex"):
        index["inkIndex"] = %*{}

    try:
        var response: Response
        if index["inkIndex"].hasKey(inkId):
            let bId = index["inkIndex"][inkId].getStr()
            response = c.put("https://api.jsonbin.io/v3/b/" & bId, $body)
        else:
            response = c.post("https://api.jsonbin.io/v3/b", $body)
        
        if response.status.startsWith("2"):
            if not index["inkIndex"].hasKey(inkId):
                let respData = parseJson(response.body)
                let newBinId = respData["metadata"]["id"].getStr()
                index["inkIndex"][inkId] = %newBinId
                saveIndex(index)
            echo "Sincronizado: ", inkId
        else:
            echo " [ERRO] Servidor remoto retornou: ", response.status
    except:
        echo "Falha na sincronização."
    finally:
        c.close()