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
    try {
        const response = await fetch(`/api/ink/${id}`);
        if (response.ok) {
            const data = await response.json(); 
            localStorage.setItem('cache_' + id, data.content || "");
            return data.content || "";
        }
    } catch (err) { console.warn("Modo offline."); }
    return localCache || "";
}

async function apiSaveInk(id, payload) {
    if (id === '0000-0000' || localStorage.getItem('ww_offline_mode') === 'true') return id;
    const isNew = (!id || id === 'temp-ink');
    const url = isNew ? '/ink' : `/ink/${id}`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: payload
        });
        if (response.ok) {
            const data = await response.json();
            if (isNew && data.inkid) {
                window.history.pushState({}, '', `?id=${data.inkid}`);
                return data.inkid;
            }
            return id;
        }
    } catch (err) { console.error("Erro API:", err); }
    return false;
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