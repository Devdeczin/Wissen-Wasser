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

{.cast(gcsafe).}:
    routes:
        # --- FRONTEND ---
        get "/":
            resp readFile(settings.staticDir / "index.html")

        get "/easteregg/daumreal":
            let apiKey = getEnv("INVERTEXTO_API_KEY")
            let pixKey = getEnv("PIX_DEVDECO_DINHEIRO")
            let qrCodeUrl = "https://api.invertexto.com/v1/qrcode?token=" & apiKey & "&text=" & pixKey
            let path = "frontend/easteregg/daumreal.html"
            
            if fileExists(path):
                var html = readFile(path)
                html = html.replace("{{QR_CODE_URL}}", qrCodeUrl)
                html = html.replace("{{PIX_KEY}}", pixKey)
                resp html, "text/html"
            else:
                resp(Http404, "Template não encontrado")

        get "/limpa":
            resp """
            <!DOCTYPE html>
            <html>
            <body style="background:black;color:white;font-family:monospace;">
                <h1>LIMPANDO CACHE...</h1>
                <script>
                localStorage.clear();
                alert('Cache limpo! Voltando para o dashboard...');
                window.location.href = '/';
                </script>
            </body>
            </html>
            """, "text/html"

        get "/ink":
            resp readFile(settings.staticDir / "ink.html")
        
        post "/ink/@id/sync":
            resp l_update_ink(@"id", request.body)
            
        get "/easteregg/@page":
            let page = @"page"
            let filePath = settings.staticDir / "easteregg" / (page & ".html")
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
                        if kind == pcDir:
                            files.add(extractFilename(file))
            except:
                echo " [ERRO] Falha ao listar inks."
            resp Http200, $(%files), "application/json"

        get "/ink/findpublic/":
            try:
                let publicInks = fetchPublicInks()
                resp Http200, $publicInks, "application/json"
            except:
                resp Http200, "[]", "application/json"

        # --- API ---
        get "/ping":
            resp Http200, l_ping(), "application/json"
        
        post "/ink":
            resp Http201, l_create_ink(request.body), "application/json"
        
        get "/ink/@id":
            let content = l_get_ink_content(@"id")
            if content == "":
                resp Http404, "Ink não encontrado."
            else:
                resp Http200, content, "application/json"
            
        post "/ink/@id":
            let id = @"id"
            if id == "temp-ink":
                resp Http400, $(%*{"status": "error", "message": "ID inválido"}), "application/json"
            let responseNode = l_update_ink(id, request.body)
            resp Http200, $responseNode, "application/json"

        get "/api/ink/@id":
            let content = l_get_ink_content(@"id")
            if content == "":
                resp Http404, $(%*{"error": "not found"}), "application/json"
            else:
                resp Http200, $(%*{"content": content}), "application/json"

        post "/ink/@id/overwrite":
            resp Http200, l_overwrite_ink(@"id", request.body), "application/json"

        post "/ink/@id/archive":
            resp Http200, l_archive_ink(@"id"), "application/json"