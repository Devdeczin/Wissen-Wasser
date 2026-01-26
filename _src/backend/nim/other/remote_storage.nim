# wissen-wasser/_src/backend/nim/other/remote_storage.nim
import httpclient, json, strutils, os
import ../other/[types, config]

{.cast(gcsafe).}:
    setupConfig()

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
    let idStr = $doc.header.inkid
    if idStr == "temp-ink": return

    var apiKey: string
    {.cast(gcsafe).}:
        apiKey = conf.jsonbinApiKey

    let c = newClient()
    c.headers["X-Bin-Name"] = idStr
    c.headers["X-Master-Key"] = apiKey
    
    let body = %*{
        "inkid": idStr,
        "content": doc.body.content,
        "updatedAt": $doc.header.updatedAt,
        "visibleForAll": doc.header.visibleForAll
    }

    var index = fetchIndex()
    try:
        var response: Response
        if index.hasKey("inkIndex") and index["inkIndex"].hasKey(idStr):
            let bId = index["inkIndex"][idStr].getStr()
            response = c.put("https://api.jsonbin.io/v3/b/" & bId, $body)
        else:
            response = c.post("https://api.jsonbin.io/v3/b", $body)
        
        if response.status.startsWith("2"):
            let respData = parseJson(response.body)
            if not index.hasKey("inkIndex") or not index["inkIndex"].hasKey(idStr):
                let newBinId = respData["metadata"]["id"].getStr()
                if not index.hasKey("inkIndex"): index["inkIndex"] = %*{}
                index["inkIndex"][idStr] = %newBinId
                saveIndex(index)
            echo " [OK] Sincronizado: ", idStr
    except:
        echo " [ERRO] Falha crítica na sincronização remota."
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

proc l_update_ink*(idStr: string, body: string): JsonNode =
    let id = idStr.toInkId()
    var contentToSave = ""
    var visible = false
    
    try:
        let j = parseJson(body)
        contentToSave = if j.hasKey("content"): j["content"].getStr() else: body
        if j.hasKey("visibleForAll"): visible = j["visibleForAll"].getBool()
    except:
        echo " [AVISO] Falha ao processar JSON no update, usando body como texto puro."
        contentToSave = body

    var doc: WwDocument
    try:
        if not inkExists(id):
            doc = newDotWw(id)
        else:
            doc = loadDocument(id)

        doc.body.content = contentToSave
        doc.header.updatedAt = nowTs()
        doc.header.visibleForAll = visible
        
        saveDocument(doc)
        try:
            syncToRemote(doc)
        except:
            echo " [ERRO] Sincronização remota falhou, mas dado salvo localmente."
            
        return %*{"status": "ok", "inkid": idStr}
    except Exception as e:
        echo " [ERRO CRÍTICO] Falha ao salvar documento: ", e.msg
        return %*{"status": "error", "msg": e.msg}