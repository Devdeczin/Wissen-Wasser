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

{.push gcsafe: on.}
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
            {.cast(gcsafe).}:
                resp readFile(settings.staticDir / "ink.html")
        
        post "/ink/@id/sync":
            let id = @"id"
            let body = request.body
            resp l_update_ink(id, body)
            
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
            let id = @"id"
            if id == "temp-ink":
                resp Http400, $(%*{"status": "error", "message": "ID temporário não permitido (burro)"}), "application/json"
            
            let body = request.body
            let responseNode = l_update_ink(id, body)
            resp Http200, $responseNode, "application/json"
        
        post "/ink/@id/sync":
            let id = @"id"
            if id == "temp-ink":
                resp Http400, "ID inválido", "text/plain"
            
            let body = request.body
            let responseNode = l_update_ink(id, body)
            resp Http200, $responseNode, "application/json"

        get "/api/ink/@id":
            let id = @"id"
            let content = l_get_ink_content(id)
            if content == "":
                resp Http404, $(%*{"error": "not found"}), "application/json"
            else:
                resp Http200, $(%*{"content": content}), "application/json"

        post "/ink/@id/overwrite":
            resp Http200, l_overwrite_ink(@"id", request.body), "application/json"

        post "/ink/@id/archive":
            {.cast(gcsafe).}:
                resp Http200, l_archive_ink(@"id"), "application/json"
{.pop.}