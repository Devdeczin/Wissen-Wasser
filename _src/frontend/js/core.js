// wissen-wasser/_src/frontend/js/core.js
async function fetchInkContent(id) {
    const specialIds = { '0000-0000': 'docs/manual.md', 'TERM-USER': 'docs/terms.md' };

    // 1. Documentos Oficiais
    if (specialIds[id]) {
        try {
            const response = await fetch('/' + specialIds[id]);
            if (response.ok) return await response.text();
        } catch (err) { return "# Erro ao carregar documento."; }
    }

    let localCache = localStorage.getItem('cache_' + id) || "";
    
    if (localCache.includes('"content":')) {
        try {
            const temp = JSON.parse(localCache);
            localCache = temp.content || "";
        } catch(e) {}
    }

    try {
        const response = await fetch(`/ink/${id}`);
        if (response.ok) {
            const content = await response.text();
            localStorage.setItem('cache_' + id, content);
            return content;
        }
    } catch (err) {
        console.warn("Usando cache local limpo.");
    }
    return localCache;
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
    } catch (err) { console.error("Erro no fetch de salvamento"); }
    return false;
}

async function manualSave() {
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';
    const content = getAllPagesContent();
    const isPublic = document.getElementById('public-toggle')?.checked || false;

    localStorage.setItem('cache_' + inkId, content);
    const result = await apiSaveInk(inkId, JSON.stringify({ content, visibleForAll: isPublic, last_modified: Date.now() }));
    
    const status = document.getElementById('status');
    if (status) status.innerText = result ? `Salvo: ${result}` : "Erro de Sincro";
}