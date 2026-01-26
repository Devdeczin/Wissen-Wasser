// wissen-wasser/_src/frontend/js/core.js
async function fetchInkContent(id) {
    const specialIds = { '0000-0000': 'docs/manual.md', 'TERM-USER': 'docs/terms.md' };

    if (specialIds[id]) {
        try {
            const response = await fetch('/' + specialIds[id]);
            if (response.ok) return await response.text();
            return "# Erro 404\nArquivo não encontrado no servidor.";
        } catch (err) {
            return "# Erro de Conexão\nNão foi possível carregar o documento.";
        }
    }

    const localCache = localStorage.getItem('cache_' + id);
    
    let cleanCache = localCache;
    if (localCache && localCache.startsWith('{"content"')) {
        try {
            const parsed = JSON.parse(localCache);
            cleanCache = parsed.content;
        } catch(e) { /* não é JSON */ }
    }

    try {
        const response = await fetch(`/api/ink/${id}`);
        if (response.ok) {
            const data = await response.json(); 
            const content = data.content || "";
            localStorage.setItem('cache_' + id, content);
            return content;
        }
    } catch (err) {
        console.warn("Kindle Offline: Usando cache.");
    }

    return cleanCache || "";
}

async function apiSaveInk(id, payload) {
    // Se for modo leitura ou offline, não tenta o servidor
    if (id === '0000-0000' || localStorage.getItem('ww_offline_mode') === 'true') return id;

    const isNew = (!id || id === 'temp-ink');
    const url = isNew ? '/ink' : `/ink/${id}`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Accept': 'application/json' 
            },
            body: payload
        });

        if (response.ok) {
            const text = await response.text(); // Lemos como texto primeiro
            try {
                const data = JSON.parse(text); // Tentamos converter para objeto
                if (isNew && data.inkid) {
                    const newUrl = `?id=${data.inkid}`;
                    window.history.pushState({}, '', newUrl);
                    return data.inkid;
                }
                return id;
            } catch (e) {
                console.error("Erro ao processar JSON da resposta:", text);
                return id; // Retorna o ID atual para não dar erro visual
            }
        }
    } catch (err) { 
        console.error("Erro na comunicação com o servidor:", err); 
    }
    return false; // Indica falha total
}

async function manualSave() {
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';
    const content = getAllPagesContent();
    const isPublic = document.getElementById('public-toggle')?.checked || false;

    const payload = JSON.stringify({ content, visibleForAll: isPublic, last_modified: Date.now() });
    localStorage.setItem('cache_' + inkId, content);

    const result = await apiSaveInk(inkId, payload);
    const status = document.getElementById('status');
    if (status) status.innerText = result ? `Salvo: ${result}` : "Erro ao salvar";
}