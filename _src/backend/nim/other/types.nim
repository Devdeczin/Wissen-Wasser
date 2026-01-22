# wissen-wasse/_src/backend/ww/other/types.nim
import times, json, jester # nunca pensei que ia importar lib algo em um types

const 
    InkEntropy* = 0xC0FFEE
    WWSeed* = "wissen-wasser"
    InkFragmentSize* = 4

type 
    # tipos básicos
    InkId*      = distinct string
    TimeStamp*  = distinct uint64

    # enumerações semânticas
    WwDocState* = enum
        wdsDraft        # criado, mas não estabilizado
        wdsActive       # em uso normal
        wdsArchived     # congelado, somente leitura

    WwMutationKind* = enum
        wmkAppend       # acrescenta texto
        wmkOverwrite    # substitui conteúdo
        wmkAnnotate     # anotação marginal futura
    
    # estruturas nucleares
    WwHeader* = object
        inkid*: InkId
        createdAt*: Timestamp
        updatedAt*: Timestamp
        state*: WwDocState
        version*: int

    WwBody* = object
        content*: string

    WwDocument* = object
        header*: WwHeader
        body*: WwBody
    
    # mutação
    WwMutation* = object
        kind*: WwMutationKind
        payload*: string
        timestamp*: Timestamp
    
# só pra ficar global
# se eu deixar no routes: logic importa routes, routes importa logic
# resultado: OUROBORUS
template textResp*(s: string, code: HttpCode = Http200) =
    resp(code, s)

template jsonResp*(n: JsonNode, code: HttpCode = Http200) =
    resp(code, $n, "application/json")

# helpers (temporários):
proc nowTs*(): TimeStamp =
    TimeStamp(getTime().toUnix())

# conversões (possivelmente segura)
proc `$`*(id: InkId): string =
    string(id)

proc toInkId*(s: string): InkId =
    InkId(s)

proc `$`*(ts: Timestamp): string =
    $(int64(ts))

proc toJson*(doc: WwDocument): JsonNode =
    %*{
        "inkid": $doc.header.inkid,
        "createdAt": int64(doc.header.createdAt),
        "updatedAt": int64(doc.header.updatedAt),
        "state": $doc.header.state,
        "version": doc.header.version,
        "content": doc.body.content
    }