# wissen-wasse/_src/backend/nim/ww/storage.nim
# persistência local do Wissen Wasser
# confia, mas não confia
import os, strutils, json
import dotww, inkid
import ../other/types

const
    WwRoot* = ".wissen-wasser"
    InkDir* = "ink"
    MainFile* = "main.ww"
    HistoryDir* = "history"
            
proc rootPath*(): string  =
    getHomeDir() / WwRoot

proc inkPath*(id: InkId): string  =
    rootPath() / InkDir / $id

proc mainFilePath*(id: InkId): string  =
    inkPath(id) / MainFile

proc historyPath*(id: InkId): string  =
    inkPath(id) / HistoryDir

proc ensureInkDirs*(id: InkId)  =
    createDir(rootPath())
    createDir(rootPath() / InkDir)
    createDir(inkPath(id))
    createDir(historyPath(id))

# escrita
proc saveDocument*(doc: WwDocument)  =
    ensureInkDirs(doc.header.inkid)

    # snapshot histórico simples
    let histFile =
        historyPath(doc.header.inkid) /
        ("v" & $doc.header.version & ".ww")

    writeFile(histFile, doc.toWw())
    writeFile(mainFilePath(doc.header.inkid), doc.toWw())

proc loadDocument*(id: InkId): WwDocument  =
    let path = mainFilePath(id)
    if not fileExists(path):
        raise newException(IOError, "document not found")

    parseWw(readFile(path))

proc inkExists*(id: InkId): bool  =
    fileExists(mainFilePath(id))

proc preview*(doc: WwDocument, maxLen: int = 512): string  =
    if doc.body.content.len <= maxLen:
        doc.body.content
    else:
        doc.body.content[0 ..< maxLen] & "…"

proc deleteInksByPrefix*(prefix: string): int =
    let base = rootPath() / InkDir
    var count = 0

    if not dirExists(base):
        return 0

    for kind, path in walkDir(base):
        if kind == pcDir and extractFilename(path).startsWith(prefix):
            removeDir(path)
            count.inc

    count

proc deleteInksByString*(ids: seq[string]) =
    for idStr in ids:
        let id = toInkId(idStr)
        let path = inkPath(id)
        if dirExists(path):
            removeDir(path)