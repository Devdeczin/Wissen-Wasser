# wissen-wasser/_src/backend/nim/ww/routes.nim
import jester, json, strutils, os
import dotww, inkid, ww_logic
import ../other/[config, types, remote_storage]

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

    # Dev
    post "/dev/list-local-cache":
        if not isDev:
            halt(Http403, "Dev routes disabled")

        let path = getHomeDir() / ".wissen-wasser" / "ink"
        var files: seq[string] = @[]

        if dirExists(path):
            for kind, f in walkDir(path):
            if kind == pcDir:
                files.add(extractFilename(f))

        resp %files

    post "/dev/ink/delete":
        let body = parseJson(request.body)
        let ids = body["ids"].getElems().mapIt(it.getStr())

        deleteInksByString(ids)

        resp %*{
            "status": "ok",
            "deleted": ids.len
        }

    post "/dev/ink/delete-by-prefix":
        if not isDev:
            halt(Http403, "Dev routes disabled")

        if request.body.len == 0:
            halt(Http400, "Missing request body")

        let body = parseJson(request.body)

        if not body.hasKey("prefix"):
            halt(Http400, "Expected JSON: { prefix: \"abcd\" }")

        let prefix = body["prefix"].getStr()

        if prefix.len == 0:
            halt(Http400, "Prefix cannot be empty")

        let deleted = deleteInksByPrefix(prefix)

        resp %*{
            "status": "ok",
            "prefix": prefix,
            "deleted": deleted
        }

    # Fallback para erros
    error Http404:
        resp "Wissen-Wasser: Rota não encontrada ou recurso inexistente."