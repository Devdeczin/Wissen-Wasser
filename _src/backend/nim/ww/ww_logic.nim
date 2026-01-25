# wissen-wasser/_src/backend/ww/logic.nim
import json, strutils, times
import storage, dotww, inkid
import ../other/[types, remote_storage]

proc toJsonString(n: JsonNode): string =
    return $n

proc l_ping*(): string =
    return toJsonString(%*{"status": "pong"})

proc l_create_ink*(body: string): string =
    let id = generatedInkId(body)
    var doc = newDotWw(id)
    if body.len > 0:
        applyMutation(doc, body)
    saveDocument(doc)
    syncToRemote(doc)
    return toJsonString(%*{
        "inkid": $id,
        "version": doc.header.version
    })

proc l_update_ink*(idStr: string, body: string): JsonNode =
    let id = idStr.toInkId()
    let j = parseJson(body)
    
    var doc: WwDocument
    if not inkExists(id):
        doc = newDotWw(id)
        echo " [LOG] Criando novo documento via Update: ", idStr
    else:
        doc = loadDocument(id)

    doc.body.content = j["content"].getStr()
    if j.hasKey("visibleForAll"):
        doc.header.visibleForAll = j["visibleForAll"].getBool()
    
    doc.header.updatedAt = nowTs()
    saveDocument(doc)
    syncToRemote(doc)
    
    return %*{"status": "ok"}

proc l_overwrite_ink*(idStr: string, body: string): string =
    let id = toInkId(idStr)
    if not inkExists(id):
        return toJsonString(%*{"error": "404: Ink not found"})

    var doc = loadDocument(id)
    overwrite(doc, body)

    saveDocument(doc)
    syncToRemote(doc)
    return toJsonString(%*{
        "inkid": $id,
        "version": doc.header.version
    })

proc l_archive_ink*(idStr: string): string =
    let id = toInkId(idStr)
    if not inkExists(id):
        return toJsonString(%*{"error": "404: Ink not found"})

    var doc = loadDocument(id)
    archive(doc)

    saveDocument(doc)
    syncToRemote(doc)
    return toJsonString(%*{
        "inkid": $id,
        "state": $doc.header.state
    })

proc l_get_ink_content*(idStr: string): string =
    let id = toInkId(idStr)
    
    # 1. Tenta Local
    if inkExists(id):
        try:
            let doc = loadDocument(id)
            return doc.body.content
        except:
            discard

    # 2. Tenta Remoto (JSONBin)
    echo " [LOG] Não encontrado localmente. Tentando nuvem para: ", idStr
    let remoteContent = fetchFromRemote(idStr)
    if remoteContent.len > 0:
        return remoteContent
        
    return ""