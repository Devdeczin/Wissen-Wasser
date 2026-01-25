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

    # se ele ficar lá em baixo, não funciona (por algum motivo)
    get "/easteregg/daumreal":
        let apiKey = getEnv("INVERTEXTO_API_KEY")
        let pixKey = getEnv("PIX_DEVDECO_DINHEIRO")
        
        # Debug no terminal para conferir se as variáveis subiram
        echo "[DEBUG] API:", apiKey
        echo "[DEBUG] PIX:", pixKey

        let qrCodeUrl = "https://api.invertexto.com/v1/qrcode?token=" & apiKey & "&text=" & pixKey

        # Buscamos o arquivo (ajuste o caminho se necessário)
        let path = "frontend/easteregg/daumreal.html"
        
        if fileExists(path):
            var html = readFile(path)
            html = html.replace("{{QR_CODE_URL}}", qrCodeUrl)
            html = html.replace("{{PIX_KEY}}", pixKey)
            
            # O segredo: 'resp' com o conteúdo e o tipo explícito
            resp html, "text/html"
        else:
            resp(Http404, "Template não encontrado")

    get "/":
        {.cast(gcsafe).}:
            resp readFile(settings.staticDir / "index.html")

    get "/ink":
        {.cast(gcsafe).}:
            resp readFile(settings.staticDir / "ink.html")
        
    get "/easteregg/@page": # gemini, você é genial
        let page = @"page"
        let filePath = settings.staticDir / "easteregg" / (page & ".html")
        if fileExists(filePath):
            {.cast(gcsafe).}:
                resp readFile(filePath)
        else:
            resp Http404, "Este easter egg ainda não foi chocado."

    get "/list-inks":
            {.cast(gcsafe).}:
                var files: seq[string] = @[]
                try:
                    let path = getHomeDir() / ".wissen-wasser" / "ink"
                    if dirExists(path):
                        for kind, file in walkDir(path):
                            if kind == pcDir:
                                files.add(extractFilename(file))
                except:
                    echo " [ERRO] Falha ao listar inks. Retornando vazio."
                    
                resp Http200, $(%files), "application/json"

    get "/ink/findpublic/":
        {.cast(gcsafe).}:
            try:
                let publicInks = fetchPublicInks()
                resp Http200, $publicInks, "application/json"
            except:
                echo " [ERRO] Falha ao buscar públicos."
                resp Http200, "[]", "application/json"
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
            let b = request.body
            let i = @"id"
            resp l_update_ink(i, b)

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