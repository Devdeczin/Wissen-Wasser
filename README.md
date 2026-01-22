# Wissen Wasser (WW)

> **Wissen Wasser is not a product. It is a system of thought, flow, and writing.**

Wissen Wasser (WW) is a distraction-free, cross-platform writing environment designed to capture thoughts with speed and intentionality. Whether you are writing on a **Kindle (E-ink)**, a high-productivity **Desktop** setup, or seeking the high-contrast focus of **BeautifulInk**, WW adapts its form to your current flow.

## The Philosophy

WW aims to bridge the gap between digital convenience and analog focus. It is built to be "anti-parasitic"—designed for the writer, not for the platform. It leverages the efficiency of the **Nim** programming language and the simplicity of cloud-synced JSON storage to ensure your thoughts are never lost.

---

## Key Features

* **Multi-Surface Architecture**:
* **Kindle Mode**: Ultra-lightweight, high-contrast UI optimized for E-ink refresh rates.
* **Desktop (JSONBin-style)**: A tech-focused dark mode inspired by developer dashboards.
* **BeautifulInk**: A "premium charcoal" theme for deep focus.


* **Notion/Obsidian-like Editor**: A unified, infinite-scroll writing area that feels modern and responsive.
* **Cloud Persistence**: Seamless integration with **JSONBin.io** for cloud backups.
* **Local Customization**: Import your own `.ttf` fonts directly through the UI.
* **High Performance**: Backend powered by **Nim** and **Jester** for near-instant execution and low memory footprint.

---

## Tech Stack

* **Backend**: [Nim](https://nim-lang.org/) (Jester Web Framework)
* **Frontend**: Vanilla JavaScript, CSS3 (No heavy frameworks)
* **Storage**: [JSONBin.io](https://jsonbin.io/) API
* **Deployment**: [Render.com](https://render.com/) via Docker

---

## Quick Start (Local Development)

### Prerequisites

* Nim compiler installed.
* A JSONBin.io API Key (.key file).

### Installation

1. **Clone the repository**:
```bash
git clone https://github.com/Devdeczin/Wissen-Wasser.git
cd wissen-wasser

```


2. **Configure Environment**:
Create a `.env` file in the root directory:
```env
JSONBIN_API_KEY=your_key_here
PORT=5000

```


3. **Run the Server**:
```bash
cd _src/backend/nim/ww
nim c -r -d:ssl --threads:off routes.nim

```

4. **Access the App**:
Open `http://localhost:5000` in your browser.

---

## Shortcuts & Controls

* **`Ctrl + S`**: Save current Ink to the cloud.
* **Theme Selector**: Switch between JSONBin Dark and BeautifulInk in real-time.
* **Font Import**: Click "+ Fonte .ttf" to load and apply a local font file to the editor.

---

## Deployment (Docker)

This project is optimized for deployment on **Render.com** using the provided `Dockerfile`.

1. Push your code to GitHub.
2. Connect the repository to Render as a **Web Service**.
3. Set the Runtime to **Docker**.
4. Add your `JSONBIN_API_KEY` to the **Environment Variables** tab.

---

## License

Wissen Wasser is released under the **Wissen Wasser License (WWL) v1.0**.

* **Personal Use**: Free to read, study, modify, and use.
* **Attribution**: Derivatives must credit **Devdeczin** and preserve this license.
* **Non-Commercial**: Commercial use is strictly prohibited without explicit written permission.
* **Anti-Parasitism**: You may not use this work to create a competing product whose primary value derives from WW's concepts or structure.

*See the full `LICENSE` file for details.*
