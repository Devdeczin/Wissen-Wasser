// wissen-wasser/_src/frontend/js/core.js

/**
 * Envia o conteúdo do Ink para o servidor Nim.
 * Se for um 'temp-ink', o servidor criará um novo ID.
 */
async function apiSaveInk(id, content) {
    // Define a rota: POST /ink para novos, POST /ink/:id para existentes
    const url = (id === 'temp-ink' || !id) ? '/ink' : `/ink/${id}`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 
                'Content-Type': 'text/plain',
                'X-Requested-With': 'WissenWasserClient'
            },
            body: content
        });

        if (response.ok) {
            const data = await response.json();
            
            // Se o servidor retornou um novo ID (primeiro salvamento), atualiza a URL
            if (id === 'temp-ink' && data.inkid) {
                const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname + `?id=${data.inkid}`;
                window.history.pushState({ path: newUrl }, '', newUrl);
                
                // Atualiza o status bar com o novo ID
                const status = document.getElementById('status');
                if (status) status.innerText = `ID: ${data.inkid} (Criado)`;
            }
            return data.inkid || id;
        }
        return false;
    } catch (err) {
        console.error("Erro na comunicação com o servidor Nim:", err);
        return false;
    }
}

/**
 * Busca o conteúdo de um Ink específico no servidor.
 * Tenta a nuvem primeiro, cai para o cache local se falhar.
 */
async function fetchInkContent(id) {
    if (!id || id === 'temp-ink') return "";

    try {
        const response = await fetch(`/ink/${id}`);
        if (response.ok) {
            const content = await response.text();
            // Sincroniza o cache local com o que veio da nuvem
            localStorage.setItem('cache_' + id, content);
            return content;
        }
    } catch (err) {
        console.warn("Servidor offline ou erro de rede. Usando cache local.");
    }

    // Fallback para o localStorage caso esteja sem internet
    return localStorage.getItem('cache_' + id) || "";
}

/**
 * Função global chamada pelo botão de Salvar ou Ctrl+S.
 * Ela detecta o ID atual e o conteúdo de todas as páginas.
 */
async function manualSave() {
    const pagesContent = getAllPagesContent();
    // Transforma o conteúdo em um dicionário JSON
    const payload = JSON.stringify({
        content: pagesContent,
        last_modified: Date.now()
    });

    const result1 = await apiSaveInk(inkId, payload);

    const status = document.getElementById('status');
    if (status) status.innerText = "Sincronizando...";

    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';

    // Coleta o texto de todas as páginas (editor A4) ou do editor único (Kindle)
    const pages = document.querySelectorAll('.page');
    let content = "";

    if (pages.length > 0) {
        content = Array.from(pages).map(p => p.innerText).join('\n');
    } else {
        const singleEditor = document.getElementById('editor');
        content = singleEditor ? singleEditor.innerText : "";
    }

    const result = await apiSaveInk(inkId, content);

    if (result) {
        if (status) status.innerText = `Salvo na Nuvem (ID: ${result})`;
        // Feedback visual de sucesso
        const saveBtn = document.getElementById('save-btn');
        if (saveBtn) {
            const originalColor = saveBtn.style.backgroundColor;
            saveBtn.style.backgroundColor = "#2ea043";
            setTimeout(() => saveBtn.style.backgroundColor = originalColor, 1000);
        }
    } else {
        if (status) status.innerText = "Erro ao salvar (mantido em cache local)";
    }
}

async function fetchInkContent(id) {
    if (!id || id === 'temp-ink') return "";

    try {
        const response = await fetch(`/ink/${id}`);
        if (response.ok) {
            const data = await response.text(); 
            try {
                // Se o backend enviar um JSON estruturado do JSONBin
                const json = JSON.parse(data);
                // Retorna apenas a parte do texto para o editor
                return json.record ? json.record.content : json.content || data;
            } catch (e) {
                return data; // Se for texto puro
            }
        }
    } catch (err) {
        console.warn("Usando cache local.");
    }
    return localStorage.getItem('cache_' + id) || "";
}