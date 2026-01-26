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

    // 2. Cache Local com Limpeza de Segurança
    let localCache = localStorage.getItem('cache_' + id) || "";
    if (localCache.startsWith('{"content"')) {
        try {
            const parsed = JSON.parse(localCache);
            localCache = parsed.content || "";
        } catch(e) { localCache = ""; }
    }

    // 3. Busca Remota
    try {
        const response = await fetch(`/api/ink/${id}`);
        if (response.ok) {
            const data = await response.json();
            const content = data.content || "";
            localStorage.setItem('cache_' + id, content);
            return content;
        }
    } catch (err) { console.warn("Offline ou Erro de Rede"); }

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