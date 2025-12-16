import chalk from 'chalk';

export const logger = {
  info: (message: string) => console.log(chalk.cyan('ℹ'), message),
  success: (message: string) => console.log(chalk.green('✓'), message),
  warning: (message: string) => console.log(chalk.yellow('⚠'), message),
  error: (message: string) => console.error(chalk.red('✗'), message),
  step: (message: string) => console.log(chalk.blue('→'), message),
  title: (message: string) => console.log(chalk.bold.cyan(`\n${message}\n`)),
};
