// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const isKindle = /kindle|silk|mobile/i.test(navigator.userAgent);

async function initEditor() {
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';
    
    const display = document.getElementById('ink-id-display');
    if (display) display.innerText = `ID: ${inkId}`;

    if (isKindle) {
        setupKindleEditor(inkId);
    } else {
        await setupA4Editor(inkId);
    }
    setupGlobalShortcuts();
}

async function setupA4Editor(inkId) {
    editorContainer.innerHTML = '';
    const firstPage = createPage();
    editorContainer.appendChild(firstPage);

    // Carregamento inicial
    const content = await fetchInkContent(inkId);
    if (content) firstPage.innerText = content;

    // EVENTO DE TECLADO PARA MARKDOWN (Dispara no Espaço)
    editorContainer.addEventListener('keyup', (e) => {
        const activePage = e.target;
        if (!activePage.classList.contains('page')) return;

        if (e.key === ' ') {
            const text = activePage.innerText;
            // Markdown Notion-like
            if (text.startsWith('# ')) {
                activePage.innerText = text.substring(2);
                document.execCommand('formatBlock', false, 'h1');
            } else if (text.startsWith('## ')) {
                activePage.innerText = text.substring(3);
                document.execCommand('formatBlock', false, 'h2');
            } else if (text.startsWith('- ')) {
                activePage.innerText = text.substring(2);
                document.execCommand('insertUnorderedList');
            }
        }
    });

    // EVENTO DE INPUT PARA QUEBRA DE PÁGINA
    editorContainer.addEventListener('input', (e) => {
        const activePage = e.target;
        
        // Se o conteúdo transbordar a altura fixa de 297mm
        if (activePage.scrollHeight > activePage.offsetHeight) {
            // Pega o último nó (provavelmente o que causou o estouro)
            const lastNode = activePage.lastChild;
            const newPage = createPage();
            editorContainer.appendChild(newPage);
            
            if (lastNode) {
                newPage.appendChild(lastNode); // Move o excesso para a nova página
            }
            
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

function handleMarkdown(element) {
    const text = element.innerHTML;
    // Detecta padrão e transforma imediatamente
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

function getAllPagesContent() {
    return Array.from(document.querySelectorAll('.page')).map(p => p.innerText).join('\n');
}

// Função para lidar com textos longos carregados da nuvem
function distributeContent(content) {
    // Se o texto carregado for muito longo, esta lógica simples ajuda, 
    // mas o evento de input fará o resto conforme você edita.
}

function setupKindleEditor(inkId) {
    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.className = 'kindle-page';
    editor.contentEditable = 'true';
    
    fetchInkContent(inkId).then(content => {
        editor.innerText = content || localStorage.getItem('cache_' + inkId) || '';
    });

    editor.addEventListener('input', () => {
        localStorage.setItem('cache_' + inkId, editor.innerText);
    });
    editorContainer.appendChild(editor);
}

// Re-vincular atalhos e temas
function setupGlobalShortcuts() {
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            manualSave();
        }
    });
}

function setTheme(themeName) {
    if (isKindle) return;
    const themeLink = document.getElementById('theme-style');
    if (themeLink) themeLink.href = `css/${themeName}.css`;
    localStorage.setItem('ww-theme', themeName);
}

window.onload = initEditor;