// wissen-wasser/_src/frontend/js/core.js
async function apiSaveInk(id, content) {
    const url = id === 'temp-ink' ? '/ink' : `/ink/${id}`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'text/plain' },
            body: content
        });

        if (response.ok) {
            const data = await response.json();
            // se for um novo ink
            // atualiza o ID na URL sem recarregar a página
            if (id === 'temp-ink') {
                window.history.pushState({}, '', `?id=${data.inkid}`);
            }
            return true;
        }
        return false;
    } catch (err) {
        console.error("Falha ao sincronizar com Nim", err);
        return false;
    }
}