# wissen-wasser/_src/backend/nim/ww/routes.nim
import jester, json, strutils, os, sequtils
import inkid, ww_logic, storage
import ../other/[config, types, remote_storage]

setupConfig()

settings:
    port = conf.port.Port
    bindAddr = "0.0.0.0"
    staticDir = "frontend"
    
routes:
    # --- FRONTEND ---
    get "/":
        {.cast(gcsafe).}:
            resp readFile(settings.staticDir / "index.html")

    get "/ink.html":
        {.cast(gcsafe).}:
            resp readFile(settings.staticDir / "ink.html")

    get "/list-inks":
        {.cast(gcsafe).}:
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
    
    post "/ink":
        resp Http201, l_create_ink(request.body), "application/json"
    
    get "/ink/@id":
        let id = @"id"
        echo " [ROTAS] Requisição recebida para ID: ", id
        let content = l_get_ink_content(id)
        if content == "":
            resp Http404, "Ink não encontrado localmente nem na nuvem."
        else:
            resp Http200, content, "application/json"
        
    post "/ink/@id":
        var b = request.body
        var i = @"id"
        resp Http200, l_update_ink(i, b), "application/json"
        
    post "/ink/@id/overwrite":
        resp Http200, l_overwrite_ink(@"id", request.body), "application/json"

    post "/ink/@id/archive":
        # Corrigida a indentação aqui
        {.cast(gcsafe).}:
            resp Http200, l_archive_ink(@"id"), "application/json"

    # --- DEV ROUTES ---
    post "/dev/list-local-cache":
        if not DEV_ENABLED: halt(Http403, "Disabled")
        let path = getHomeDir() / ".wissen-wasser" / "ink"
        var files: seq[string] = @[]
        if dirExists(path):
            for kind, f in walkDir(path):
                if kind == pcDir: files.add(extractFilename(f))
        resp %files

    post "/dev/ink/delete":
        if not DEV_ENABLED: halt(Http403, "Disabled")
        let body = parseJson(request.body)
        let ids = body["ids"].getElems().mapIt(it.getStr())
        deleteInksByString(ids)
        resp %*{"status": "ok", "deleted": ids.len}

    post "/dev/ink/delete-by-prefix":
        if not DEV_ENABLED: halt(Http403, "Disabled")
        let body = parseJson(request.body)
        let prefix = body["prefix"].getStr()
        let deleted = deleteInksByPrefix(prefix)
        resp %*{"status": "ok", "prefix": prefix, "deleted": deleted}

    error Http404:
        resp "Wissen-Wasser: Rota não encontrada ou recurso inexistente."