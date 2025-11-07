/*
 * This file defines the shape of the DeFi vault's private state,
 * as well as the witness function that accesses it.
 */

import { Ledger } from './managed/defi-vault/contract/index.cjs';
import { WitnessContext } from '@midnight-ntwrk/compact-runtime';

/* **********************************************************************
 * The private state needed by the DeFi vault contract is
 * the TEE's secret key for signing operations.
 */

export type DeFiVaultPrivateState = {
  readonly secretKey: Uint8Array;
};

export const createDeFiVaultPrivateState = (secretKey: Uint8Array) => ({
  secretKey,
});

/* **********************************************************************
 * The witnesses object for the DeFi vault contract provides access to
 * the TEE's secret key for cryptographic operations.
 */

export const witnesses = {
  local_secret_key: ({ privateState }: WitnessContext<Ledger, DeFiVaultPrivateState>): [DeFiVaultPrivateState, Uint8Array] => [
    privateState,
    privateState.secretKey,
  ],
};