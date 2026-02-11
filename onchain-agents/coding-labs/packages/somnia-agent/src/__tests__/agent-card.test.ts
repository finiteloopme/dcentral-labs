import { describe, it, expect } from 'vitest';
import { somniaAgentCard } from '../agent-card.js';

describe('somniaAgentCard', () => {
  it('should have required A2A fields', () => {
    expect(somniaAgentCard.name).toBe('Somnia Agent');
    expect(somniaAgentCard.url).toBeDefined();
    expect(somniaAgentCard.protocolVersion).toBe('0.3.0');
    expect(somniaAgentCard.version).toBeDefined();
  });

  it('should have provider information', () => {
    expect(somniaAgentCard.provider).toBeDefined();
    expect(somniaAgentCard.provider?.organization).toBe('Coding Labs');
  });

  it('should have capabilities defined', () => {
    expect(somniaAgentCard.capabilities).toBeDefined();
    expect(somniaAgentCard.capabilities?.streaming).toBe(true);
    expect(somniaAgentCard.capabilities?.pushNotifications).toBe(false);
  });

  it('should have 6 skills defined', () => {
    expect(somniaAgentCard.skills).toHaveLength(6);
  });

  it('should have solidity-gen skill', () => {
    const soliditySkill = somniaAgentCard.skills?.find(
      (s) => s.id === 'solidity-gen'
    );
    expect(soliditySkill).toBeDefined();
    expect(soliditySkill?.name).toBe('Solidity Contract Generation');
    expect(soliditySkill?.tags).toContain('solidity');
    expect(soliditySkill?.examples).toBeDefined();
    expect(soliditySkill?.examples?.length).toBeGreaterThan(0);
  });

  it('should have deploy skill', () => {
    const deploySkill = somniaAgentCard.skills?.find((s) => s.id === 'deploy');
    expect(deploySkill).toBeDefined();
    expect(deploySkill?.name).toBe('Contract Deployment');
  });

  it('should have tx-status skill', () => {
    const txSkill = somniaAgentCard.skills?.find((s) => s.id === 'tx-status');
    expect(txSkill).toBeDefined();
  });

  it('should have query-state skill', () => {
    const querySkill = somniaAgentCard.skills?.find(
      (s) => s.id === 'query-state'
    );
    expect(querySkill).toBeDefined();
  });

  it('should have Somnia-specific skills', () => {
    const reactivitySkill = somniaAgentCard.skills?.find(
      (s) => s.id === 'reactivity-setup'
    );
    const dataStreamsSkill = somniaAgentCard.skills?.find(
      (s) => s.id === 'data-streams'
    );

    expect(reactivitySkill).toBeDefined();
    expect(reactivitySkill?.tags).toContain('somnia-specific');

    expect(dataStreamsSkill).toBeDefined();
    expect(dataStreamsSkill?.tags).toContain('somnia-specific');
  });

  it('should have valid input/output modes', () => {
    expect(somniaAgentCard.defaultInputModes).toContain('text');
    expect(somniaAgentCard.defaultOutputModes).toContain('text');
    expect(somniaAgentCard.defaultOutputModes).toContain('file');
  });
});
