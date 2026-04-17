/**
 * Agent Playground - UI Injection Layer
 * ======================================
 * Transforms the adk-web dev UI into a premium "Agent Playground" experience.
 *
 * Inject into adk-web index.html:
 *   <script src="/agent-playground.js"></script>
 *
 * Features:
 *   1. Welcome screen overlay with agent cards and suggestion chips
 *   2. Toolbar declutter (hide dev-only elements)
 *   3. Agent-aware bot message labels (MutationObserver)
 *   4. Auto-hide side panel
 *   5. CSS polish injection
 */
(function AgentPlayground() {
  'use strict';

  // =========================================================================
  // Configuration
  // =========================================================================

  const REGISTRY_URL = 'http://localhost:4000/agents';

  const PALETTE = {
    bg: '#131314',
    surface: '#1E1F20',
    surfaceHover: '#282A2C',
    text: '#E8EAED',
    muted: '#9AA0A6',
    accent: '#8AB4F8',
    border: '#303030',
    borderHover: '#5F6368',
  };

  const AGENT_META = {
    agent_playground: { name: 'Agent Playground', color: '#8AB4F8', icon: '✨' },
    somnia_agent:     { name: 'Somnia',           color: '#A370F0', icon: '⚡' },
    somnia:           { name: 'Somnia',           color: '#A370F0', icon: '⚡' },
    sonic_agent:      { name: 'Sonic',            color: '#4285F4', icon: '🔵' },
    sonic:            { name: 'Sonic',            color: '#4285F4', icon: '🔵' },
    midnight_agent:   { name: 'Midnight',         color: '#F87171', icon: '🌙' },
    midnight:         { name: 'Midnight',         color: '#F87171', icon: '🌙' },
    store_agent:      { name: 'Store',            color: '#34A853', icon: '🏪' },
    store:            { name: 'Store',            color: '#34A853', icon: '🏪' },
    payment_agent:    { name: 'Payment',          color: '#FBBC05', icon: '💳' },
    payment:          { name: 'Payment',          color: '#FBBC05', icon: '💳' },
    security_agent:   { name: 'Security',         color: '#EA4335', icon: '🛡️' },
    security:         { name: 'Security',         color: '#EA4335', icon: '🛡️' },
  };

  // Agent card border colors by type
  function getAgentBorderColor(agent) {
    const id = agent.id || '';
    if (['somnia', 'sonic'].includes(id)) return '#4285F4';       // EVM chains = blue
    if (id === 'midnight') return '#A370F0';                       // Midnight = purple
    if (['store', 'payment'].includes(id)) return '#34A853';       // Commerce = green
    if (id === 'security') return '#EA4335';                       // Security = red
    return PALETTE.accent;
  }

  // =========================================================================
  // 1. CSS Injection
  // =========================================================================

  function injectCSS() {
    const style = document.createElement('style');
    style.id = 'ap-styles';
    style.textContent = `
      /* Hide event numbers on messages (show on hover) */
      .event-number-label { opacity: 0; transition: opacity 0.2s; }
      .message-row:hover .event-number-label { opacity: 1; }

      /* Hide function call raw JSON by default */
      .function-args-tooltip { display: none; }

      /* Softer message bubbles */
      .message-card { border-radius: 16px !important; }

      /* Hide "Powered by ADK" or similar disclaimers */
      .powered-by-adk { display: none !important; }

      /* Welcome overlay transitions */
      #ap-welcome {
        transition: opacity 0.3s ease, transform 0.3s ease;
      }
      #ap-welcome.ap-dismiss {
        opacity: 0;
        transform: translateY(-20px);
        pointer-events: none;
      }

      /* Agent card hover */
      .ap-agent-card {
        transition: border-color 0.2s, background 0.2s, transform 0.15s;
        cursor: default;
      }
      .ap-agent-card:hover {
        background: ${PALETTE.surfaceHover} !important;
        border-color: ${PALETTE.borderHover} !important;
        transform: translateY(-2px);
      }

      /* Suggestion chip hover */
      .ap-chip {
        transition: background 0.2s, border-color 0.2s, transform 0.15s;
        cursor: pointer;
      }
      .ap-chip:hover {
        background: ${PALETTE.surfaceHover} !important;
        border-color: ${PALETTE.accent} !important;
        transform: translateY(-1px);
      }

      /* Agent label on bot messages */
      .ap-agent-label {
        font-size: 11px;
        font-weight: 500;
        letter-spacing: 0.5px;
        padding: 2px 8px;
        border-radius: 4px;
        display: inline-flex;
        align-items: center;
        gap: 4px;
        margin-bottom: 4px;
        background: rgba(255,255,255,0.05);
      }

      /* Toolbar branding */
      .ap-toolbar-brand {
        font-size: 14px;
        font-weight: 500;
        background: linear-gradient(135deg, #4285F4, #A370F0);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        letter-spacing: 0.5px;
        white-space: nowrap;
      }
    `;
    document.head.appendChild(style);
  }

  // =========================================================================
  // 2. Hide Side Panel on Load
  // =========================================================================

  function hideSidePanel() {
    if (!window.location.search.includes('hideSidePanel')) {
      const url = new URL(window.location);
      url.searchParams.set('hideSidePanel', 'true');
      window.history.replaceState({}, '', url);
    }
  }

  // =========================================================================
  // 3. Welcome Screen Overlay
  // =========================================================================

  /** Fetch agent data from registry + agent cards for skills */
  async function fetchAgentData() {
    try {
      const res = await fetch(REGISTRY_URL);
      if (!res.ok) throw new Error(`Registry returned ${res.status}`);
      const data = await res.json();
      const agents = data.agents || [];

      // Fetch agent cards in parallel for skill data
      const enriched = await Promise.all(
        agents.map(async (agent) => {
          try {
            const cardUrl = `${agent.url.replace(/\/$/, '')}/.well-known/agent-card.json`;
            const cardRes = await fetch(cardUrl, { signal: AbortSignal.timeout(3000) });
            if (cardRes.ok) {
              const card = await cardRes.json();
              agent._skills = card.skills || [];
            }
          } catch {
            // Agent not reachable — that's fine, we still show the card
            agent._skills = [];
          }
          return agent;
        })
      );

      return enriched;
    } catch (err) {
      console.warn('[AgentPlayground] Could not fetch agent data:', err);
      return null;
    }
  }

  /** Create a single agent card element */
  function createAgentCard(agent) {
    const borderColor = getAgentBorderColor(agent);
    const meta = AGENT_META[agent.id] || { icon: '🤖', color: PALETTE.accent };
    const skillCount = (agent._skills || []).length;
    const firstSentence = (agent.description || '').split(/\.\s/)[0] + '.';

    const card = document.createElement('div');
    card.className = 'ap-agent-card';
    card.style.cssText = `
      background: ${PALETTE.surface};
      border: 1px solid ${PALETTE.border};
      border-left: 3px solid ${borderColor};
      border-radius: 12px;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    `;

    card.innerHTML = `
      <div style="display:flex; align-items:center; justify-content:space-between;">
        <span style="font-size:16px; font-weight:500; color:${PALETTE.text};">
          ${meta.icon} ${agent.name}
        </span>
        ${skillCount > 0 ? `
          <span style="font-size:11px; color:${PALETTE.muted}; background:${PALETTE.bg}; padding:2px 8px; border-radius:10px; border:1px solid ${PALETTE.border};">
            ${skillCount} skill${skillCount !== 1 ? 's' : ''}
          </span>
        ` : ''}
      </div>
      <p style="font-size:13px; color:${PALETTE.muted}; margin:0; line-height:1.4;">
        ${firstSentence}
      </p>
      ${agent.keywords ? `
        <div style="display:flex; flex-wrap:wrap; gap:4px; margin-top:4px;">
          ${agent.keywords.slice(0, 4).map(kw => `
            <span style="font-size:10px; color:${PALETTE.muted}; background:${PALETTE.bg}; padding:1px 6px; border-radius:6px; border:1px solid ${PALETTE.border};">
              ${kw}
            </span>
          `).join('')}
        </div>
      ` : ''}
    `;

    return card;
  }

  /** Create a suggestion chip */
  function createSuggestionChip(text, agentMeta) {
    const chip = document.createElement('button');
    chip.className = 'ap-chip';
    chip.style.cssText = `
      background: ${PALETTE.surface};
      border: 1px solid ${PALETTE.border};
      border-radius: 20px;
      padding: 8px 16px;
      color: ${PALETTE.text};
      font-size: 13px;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      max-width: 280px;
      text-align: left;
      font-family: inherit;
    `;
    chip.innerHTML = `<span style="flex-shrink:0;">${agentMeta.icon}</span> ${text}`;
    chip.title = `Try: "${text}"`;

    chip.addEventListener('click', () => {
      injectIntoChat(text);
      dismissWelcome();
    });

    return chip;
  }

  /** Inject text into the chat input */
  function injectIntoChat(text) {
    // adk-web uses a textarea for chat input
    const textarea = document.querySelector('textarea');
    if (textarea) {
      // Angular needs nativeElement value + input event
      const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
        window.HTMLTextAreaElement.prototype, 'value'
      ).set;
      nativeInputValueSetter.call(textarea, text);
      textarea.dispatchEvent(new Event('input', { bubbles: true }));
      textarea.focus();
    }
  }

  /** Dismiss the welcome overlay */
  function dismissWelcome() {
    const welcome = document.getElementById('ap-welcome');
    if (welcome) {
      welcome.classList.add('ap-dismiss');
      setTimeout(() => welcome.remove(), 300);
    }
  }

  /** Build and insert the welcome overlay */
  async function showWelcomeScreen() {
    // Wait for the chat container to exist
    const chatContainer = await waitForElement('.chat-container, .messages-container, mat-sidenav-content, .mat-sidenav-content');
    if (!chatContainer) {
      console.warn('[AgentPlayground] Could not find chat container for welcome overlay');
      return;
    }

    // Don't show if messages already exist
    const existingMessages = document.querySelectorAll('.message-row, .message-card');
    if (existingMessages.length > 0) return;

    // Create overlay
    const overlay = document.createElement('div');
    overlay.id = 'ap-welcome';
    overlay.style.cssText = `
      position: absolute;
      inset: 0;
      z-index: 100;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      background: ${PALETTE.bg};
      padding: 40px;
      overflow-y: auto;
    `;

    overlay.innerHTML = `
      <h1 style="font-size:48px; font-weight:300; background:linear-gradient(135deg, #4285F4, #A370F0, #F87171, #FBBC05); -webkit-background-clip:text; -webkit-text-fill-color:transparent; margin:0 0 8px 0; text-align:center;">
        Agent Playground
      </h1>
      <p style="color:${PALETTE.muted}; font-size:18px; margin:0 0 40px 0; text-align:center;">
        Multi-chain blockchain development assistant
      </p>
      <div id="ap-agents" style="display:grid; grid-template-columns:repeat(3, 1fr); gap:16px; max-width:800px; width:100%;"></div>
      <div id="ap-suggestions" style="display:flex; flex-wrap:wrap; gap:8px; margin-top:32px; justify-content:center; max-width:800px;"></div>
      <p style="color:${PALETTE.border}; font-size:12px; margin-top:40px; text-align:center;">
        Click a suggestion or start typing to begin
      </p>
    `;

    // Insert into the chat area (needs relative positioning for absolute overlay)
    const parent = chatContainer;
    const computedPos = window.getComputedStyle(parent).position;
    if (computedPos === 'static') {
      parent.style.position = 'relative';
    }
    parent.appendChild(overlay);

    // Populate with agent data
    const agents = await fetchAgentData();
    const agentsGrid = document.getElementById('ap-agents');
    const suggestionsDiv = document.getElementById('ap-suggestions');

    if (agents && agentsGrid) {
      agents.forEach(agent => {
        agentsGrid.appendChild(createAgentCard(agent));
      });

      // Collect suggestion chips from agent skills
      if (suggestionsDiv) {
        const suggestions = [];
        agents.forEach(agent => {
          const meta = AGENT_META[agent.id] || { icon: '🤖', color: PALETTE.accent };
          (agent._skills || []).forEach(skill => {
            if (skill.examples && skill.examples.length > 0) {
              suggestions.push({ text: skill.examples[0], meta });
            }
          });
        });

        // Pick a diverse set (max 8, spread across agents)
        const picked = [];
        const byAgent = new Map();
        suggestions.forEach(s => {
          const key = s.meta.icon;
          if (!byAgent.has(key)) byAgent.set(key, []);
          byAgent.get(key).push(s);
        });
        // Round-robin pick
        let round = 0;
        while (picked.length < 8) {
          let added = false;
          for (const [, items] of byAgent) {
            if (round < items.length && picked.length < 8) {
              picked.push(items[round]);
              added = true;
            }
          }
          if (!added) break;
          round++;
        }

        picked.forEach(s => {
          suggestionsDiv.appendChild(createSuggestionChip(s.text, s.meta));
        });
      }
    } else if (agentsGrid) {
      // Fallback: show a message if registry is unreachable
      agentsGrid.innerHTML = `
        <div style="grid-column: 1/-1; text-align:center; color:${PALETTE.muted}; padding:20px;">
          <p style="font-size:14px; margin:0;">Agent registry not available</p>
          <p style="font-size:12px; margin:8px 0 0 0; color:${PALETTE.border};">Start typing to begin chatting</p>
        </div>
      `;
    }

    // Dismiss on typing
    const textarea = document.querySelector('textarea');
    if (textarea) {
      textarea.addEventListener('input', () => dismissWelcome(), { once: true });
    }

    // Also watch for textarea appearing later (Angular lazy render)
    const inputObserver = new MutationObserver(() => {
      const ta = document.querySelector('textarea');
      if (ta) {
        ta.addEventListener('input', () => dismissWelcome(), { once: true });
        inputObserver.disconnect();
      }
    });
    inputObserver.observe(document.body, { childList: true, subtree: true });
  }

  // =========================================================================
  // 4. Toolbar Declutter
  // =========================================================================

  function declutterToolbar() {
    // UUID pattern for session/user IDs
    const uuidPattern = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;

    function hideDevElements() {
      // Strategy: walk all text nodes and elements looking for dev-only content
      const allElements = document.querySelectorAll('*');

      allElements.forEach(el => {
        const text = el.textContent || '';
        const tag = el.tagName.toLowerCase();

        // Skip our own elements
        if (el.id && el.id.startsWith('ap-')) return;
        if (el.closest('#ap-welcome')) return;

        // Hide elements containing UUID patterns (session/user ID displays)
        // But only small elements (not the whole page)
        if (uuidPattern.test(text) && text.length < 200 && !['body', 'html', 'app-root'].includes(tag)) {
          // Check if this is a label/display element, not a container
          const isLeaf = el.children.length <= 2;
          if (isLeaf && el.offsetHeight < 60) {
            el.style.display = 'none';
          }
        }

        // Hide "SSE" toggle
        if (text.trim() === 'SSE' && el.offsetHeight < 50) {
          // Find the parent that contains the toggle
          const parent = el.closest('mat-slide-toggle') || el.closest('.mat-slide-toggle') || el.parentElement;
          if (parent) parent.style.display = 'none';
        }

        // Hide "Developer UI" disclaimer banner
        if (text.includes('Developer UI') && text.includes('not intended') || text.includes('developer purposes')) {
          el.style.display = 'none';
        }

        // Hide bottom disclaimer bar
        if (el.classList.contains('disclaimer') || el.classList.contains('footer-disclaimer')) {
          el.style.display = 'none';
        }
      });

      // Try to insert branding in toolbar
      const toolbar = document.querySelector('mat-toolbar, .mat-toolbar, [role="toolbar"]');
      if (toolbar && !document.getElementById('ap-brand')) {
        const brand = document.createElement('span');
        brand.id = 'ap-brand';
        brand.className = 'ap-toolbar-brand';
        brand.textContent = '✨ Agent Playground';

        // Insert after the first child (usually the menu button)
        const firstChild = toolbar.firstElementChild;
        if (firstChild && firstChild.nextSibling) {
          toolbar.insertBefore(brand, firstChild.nextSibling);
        } else {
          toolbar.prepend(brand);
        }
      }
    }

    // Run immediately and again after Angular renders
    setTimeout(hideDevElements, 500);
    setTimeout(hideDevElements, 1500);
    setTimeout(hideDevElements, 3000);

    // Also use MutationObserver for dynamically added elements
    let declutterCount = 0;
    const maxDeclutter = 10;
    const observer = new MutationObserver(() => {
      if (declutterCount < maxDeclutter) {
        declutterCount++;
        hideDevElements();
      } else {
        observer.disconnect();
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  // =========================================================================
  // 5. Agent-Aware Bot Messages (MutationObserver)
  // =========================================================================

  function setupMessageObserver() {
    const processedMessages = new WeakSet();

    function labelBotMessages() {
      // adk-web bot messages have a robot icon button with mat-mini-fab
      // The author name is in the matTooltip on that button
      const botIcons = document.querySelectorAll('button[mat-mini-fab], .mat-mini-fab, .mat-mdc-mini-fab');

      botIcons.forEach(btn => {
        // Skip already processed
        if (processedMessages.has(btn)) return;

        // Get the tooltip text (agent name)
        const tooltip = btn.getAttribute('mattooltip') ||
                        btn.getAttribute('matTooltip') ||
                        btn.getAttribute('aria-label') ||
                        btn.getAttribute('title') || '';

        if (!tooltip) return;

        // Normalize: "somnia_agent" or "Somnia Agent" → lookup key
        const normalizedKey = tooltip.toLowerCase().replace(/\s+/g, '_');
        const meta = AGENT_META[normalizedKey] ||
                     AGENT_META[tooltip] ||
                     AGENT_META[tooltip.toLowerCase()];

        if (!meta) return;

        processedMessages.add(btn);

        // Find the message content container (sibling or parent's child)
        const messageRow = btn.closest('.message-row') || btn.closest('.message-card') || btn.parentElement?.parentElement;
        if (!messageRow) return;

        // Check if label already exists
        if (messageRow.querySelector('.ap-agent-label')) return;

        // Find the message content area
        const contentArea = messageRow.querySelector('.message-content, .markdown-content, mat-card-content, .mat-card-content, .mat-mdc-card-content');
        if (!contentArea) return;

        // Create label
        const label = document.createElement('div');
        label.className = 'ap-agent-label';
        label.style.color = meta.color;
        label.innerHTML = `${meta.icon} ${meta.name}`;

        // Insert before the content
        contentArea.parentElement.insertBefore(label, contentArea);
      });
    }

    // Run on existing messages
    setTimeout(labelBotMessages, 1000);

    // Watch for new messages
    const observer = new MutationObserver(() => {
      // Debounce
      clearTimeout(observer._timeout);
      observer._timeout = setTimeout(labelBotMessages, 200);
    });

    // Start observing once the message area exists
    waitForElement('.chat-container, .messages-container, mat-sidenav-content, .mat-sidenav-content').then(container => {
      if (container) {
        observer.observe(container, { childList: true, subtree: true });
      }
    });
  }

  // =========================================================================
  // Utilities
  // =========================================================================

  /** Wait for an element to appear in the DOM */
  function waitForElement(selector, timeout = 10000) {
    return new Promise((resolve) => {
      const el = document.querySelector(selector);
      if (el) return resolve(el);

      const observer = new MutationObserver(() => {
        const el = document.querySelector(selector);
        if (el) {
          observer.disconnect();
          resolve(el);
        }
      });

      observer.observe(document.body, { childList: true, subtree: true });

      setTimeout(() => {
        observer.disconnect();
        resolve(null);
      }, timeout);
    });
  }

  // =========================================================================
  // Bootstrap
  // =========================================================================

  function init() {
    console.log('[AgentPlayground] Initializing...');

    // 1. Inject CSS
    injectCSS();

    // 2. Hide side panel
    hideSidePanel();

    // 3. Show welcome screen
    showWelcomeScreen();

    // 4. Declutter toolbar
    declutterToolbar();

    // 5. Set up message observer
    setupMessageObserver();

    console.log('[AgentPlayground] Ready ✨');
  }

  // Wait for DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
