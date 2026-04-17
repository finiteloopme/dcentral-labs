#!/usr/bin/env bash
# customize-ui.sh — Patch bundled adk-web with Gemini AI visual branding
# Idempotent: safe to run multiple times.
# Usage: cd packages/adk-backend && bash scripts/customize-ui.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_DIR="$PKG_DIR/assets"
UI_DIR="$PKG_DIR/node_modules/@google/adk-devtools/dist/browser"

# ── Guard: skip if adk-web bundle is missing ──────────────────────────
if [[ ! -d "$UI_DIR" ]]; then
  echo "[customize-ui] adk-web browser dir not found at $UI_DIR — skipping."
  exit 0
fi

INDEX="$UI_DIR/index.html"
if [[ ! -f "$INDEX" ]]; then
  echo "[customize-ui] index.html not found at $INDEX — skipping."
  exit 0
fi

echo "[customize-ui] Patching adk-web in $UI_DIR"

# ── 1. Patch page title ──────────────────────────────────────────────
if grep -q '<title>Agent Playground' "$INDEX"; then
  echo "[customize-ui]  ✓ Title already patched"
else
  perl -0777 -pi -e 's/<title>[^<]*<\/title>/<title>Agent Playground | Google Cloud<\/title>/s' "$INDEX"
  echo "[customize-ui]  ✓ Title updated"
fi

# ── 2. Inject Gemini CSS (before </head>) ────────────────────────────
MARKER="Agent Playground — Gemini AI Visual Design"
if grep -qF "$MARKER" "$INDEX"; then
  echo "[customize-ui]  ✓ CSS already injected"
else
  # Write CSS to a temp file, then use perl to insert before </head>
  CSS_FILE=$(mktemp)
  cat > "$CSS_FILE" << 'CSSEOF'
<style>
/* Agent Playground — Gemini AI Visual Design */
html.dark-theme {
  /* Gemini sparkle gradient accents */
  --builder-canvas-header-title-gradient: linear-gradient(135deg, #4285F4, #A370F0, #F87171, #FBBC05);
  --builder-canvas-container-background: linear-gradient(135deg, #0c0b0f 0%, #131314 50%, #0f1218 100%);
  --builder-canvas-node-badge-background: linear-gradient(135deg, rgba(66,133,244,0.2), rgba(163,112,240,0.3));
  --builder-canvas-add-btn-shadow: 0 4px 12px rgba(66,133,244,0.35);
  --builder-canvas-header-background: linear-gradient(90deg, #1a1820 0%, #1e2030 100%);

  /* Gemini accent on active/focused elements */
  --chat-panel-bot-message-focus-within-message-card-border-color: #A370F0;
  --event-tab-event-list-active-indicator-color: #A370F0;
  --chat-panel-thought-chip-background-color: linear-gradient(90deg, #4285F4, #A370F0);

  /* Subtle blue-purple tint on surfaces */
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
</style>
CSSEOF

  # Read CSS content and inject before </head>
  perl -0777 -pi -e '
    open(my $fh, "<", "'"$CSS_FILE"'") or die "Cannot open CSS file: $!";
    my $css = do { local $/; <$fh> };
    close($fh);
    s{</head>}{$css</head>}s;
  ' "$INDEX"
  rm -f "$CSS_FILE"
  echo "[customize-ui]  ✓ Gemini CSS injected"
fi

# ── 3. Replace favicon ───────────────────────────────────────────────
FAVICON_TARGET="$UI_DIR/adk_favicon.svg"
if [[ -f "$ASSETS_DIR/favicon.svg" ]]; then
  cp "$ASSETS_DIR/favicon.svg" "$FAVICON_TARGET"
  echo "[customize-ui]  ✓ Favicon replaced"
else
  echo "[customize-ui]  ⚠ favicon.svg not found in $ASSETS_DIR — skipped"
fi

# ── 4. Replace logo ─────────────────────────────────────────────────
LOGO_TARGET="$UI_DIR/assets/ADK-512-color.svg"
if [[ -f "$ASSETS_DIR/logo.svg" ]] && [[ -d "$UI_DIR/assets" ]]; then
  cp "$ASSETS_DIR/logo.svg" "$LOGO_TARGET"
  echo "[customize-ui]  ✓ Logo replaced"
elif [[ -f "$ASSETS_DIR/logo.svg" ]]; then
  mkdir -p "$UI_DIR/assets"
  cp "$ASSETS_DIR/logo.svg" "$LOGO_TARGET"
  echo "[customize-ui]  ✓ Logo replaced (created assets dir)"
else
  echo "[customize-ui]  ⚠ logo.svg not found in $ASSETS_DIR — skipped"
fi

echo "[customize-ui] Done."
