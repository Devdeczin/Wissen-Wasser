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
        resp readFile(settings.staticDir / "index.html")

    get "/ink.html":
        resp readFile(settings.staticDir / "ink.html")

    get "/list-inks":
        # Lista os diretórios dentro de ~/.wissen-wasser/ink/
        var files: seq[string] = @[]
        let path = getHomeDir() / ".wissen-wasser" / "ink"
        if dirExists(path):
            for kind, file in walkDir(path):
                if kind == pcDir:
                    files.add(extractFilename(file))
        resp %files

    # --- API ---

    get "/ping":
        resp Http200, l_ping(), "application/json"
    
    # Criar novo (Novo documento)
    post "/ink":
        resp Http201, l_create_ink(request.body), "application/json"
    
    # Carregar conteúdo (Usado pelo Editor no Notebook)
    get "/ink/@id":
        let content = l_get_ink_content(@"id")
        if content == "":
            resp Http404, "Ink não encontrado localmente nem na nuvem."
        else:
            # Retornamos texto puro para o editor injetar no innerText
            resp Http200, content, "text/plain"
    
    # Atualizar existente (O manualSave() do Kindle/Notebook envia para cá)
    post "/ink/@id":
        resp Http200, l_update_ink(@"id", request.body), "application/json"
        
    post "/ink/@id/overwrite":
        resp Http200, l_overwrite_ink(@"id", request.body), "application/json"

    post "/ink/@id/archive":
        resp Http200, l_archive_ink(@"id"), "application/json"

    # Fallback para erros
    error Http404:
        resp "Wissen-Wasser: Rota não encontrada ou recurso inexistente."