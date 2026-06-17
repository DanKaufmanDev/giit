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