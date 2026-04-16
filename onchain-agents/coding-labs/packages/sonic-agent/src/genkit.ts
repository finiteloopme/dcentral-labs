/**
 * LLM Configuration for Sonic Agent
 *
 * Uses the shared model factory to create the correct LLM provider
 * based on config.toml settings. For sonic-agent, config.toml assigns
 * the "vertex-gemini" provider (Gemini via Vertex AI).
 */

import { createModelForComponent } from '@coding-labs/shared/llm';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Get the directory of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Create model from config.toml (respects env var overrides)
export const model = createModelForComponent('sonic-agent');

/**
 * Load the SKILLS.md file as context for the LLM.
 */
export function loadSkillsContext(): string {
  try {
    // Try multiple paths (dev vs dist)
    const paths = [
      join(__dirname, '..', 'SKILLS.md'),
      join(__dirname, '..', '..', 'SKILLS.md'),
      join(process.cwd(), 'packages', 'sonic-agent', 'SKILLS.md'),
    ];

    for (const path of paths) {
      try {
        return readFileSync(path, 'utf-8');
      } catch {
        continue;
      }
    }

    console.warn('[SonicAgent] SKILLS.md not found, using fallback context');
    return `You are a Sonic blockchain development assistant.
Sonic is a high-performance EVM chain with 400,000 TPS and sub-second finality.
Chain ID: 146, RPC: https://rpc.soniclabs.com, Explorer: https://sonicscan.org
Generate clean, well-documented Solidity code following best practices.`;
  } catch (error) {
    console.error('[SonicAgent] Error loading SKILLS.md:', error);
    return 'You are a Sonic blockchain development assistant.';
  }
}

/**
 * System prompt for Solidity code generation.
 */
export function getSolidityGenSystemPrompt(): string {
  const skillsContext = loadSkillsContext();

  return `${skillsContext}

## Your Role

You are an expert Solidity developer specializing in Sonic blockchain.
When asked to generate smart contracts:

1. Use Solidity ^0.8.28
2. Import OpenZeppelin contracts when appropriate
3. Include proper access control (Ownable, etc.)
4. Add events for important state changes
5. Include NatSpec documentation
6. Follow security best practices

## Output Format

Return ONLY the Solidity code. Do not include explanations unless asked.
Start with the SPDX license identifier and pragma statement.

## Example

\`\`\`solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MyToken
/// @notice A simple ERC-20 token
contract MyToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
}
\`\`\``;
}
