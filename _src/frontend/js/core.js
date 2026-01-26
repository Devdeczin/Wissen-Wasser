// wissen-wasser/_src/frontend/js/core.js
async function fetchInkContent(id) {
    // 1. IDs especiais buscam arquivos .md estáticos
    const specialIds = {
        '0000-0000': 'docs/manual.md',
        'TERM-USER': 'docs/terms.md'
    };

    if (specialIds[id]) {
        try {
            const response = await fetch(specialIds[id]);
            if (response.ok) return await response.text();
        } catch (err) {
            return "# Erro ao carregar documento oficial.";
        }
    }

    // 2. Fluxo normal para Inks do usuário
    const localCache = localStorage.getItem('cache_' + id);

    try {
        const response = await fetch(`/api/ink/${id}`);
        if (response.ok) {
            const data = await response.json(); 
            const content = data.content || "";
            localStorage.setItem('cache_' + id, content);
            return content;
        }
    } catch (err) {
        console.warn("Usando cache local.");
    }

    return localCache || "";
}

async function apiSaveInk(id, payload) {
    if (id === '0000-0000' || localStorage.getItem('ww_offline_mode') === 'true') return id;

    const isNew = (id === 'temp-ink' || !id);
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
            const data = await response.json();
            if ((id === 'temp-ink' || !id) && data.inkid) {
                const newUrl = `?id=${data.inkid}`;
                window.history.pushState({}, '', newUrl);
                return data.inkid;
            }
            return id;
        }
    } catch (err) { 
        console.error("Erro na API:", err); 
    }
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