// wissen-wasser/_src/frontend/js/editor.js
const editorContainer = document.getElementById('editor-container');
const urlParams = new URLSearchParams(window.location.search);
const isKindle = /kindle|silk/i.test(navigator.userAgent) || urlParams.get('mode') === 'kindle';

async function initEditor() {
    const inkId = urlParams.get('id') || 'temp-ink';
    const display = document.getElementById('ink-id-display');
    
    if (display) {
        display.innerText = (inkId === '0000-0000') ? "MODO: LEITURA" : `ID: ${inkId}`;
    }

    if (inkId === '0000-0000') {
        const publicToggle = document.getElementById('public-toggle');
        if (publicToggle) publicToggle.parentElement.style.display = 'none';
        const saveBtn = document.getElementById('save-btn');
        if (saveBtn) saveBtn.style.opacity = "0.5";
    }

    if (isKindle) {
        await setupKindleEditor(inkId);
    } else {
        await setupA4Editor(inkId);
    }

    setupGlobalShortcuts();
    setupAutoSave(inkId);
}

// Parser Unificado (Markdown + Kindle Tags)
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

async function setupKindleEditor(inkId) {
    document.body.classList.add('kindle-mode');
    const themeLink = document.getElementById('theme-style');
    if (themeLink) themeLink.href = 'css/inkindle.css';
    document.querySelectorAll('.desktop-only').forEach(el => el.remove());

    editorContainer.innerHTML = '';
    const editor = document.createElement('div');
    editor.id = 'editor';
    editor.contentEditable = (inkId !== '0000-0000').toString();
    editor.spellcheck = false;
    
    const content = await fetchInkContent(inkId);
    if (inkId === '0000-0000' || inkId === 'TERM-USER') {
        editor.innerHTML = parseFullMarkdown(content);
    } else {
        editor.innerText = content || "";
    }
    editorContainer.appendChild(editor);
}

async function setupA4Editor(inkId) {
    editorContainer.innerHTML = '';
    const content = await fetchInkContent(inkId);
    
    let currentPage = createPage();
    editorContainer.appendChild(currentPage);

    if (inkId === '0000-0000' || inkId === 'TERM-USER') {
        currentPage.contentEditable = 'false';
        currentPage.innerHTML = parseFullMarkdown(content);

        setTimeout(() => {
            while (currentPage.scrollHeight > currentPage.offsetHeight) {
                const nextPage = createPage();
                nextPage.contentEditable = 'false';
                editorContainer.appendChild(nextPage);

                while (currentPage.scrollHeight > currentPage.offsetHeight && currentPage.lastChild) {
                    nextPage.insertBefore(currentPage.lastChild, nextPage.firstChild);
                }
                currentPage = nextPage;
            }
        }, 50);
    } else {
        currentPage.innerText = content || "";
    }

    editorContainer.addEventListener('input', (e) => {
        const activePage = e.target;
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
    return div;
}

function handleMarkdown(element) {
    const selection = window.getSelection();
    if (!selection.rangeCount) return;
    const range = selection.getRangeAt(0);
    const textNode = range.startContainer;
    const content = textNode.textContent;
    const patterns = [{ reg: /^#\s/, tag: 'h1' }, { reg: /^##\s/, tag: 'h2' }, { reg: /^-\s/, tag: 'insertUnorderedList' }];

    patterns.forEach(p => {
        if (p.reg.test(content)) {
            document.execCommand(p.tag.startsWith('insert') ? p.tag : 'formatBlock', false, p.tag.startsWith('insert') ? null : p.tag);
            textNode.textContent = content.replace(p.reg, '');
        }
    });
}

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