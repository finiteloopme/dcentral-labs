/**
 * Security Agent Card
 *
 * Defines the A2A agent card for the Security Agent.
 * Skills cover smart contract auditing, vulnerability scanning,
 * and protocol/ecosystem risk assessment.
 */

import type { AgentCard } from '@a2a-js/sdk';

const PORT = process.env.SECURITY_AGENT_PORT || 4006;
const HOST = process.env.SECURITY_AGENT_HOST || 'localhost';

export const securityAgentCard: AgentCard = {
  name: 'Security Agent',
  description:
    'AI agent for smart contract security auditing, vulnerability scanning, and protocol risk assessment. ' +
    'Supports Solidity (EVM chains) and Compact (Midnight) contracts.',
  url: `http://${HOST}:${PORT}/`,
  protocolVersion: '0.3.0',
  provider: {
    organization: 'Coding Labs',
    url: 'https://github.com/dcentral-labs/onchain-agents',
  },
  version: '0.1.0',
  capabilities: {
    streaming: true,
    pushNotifications: false,
    stateTransitionHistory: true,
  },
  defaultInputModes: ['text', 'file'],
  defaultOutputModes: ['text', 'file'],
  skills: [
    {
      id: 'audit-contract',
      name: 'Smart Contract Audit',
      description:
        'Comprehensive security audit of Solidity or Compact smart contract code. ' +
        'Identifies vulnerabilities, rates severity, and provides remediation guidance.',
      tags: ['audit', 'security', 'smart-contract', 'solidity', 'compact'],
      examples: [
        'Audit this Solidity contract for security vulnerabilities',
        'Review my Compact contract for ZK-specific issues',
        'Check this ERC-20 token for common exploits',
      ],
      inputModes: ['text', 'file'],
      outputModes: ['text', 'file'],
    },
    {
      id: 'scan-vulnerabilities',
      name: 'Vulnerability Scan',
      description:
        'Quick scan for known vulnerability patterns in smart contract code. ' +
        'Faster and more targeted than a full audit.',
      tags: ['scan', 'vulnerability', 'pattern', 'quick-check'],
      examples: [
        'Scan this contract for reentrancy bugs',
        'Check for common vulnerability patterns',
        'Find potential security issues in this code',
      ],
      inputModes: ['text', 'file'],
      outputModes: ['text'],
    },
    {
      id: 'assess-risk',
      name: 'Protocol Risk Assessment',
      description:
        'Evaluate the security posture and risk profile of a blockchain protocol or ecosystem. ' +
        'Covers audit history, governance, upgrade mechanisms, and known incidents.',
      tags: ['risk', 'protocol', 'ecosystem', 'assessment', 'due-diligence'],
      examples: [
        'What are the security risks of using Somnia?',
        'Assess the risk profile of the Midnight protocol',
        'How safe is the Sonic ecosystem for DeFi?',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'explain-finding',
      name: 'Finding Deep-Dive',
      description:
        'Detailed explanation of a specific vulnerability type with real-world examples, ' +
        'attack scenarios, and remediation guidance.',
      tags: ['explain', 'vulnerability', 'education', 'remediation'],
      examples: [
        'Explain reentrancy attacks with examples',
        'What is a flash loan attack and how to prevent it?',
        'Deep dive into Compact witness validation vulnerabilities',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'compare-protocols',
      name: 'Protocol Comparison',
      description:
        'Compare the security characteristics and risk profiles of different blockchain protocols or chains.',
      tags: ['compare', 'protocol', 'security-posture', 'evaluation'],
      examples: [
        'Compare security of Somnia vs Sonic',
        'Which chain has better security guarantees: Midnight or Sonic?',
        'Compare the audit history of these protocols',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
  ],
  supportsAuthenticatedExtendedCard: false,
};
