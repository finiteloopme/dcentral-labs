/**
 * Midnight address encoding/decoding utilities
 * 
 * Midnight uses Bech32m encoding for addresses with the following prefixes:
 * - mn_addr_<network> - Unshielded addresses
 * - mn_shield-addr_<network> - Shielded addresses
 * - mn_dust_<network> - DUST token addresses
 * 
 * Based on the midnight-wallet address-format package (Apache 2.0).
 */

import { bech32m } from '@scure/base';
import { type NetworkId } from './types.js';

/**
 * Address types supported by Midnight
 */
export type AddressType = 'addr' | 'shield-addr' | 'dust' | 'contract';

/**
 * Parsed address components
 */
export interface ParsedAddress {
  type: AddressType;
  network: string;
  data: Uint8Array;
  original: string;
}

/**
 * Build the Bech32m prefix for an address
 */
function buildPrefix(type: AddressType, network: NetworkId): string {
  return `mn_${type}_${network}`;
}

/**
 * Parse a Bech32m prefix to extract type and network
 */
function parsePrefix(prefix: string): { type: AddressType; network: string } | null {
  const match = prefix.match(/^mn_([a-z-]+)_([a-z]+)$/);
  if (!match) return null;
  
  const [, type, network] = match;
  
  // Validate type
  const validTypes: AddressType[] = ['addr', 'shield-addr', 'dust', 'contract'];
  if (!validTypes.includes(type as AddressType)) {
    return null;
  }
  
  return { type: type as AddressType, network };
}

/**
 * Encode raw bytes into a Bech32m Midnight address
 * 
 * @param type - Address type
 * @param network - Network identifier
 * @param data - Raw address bytes
 * @returns Bech32m encoded address string
 */
export function encodeAddress(type: AddressType, network: NetworkId, data: Uint8Array): string {
  const prefix = buildPrefix(type, network);
  const words = bech32m.toWords(data);
  return bech32m.encode(prefix, words, 256); // 256 char limit
}

/**
 * Decode a Bech32m Midnight address
 * 
 * @param address - Bech32m encoded address
 * @returns Parsed address components
 * @throws Error if address is invalid
 */
export function decodeAddress(address: string): ParsedAddress {
  try {
    const decoded = bech32m.decode(address, 256);
    const prefixParts = parsePrefix(decoded.prefix);
    
    if (!prefixParts) {
      throw new Error(`Invalid address prefix: ${decoded.prefix}`);
    }
    
    const data = bech32m.fromWords(decoded.words);
    
    return {
      type: prefixParts.type,
      network: prefixParts.network,
      data: new Uint8Array(data),
      original: address,
    };
  } catch (error) {
    if (error instanceof Error && error.message.includes('Invalid address prefix')) {
      throw error;
    }
    throw new Error(`Invalid Bech32m address: ${error instanceof Error ? error.message : 'unknown error'}`);
  }
}

/**
 * Validate a Midnight address
 * 
 * @param address - Address to validate
 * @returns Validation result
 */
export function validateAddress(address: string): { valid: boolean; error?: string; parsed?: ParsedAddress } {
  try {
    const parsed = decodeAddress(address);
    return { valid: true, parsed };
  } catch (error) {
    return {
      valid: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Get human-readable address type name
 */
export function getAddressTypeName(type: AddressType): string {
  const names: Record<AddressType, string> = {
    'addr': 'Unshielded Address',
    'shield-addr': 'Shielded Address',
    'dust': 'DUST Token Address',
    'contract': 'Contract Address',
  };
  return names[type] || type;
}

/**
 * Truncate an address for display (keep prefix and last 8 chars)
 */
export function truncateAddress(address: string, tailLength: number = 8): string {
  if (address.length <= 40) return address;
  
  // Find the last underscore in the prefix (mn_addr_standalone)
  const prefixEnd = address.lastIndexOf('1'); // Bech32m separator
  if (prefixEnd === -1) return address;
  
  const prefix = address.substring(0, prefixEnd + 1);
  const tail = address.substring(address.length - tailLength);
  
  return `${prefix}...${tail}`;
}

/**
 * Derive an unshielded address from a coin public key
 * 
 * This is a simplified version - actual implementation would use
 * the wallet SDK's address derivation.
 * 
 * @param coinPublicKey - Hex-encoded coin public key
 * @param network - Network identifier
 * @returns Bech32m encoded unshielded address
 */
export function deriveUnshieldedAddress(coinPublicKey: string, network: NetworkId): string {
  // Remove 0x prefix if present
  const keyHex = coinPublicKey.startsWith('0x') ? coinPublicKey.slice(2) : coinPublicKey;
  
  // Convert hex to bytes
  const keyBytes = new Uint8Array(keyHex.length / 2);
  for (let i = 0; i < keyHex.length; i += 2) {
    keyBytes[i / 2] = parseInt(keyHex.substring(i, i + 2), 16);
  }
  
  return encodeAddress('addr', network, keyBytes);
}
