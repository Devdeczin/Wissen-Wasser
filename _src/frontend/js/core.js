// wissen-wasser/_src/frontend/js/core.js
async function fetchInkContent(id) {
    if (!id || id === 'temp-ink') return "";

    try {
        const response = await fetch(`/ink/${id}`);
        if (response.ok) {
            const data = await response.text();
            localStorage.setItem('cache_' + id, data); // Salva o bruto no cache
            
            try {
                const json = JSON.parse(data);
                // Prioriza o campo 'content' que contém o texto com Markdown
                return json.record ? json.record.content : (json.content || data);
            } catch (e) {
                return data; // Se não for JSON, retorna o texto puro
            }
        }
    } catch (err) {
        console.warn("Usando cache local.");
    }
    return localStorage.getItem('cache_' + id) || "";
}

async function apiSaveInk(id, payload) {
    const url = (id === 'temp-ink' || !id) ? '/ink' : `/ink/${id}`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'X-Requested-With': 'WissenWasserClient'
            },
            body: payload
        });

        if (response.ok) {
            const data = await response.json();
            if (id === 'temp-ink' && data.inkid) {
                const newUrl = `${window.location.pathname}?id=${data.inkid}`;
                window.history.pushState({ path: newUrl }, '', newUrl);
                const display = document.getElementById('ink-id-display');
                if (display) display.innerText = `ID: ${data.inkid}`;
            }
            return data.inkid || id;
        }
        return false;
    } catch (err) {
        console.error("Erro na comunicação:", err);
        return false;
    }
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