# wissen-wasser/_src/backend/nim/ww/routes.nim
import jester, json, strutils, os, sequtils
import inkid, ww_logic, storage
import ../other/[config, types, remote_storage]

{.cast(gcsafe).}:
    setupConfig()

settings:
    port = conf.port.Port
    bindAddr = "0.0.0.0"
    staticDir = "frontend"

let localSettings = settings

routes:
    # --- FRONTEND ---
    get "/":
        resp readFile(localSettings.staticDir / "index.html")

    get "/easteregg/daumreal":
        let apiKey = getEnv("INVERTEXTO_API_KEY")
        let pixKey = getEnv("PIX_DEVDECO_DINHEIRO")
        let qrCodeUrl = "https://api.invertexto.com/v1/qrcode?token=" & apiKey & "&text=" & pixKey
        let path = localSettings.staticDir / "easteregg" / "daumreal.html"
        
        if fileExists(path):
            var html = readFile(path)
            html = html.replace("{{QR_CODE_URL}}", qrCodeUrl)
            html = html.replace("{{PIX_KEY}}", pixKey)
            resp html, "text/html"
        else:
            resp(Http404, "Template não encontrado")

    get "/limpa":
        resp """
        <!DOCTYPE html><html><body style="background:black;color:white;font-family:monospace;">
        <h1>LIMPANDO CACHE...</h1><script>localStorage.clear();alert('Cache limpo!');window.location.href='/';</script>
        </body></html>
        """, "text/html"

    get "/ink":
        resp readFile(localSettings.staticDir / "ink.html")
    
    get "/easteregg/@page":
        let filePath = localSettings.staticDir / "easteregg" / (@"page" & ".html")
        if fileExists(filePath):
            resp readFile(filePath)
        else:
            resp Http404, "Este easter egg ainda não foi chocado."

    get "/list-inks":
        var files: seq[string] = @[]
        try:
            let path = getHomeDir() / ".wissen-wasser" / "ink"
            if dirExists(path):
                for kind, file in walkDir(path):
                    if kind == pcDir: files.add(extractFilename(file))
        except: discard
        resp Http200, $(%files), "application/json"

    get "/ink/findpublic/":
        try:
            resp Http200, $fetchPublicInks(), "application/json"
        except:
            resp Http200, "[]", "application/json"

    # --- API ---
    get "/ping":
        resp Http200, l_ping(), "application/json"
    
    post "/ink":
        resp Http201, l_create_ink(request.body), "application/json"
    
    get "/ink/@id":
        let content = l_get_ink_content(@"id")
        if content == "": resp Http404, "Não encontrado."
        else: resp Http200, content, "application/json"
        
    post "/ink/@id":
        if @"id" == "temp-ink": resp Http400, "ID inválido"
        resp Http200, $(l_update_ink(@"id", request.body)), "application/json"

    get "/api/ink/@id":
        let content = l_get_ink_content(@"id")
        if content == "": resp Http404, $(%*{"error": "not found"})
        else: resp Http200, $(%*{"content": content}), "application/json"

    post "/ink/@id/overwrite":
        resp Http200, l_overwrite_ink(@"id", request.body), "application/json"

    post "/ink/@id/archive":
        resp Http200, l_archive_ink(@"id"), "application/json"

    error Http404:
        let msg = "EI! Essa rota não existe, seu burro, não sabe ler?"
        resp """
        <!DOCTYPE html>
        <html lang="pt-br">
        <head>
            <meta charset="UTF-8">
            <title>404 - BURRO!</title>
            <style>
                body { background: #1a1a1a; color: #ff4444; font-family: 'Courier New', monospace; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; text-align: center; }
                .rat { font-size: 50px; margin-bottom: 20px; filter: grayscale(1); }
                .bubble { background: #fff; color: #000; padding: 20px; border-radius: 20px; position: relative; max-width: 80%; border: 4px solid #ff4444; font-weight: bold; }
                .bubble::after { content: ''; position: absolute; bottom: -20px; left: 50%; border-width: 20px 20px 0; border-style: solid; border-color: #fff transparent; display: block; width: 0; margin-left: -20px; }
                h1 { font-size: 80px; margin: 10px 0; }
                a { color: #44ff44; text-decoration: none; margin-top: 30px; border: 2px solid #44ff44; padding: 10px; }
                a:hover { background: #44ff44; color: #000; }
            </style>
        </head>
        <body>
            <div class="bubble">""" & msg & """</div>
            <div class="rat">🐀</div>
            <h1>404</h1>
            <p>O rato está decepcionado com a sua incapacidade de digitar uma URL.</p>
            <a href="/">VOLTAR PARA O INÍCIO (SE CONSEGUIR)</a>
        </body>
        </html>
        """, "text/html"