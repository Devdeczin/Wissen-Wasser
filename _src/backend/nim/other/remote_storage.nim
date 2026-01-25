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
            let record = data["record"]
            if not record.hasKey("inkIndex"):
                return %*{"inkIndex": {}}
            return record
        else:
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

proc syncToRemote*(doc: WwDocument) =
    let inkId = $doc.header.inkid
    if inkId == "temp-ink": return

    let c = newClient()
    c.headers["X-Bin-Name"] = inkId
    
    let body = %*{
        "inkid": inkId,
        "content": doc.body.content,
        "updatedAt": $doc.header.updatedAt,
        "visibleForAll": doc.header.visibleForAll
    }

    var index = fetchIndex()
    try:
        var response: Response
        if index.hasKey("inkIndex") and index["inkIndex"].hasKey(inkId):
            let bId = index["inkIndex"][inkId].getStr()
            echo " [DEBUG] Atualizando Bin existente: ", bId
            response = c.put("https://api.jsonbin.io/v3/b/" & bId, $body)
        else:
            echo " [DEBUG] Criando NOVO Bin para: ", inkId
            response = c.post("https://api.jsonbin.io/v3/b", $body)
        
        if response.status.startsWith("2"):
            let respData = parseJson(response.body)
            if not index.hasKey("inkIndex") or not index["inkIndex"].hasKey(inkId):
                let newBinId = respData["metadata"]["id"].getStr()
                if not index.hasKey("inkIndex"): index["inkIndex"] = %*{}
                index["inkIndex"][inkId] = %newBinId
                saveIndex(index)
                echo " [OK] Novo Bin vinculado ao índice."
            echo " [OK] Conteúdo sincronizado com sucesso."
        else:
            echo " [ERRO] JSONBin recusou os dados: ", response.status, " - ", response.body
    except:
        echo " [CRÍTICO] Falha na conexão com JSONBin."
    finally:
        c.close()

proc fetchPublicInks*(): JsonNode =
    result = newJArray()
    let index = fetchIndex()
    if not index.hasKey("inkIndex"): return

    let c = newClient()
    try:
        for inkId, binId in index["inkIndex"].pairs:
            let url = "https://api.jsonbin.io/v3/b/" & binId.getStr() & "/latest"
            let r = c.get(url)
            if r.status.startsWith("2"):
                let data = parseJson(r.body)["record"]
                if data.hasKey("visibleForAll") and data["visibleForAll"].getBool():
                    result.add(%*{"id": inkId, "preview": data["content"].getStr().substr(0, 60) & "..."})
    except:
        echo " [ERRO] Falha ao varrer inks públicos."
    finally:
        c.close()

proc fetchFromRemote*(inkId: string): string =
    # 1. Descobre qual o Bin ID associado a esse Ink ID
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
            # O JSONBin retorna os dados dentro de "record"
            let record = data["record"]
            if record.hasKey("content"):
                return record["content"].getStr()
            else:
                return $record # Fallback
    except:
        echo " [ERRO] Falha ao ler bin remoto: ", binId
    finally:
        c.close()
    return ""