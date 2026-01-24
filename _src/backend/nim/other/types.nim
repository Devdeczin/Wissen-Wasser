# wissen-wasse/_src/backend/ww/other/types.nim
# ww/types.nim
import times, json, os

const
    InkEntropy* = 0xC0FFEE
    WWSeed* = "wissen-wasser"
    InkFragmentSize* = 4

type
    InkId*     = distinct string
    Timestamp* = distinct uint64

    WwDocState* = enum
        wdsDraft
        wdsActive
        wdsArchived

    WwMutationKind* = enum
        wmkAppend
        wmkOverwrite
        wmkAnnotate

    WwHeader* = object
        inkid*: InkId
        createdAt*: Timestamp
        updatedAt*: Timestamp
        state*: WwDocState
        version*: int
        visibleForAll*: bool

    WwBody* = object
        content*: string

    WwDocument* = object
        header*: WwHeader
        body*: WwBody

    WwMutation* = object
        kind*: WwMutationKind
        payload*: string
        timestamp*: Timestamp

const DEV_ENABLED* = defined(dev)
let isDev* = DEV_ENABLED or getEnv("WW_DEV", "0") == "1"

proc nowTs*(): Timestamp =
    Timestamp(getTime().toUnix())

proc `$`*(id: InkId): string = string(id)
proc toInkId*(s: string): InkId = InkId(s)

proc `$`*(ts: Timestamp): string =
    $(int64(ts))

proc toJson*(doc: WwDocument): JsonNode =
    %*{
        "inkid": $doc.header.inkid,
        "createdAt": int64(doc.header.createdAt),
        "updatedAt": int64(doc.header.updatedAt),
        "state": $doc.header.state,
        "version": doc.header.version,
        "visibleForAll": doc.header.visibleForAll,
        "content": doc.body.content
    }