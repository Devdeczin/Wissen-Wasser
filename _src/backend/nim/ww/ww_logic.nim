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

proc l_update_ink*(idStr: string, body: string): string =
    let id = toInkId(idStr)
    if not inkExists(id):
        return toJsonString(%*{"error": "404: Ink not found"})
    
    var doc = loadDocument(id)
    applyMutation(doc, body)

    saveDocument(doc)
    syncToRemote(doc)
    return toJsonString(%*{
        "inkid": $id,
        "version": doc.header.version,
        "updatedAt": int64(doc.header.updatedAt)
    })

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
    
    # 1. Tenta carregar localmente
    if inkExists(id):
        let doc = loadDocument(id)
        return doc.body.content
    
    # 2. Se não existe local (ex: abriu no Notebook mas foi criado no Kindle)
    # Tenta buscar no JSONBin através do mapeamento
    echo "Ink local não encontrado. Buscando na nuvem..."
    let cloudContent = fetchFromRemote(idStr)
    
    if cloudContent != "":
        var doc = newDotWw(id)
        overwrite(doc, cloudContent)
        saveDocument(doc) 
        return cloudContent
        
    return ""