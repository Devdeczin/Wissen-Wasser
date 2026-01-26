// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const urlParams = new URLSearchParams(window.location.search);
const isKindle = /kindle|silk/i.test(navigator.userAgent) || urlParams.get('mode') === 'kindle';

// 1. PARSER (Markdown + Kindle Tags)
function parseFullMarkdown(text) {
    if (!text) return "";
    return text
        .replace(/^# (.*$)/gim, '<h1>$1</h1>')
        .replace(/^## (.*$)/gim, '<h2>$1</h2>')
        .replace(/^- (.*$)/gim, '<ul><li>$1</li></ul>')
        .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
        .replace(/^cap:\s*(.*$)/gim, '<div class="chapter-mark"><span>Capítulo: $1</span></div>')
        .replace(/^note:\s*(.*$)/gim, '<aside class="note-block"><strong>Nota:</strong> $1</aside>')
        .replace(/<\/ul>\s*<ul>/gim, '');
}

// 2. UTILITÁRIOS DE CRIAÇÃO
function createPage() {
    const div = document.createElement('div');
    div.className = 'page';
    div.contentEditable = 'true';
    return div;
}

// 3. INICIALIZADOR PRINCIPAL
async function initEditor() {
    const inkId = urlParams.get('id') || 'temp-ink';
    
    // UI Update básica
    const display = document.getElementById('ink-id-display');
    if (display) display.innerText = (inkId === '0000-0000') ? "MODO: LEITURA" : `ID: ${inkId}`;

    // Escolha do modo (Kindle vs A4)
    if (isKindle) {
        await setupKindleEditor(inkId);
    } else {
        await setupA4Editor(inkId);
    }

    setupGlobalShortcuts();
    setupAutoSave(inkId);
}

// 4. MODO KINDLE (Simplificado para performance)
async function setupKindleEditor(inkId) {
    document.body.classList.add('kindle-mode');
    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.className = 'kindle-page';
    editor.contentEditable = 'true';
    editorContainer.appendChild(editor);

    const content = await fetchInkContent(inkId);
    if (inkId === '0000-0000' || inkId === 'TERM-USER') {
        editor.innerHTML = parseFullMarkdown(content);
        editor.contentEditable = 'false';
    } else {
        editor.innerText = content || "";
    }
}

// 5. MODO DESKTOP (A4 com quebra de página)
async function setupA4Editor(inkId) {
    editorContainer.innerHTML = '';
    let currentPage = createPage();
    editorContainer.appendChild(currentPage);

    const content = await fetchInkContent(inkId);

    if (inkId === '0000-0000' || inkId === 'TERM-USER') {
        currentPage.contentEditable = 'false';
        currentPage.innerHTML = parseFullMarkdown(content);
        
        // Timeout para processar as múltiplas páginas
        setTimeout(() => {
            let page = currentPage;
            while (page.scrollHeight > page.offsetHeight) {
                const nextPage = createPage();
                nextPage.contentEditable = 'false';
                editorContainer.appendChild(nextPage);
                while (page.scrollHeight > page.offsetHeight && page.lastChild) {
                    nextPage.insertBefore(page.lastChild, nextPage.firstChild);
                }
                page = nextPage;
            }
        }, 100);
    } else {
        currentPage.innerText = content || "";
        currentPage.focus();
    }

    // Listener para Markdown dinâmico e novas páginas
    editorContainer.addEventListener('input', (e) => {
        const activePage = e.target;
        if (!activePage.classList.contains('page')) return;

        // MD dinâmico ao digitar espaço
        if (e.data === ' ') handleMarkdown(activePage);

        // Auto-quebra de página
        if (activePage.scrollHeight > activePage.offsetHeight) {
            const newPage = createPage();
            editorContainer.appendChild(newPage);
            newPage.focus();
        }
    });
}

// 6. LOGICA DE MARKDOWN EM TEMPO REAL
function handleMarkdown(element) {
    const selection = window.getSelection();
    if (!selection || !selection.rangeCount) return;
    
    const range = selection.getRangeAt(0);
    const textNode = range.startContainer;
    const content = textNode.textContent;

    const patterns = [
        { reg: /^#\s/, tag: 'h1' },
        { reg: /^##\s/, tag: 'h2' },
        { reg: /^-\s/, tag: 'insertUnorderedList' }
    ];

    patterns.forEach(p => {
        if (p.reg.test(content)) {
            const command = p.tag.startsWith('insert') ? p.tag : 'formatBlock';
            document.execCommand(command, false, p.tag.startsWith('insert') ? null : p.tag);
            textNode.textContent = content.replace(p.reg, '');
        }
    });
}

// 7. AUXILIARES DE SISTEMA
function getAllPagesContent() {
    const kindleEditor = document.getElementById('editor');
    if (kindleEditor) return kindleEditor.innerText;
    
    const pages = document.querySelectorAll('.page');
    return Array.from(pages).map(p => p.innerText).join('\n');
}

function setupAutoSave(inkId) {
    if (inkId === '0000-0000') return;
    setInterval(() => manualSave(), isKindle ? 180000 : 60000);
}

function setupGlobalShortcuts() {
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            manualSave();
        }
    });
}

window.onload = initEditor;