// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const isKindle = /kindle|silk|mobile/i.test(navigator.userAgent);

// --- CONFIGURAÇÕES DE PAGINAÇÃO ---
const A4_HEIGHT_PX = 1122; // Aproximado para 297mm em 96dpi

function initEditor() {
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';
    
    // Problema 2: Mostrar InkID
    const display = document.getElementById('ink-id-display');
    if (display) display.innerText = `ID: ${inkId}`;

    if (isKindle) {
        setupKindleEditor(inkId);
    } else {
        setupA4Editor(inkId);
    }
}

function setupA4Editor(inkId) {
    editorContainer.innerHTML = '';
    
    // Cria a primeira folha
    const firstPage = createPage();
    editorContainer.appendChild(firstPage);

    // Carrega conteúdo inicial
    fetchInkContent(inkId).then(content => {
        if(content) firstPage.innerText = content;
    });

    // Evento unificado para Markdown e Paginação
    editorContainer.addEventListener('keyup', (e) => {
        const activePage = e.target;
        if (!activePage.classList.contains('page')) return;

        // Problema 3: Markdown Notion-like
        handleMarkdown(activePage, e);

        // Problema 1: Divisão de páginas (Estilo Word)
        // Se a altura do texto (scrollHeight) for maior que a folha (297mm)
        if (activePage.scrollHeight > activePage.offsetHeight) {
            const newPage = createPage();
            editorContainer.appendChild(newPage);
            newPage.focus();
        }
    });
}

function createPage() {
    const div = document.createElement('div');
    div.className = 'page';
    div.contentEditable = 'true';
    div.spellcheck = false;
    return div;
}

function handleMarkdown(element, event) {
    // Só dispara ao apertar Espaço (Markdown Notion costuma ser assim)
    if (event.key !== ' ') return;

    const content = element.innerText;
    
    // H1: Se a linha começa com # 
    if (content.startsWith('# ')) {
        element.innerText = content.substring(2);
        document.execCommand('formatBlock', false, 'h1');
    }
    // H2: Se começa com ## 
    else if (content.startsWith('## ')) {
        element.innerText = content.substring(3);
        document.execCommand('formatBlock', false, 'h2');
    }
    // Lista: Se começa com - 
    else if (content.startsWith('- ')) {
        element.innerText = content.substring(2);
        document.execCommand('insertUnorderedList');
    }
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