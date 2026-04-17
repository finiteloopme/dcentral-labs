#!/usr/bin/env bash
# Customize adk-web UI bundled inside @google/adk-devtools
# This script patches the bundled dev-ui files with Agent Playground branding
# and Gemini-aligned styles. Run after pnpm install.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Find the bundled browser directory
BROWSER_DIR="${PACKAGE_DIR}/node_modules/@google/adk-devtools/dist/browser"

if [ ! -d "$BROWSER_DIR" ]; then
  echo "[customize-ui] Browser directory not found at ${BROWSER_DIR}, skipping"
  exit 0
fi

echo "[customize-ui] Customizing adk-web UI at ${BROWSER_DIR}..."

# --- 1. Patch index.html ---
INDEX_HTML="${BROWSER_DIR}/index.html"

if [ -f "$INDEX_HTML" ]; then
  # Replace page title
  sed -i 's|<title>[^<]*</title>|<title>Agent Playground \| Google Cloud</title>|g' "$INDEX_HTML"

  # Inject Gemini branding CSS and feature flag overrides before </head>
  # Only inject if not already present (idempotent)
  if ! grep -q "agent-playground-branding" "$INDEX_HTML"; then
    # Write CSS to temp file for safe injection (avoids sed delimiter issues)
    CSS_FILE=$(mktemp)
    cat > "$CSS_FILE" << 'CSSEOF'
<!-- Agent Playground Branding -->
<style id="agent-playground-branding">
  /* === Gemini Sparkle Gradients === */
  html.dark-theme {
    /* Canvas/builder header title gradient - Gemini sparkle colors */
    --builder-canvas-header-title-gradient: linear-gradient(135deg, #4285F4, #A370F0, #F87171, #FBBC05);
    --builder-canvas-container-background: linear-gradient(135deg, #0c0b0f 0%, #131314 50%, #0f1218 100%);
    --builder-canvas-node-badge-background: linear-gradient(135deg, rgba(66, 133, 244, 0.2), rgba(163, 112, 240, 0.3));
    --builder-canvas-add-btn-shadow: 0 4px 12px rgba(66, 133, 244, 0.35);
    --builder-canvas-header-background: linear-gradient(90deg, #1a1820 0%, #1e2030 100%);

    /* Gemini purple accent on active/focused elements */
    --chat-panel-bot-message-focus-within-message-card-border-color: #A370F0;
    --event-tab-event-list-active-indicator-color: #A370F0;
    --chat-panel-thought-chip-background-color: linear-gradient(90deg, #4285F4, #A370F0);

    /* Subtle blue-purple tint on surfaces (vs pure gray) */
    --chat-side-drawer-background-color: #18161e;
    --chat-toolbar-background-color: #1a1820;
    --side-panel-app-select-container-background-color: #1a1820;
    --side-panel-details-panel-container-background-color: #1e1c26;

    /* Gemini sparkle for user message bubbles */
    --chat-panel-user-message-message-card-background-color: #1a2744;
    --chat-user-message-message-card-background-color: #1a2744;

    /* Toolbar toggle with Gemini purple */
    --chat-toolbar-sse-toggle-selected-track-color: #A370F0;
    --chat-toolbar-sse-toggle-selected-handle-color: #4285F4;

    /* Builder accent — Gemini blue */
    --builder-accent-color: #4285F4;
    --builder-button-primary-background-color: linear-gradient(90deg, #4285F4, #A370F0);

    /* Trace bars with Gemini blue */
    --trace-tab-trace-bar-background-color: #1a2744;
    --trace-tab-trace-bar-color: #8AB4F8;
    --trace-tree-trace-bar-background-color: #1a2744;
    --trace-tree-trace-bar-color: #8AB4F8;
  }

  /* === Hide elements for clean Agent Playground UX === */
  /* Hide Dev UI disclaimer banner */
  .developer-disclaimer, [class*="disclaimer"] {
    display: none !important;
  }
  /* Hide eval tab (endpoints return 501 in adk-js) */
  [aria-label="Eval"], mat-tab[aria-label="Eval"] {
    display: none !important;
  }
  /* Hide bidi streaming controls (not implemented in adk-js) */
  .bidi-streaming-controls, [class*="bidi"] {
    display: none !important;
  }
</style>
CSSEOF

    # Use perl to safely inject CSS before </head> (handles all special chars)
    perl -0777 -pi -e '
      open(my $fh, "<", "'"$CSS_FILE"'") or die "Cannot open CSS file: $!";
      my $css = do { local $/; <$fh> };
      close($fh);
      s{</head>}{$css</head>}s;
    ' "$INDEX_HTML"
    rm -f "$CSS_FILE"
    echo "[customize-ui] ✓ Injected Gemini branding CSS"
  else
    echo "[customize-ui] Branding CSS already present, skipping"
  fi
fi

# --- 2. Replace favicon ---
CUSTOM_FAVICON="${PACKAGE_DIR}/assets/favicon.svg"
if [ -f "$CUSTOM_FAVICON" ]; then
  cp "$CUSTOM_FAVICON" "${BROWSER_DIR}/adk_favicon.svg"
  echo "[customize-ui] ✓ Replaced favicon"
fi

# --- 3. Replace logo ---
CUSTOM_LOGO="${PACKAGE_DIR}/assets/logo.svg"
if [ -f "$CUSTOM_LOGO" ]; then
  mkdir -p "${BROWSER_DIR}/assets"
  cp "$CUSTOM_LOGO" "${BROWSER_DIR}/assets/ADK-512-color.svg"
  echo "[customize-ui] ✓ Replaced logo"
fi

# --- 4. Copy Agent Playground injection script ---
if [ -f "$SCRIPT_DIR/../assets/agent-playground.js" ]; then
  cp "$SCRIPT_DIR/../assets/agent-playground.js" "$BROWSER_DIR/agent-playground.js"
  echo "[customize-ui] ✓ Copied agent-playground.js"
fi

# --- 5. Inject agent-playground.js script tag before </body> ---
if [ -f "$BROWSER_DIR/agent-playground.js" ]; then
  perl -i -pe 's|</body>|<script src="./agent-playground.js"></script></body>|' "$BROWSER_DIR/index.html"
  echo "[customize-ui] ✓ Injected agent-playground.js script tag"
fi

echo "[customize-ui] Done!"
