import { describe, it, expect } from 'vitest';
import { validateCompact } from './validate.js';
import { loadConfig } from '../config.js';

const config = loadConfig();

describe('compact_validate', () => {
  it('rejects empty source', async () => {
    const result = await validateCompact('', config);
    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Empty source code');
  });

  it('rejects source without pragma', async () => {
    const result = await validateCompact(
      'export ledger counter: Uint32;',
      config
    );
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes('pragma'))).toBe(true);
  });

  it('warns on old language version', async () => {
    const source = `pragma language_version 0.17;
export ledger counter: Uint32;
export circuit increment(): [] {
  counter = counter + 1;
}`;
    const result = await validateCompact(source, config);
    // May pass structural check but with warning about version
    expect(result.warnings.some((w) => w.includes('0.17'))).toBe(true);
  });

  it('detects mismatched braces', async () => {
    const source = `pragma language_version 0.20;
export ledger counter: Uint32;
export circuit increment(): [] {
  counter = counter + 1;
`;
    const result = await validateCompact(source, config);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes('braces'))).toBe(true);
  });

  it('passes valid Compact code structurally', async () => {
    const source = `pragma language_version 0.20;

export ledger counter: Uint32;

export circuit increment(): [] {
  counter = counter + 1;
}`;
    // Structural validation should pass (compiler may not be available)
    const result = await validateCompact(source, config);
    // If compiler not available, structural validation passes
    if (
      result.message.includes('structural only') ||
      result.message.includes('compiler verified')
    ) {
      expect(result.valid).toBe(true);
    }
    expect(result.errors.length).toBe(0);
  });

  it('warns when no exports found', async () => {
    const source = `pragma language_version 0.20;
ledger counter: Uint32;
circuit increment(): [] {
  counter = counter + 1;
}`;
    const result = await validateCompact(source, config);
    expect(result.warnings.some((w) => w.includes('exported'))).toBe(true);
  });
});
