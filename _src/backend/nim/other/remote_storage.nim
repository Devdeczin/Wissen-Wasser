# wissen-wasser/_src/backend/nim/ww/other/remote_storage.nim
import httpclient, json, strutils
import ../other/[types, config]

proc newClient(): HttpClient =
    result = newHttpClient()
    result.headers = newHttpHeaders({
        "X-Master-Key": conf.jsonbinApiKey,
        "Content-Type": "application/json"
    })

proc fetchIndex(): JsonNode =
    if conf.jsonbinIndexBinId.len == 0:
        return %*{"inkIndex": {}}

    let c = newClient()
    try:
        let r = c.get("https://api.jsonbin.io/v3/b/" & conf.jsonbinIndexBinId)
        if not r.status.startsWith("2"):
            return %*{"inkIndex": {}}
        let data = parseJson(r.body)
            return data["record"]
    finally:
        c.close()

proc saveIndex(index: JsonNode) =
    let c = newClient()
    try:
        discard c.put(
            "https://api.jsonbin.io/v3/b/" & conf.jsonbinIndexBinId,
            $%*{"record": index}
        )
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
        return ""

    let c = newClient()
    try:
        let r = c.get("https://api.jsonbin.io/v3/b/" & binId)
        if not r.status.startsWith("2"):
            return ""
        let data = parseJson(r.body)
        return data["record"]["content"].getStr()
    finally:
        c.close()

proc syncToRemote*(doc: WwDocument) =
    let inkId = $doc.header.inkid
    let c = newClient()

    let body = %*{
        "record": {
        "inkid": inkId,
        "content": doc.body.content
        }
    }

    var index = fetchIndex()
    if not index.hasKey("inkIndex"):
        index["inkIndex"] = %*{}

    try:
        if index["inkIndex"].hasKey(inkId):
            let binId = index["inkIndex"][inkId].getStr()
            discard c.put("https://api.jsonbin.io/v3/b/" & binId, $body)
        else:
            let r = c.post("https://api.jsonbin.io/v3/b", $body)
        if r.status.startsWith("2"):
            let resp = parseJson(r.body)
            let newBinId = resp["metadata"]["id"].getStr()
            index["inkIndex"][inkId] = %newBinId
            saveIndex(index)
    finally:
        c.close()