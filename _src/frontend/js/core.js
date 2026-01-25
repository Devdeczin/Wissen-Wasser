// wissen-wasser/_src/frontend/js/core.js
async function fetchInkContent(id) {
    // 1. Curto-circuito para o Manual de Instruções
    if (id === '0000-0000') {
        return `# Wissen-Wasser: Manual de Uso
Bem-vindo ao seu editor minimalista focado em escrita pura.

## Atalhos e Markdown:
- # Título: Digite # e Espaço para criar um título.
- ## Subtítulo: Digite ## e Espaço.
- Lista: Digite - e Espaço para listas.

## Dicas:
- Configurações: Clique 5 vezes ou segure a logo WISSEN-WASSER no topo.
- Modo Kindle: O site detecta automaticamente e ajusta o contraste e fontes.
- Sincronização: Seus Inks são salvos no cache do navegador e na nuvem.

Este manual é apenas leitura e reside apenas no seu dispositivo.`;
    }

    if (!id || id === 'temp-ink') return "";

    if (localStorage.getItem('ww_offline_mode') === 'true') {
        return localStorage.getItem('cache_' + id) || "Arquivo não disponível offline.";
    }

    try {
        const response = await fetch(`/ink/${id}`);
        if (response.ok) {
            const data = await response.text();
            localStorage.setItem('cache_' + id, data);
            try {
                const json = JSON.parse(data);
                return json.record ? json.record.content : (json.content || data);
            } catch (e) { return data; }
        }
    } catch (err) { console.warn("Usando cache."); }
    return localStorage.getItem('cache_' + id) || "";
}

async function apiSaveInk(id, payload) {
    // Se for o manual, fingimos que salvou com sucesso para o UI não bugar
    if (id === '0000-0000') {
        console.log("Manual de instruções: salvamento ignorado.");
        return id; 
    }

    // Bloqueio do Modo Offline (Aproveitando para adicionar aqui)
    if (localStorage.getItem('ww_offline_mode') === 'true') {
        console.log("Modo offline ativo: salvo apenas no cache.");
        return id;
    }

    const url = (id === 'temp-ink' || !id) ? '/ink' : `/ink/${id}`;
    
    try {
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: payload
            });

            if (response.ok) {
                const data = await response.json();
                if ((id === 'temp-ink' || !id) && data.inkid) {
                    const newUrl = `ink.html?id=${data.inkid}`;
                    window.history.pushState({ path: newUrl }, '', newUrl);
                }
                return data.inkid || id;
            }
        } catch (err) { console.error(err); }
        return false;
    }

async function manualSave() {
    const status = document.getElementById('status');
    if (status) status.innerText = "Sincronizando...";

    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';

    // Captura o conteúdo do editor (Kindle ou A4)
    const content = getAllPagesContent();
    
    // Captura se deve ser público do checkbox no HTML
    const publicCheckbox = document.getElementById('public-toggle');
    const isPublic = publicCheckbox ? publicCheckbox.checked : false;

    const payload = JSON.stringify({
        content: content,
        visibleForAll: isPublic,
        last_modified: Date.now()
    });

    localStorage.setItem('cache_' + inkId, content);

    const result = await apiSaveInk(inkId, payload);

    if (result) {
        if (status) status.innerText = `Salvo (ID: ${result})`;
        const saveBtn = document.getElementById('save-btn');
        if (saveBtn) {
            const originalColor = saveBtn.style.backgroundColor;
            saveBtn.style.backgroundColor = "#2ea043";
            setTimeout(() => saveBtn.style.backgroundColor = originalColor, 1000);
        }
    } else {
        if (status) status.innerText = "Erro ao salvar";
    }
}