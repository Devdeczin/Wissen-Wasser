// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const isKindle = /kindle|silk|mobile/i.test(navigator.userAgent);

function setupGlobalShortcuts() {
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            manualSave(); // Função que está no seu ink.html ou core.js
        }
    });
}

// Importar fonte localmente
async function handleFontImport(event) {
    const file = event.target.files[0];
    if (!file) return;

    const fontName = "CustomFont-" + Math.floor(Math.random() * 1000);
    const reader = new FileReader();

    reader.onload = async (e) => {
        const fontData = e.target.result;
        const fontFace = new FontFace(fontName, fontData);
        
        try {
            const loaded = await fontFace.load();
            document.fonts.add(loaded);
            document.getElementById('editor').style.fontFamily = fontName;
            document.getElementById('status').innerText = "Fonte aplicada!";
        } catch (err) {
            alert("Erro ao carregar .ttf");
        }
    };
    reader.readAsArrayBuffer(file);
}
function initEditor() {
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';
    const savedTheme = localStorage.getItem('ww-theme') || 'desktop';

    if (isKindle) {
        // Esconde botões que o Kindle não suporta
        document.querySelectorAll('.desktop-only').forEach(el => el.style.display = 'none');
        setupKindleEditor(inkId);
    } else {
        setTheme(savedTheme);
        setupUnifiedEditor(inkId);
    }
    
    setupGlobalShortcuts();
}

function setupKindleEditor(inkId) {
    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    // no Kindle, usamos uma estrutura sem sombras ou margens grandes
    editor.style.width = '100%';
    editor.style.padding = '20px';
    editor.contentEditable = 'true';
    editor.spellcheck = false;

    // carrega o conteúdo
    editor.innerText = localStorage.getItem('cache_' + inkId) || '';

    editor.addEventListener('input', () => {
        localStorage.setItem('cache_' + inkId, editor.innerText);
    });

    editorContainer.appendChild(editor);
}

// atualize a chamada do UnifiedEditor para receber o ID
function setupUnifiedEditor(inkId) {
    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.className = 'page';
    editor.contentEditable = 'true';
    editor.spellcheck = false;
    
    editor.innerText = localStorage.getItem('cache_' + inkId) || '';

    editor.addEventListener('input', () => {
        localStorage.setItem('cache_' + inkId, editor.innerText);
        const status = document.getElementById('status');
        if (status) status.innerText = "digitando...";
    });

    editorContainer.appendChild(editor);
    setTimeout(() => editor.focus(), 100);
}

function setupUnifiedEditor() {
    // Limpa o container antes de criar
    editorContainer.innerHTML = '';
    
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.className = 'page';
    editor.contentEditable = 'true';
    editor.spellcheck = false;
    
    const inkId = new URLSearchParams(window.location.search).get('id') || 'temp-ink';
    editor.innerText = localStorage.getItem('cache_' + inkId) || '';

    editor.addEventListener('input', () => {
        localStorage.setItem('cache_' + inkId, editor.innerText);
        const status = document.getElementById('status');
        if (status) status.innerText = "digitando...";
    });

    editorContainer.appendChild(editor);
    
    // Garantia de clique: se o container estiver vazio, o editor precisa de altura
    setTimeout(() => editor.focus(), 100);
}

// --- FUNCIONALIDADES NOVAS ---

function setupGlobalShortcuts() {
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            if (typeof manualSave === 'function') manualSave();
        }
    });
}

// Importador de Fontes Locais (.ttf)
function handleFontImport(event) {
    const file = event.target.files[0];
    if (!file) return;

    const fontName = file.name.split('.')[0].replace(/\s+/g, '-');
    const reader = new FileReader();

    reader.onload = async (e) => {
        const fontData = e.target.result;
        const fontFace = new FontFace(fontName, fontData);
        
        try {
            const loadedFace = await fontFace.load();
            document.fonts.add(loadedFace);
            
            // Aplica a fonte ao editor
            const editor = document.getElementById('editor');
            if (editor) editor.style.fontFamily = fontName;
            
            // Adiciona ao seletor de fontes para referência
            const selector = document.getElementById('font-selector');
            const opt = document.createElement('option');
            opt.value = fontName;
            opt.innerText = `Local: ${fontName}`;
            opt.selected = true;
            selector.appendChild(opt);
            
            alert(`Fonte "${fontName}" carregada com sucesso!`);
        } catch (err) {
            console.error("Erro ao carregar fonte:", err);
        }
    };
    reader.readAsArrayBuffer(file);
}

function setTheme(themeName) {
    if (isKindle) return;
    const themeLink = document.getElementById('theme-style');
    themeLink.href = `css/${themeName}.css`;
    localStorage.setItem('ww-theme', themeName);
}

window.onload = initEditor;