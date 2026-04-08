/**
 * Assess Risk Skill
 *
 * Protocol/ecosystem risk assessment. Analyzes a protocol or chain's
 * security posture — does NOT analyze code directly.
 */

import type { Message } from '@a2a-js/sdk';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { generateText } from 'ai';
import { model } from '../genkit.js';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';

// Load SKILLS.md as context for the LLM
const __dirname = dirname(fileURLToPath(import.meta.url));
const skillsPath = join(__dirname, '..', '..', 'SKILLS.md');

let skillsContext: string;
try {
  skillsContext = readFileSync(skillsPath, 'utf-8');
} catch {
  console.warn('[assess-risk] SKILLS.md not found, using minimal context');
  skillsContext = '# Protocol Risk Assessment Framework\n\nUse standard risk assessment criteria.';
}

const SYSTEM_PROMPT = `You are a blockchain protocol risk analyst specializing in security assessment
and due diligence for DeFi protocols and blockchain ecosystems.

${skillsContext}

## Risk Assessment Instructions

Evaluate the security posture and risk profile of the specified protocol or blockchain ecosystem.
This is a PROTOCOL-LEVEL assessment, not a code audit.

Cover the following dimensions:

1. **Chain/Protocol Maturity**
   - Time since launch, mainnet stability, incident history
   - Validator/node set size and decentralization

2. **Audit History**
   - Known audits (who, when, scope, findings)
   - Bug bounty programs

3. **Governance Model**
   - Multisig, timelock, DAO, or centralized control
   - Upgrade mechanisms (transparent proxy, UUPS, beacon, immutable)

4. **Dependency Risks**
   - External calls, oracle dependencies, bridge security
   - Cross-chain exposure

5. **Known Incidents**
   - Past exploits, hacks, or security events
   - Response and recovery actions

6. **TVL and Economic Security**
   - Total value locked trends
   - Economic attack vectors

7. **Team and Community**
   - Team reputation, doxxing status
   - Community size and engagement

## Output Format

### Protocol Risk Assessment: <Protocol Name>

#### Risk Score: <1-10> (<Low/Medium/High/Critical>)

#### Executive Summary
2-3 sentence overview.

#### Risk Dimensions

| Dimension | Score (1-10) | Assessment |
|-----------|-------------|------------|
| Maturity | X | ... |
| Audit Coverage | X | ... |
| Governance | X | ... |
| Dependencies | X | ... |
| Incident History | X | ... |
| Economic Security | X | ... |
| Team/Community | X | ... |

#### Detailed Analysis
(One section per dimension)

#### Key Risks
Numbered list of top risks.

#### Recommendations
Actionable recommendations for users/developers.

Also produce a JSON summary:
\`\`\`json
{
  "protocol": "<name>",
  "overallRiskScore": <1-10>,
  "overallRiskLevel": "<low|medium|high|critical>",
  "dimensions": {
    "maturity": { "score": <1-10>, "assessment": "<brief>" },
    "auditCoverage": { "score": <1-10>, "assessment": "<brief>" },
    "governance": { "score": <1-10>, "assessment": "<brief>" },
    "dependencies": { "score": <1-10>, "assessment": "<brief>" },
    "incidentHistory": { "score": <1-10>, "assessment": "<brief>" },
    "economicSecurity": { "score": <1-10>, "assessment": "<brief>" },
    "teamCommunity": { "score": <1-10>, "assessment": "<brief>" }
  },
  "keyRisks": ["<risk1>", "<risk2>"],
  "recommendations": ["<rec1>", "<rec2>"]
}
\`\`\`
`;

/**
 * Extract JSON block from LLM response
 */
function extractJsonBlock(text: string): string | null {
  const jsonMatch = text.match(/```json\s*\n([\s\S]*?)```/);
  if (jsonMatch) {
    return jsonMatch[1].trim();
  }
  return null;
}

/**
 * Perform protocol/ecosystem risk assessment
 */
export async function* assessRisk(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userRequest = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing protocol risk profile...' };

  try {
    yield {
      type: 'status',
      message: 'Evaluating security posture and risk dimensions...',
    };

    const response = await generateText({
      model,
      system: SYSTEM_PROMPT,
      prompt: userRequest,
      temperature: 0.2,
      maxOutputTokens: 6144,
    });

    const riskReport = response.text;

    // Emit markdown report
    yield {
      type: 'artifact',
      name: 'risk-assessment.md',
      content: riskReport,
      mimeType: 'text/markdown',
    };

    // Extract and emit JSON summary if present
    const jsonBlock = extractJsonBlock(riskReport);
    if (jsonBlock) {
      yield {
        type: 'artifact',
        name: 'risk-assessment.json',
        content: jsonBlock,
        mimeType: 'application/json',
      };
    }

    yield {
      type: 'result',
      data: riskReport,
      message: 'Protocol risk assessment completed',
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[assess-risk] Assessment failed:', errorMessage);
    yield {
      type: 'error',
      message: `Failed to assess protocol risk: ${errorMessage}`,
    };
  }
}
