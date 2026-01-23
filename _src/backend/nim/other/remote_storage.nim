# wissen-wasser/_src/backend/nim/ww/other/remote_storage.nim
import httpclient, json, strutils, os, uri
import types, ../ww/dotww, config

proc syncToRemote*(doc: WwDocument) =
    let apiKey = conf.jsonbinApiKey
    if apiKey.len == 0: return

    let client = newHttpClient()
    let inkIdStr = $doc.header.inkid
    
    # Vamos usar o InkID como o nome do Bin para facilitar a busca posterior
    client.headers = newHttpHeaders({
        "X-Master-Key": apiKey,
        "Content-Type": "application/json",
        "X-Bin-Name": inkIdStr,
        "X-Bin-Private": "true"
    })

    let body = %*{ "content": doc.body.content, "inkid": inkIdStr }

    try:
        # Primeiro, tentamos descobrir se já existe um Bin com esse nome
        # A API v3 permite buscar bins. Para simplificar, vamos tentar o POST.
        # Se você quiser perfeição absoluta, use o ID retornado no primeiro POST.
        # Mas para o seu caso de uso, vamos simplificar o "Fetch" abaixo.
        
        let response = client.post("https://api.jsonbin.io/v3/b", $body)
        if response.status.startsWith("2"):
            echo "Sincronizado na nuvem: ", inkIdStr
        else:
            echo "Erro JSONBin: ", response.body
    except:
        echo "Falha de rede ao sincronizar."
    finally:
        client.close()

proc fetchFromRemote*(inkIdStr: string): string =
    # Como não temos banco de dados para guardar o Bin ID,
    # a melhor forma no plano free do JSONBin é listar seus bins e filtrar pelo nome.
    
    let apiKey = conf.jsonbinApiKey
    let client = newHttpClient()
    client.headers = newHttpHeaders({"X-Master-Key": apiKey})
    
    try:
        # Busca a lista de Bins criados por você
        let listResp = client.get("https://api.jsonbin.io/v3/b/list")
        if listResp.status.startsWith("2"):
            let bins = parseJson(listResp.body)
            for bin in bins:
                # Se encontrarmos um bin com o nome igual ao nosso InkID
                if bin.hasKey("snippetMeta") and bin["snippetMeta"]["name"].getStr() == inkIdStr:
                    let binId = bin["record"].getStr()
                    # Agora baixamos o conteúdo desse ID
                    let dataResp = client.get("https://api.jsonbin.io/v3/b/" & binId & "/latest")
                    let record = parseJson(dataResp.body)
                    return record["record"]["content"].getStr()
    except:
        echo "Erro ao buscar na nuvem."
    finally:
        client.close()
    return ""