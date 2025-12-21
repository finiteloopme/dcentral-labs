import chalk from 'chalk';

export const logger = {
  info: (message: string) => console.log(chalk.cyan('ℹ'), message),
  success: (message: string) => console.log(chalk.green('✓'), message),
  warning: (message: string) => console.log(chalk.yellow('⚠'), message),
  error: (message: string) => console.error(chalk.red('✗'), message),
  step: (message: string) => console.log(chalk.blue('→'), message),
  title: (message: string) => console.log(chalk.bold.cyan(`\n${message}\n`)),
  
  /**
   * Show deprecation warning for legacy toolkit usage
   * Called when --use-legacy-toolkit flag is used
   */
  showLegacyToolkitWarning: () => {
    console.log('');
    console.log(chalk.yellow('  ⚠  Warning: --use-legacy-toolkit is deprecated and will be removed in a future release.'));
    console.log(chalk.yellow('     The SDK is now the recommended method for all wallet operations.'));
    console.log('');
  },
  
  /**
   * Show sync progress indicator for SDK wallet operations
   * @param progress - Object with shielded, unshielded, dust sync status
   */
  showSyncProgress: (progress: { shielded: boolean; unshielded: boolean; dust: boolean }) => {
    const shielded = progress.shielded ? chalk.green('✓') : chalk.yellow('⏳');
    const unshielded = progress.unshielded ? chalk.green('✓') : chalk.yellow('⏳');
    const dust = progress.dust ? chalk.green('✓') : chalk.yellow('⏳');
    
    // Use carriage return to update in place
    process.stdout.write(`\r  Syncing wallet... [shielded ${shielded}] [unshielded ${unshielded}] [dust ${dust}]`);
  },
  
  /**
   * Clear the sync progress line
   */
  clearSyncProgress: () => {
    process.stdout.write('\r' + ' '.repeat(80) + '\r');
  },
};
