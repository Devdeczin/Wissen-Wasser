// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const urlParams = new URLSearchParams(window.location.search);

// Detecção: A  penas Kindle/Silk real ou se forçado via URL (?mode=kindle)
const isKindle = /kindle|silk/i.test(navigator.userAgent) || urlParams.get('mode') === 'kindle';

async function initEditor() {
    // 1. Captura o ID da URL antes de qualquer coisa
    const urlParams = new URLSearchParams(window.location.search);
    const inkId = urlParams.get('id') || 'temp-ink';

    console.log("Editor carregado com ID:", inkId);

    // 2. Atualiza a interface visual IMEDIATAMENTE
    const display = document.getElementById('ink-id-display');
    if (display) {
        display.innerText = (inkId === '0000-0000') ? "MODO: LEITURA" : `ID: ${inkId}`;
    }

    // 3. Bloqueia salvamento e checkbox se for o manual
    if (inkId === '0000-0000') {
        const publicToggle = document.getElementById('public-toggle');
        if (publicToggle) publicToggle.parentElement.style.display = 'none';
        
        // Desativa o botão salvar visualmente para o manual
        const saveBtn = document.getElementById('save-btn');
        if (saveBtn) saveBtn.style.opacity = "0.5";
    }

    // 4. Inicializa o editor específico (Kindle ou Desktop)
    if (isKindle) {
        setupKindleEditor(inkId);
    } else {
        await setupA4Editor(inkId);
    }

    setupGlobalShortcuts();
    setupAutoSave(inkId);
}

// --- MODO KINDLE ---
function setupKindleEditor(inkId) {
    document.body.classList.add('kindle-mode'); // Adiciona a classe que você criou no style
    
    const themeLink = document.getElementById('theme-style');
    if (themeLink) themeLink.href = 'css/inkindle.css';

    // Remove elementos que o Kindle não aguenta
    document.querySelectorAll('.desktop-only').forEach(el => el.remove());

    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.contentEditable = 'true';
    editor.spellcheck = false; // Essencial para reduzir lag no Kindle
    
    fetchInkContent(inkId).then(content => {
        editor.innerText = content || "";
    });

    editorContainer.appendChild(editor);
}

// --- MODO DESKTOP (A4) ---
async function setupA4Editor(inkId) {
    editorContainer.innerHTML = '';
    const firstPage = createPage();
    editorContainer.appendChild(firstPage);

    const content = await fetchInkContent(inkId);
    firstPage.innerText = content || "";

    editorContainer.addEventListener('input', (e) => {
        const activePage = e.target;
        if (!activePage.classList.contains('page')) return;

        // MD dinâmico ao digitar espaço
        if (e.data === ' ') {
            handleMarkdown(activePage);
        }

        // Quebra de página A4
        if (activePage.scrollHeight > activePage.offsetHeight) {
            const newPage = createPage();
            editorContainer.appendChild(newPage);
            if (activePage.lastChild) newPage.appendChild(activePage.lastChild);
            newPage.focus();
        }
    });
}

function createPage() {
    const div = document.createElement('div');
    div.className = 'page';
    div.contentEditable = 'true';
    return div;
}

// --- PARSER MARKDOWN ESTÁVEL ---
function handleMarkdown(element) {
    const selection = window.getSelection();
    if (!selection.rangeCount) return;
    
    const range = selection.getRangeAt(0);
    const textNode = range.startContainer;
    const content = textNode.textContent;

    // Regex para identificar padrões no início do nó de texto
    const patterns = [
        { reg: /^#\s/, tag: 'h1' },
        { reg: /^##\s/, tag: 'h2' },
        { reg: /^-\s/, tag: 'insertUnorderedList' }
    ];

    patterns.forEach(p => {
        if (p.reg.test(content)) {
            if (p.tag.startsWith('insert')) {
                document.execCommand(p.tag, false, null);
            } else {
                document.execCommand('formatBlock', false, p.tag);
            }
            // Remove o símbolo do MD após converter
            textNode.textContent = content.replace(p.reg, '');
        }
    });
}

// --- SALVAMENTO E ATALHOS ---
function setupAutoSave(inkId) {
    if (inkId === '0000-0000') return;

    // No Kindle, aumentamos o intervalo ou desativamos o autosave agressivo
    const interval = isKindle ? 180000 : 60000; // 3 minutos no Kindle, 1 no PC

    setInterval(() => {
        if (document.activeElement.id !== 'editor') {
            manualSave();
        }
    }, interval);
}

function getAllPagesContent() {
    // Tenta pegar do editor único (Kindle)
    const kindleEditor = document.getElementById('editor');
    if (kindleEditor) return kindleEditor.innerText;

    // Tenta pegar das páginas (A4)
    const pages = document.querySelectorAll('.page');
    if (pages.length > 0) {
        return Array.from(pages).map(p => p.innerText).join('\n');
    }

    return ""; // Fallback
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