/**
 * BIP39 Mnemonic utilities for wallet generation
 * 
 * Uses @scure/bip39 for secure, audited mnemonic operations.
 */

import { randomBytes } from 'node:crypto';
import { generateMnemonic as generateBip39Mnemonic, validateMnemonic as validateBip39Mnemonic, mnemonicToSeedSync } from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';
import { hex } from '@scure/base';

// Helper functions using @scure/base hex coder
const bytesToHex = (bytes: Uint8Array): string => hex.encode(bytes);
const hexToBytes = (hexStr: string): Uint8Array => hex.decode(hexStr);

/**
 * Generate a new BIP39 mnemonic phrase
 * 
 * @param strength - Entropy strength in bits (128 = 12 words, 256 = 24 words)
 * @returns Array of mnemonic words
 */
export function generateMnemonic(strength: 128 | 256 = 256): string[] {
  const mnemonic = generateBip39Mnemonic(wordlist, strength);
  return mnemonic.split(' ');
}

/**
 * Validate a BIP39 mnemonic phrase
 * 
 * @param words - Mnemonic words (array or space-separated string)
 * @returns Validation result
 */
export function validateMnemonic(words: string[] | string): { valid: boolean; error?: string } {
  const mnemonic = Array.isArray(words) ? words.join(' ') : words;
  const wordArray = mnemonic.trim().split(/\s+/);
  
  // Check word count
  const validWordCounts = [12, 15, 18, 21, 24];
  if (!validWordCounts.includes(wordArray.length)) {
    return {
      valid: false,
      error: `Invalid word count: ${wordArray.length}. Expected one of: ${validWordCounts.join(', ')}`,
    };
  }
  
  // Check each word is in wordlist
  for (const word of wordArray) {
    if (!wordlist.includes(word.toLowerCase())) {
      return {
        valid: false,
        error: `Word "${word}" is not in the BIP39 English wordlist`,
      };
    }
  }
  
  // Validate checksum
  if (!validateBip39Mnemonic(mnemonic, wordlist)) {
    return {
      valid: false,
      error: 'Invalid mnemonic checksum',
    };
  }
  
  return { valid: true };
}

/**
 * Convert mnemonic to seed bytes
 * 
 * @param words - Mnemonic words (array or space-separated string)
 * @param passphrase - Optional BIP39 passphrase
 * @returns 64-byte seed
 */
export function mnemonicToSeed(words: string[] | string, passphrase: string = ''): Uint8Array {
  const mnemonic = Array.isArray(words) ? words.join(' ') : words;
  return mnemonicToSeedSync(mnemonic, passphrase);
}

/**
 * Convert mnemonic to hex-encoded seed (first 32 bytes for Midnight)
 * 
 * Midnight uses a 32-byte seed, so we take the first half of the BIP39 seed.
 * 
 * @param words - Mnemonic words (array or space-separated string)
 * @param passphrase - Optional BIP39 passphrase
 * @returns Hex-encoded 32-byte seed
 */
export function mnemonicToHexSeed(words: string[] | string, passphrase: string = ''): string {
  const fullSeed = mnemonicToSeed(words, passphrase);
  // Take first 32 bytes for Midnight compatibility
  const seed32 = fullSeed.slice(0, 32);
  return bytesToHex(seed32);
}

/**
 * Generate a random 32-byte seed as hex
 */
export function generateRandomSeed(): string {
  const bytes = randomBytes(32);
  return bytesToHex(bytes);
}

/**
 * Validate a hex seed string
 */
export function validateHexSeed(seed: string): { valid: boolean; error?: string } {
  // Remove 0x prefix if present
  const cleanSeed = seed.startsWith('0x') ? seed.slice(2) : seed;
  
  // Check length (32 bytes = 64 hex chars)
  if (cleanSeed.length !== 64) {
    return {
      valid: false,
      error: `Invalid seed length: ${cleanSeed.length} chars. Expected 64 hex characters (32 bytes).`,
    };
  }
  
  // Check valid hex
  if (!/^[0-9a-fA-F]+$/.test(cleanSeed)) {
    return {
      valid: false,
      error: 'Seed contains invalid characters. Expected hex string.',
    };
  }
  
  return { valid: true };
}

/**
 * Normalize a hex seed (remove 0x prefix, lowercase)
 */
export function normalizeHexSeed(seed: string): string {
  const cleanSeed = seed.startsWith('0x') ? seed.slice(2) : seed;
  return cleanSeed.toLowerCase();
}

/**
 * Convert hex string to bytes
 */
export function hexToSeedBytes(seed: string): Uint8Array {
  const normalized = normalizeHexSeed(seed);
  return hexToBytes(normalized);
}

/**
 * Convert bytes to hex string
 */
export function seedBytesToHex(bytes: Uint8Array): string {
  return bytesToHex(bytes);
}
