# wissen-wasser/_src/backend/nim/ww/other/remote_storage.nim
import httpclient, json, strutils, os
import types, ../ww/dotww, config

proc syncToRemote*(doc: WwDocument) =
    let apiKey = conf.jsonbinApiKey
    if apiKey.len == 0: return

    let client = newHttpClient()
    # cabeçalhos exigidos pela API v3 do JSONBin
    client.headers = newHttpHeaders({
        "Content-Type": "application/json",
        "X-Access-Key": apiKey,
        "X-Bin-Name": $doc.header.inkid, # nomeia o bin com o ID do seu ink
        "X-Bin-Private": "true"
    })

    let body = %*{
        "metadata": {
            "inkid": $doc.header.inkid,
            "version": doc.header.version
        },
        "content": doc.body.content
    }

    try:
        let response = client.post("https://api.jsonbin.io/v3/b", $body)
        if response.status.startsWith("2"):
            echo "Sincronizado com sucesso: ", doc.header.inkid
        else:
            echo "Erro na sincronização: ", response.body
    except:
        echo "Falha crítica na rede ao tentar sincronizar."
    finally:
        client.close()