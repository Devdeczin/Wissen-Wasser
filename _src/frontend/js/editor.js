// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const isKindle = /kindle|silk|mobile/i.test(navigator.userAgent);

// --- CONFIGURAÇÕES DE PAGINAÇÃO ---
const A4_HEIGHT_PX = 1122; // Aproximado para 297mm em 96dpi

function initEditor() {
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';
    const savedTheme = localStorage.getItem('ww-theme') || 'desktop';

    // Mostra o InkID no status bar se ele existir
    const status = document.getElementById('status');
    if (status) status.innerText = `ID: ${inkId}`;

    if (isKindle) {
        document.querySelectorAll('.desktop-only').forEach(el => el.style.display = 'none');
        setupKindleEditor(inkId);
    } else {
        setTheme(savedTheme);
        setupA4Editor(inkId);
    }
    
    setupGlobalShortcuts();
}

// --- EDITORES ---

function setupA4Editor(inkId) {
    editorContainer.innerHTML = '';
    
    // Tenta carregar conteúdo inicial
    const savedContent = localStorage.getItem('cache_' + inkId) || '';
    
    // Cria a primeira página
    const firstPage = createPage();
    editorContainer.appendChild(firstPage);
    firstPage.innerText = savedContent;

    // Monitoramento de input para Markdown e Paginação
    editorContainer.addEventListener('input', (e) => {
        const activePage = e.target;
        if (!activePage.classList.contains('page')) return;

        // 1. Markdown Notion-like
        handleMarkdown(activePage);

        // 2. Lógica de Paginação (se o texto estourar a altura da folha)
        if (activePage.scrollHeight > activePage.offsetHeight) {
            const nextPage = createPage();
            activePage.after(nextPage);
            nextPage.focus();
        }

        // 3. Salvamento em cache
        const allText = Array.from(document.querySelectorAll('.page')).map(p => p.innerText).join('\n');
        localStorage.setItem('cache_' + inkId, allText);
        
        const status = document.getElementById('status');
        if (status) status.innerText = "digitando...";
    });

    setTimeout(() => firstPage.focus(), 100);
}

function setupKindleEditor(inkId) {
    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.style.width = '100%';
    editor.style.padding = '20px';
    editor.contentEditable = 'true';
    editor.spellcheck = false;

    editor.innerText = localStorage.getItem('cache_' + inkId) || '';

    editor.addEventListener('input', () => {
        localStorage.setItem('cache_' + inkId, editor.innerText);
    });

    editorContainer.appendChild(editor);
}

// --- UTILITÁRIOS DE CRIAÇÃO E ESTILO ---

function createPage() {
    const div = document.createElement('div');
    div.className = 'page'; // Usa sua classe CSS para o estilo A4
    div.contentEditable = 'true';
    div.spellcheck = false;
    return div;
}

function handleMarkdown(element) {
    const text = element.innerHTML;
    
    // Notion-like: Detecta padrão e transforma o bloco imediatamente
    if (text.includes('#&nbsp;')) {
        document.execCommand('formatBlock', false, 'h1');
        element.innerHTML = text.replace('#&nbsp;', '');
    } else if (text.includes('##&nbsp;')) {
        document.execCommand('formatBlock', false, 'h2');
        element.innerHTML = text.replace('##&nbsp;', '');
    } else if (text.includes('-&nbsp;')) {
        document.execCommand('insertUnorderedList');
        element.innerHTML = text.replace('-&nbsp;', '');
    }
}

function changeFontSize(size) {
    const pages = document.querySelectorAll('.page, #editor');
    pages.forEach(p => p.style.fontSize = size + 'px');
}

// --- FUNÇÕES MANTIDAS DO ORIGINAL ---

function setupGlobalShortcuts() {
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            if (typeof manualSave === 'function') manualSave();
        }
    });
}

async function handleFontImport(event) {
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
            
            const editors = document.querySelectorAll('.page, #editor');
            editors.forEach(ed => ed.style.fontFamily = fontName);
            
            const selector = document.getElementById('font-selector');
            if (selector) {
                const opt = document.createElement('option');
                opt.value = fontName;
                opt.innerText = `Local: ${fontName}`;
                opt.selected = true;
                selector.appendChild(opt);
            }
            
            const status = document.getElementById('status');
            if (status) status.innerText = "Fonte aplicada!";
        } catch (err) {
            console.error("Erro ao carregar fonte:", err);
            alert("Erro ao carregar .ttf");
        }
    };
    reader.readAsArrayBuffer(file);
}

function setTheme(themeName) {
    if (isKindle) return;
    const themeLink = document.getElementById('theme-style');
    if (themeLink) {
        themeLink.href = `css/${themeName}.css`;
        localStorage.setItem('ww-theme', themeName);
    }
}

window.onload = initEditor;