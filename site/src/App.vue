<script setup>
import { computed, onMounted, ref } from 'vue'

const repo = 'DanKaufmanDev/giit'
const releasesUrl = `https://github.com/${repo}/releases`

const installer = 'curl -fsSL https://giit.danielkaufman.dev/install.sh | sh'

const platforms = [
  {
    id: 'macos',
    label: 'macOS',
    command: installer,
    note: 'or download the installer for the releases button below.',
  },
  {
    id: 'windows',
    label: 'Windows',
    command: 'winget install DanKaufmanDev.Giit',
    note: 'or download the installer for the releases button below.',
  },
  {
    id: 'linux',
    label: 'Linux',
    command: installer,
    note: 'or download the installer for the releases button below.',
  },
]

const assetPreference = {
  macos: [/\.dmg$/i],
  windows: [/\.msi$/i, /\.exe$/i],
  linux: [/\.appimage$/i, /\.deb$/i, /\.rpm$/i],
}

const latest = ref({ loading: true, version: '', assets: [] })

const features = [
  {
    title: 'Sandbox',
    text: 'Preview risky repository operations before they mutate your working tree.',
    accent: 'red',
    icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>',
  },
  {
    title: 'Recover',
    text: 'Keep recovery points and workflow history on your machine, where they belong.',
    accent: 'green',
    icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 4v4h4"/><path d="M12 8v4l3 2"/></svg>',
  },
  {
    title: 'Undo',
    text: 'Bring familiar undo into Git workflows that usually require memory and reflog spelunking.',
    accent: 'blue',
    icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 14 4 9l5-5"/><path d="M4 9h11a5 5 0 0 1 0 10h-4"/></svg>',
  },
]

const workflows = [
  'Merge and rebase previews',
  'Checkout and discard recovery',
  'Stash apply and pop inspection',
  'Commit history edits with recovery points',
  'Conflict assistance from the file view',
  'Snapshot-based restore flows',
]

const detectedPlatform = ref('macos')
const copiedCommand = ref('')

const activePlatform = computed(() => {
  return platforms.find((platform) => platform.id === detectedPlatform.value) ?? platforms[0]
})

const latestLabel = computed(() => {
  if (latest.value.loading) return 'Checking latest release…'
  return latest.value.version ? `Latest release · ${latest.value.version}` : 'v1.0.0 · coming soon'
})

const downloadUrl = computed(() => {
  const prefs = assetPreference[activePlatform.value.id] ?? []
  const assets = latest.value.assets.filter((item) => !/\.sig$/i.test(item.name))
  for (const pattern of prefs) {
    const asset = assets.find((item) => pattern.test(item.name))
    if (asset) return asset.url
  }
  return releasesUrl
})

const hasAsset = computed(() => downloadUrl.value !== releasesUrl)

onMounted(async () => {
  // Always open at the top (#top), regardless of any restored scroll position.
  if ('scrollRestoration' in window.history) {
    window.history.scrollRestoration = 'manual'
  }
  window.scrollTo(0, 0)

  const userAgent = window.navigator.userAgent.toLowerCase()

  // Keep detection deliberately conservative; users can still switch manually.
  if (userAgent.includes('windows')) {
    detectedPlatform.value = 'windows'
  } else if (userAgent.includes('linux') || userAgent.includes('x11')) {
    detectedPlatform.value = 'linux'
  } else {
    detectedPlatform.value = 'macos'
  }

  // Resolve the latest release so the UI can surface the real version + assets.
  // Degrades gracefully (and silently) until the first release is published.
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' },
    })
    if (res.ok) {
      const data = await res.json()
      latest.value = {
        loading: false,
        version: data.tag_name ?? '',
        assets: (data.assets ?? []).map((asset) => ({
          name: asset.name,
          url: asset.browser_download_url,
        })),
      }
    } else {
      latest.value = { loading: false, version: '', assets: [] }
    }
  } catch {
    latest.value = { loading: false, version: '', assets: [] }
  }
})

async function copyCommand(command) {
  copiedCommand.value = ''

  try {
    if (navigator.clipboard) {
      await navigator.clipboard.writeText(command)
    } else {
      throw new Error('Clipboard API unavailable')
    }
    copiedCommand.value = command
  } catch {
    // Some browsers block the Clipboard API in previews; keep a tiny fallback.
    const textarea = document.createElement('textarea')
    textarea.value = command
    textarea.setAttribute('readonly', '')
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()

    document.execCommand('copy')
    copiedCommand.value = command

    document.body.removeChild(textarea)
  }
}
</script>

<template>
  <header class="site-header" aria-label="Primary navigation">
    <a class="brand" href="/" aria-label="Giit home">
      <img class="nav-img" src="/giit-logo.webp" alt="giit logo" aria-label="giit logo" />
    </a>

    <nav>
      <a href="#safety">Safety</a>
      <a href="#install">Install</a>
      <a href="https://github.com/DanKaufmanDev/giit/issues">Issues</a>
    </nav>
  </header>

  <main id="top">
    <section class="hero-section">
      <div class="hero-copy">
        <a class="hero-badge" href="https://github.com/DanKaufmanDev/giit">
          <span class="pulse"></span>{{ latestLabel }}
        </a>
        <h1>A <span class="gradient-text">safety-first</span> Git client for people who move fast.</h1>
        <p class="hero-text">
          Giit wraps risky Git workflows in sandboxed previews, local recovery
          points, and familiar Cmd/Ctrl+Z undo so you can work quickly without
          treating every action like a cliff edge.
        </p>

        <div class="hero-actions">
          <a class="button primary" href="#install">Get Giit</a>
          <a class="button secondary" href="https://github.com/DanKaufmanDev/giit" target="_blank">View Public Repo</a>
        </div>
      </div>

      <div class="product-frame" role="img" aria-label="Preview of the Giit desktop app">
        <div class="app-titlebar">
          <div class="traffic"><span></span><span></span><span></span></div>
          <span class="app-title">Giit</span>
        </div>

        <div class="app-tabs">
          <div class="tabs-left">
            <span class="tab active"><i class="tab-dot purple"></i>tab 1</span>
            <span class="tab"><i class="tab-dot"></i>tab 2</span>
            <button class="tab-add" type="button" tabindex="-1" aria-hidden="true">+</button>
          </div>
          <span class="detached">main</span>
        </div>

        <div class="app-body">
          <aside class="app-sidebar">
            <div class="side-section" id="active-section">
              <p class="side-head">Files <b class="active-badge">Active</b></p>
              <ul class="file-tree">
                <li class="file"><span class="fname">.gitignore</span><b class="badge m">M</b></li>
                <li class="file"><span class="fname">Cargo.toml</span><b class="badge m">M</b></li>
                <li class="file"><span class="fname">Cargo.lock</span><b class="badge m">M</b></li>
                <li class="folder selected"><span class="fname"><i class="caret"></i>src</span><b class="badge m">M</b></li>
                <li class="file indent-1"><span class="fname"><i class="tree-join"></i>main.rs</span><b class="badge m">M</b></li>
                <li class="file indent-1"><span class="fname"><i class="tree-join"></i>lib.rs</span><b class="badge m">M</b></li>
                <li class="folder indent-1"><span class="fname"><i class="caret"></i>git</span><b class="badge m">M</b></li>
                <li class="file indent-2"><span class="fname"><i class="tree-join"></i>repo.rs</span><b class="badge m">M</b></li>
                <li class="file indent-2"><span class="fname"><i class="tree-join"></i>snapshot.rs</span><b class="badge u">U</b></li>
                <li class="file indent-2"><span class="fname"><i class="tree-join"></i>diff.rs</span><b class="badge m">M</b></li>
                <li class="file indent-1"><span class="fname"><i class="tree-join"></i>commands.rs</span><b class="badge m">M</b></li>
                <li class="file indent-1"><span class="fname"><i class="tree-join"></i>error.rs</span><b class="badge m">M</b></li>
              </ul>
            </div>

            <div class="side-section">
              <p class="side-head">Branches</p>
              <ul class="branch-list">
                <li>
                  <i class="branch-dot"></i>
                  <span class="branch-name">master</span>
                  <b class="head-badge">HEAD</b>
                </li>
                <li class="remote">
                  <i class="branch-ico">☁</i>
                  <span class="branch-name">origin/master</span>
                </li>
              </ul>
            </div>

            <div class="side-section">
              <p class="side-head">Commit History</p>
              <ul class="log-list">
                <li>
                  <span class="log-hash commit">a1f4c9d</span>
                  <span class="log-body">
                    <span class="log-msg">feat: add snapshot timeline view</span>
                    <span class="log-sub">By DanKaufmanDev</span>
                  </span>
                </li>
                <li>
                  <span class="log-hash commit">9e2b1a7</span>
                  <span class="log-body">
                    <span class="log-msg">fix: guard against dirty checkout data loss</span>
                    <span class="log-sub">By DanKaufmanDev</span>
                  </span>
                </li>
              </ul>
            </div>

            <div class="side-section">
              <p class="side-head">Stashes</p>
              <p class="empty">Stash vault is empty.</p>
            </div>

            <div class="side-section">
              <p class="side-head">Snapshots</p>
              <ul class="log-list">
                <li>
                  <span class="log-hash snap">8ff57fd</span>
                  <span class="log-body"><span class="log-msg">Before merge · feature/timeline</span></span>
                  <span class="log-time">2m ago</span>
                </li>
                <li>
                  <span class="log-hash snap">3779588</span>
                  <span class="log-body"><span class="log-msg">Before rebase onto master</span></span>
                  <span class="log-time">1h ago</span>
                </li>
                <li>
                  <span class="log-hash snap">be8f886</span>
                  <span class="log-body"><span class="log-msg">Before discard · src/main.rs</span></span>
                  <span class="log-time">5h ago</span>
                </li>
              </ul>
            </div>
          </aside>

          <div class="app-main">
            <img class="app-logo" src="/giit-logo.webp" alt="" />
            <p class="app-tagline">Git Safe with Giit</p>
            <p class="app-desc">
              giit makes git easier and safer to use — every risky operation is
              snapshotted automatically, so you can always press ⌘+Z and walk it
              back. No commands memorized, no history lost.
            </p>

            <div class="app-feature-grid">
              <div class="app-feature">
                <strong class="blue">Time Machine</strong>
                <span>Auto-snapshots before anything destructive. Undo merges, drops, rebases.</span>
              </div>
              <div class="app-feature">
                <strong class="purple">Commit Graph</strong>
                <span>See where branches fork, merge, and who's working where.</span>
              </div>
              <div class="app-feature">
                <strong class="green">Keyboard First</strong>
                <span>Stage hunks, squash, cherry-pick, stash — without leaving home row.</span>
              </div>
              <div class="app-feature">
                <strong class="gold">Smart &amp; Safe</strong>
                <span>Conflicts resolved block by block. Dirty checkouts auto-stashed.</span>
              </div>
            </div>

            <p class="app-hint">
              Press <kbd>Tab</kbd> to get started · <kbd>?</kbd> for all keybinds
            </p>
            <p class="app-copy">© 2026 Giit. All rights reserved.</p>
          </div>
        </div>

        <div class="app-statusbar">
          <span class="keys"><kbd>tab</kbd> Swap Panels</span>
          <span class="keys">
            <kbd>⌘</kbd><b>+</b><kbd>z</kbd> Undo <em>|</em>
            <kbd>U</kbd> Recovery <em>|</em>
            <kbd>?</kbd> Help <em>|</em> 1.0.0
          </span>
        </div>
      </div>
    </section>

    <section id="safety" class="feature-band">
      <div class="section-heading">
        <p class="eyebrow">Why Giit is different</p>
        <h2>Safety is the workflow, not an afterthought.</h2>
      </div>

      <div class="feature-grid">
        <article
          v-for="feature in features"
          :key="feature.title"
          :class="['feature-card', feature.accent]"
        >
          <span class="feature-icon" v-html="feature.icon"></span>
          <h3>{{ feature.title }}</h3>
          <p>{{ feature.text }}</p>
        </article>
      </div>
    </section>

    <section class="workflow-section">
      <div class="section-heading compact">
        <p class="eyebrow">Built for real Git work</p>
        <h2>The sharp operations get guardrails.</h2>
      </div>

      <ul class="workflow-list">
        <li v-for="workflow in workflows" :key="workflow">{{ workflow }}</li>
      </ul>
    </section>

    <section id="install" class="install-section">
      <div class="install-copy">
        <p class="eyebrow">Install</p>
        <h2>Choose your download.</h2>
        <p>
          Grab the latest stable release for your platform.<br> 
          <b class="install-sub">(The site will automatically detect your operating system and chip architecture.)</b>
        </p>
      </div>

      <div class="install-panel">
        <a
          class="install-latest"
          :class="{ live: latest.version }"
          :href="releasesUrl"
          target="_blank"
          rel="noopener"
        >
          <span class="pulse"></span>{{ latestLabel }}
        </a>

        <div class="platform-tabs" aria-label="Platform selector">
          <button
            v-for="platform in platforms"
            :key="platform.id"
            :class="{ selected: detectedPlatform === platform.id }"
            type="button"
            @click="detectedPlatform = platform.id"
          >
            {{ platform.label }}
          </button>
        </div>

        <div class="install-actions">
          <a class="button primary" :href="downloadUrl" target="_blank" rel="noopener">
            {{ hasAsset ? `Download for ${activePlatform.label}` : 'View releases' }}
          </a>
          <p class="install-note">{{ activePlatform.note }}</p>
        </div>

        <div class="install-links">
          <a :href="releasesUrl" target="_blank">Releases</a>
          <a href="https://github.com/DanKaufmanDev/giit/blob/master/PRIVACY.md" target="_blank">Privacy</a>
          <a href="https://github.com/DanKaufmanDev/giit/blob/master/SECURITY.md" target="_blank">Security</a>
        </div>
      </div>
    </section>
  </main>

  <footer>
    <span>© 2026 Giit</span>
    <a href="https://github.com/DanKaufmanDev/giit/blob/master/LICENSE" target="_blank">License</a>
    <a href="https://github.com/DanKaufmanDev/giit/blob/master/CHANGELOG.md" target="_blank">Changelog</a>
    <a href="https://github.com/sponsors/DanKaufmanDev" target="_blank">Sponsor</a>
  </footer>
</template>

<style scoped>
:global(:root) {
  color: #e7eaef;
  background: #0e1116;
  font-family:
    "JetBrains Mono Variable", "JetBrains Mono", ui-monospace, "SFMono-Regular",
    Menlo, Consolas, monospace;
  font-synthesis: none;
  line-height: 1.5;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  color-scheme: dark;
  --ink: #e7eaef;
  --muted: #9aa4b0;
  --paper: #0e1116;
  --surface: #171b21;
  --panel-dark: #0a0c10;
  --line: #272d35;
  --red: #e56e60;
  --light-gold: #e7b64320;
  --gold: #e7b743;
  --green: #4bb185;
  --light-blue: #6ba9e334;
  --blue: #5b8cc0;
  --purple: #a78bfa;
}

:global(*) {
  box-sizing: border-box;
}

:global(html) {
  scroll-behavior: smooth;
  scroll-padding-top: 80px;
}

:global(body) {
  margin: 0;
  min-width: 320px;
}

a {
  color: inherit;
  text-decoration: none;
}

button {
  font: inherit;
}

:global(:focus-visible) {
  outline: 2px solid var(--blue);
  outline-offset: 3px;
}

@media (prefers-reduced-motion: reduce) {
  :global(*),
  :global(*::before),
  :global(*::after) {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001ms !important;
    scroll-behavior: auto !important;
  }
}

.site-header {
  position: sticky;
  top: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 72px;
  padding: 14px clamp(20px, 5vw, 72px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 25px;
  background: rgba(14, 17, 22, 0.85);
  backdrop-filter: blur(18px);
}

.brand,
nav,
.hero-actions,
.install-links,
footer {
  display: flex;
  align-items: center;
}

.brand {
  gap: 10px;
  font-weight: 900;
}

.brand img {
  width: 5rem;
  object-fit: contain;
}

nav {
  gap: clamp(14px, 3vw, 32px);
  color: var(--muted);
  font-size: 0.94rem;
  font-weight: 760;
}

nav a,
.install-links a,
footer a {
  transition: color 0.18s ease;
}

nav a:hover,
footer a:hover,
.install-links a:hover {
  color: var(--purple);
}

.hero-section,
.feature-band,
.workflow-section,
.install-section {
  padding: clamp(72px, 9vw, 120px) clamp(20px, 5vw, 72px);
}

.hero-section {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 0.86fr) minmax(420px, 1.14fr);
  gap: clamp(36px, 6vw, 84px);
  align-items: center;
  min-height: auto;
  overflow: hidden;
}

.hero-section::before {
  content: "";
  position: absolute;
  inset: -30% -10% auto -10%;
  z-index: 0;
  height: 720px;
  background:
    radial-gradient(46% 60% at 18% 4%, rgba(229, 110, 96, 0.18), transparent 70%),
    radial-gradient(42% 55% at 88% 12%, rgba(167, 139, 250, 0.16), transparent 72%);
  pointer-events: none;
}

.hero-copy,
.hero-section .product-frame {
  position: relative;
  z-index: 1;
}

.hero-copy {
  max-width: 680px;
  margin-bottom: auto;
}

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  margin-bottom: 22px;
  padding: 7px 14px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 700;
  transition: border-color 0.2s ease, color 0.2s ease;
}

.hero-badge:hover {
  border-color: rgba(167, 139, 250, 0.5);
  color: #e7eaef;
}

.hero-badge .pulse {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--green);
  box-shadow: 0 0 0 0 rgba(75, 177, 133, 0.5);
  animation: pulse 2.2s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(75, 177, 133, 0.5);
  }
  70% {
    box-shadow: 0 0 0 7px rgba(75, 177, 133, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(75, 177, 133, 0);
  }
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  margin: 0 0 18px;
  padding: 6px 12px;
  border: 1px solid rgba(96, 123, 229, 0.3);
  border-radius: 999px;
  background: rgba(96, 129, 229, 0.08);
  color: var(--blue);
  font-size: 0.72rem;
  font-weight: 800;
  letter-spacing: 1.4px;
  text-transform: uppercase;
}

.install-sub {
  color: #ffffff93;
  font-size: 0.85rem;
  opacity: 0.5;
}

.gradient-text {
  background: linear-gradient(110deg, var(--blue), var(--purple) 55%, var(--blue));
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  color: transparent;
}

h1,
h2,
h3,
p {
  margin-top: 0;
}

h1 {
  max-width: 760px;
  margin-bottom: 24px;
  color: var(--ink);
  font-size: clamp(2.85rem, 5vw, 4.65rem);
  line-height: 1.01;
  letter-spacing: 0;
}

h2 {
  margin-bottom: 18px;
  color: var(--ink);
  font-size: clamp(2.2rem, 5vw, 4.4rem);
  line-height: 1;
  letter-spacing: 0;
}

h3 {
  margin-bottom: 12px;
  font-size: 1.28rem;
  line-height: 1.15;
}

.hero-text,
.install-copy p {
  color: var(--muted);
  font-size: clamp(1.08rem, 2vw, 1.32rem);
}

.hero-actions {
  flex-wrap: wrap;
  gap: 14px;
  margin-top: 34px;
}

.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
  border: 1px solid var(--ink);
  border-radius: 8px;
  padding: 0 22px;
  font-weight: 900;
  transition: transform 0.15s ease, box-shadow 0.2s ease, background 0.2s ease,
    border-color 0.2s ease;
}

.button:hover {
  transform: translateY(-2px);
}

.button.primary {
  border-color: var(--blue);
  background: var(--light-blue);
  color: #ffffff;
  box-shadow: 0 8px 24px rgba(96, 169, 229, 0.35);
}

.button.primary:hover {
  box-shadow: 0 14px 32px rgba(96, 169, 229, 0.35);
}

.button.secondary {
  background: transparent;
}

.button.secondary:hover {
  border-color: #ffffff;
  background: rgba(255, 255, 255, 0.05);
}

.product-frame {
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 14px;
  background: #090c12;
  box-shadow: 0 30px 80px rgba(0, 0, 0, 0.55);
  font-family:
    "JetBrains Mono Variable", "JetBrains Mono", ui-monospace, "SFMono-Regular",
    Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.4;
  color: #aab3c0;
  user-select: none;
}

.app-titlebar {
  position: relative;
  display: flex;
  align-items: center;
  height: 36px;
  padding: 0 14px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  background: #0d111a;
}

.traffic {
  display: flex;
  gap: 8px;
}

.traffic span {
  width: 11px;
  height: 11px;
  border-radius: 999px;
  background: var(--red);
}

.traffic span:nth-child(2) {
  background: var(--gold);
}

.traffic span:nth-child(3) {
  background: var(--green);
}

.app-title {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  color: #c8cdd5;
  font-size: 12px;
  font-weight: 700;
}

.app-tabs {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  height: 42px;
  padding: 0 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  background: #0b0e15;
}

.tabs-left {
  display: flex;
  align-items: center;
  gap: 4px;
}

.tab {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 6px 12px;
  border-radius: 7px;
  color: #7e8895;
}

.tab.active {
  background: #161b24;
  color: #e7eaef;
}

.tab-dot {
  width: 7px;
  height: 7px;
  border-radius: 999px;
  background: #4a5260;
}

.tab-dot.green {
  background: var(--green);
}

.tab-dot.purple {
  background: var(--purple);
}

.tab-add {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: #7e8895;
  font-size: 15px;
  line-height: 1;
}

.detached {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: var(--purple);
  font-weight: 600;
}

.detached::before {
  content: "";
  width: 7px;
  height: 7px;
  border-radius: 999px;
  background: var(--purple);
}

.app-body {
  display: grid;
  grid-template-columns: 232px minmax(0, 1fr);
  flex: 1;
  min-height: 900px;
}

.app-sidebar {
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  /* Divider drawn as an inset shadow so it doesn't shrink the box the overlay centers against. */
  box-shadow: inset -1px 0 0 rgba(255, 255, 255, 0.06);
  background:
    radial-gradient(130% 45% at 50% 0%, rgba(124, 108, 210, 0.12), transparent 62%),
    #090c12;
}

.side-section {
  flex: 1 1 0;
  min-height: 0;
  overflow: hidden;
  padding: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 10px;
}

/* Files gets the lion's share; the remaining four split evenly. */
.side-section:first-child {
  flex: 3 1 0;
}

.side-section:last-child {
  border-bottom: none;
}

/* Frosted "glass" overlay that floats centered over the file browser. */
#active-section {
  margin: 2px;
  inset: 2%;
  z-index: 2;
  flex-direction: column;
  justify-content: center;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 12px;
  background: rgba(28, 32, 40, 0.45);
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.55);
  -webkit-backdrop-filter: blur(14px) saturate(140%);
  backdrop-filter: blur(14px) saturate(140%);
  overflow: hidden;
}

.side-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 0 0 10px;
  color: #5a6472;
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 1.6px;
  text-transform: uppercase;
}

.active-badge {
  padding: 2px 7px;
  border: 1px solid rgba(91, 140, 192, 0.4);
  border-radius: 5px;
  color: var(--blue);
  font-size: 8px;
  letter-spacing: 1px;
}

.file-tree {
  margin: 0;
  padding: 0;
  list-style: none;
}

.file-tree li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 4px 8px;
  margin: 0 -8px;
  border-radius: 6px;
}

.file-tree li.selected {
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.04);
}

.tree-join {
  flex: none;
  width: 11px;
  color: #4f5763;
  font-style: normal;
}

.tree-join::before {
  content: "└";
}

.fname {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.file-tree .folder > .fname {
  color: #e7eaef;
  font-weight: 700;
}

.caret {
  width: 0;
  height: 0;
  margin-right: 1px;
  border-top: 5px solid #8a93a0;
  border-right: 4px solid transparent;
  border-left: 4px solid transparent;
}

.indent-1 {
  padding-left: 16px;
}

.indent-2 {
  padding-left: 32px;
}

.badge {
  flex: none;
  font-size: 11px;
  font-weight: 700;
}

.badge.u {
  color: var(--blue);
  background: var(--light-blue);
  padding-right: 2px;
  padding-left: 2px;
  border-radius: 25%;
}

.badge.m {
  color: var(--gold);
  background: var(--light-gold);
  padding-right: 2px;
  padding-left: 2px;
  border-radius: 25%;
}

.empty {
  margin: 0;
  color: #4f5763;
  font-style: italic;
}

/* Branches */
.branch-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.branch-list li {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 5px 0;
}

.branch-dot {
  flex: none;
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--purple);
}

.branch-ico {
  flex: none;
  width: 8px;
  color: var(--purple);
  font-style: normal;
  text-align: center;
}

.branch-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: #d4d9e0;
}

.branch-list .remote .branch-name {
  color: #6b7480;
}

.head-badge {
  flex: none;
  padding: 1px 6px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.07);
  color: #8a93a0;
  font-size: 8px;
  font-weight: 700;
  letter-spacing: 1px;
}

/* Commit history & snapshots */
.log-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.log-list li {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 3px 9px;
  padding: 5px 0;
}

.log-hash {
  flex: none;
  padding: 1px 6px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 700;
}

.log-hash.commit {
  background: rgba(167, 139, 250, 0.16);
  color: #c4b5fd;
}

.log-hash.snap {
  background: rgba(231, 183, 67, 0.16);
  color: var(--gold);
}

/* Let msg and sub flow directly into the row so the sub can wrap full-width. */
.log-body {
  display: contents;
}

.log-msg {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: #d4d9e0;
}

.log-sub {
  flex-basis: 100%;
  color: #5a6472;
  font-size: 11px;
}

.log-time {
  flex: none;
  color: #5a6472;
  font-size: 11px;
  white-space: nowrap;
}

.app-main {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 40px 28px;
  text-align: center;
}

.app-logo {
  width: 96px;
  height: auto;
  margin-bottom: 4px;
}

.app-tagline {
  margin: 0;
  color: #e7eaef;
  font-size: 15px;
  font-weight: 700;
}

.app-desc {
  max-width: 380px;
  margin: 0;
  color: #8a93a0;
  line-height: 1.55;
}

.app-feature-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  width: 100%;
  max-width: 430px;
  margin-top: 6px;
}

.app-feature {
  padding: 12px 14px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.02);
  text-align: left;
}

.app-feature strong {
  display: block;
  margin-bottom: 5px;
  font-size: 12px;
}

.app-feature span {
  color: #8a93a0;
  font-size: 11px;
  line-height: 1.45;
}

.app-feature .blue {
  color: var(--blue);
}

.app-feature .purple {
  color: var(--purple);
}

.app-feature .green {
  color: var(--green);
}

.app-feature .gold {
  color: var(--gold);
}

.app-hint {
  margin: 10px 0 0;
  color: #8a93a0;
}

.app-copy {
  margin: 0;
  color: #4f5763;
  font-size: 11px;
}

.product-frame kbd {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  padding: 1px 6px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 5px;
  background: rgba(255, 255, 255, 0.05);
  color: #c8cdd5;
  font: inherit;
  font-size: 11px;
}

.app-statusbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  height: 36px;
  padding: 0 14px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  background: #0d111a;
  color: #7e8895;
}

.app-statusbar .keys {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.app-statusbar em {
  color: #313945;
  font-style: normal;
}

.feature-card,
.install-panel {
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  background: var(--surface);
}

code {
  overflow-wrap: anywhere;
  border-radius: 6px;
  background: #20242b;
  color: #f8f6ef;
  font-family: "SFMono-Regular", ui-monospace, Menlo, Consolas, monospace;
  font-size: 0.9rem;
}

.diff-panel code {
  padding: 12px;
}

.feature-band {
  position: relative;
  background:
    radial-gradient(60% 70% at 50% 0%, rgba(124, 108, 210, 0.1), transparent 70%),
    linear-gradient(180deg, #161b22, #0e1116);
  color: #ffffff;
}

.feature-band h2,
.feature-band h3 {
  color: #ffffff;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
  margin-top: 42px;
}

.feature-card {
  display: flex;
  flex-direction: column;
  min-height: 240px;
  padding: clamp(24px, 3vw, 34px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.025);
  color: var(--ink);
  transition: transform 0.2s ease, border-color 0.2s ease, background 0.2s ease;
}

.feature-card:hover {
  transform: translateY(-4px);
  border-color: rgba(255, 255, 255, 0.18);
  background: rgba(255, 255, 255, 0.05);
}

.feature-card p {
  margin: 0;
  color: var(--muted);
  line-height: 1.6;
}

.feature-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 46px;
  height: 46px;
  margin-bottom: 20px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.05);
}

/* :deep() so the rule reaches the v-html-injected <svg> (no scope attribute). */
.feature-icon :deep(svg) {
  width: 24px;
  height: 24px;
}

.feature-card.red .feature-icon {
  color: var(--red);
  background: rgba(229, 110, 96, 0.13);
}

.feature-card.green .feature-icon {
  color: var(--green);
  background: rgba(75, 177, 133, 0.13);
}

.feature-card.blue .feature-icon {
  color: var(--blue);
  background: rgba(91, 140, 192, 0.13);
}

.workflow-section {
  display: grid;
  grid-template-columns: minmax(0, 0.75fr) minmax(320px, 1fr);
  gap: clamp(36px, 7vw, 88px);
  align-items: start;
}

.compact {
  max-width: 560px;
}

.workflow-list {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.workflow-list li {
  display: flex;
  align-items: center;
  gap: 14px;
  min-height: 78px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-left: 3px solid var(--blue);
  border-radius: 10px;
  padding: 18px;
  background: var(--surface);
  font-weight: 700;
  transition: transform 0.18s ease, border-color 0.18s ease, background 0.18s ease;
}

.workflow-list li::before {
  content: "✓";
  flex: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 7px;
  background: var(--light-blue);
  color: var(--blue);
  font-size: 12px;
  font-weight: 900;
}

.workflow-list li:hover {
  transform: translateX(4px);
  border-left-color: var(--purple);
  background: #1b2129;
}

.install-section {
  display: grid;
  grid-template-columns: minmax(0, 0.82fr) minmax(380px, 1fr);
  gap: clamp(36px, 7vw, 84px);
  align-items: center;
  background: #12161c;
}

.install-panel {
  padding: clamp(22px, 4vw, 36px);
  border-radius: 14px;
  box-shadow: 0 22px 60px rgba(0, 0, 0, 0.45);
}

.install-latest {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  width: fit-content;
  margin-bottom: 18px;
  padding: 6px 12px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 700;
  transition: border-color 0.2s ease, color 0.2s ease;
}

.install-latest:hover {
  border-color: rgba(255, 255, 255, 0.28);
  color: var(--ink);
}

.install-latest .pulse {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--gold);
}

.install-latest.live .pulse {
  background: var(--green);
  box-shadow: 0 0 0 0 rgba(75, 177, 133, 0.5);
  animation: pulse 2.2s infinite;
}

.platform-tabs {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-bottom: 18px;
}

.platform-tabs button {
  min-height: 42px;
  cursor: pointer;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  background: var(--surface);
  color: var(--ink);
  font-weight: 900;
  transition: transform 0.15s ease, border-color 0.18s ease, background 0.18s ease,
    box-shadow 0.2s ease;
}

.platform-tabs button:hover {
  border-color: rgba(255, 255, 255, 0.28);
}

.platform-tabs .selected,
.platform-tabs .selected:hover {
  border-color: var(--blue);
  background: rgba(96, 138, 229, 0.16);
}

.install-actions {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-top: 16px;
}

.install-actions .button {
  width: fit-content;
}

.install-note {
  margin: 0;
  color: var(--muted);
}

.install-links {
  flex-wrap: wrap;
  gap: 16px;
  margin-top: 24px;
  color: var(--blue);
  font-weight: 900;
}

footer {
  flex-wrap: wrap;
  justify-content: center;
  gap: 18px 28px;
  padding: 34px 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  color: var(--muted);
  font-size: 0.94rem;
  font-weight: 760;
}

@media (max-width: 980px) {
  .hero-section,
  .workflow-section,
  .install-section {
    grid-template-columns: 1fr;
  }

  .feature-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 680px) {
  .site-header {
    position: static;
    align-items: flex-start;
    flex-direction: column;
    gap: 14px;
  }

  nav {
    width: 100%;
    justify-content: space-between;
    gap: 10px;
    overflow-x: auto;
    padding-bottom: 4px;
  }

  h1 {
    font-size: 3.2rem;
  }

  .hero-section,
  .feature-band,
  .workflow-section,
  .install-section {
    padding-top: 64px;
    padding-bottom: 64px;
  }

  .workflow-list,
  .platform-tabs,
  .command-box {
    grid-template-columns: 1fr;
  }

  .app-body {
    grid-template-columns: 168px minmax(0, 1fr);
  }

  .app-feature-grid {
    grid-template-columns: 1fr;
  }

  .button {
    width: 100%;
  }
}
</style>