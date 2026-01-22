# wissen-wasser/_src/backend/nim/ww/routes.nim
import jester, json, strutils, os
import dotww, inkid, ww_logic
import ../other/[config, types]

settings:
    port = conf.port.Port
    bindAddr = "0.0.0.0"
    staticDir = "frontend" 

routes:
    # --- FRONTEND ---
    
    get "/":
        # quando o usuário acessar a raiz, entregamos o index.html
        resp readFile(settings.staticDir / "index.html")

    get "/list-inks":
        # lista arquivos na pasta flows
        var files: seq[string] = @[]
        for file in walkFiles("../../../flows/*.ww"):
            files.add(extractFilename(file).replace(".ww", ""))
        resp %files # Retorna um JSON ["id1", "id2"]

    get "/ink.html":
        # garante que o editor também seja servido
        resp readFile(settings.staticDir / "ink.html")

    # --- API ---

    get "/ping":
        resp Http200, l_ping(), "application/json"
    
    post "/ink":
        resp Http201, l_create_ink(request.body), "application/json"
    
    post "/ink/@id":
        resp Http200, l_update_ink(@"id", request.body), "application/json"
    
    post "/ink/@id/overwrite":
        resp Http200, l_overwrite_ink(@"id", request.body), "application/json"

    post "/ink/@id/archive":
        resp Http200, l_archive_ink(@"id"), "application/json"
    
    get "/ink/@id/content":
        let content = l_get_ink_content(@"id")
        if content == "":
            resp Http404, "Not Found"
        else:
            resp Http200, content, "text/plain"

    # --- FALLBACK ---
    # Se nada acima bater, o Jester tenta servir arquivos da staticDir automaticamente.
    # Se ainda assim não achar, damos 404.
    error Http404:
        resp "Arquivo não encontrado ou Rota inválida."