# wissen-wasser/_src/backend/nim/ww/dotww.nim
import strutils
import ../other/types

proc newDotWw*(id: InkId): WwDocument =
    let now = nowTs()
    WwDocument(
        header: WwHeader(
            inkid: id,
            createdAt: now,
            updatedAt: now,
            state: wdsDraft,
            version: 1
        ),
        body: WwBody(content: "")
    )

proc applyMutation*(doc: var WwDocument, payload: string) =
    if doc.header.state == wdsArchived:
        raise newException(ValueError, "document is archived")

    doc.body.content.add(payload)
    doc.header.version.inc
    doc.header.updatedAt = nowTs()

proc overwrite*(doc: var WwDocument, newContent: string) =
    if doc.header.state == wdsArchived:
        raise newException(ValueError, "document is archived")

    doc.body.content = newContent
    doc.header.version.inc
    doc.header.updatedAt = nowTs()

proc archive*(doc: var WwDocument) =
    doc.header.state = wdsArchived
    doc.header.updatedAt = nowTs()

proc activate*(doc: var WwDocument) =
    if doc.header.state == wdsArchived:
        raise newException(ValueError, "cannot reactivate archived document")

    doc.header.state = wdsActive
    doc.header.updatedAt = nowTs()

proc toWw*(doc: WwDocument): string =
    result = "" # Inicializa a string result
    result.add "# WW\n"
    result.add "inkid: " & $doc.header.inkid & "\n"
    result.add "created: " & $doc.header.createdAt & "\n"
    result.add "updated: " & $doc.header.updatedAt & "\n"
    result.add "state: " & $doc.header.state & "\n"
    result.add "version: " & $doc.header.version & "\n"
    result.add "\n"
    result.add doc.body.content

proc parseWw*(raw: string): WwDocument =
    let lines = raw.splitLines()

    var headerEnded = false
    var bodyLines: seq[string] = @[]
    var hdr: WwHeader

    for line in lines:
        # Se encontrar linha vazia, o cabeçalho acabou
        if line.len == 0 and not headerEnded:
            headerEnded = true
            continue # Pula a linha vazia e vai para a próxima

        if not headerEnded:
            let parts = line.split(": ", 1)
            if parts.len != 2: continue # Pula linhas de cabeçalho mal formatadas

            case parts[0]
            of "inkid":
                hdr.inkid = toInkId(parts[1])
            of "created":
                hdr.createdAt = Timestamp(parseInt(parts[1]))
            of "updated":
                hdr.updatedAt = Timestamp(parseInt(parts[1]))
            of "state":
                hdr.state = parseEnum[WwDocState](parts[1])
            of "version":
                hdr.version = parseInt(parts[1])
            else:
                discard
        else:
            # Tudo que vem após a primeira linha vazia é corpo
            bodyLines.add(line)

    result = WwDocument(
        header: hdr,
        body: WwBody(content: bodyLines.join("\n"))
    )