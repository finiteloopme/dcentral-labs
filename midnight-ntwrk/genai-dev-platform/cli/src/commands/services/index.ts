import { Command } from 'commander';
import { execSync } from 'child_process';
import { logger } from '../../utils/logger';

// Service definitions with their environment variable names
const SERVICES = [
  { name: 'Midnight Node', envVar: 'MIDNIGHT_NODE_URL', healthPath: '/health', port: 9944 },
  { name: 'Proof Server', envVar: 'PROOF_SERVER_URL', healthPath: null, port: 6300 },  // TCP check only
  { name: 'Indexer', envVar: 'INDEXER_URL', healthPath: '/health', port: 8088 },
];

function getServiceUrl(envVar: string): string | null {
  return process.env[envVar] || null;
}

async function checkHealth(url: string, healthPath: string | null): Promise<boolean> {
  try {
    if (healthPath) {
      // HTTP health check
      const fullUrl = `${url}${healthPath}`;
      const response = await fetch(fullUrl, { 
        method: 'GET',
        signal: AbortSignal.timeout(5000),
      });
      return response.ok;
    } else {
      // TCP check - just try to connect to the base URL
      const response = await fetch(url, { 
        method: 'GET',
        signal: AbortSignal.timeout(5000),
      });
      return true; // If we get any response, service is up
    }
  } catch {
    return false;
  }
}

function getClusterName(): string {
  return process.env.CLUSTER_NAME || 'midnight-dev';
}

function getProjectId(): string | null {
  try {
    return execSync('gcloud config get-value project 2>/dev/null', {
      encoding: 'utf-8',
    }).trim();
  } catch {
    return null;
  }
}

function getRegion(): string {
  return process.env.GOOGLE_CLOUD_REGION || 'us-central1';
}

// Status command - check health of all services
const statusCommand = new Command('status')
  .description('Check status of Midnight services')
  .action(async () => {
    logger.title('Midnight Services Status');
    console.log('');
    
    const chainEnv = process.env.CHAIN_ENVIRONMENT || process.env.MIDNIGHT_NETWORK || 'standalone';
    logger.info(`Chain Environment: ${chainEnv}`);
    console.log('');

    for (const service of SERVICES) {
      const url = getServiceUrl(service.envVar);
      
      if (!url) {
        console.log(`  ${service.name.padEnd(20)} \x1b[33m○ Not configured\x1b[0m`);
        continue;
      }

      const isHealthy = await checkHealth(url, service.healthPath);
      const status = isHealthy 
        ? '\x1b[32m● Healthy\x1b[0m' 
        : '\x1b[31m○ Unhealthy\x1b[0m';
      
      console.log(`  ${service.name.padEnd(20)} ${status.padEnd(25)} ${url}`);
    }
    
    console.log('');
  });

// Start command - verify services are running
const startCommand = new Command('start')
  .description('Verify Midnight services are running')
  .action(async () => {
    logger.title('Midnight Services');
    
    const chainEnv = process.env.CHAIN_ENVIRONMENT || process.env.MIDNIGHT_NETWORK || 'standalone';
    
    if (chainEnv === 'standalone') {
      logger.info('Standalone services are managed by GKE Autopilot.');
      logger.info('Services are always-on with replicas=1.');
      console.log('');
      logger.info('Checking service health...');
      console.log('');
      
      let allHealthy = true;
      
      for (const service of SERVICES) {
        const url = getServiceUrl(service.envVar);
        
        if (!url) {
          logger.warning(`${service.name}: URL not configured`);
          allHealthy = false;
          continue;
        }

        const isHealthy = await checkHealth(url, service.healthPath);
        if (isHealthy) {
          logger.success(`${service.name}: Healthy`);
        } else {
          logger.error(`${service.name}: Not responding`);
          allHealthy = false;
        }
      }
      
      console.log('');
      
      if (allHealthy) {
        logger.success('All services are running');
      } else {
        logger.warning('Some services may not be ready');
        logger.info('Services may take a few minutes to initialize.');
      }
    } else {
      logger.info(`Chain Environment: ${chainEnv}`);
      logger.info('Remote chain services are managed externally.');
      console.log('');
      
      // For remote chains, just check the proof server
      const proofUrl = getServiceUrl('PROOF_SERVER_URL');
      if (proofUrl) {
        const isHealthy = await checkHealth(proofUrl, null);
        if (isHealthy) {
          logger.success('Proof Server: Healthy');
        } else {
          logger.warning('Proof Server: Not responding');
        }
      }
    }
    
    console.log('');
  });

// Stop command - not applicable for GKE Autopilot
const stopCommand = new Command('stop')
  .description('Stop services (not applicable - services are always-on)')
  .action(() => {
    logger.title('Midnight Services');
    
    const chainEnv = process.env.CHAIN_ENVIRONMENT || process.env.MIDNIGHT_NETWORK || 'standalone';
    
    if (chainEnv === 'standalone') {
      logger.info('Standalone services are managed by GKE Autopilot.');
      logger.info('Services are always-on with min replicas=1 and cannot be stopped.');
      console.log('');
      logger.info('To manage GKE services, use kubectl or the GCP Console:');
      console.log('  kubectl get pods -n midnight-services');
    } else {
      logger.info(`Chain Environment: ${chainEnv}`);
      logger.info('Remote chain services are managed externally.');
    }
    
    console.log('');
  });

// Logs command - fetch logs from GKE
const logsCommand = new Command('logs')
  .description('View service logs from GKE')
  .argument('[service]', 'Service name: node, proof, indexer')
  .option('-f, --follow', 'Follow log output (tail)')
  .option('-n, --lines <lines>', 'Number of lines to show', '50')
  .action((service: string | undefined, options: { follow?: boolean; lines: string }) => {
    const namespace = 'midnight-services';
    
    // Map service shorthand to pod label selector
    const serviceMap: Record<string, string> = {
      'node': 'app=midnight-node',
      'midnight-node': 'app=midnight-node',
      'proof': 'app=proof-server',
      'proof-server': 'app=proof-server',
      'indexer': 'app=indexer',
    };
    
    const followFlag = options.follow ? '-f' : '';
    const linesFlag = `--tail=${options.lines}`;
    
    if (service) {
      const labelSelector = serviceMap[service.toLowerCase()];
      if (!labelSelector) {
        logger.error(`Unknown service: ${service}`);
        logger.info('Valid services: node, proof, indexer');
        process.exit(1);
      }
      
      logger.info(`Fetching logs for ${service}...`);
      console.log('');
      
      try {
        execSync(
          `kubectl logs -n ${namespace} -l ${labelSelector} ${linesFlag} ${followFlag}`,
          { encoding: 'utf-8', stdio: 'inherit' }
        );
      } catch (error) {
        logger.error('Failed to fetch logs. Ensure kubectl is configured.');
        logger.info('Run: gcloud container clusters get-credentials midnight-dev-gke --region=<REGION>');
      }
    } else {
      // Default to showing all services
      logger.info('Showing logs for all services. Specify a service for filtered logs:');
      logger.info('  midnightctl services logs node');
      logger.info('  midnightctl services logs proof');
      logger.info('  midnightctl services logs indexer');
      console.log('');
      
      try {
        // Show pods first, then recent logs from each
        execSync(`kubectl get pods -n ${namespace}`, { encoding: 'utf-8', stdio: 'inherit' });
        console.log('');
        
        for (const [name, selector] of Object.entries(serviceMap)) {
          if (!name.includes('-')) { // Skip aliases like "midnight-node"
            console.log(`\n--- ${name} ---`);
            try {
              execSync(
                `kubectl logs -n ${namespace} -l ${selector} --tail=10`,
                { encoding: 'utf-8', stdio: 'inherit' }
              );
            } catch {
              console.log('  (no logs available)');
            }
          }
        }
      } catch (error) {
        logger.error('Failed to fetch logs. Ensure kubectl is configured.');
        logger.info('Run: gcloud container clusters get-credentials midnight-dev-gke --region=<REGION>');
      }
    }
  });

// URLs command - show service URLs
const urlsCommand = new Command('urls')
  .description('Show service URLs')
  .action(() => {
    logger.title('Midnight Service URLs');
    console.log('');
    
    const chainEnv = process.env.CHAIN_ENVIRONMENT || process.env.MIDNIGHT_NETWORK || 'standalone';
    logger.info(`Chain Environment: ${chainEnv}`);
    console.log('');
    
    for (const service of SERVICES) {
      const url = getServiceUrl(service.envVar);
      console.log(`  ${service.name.padEnd(20)} ${url || '<not configured>'}`);
    }
    
    console.log('');
  });

// Main services command
export const servicesCommand = new Command('services')
  .description('Manage Midnight development services')
  .addCommand(startCommand)
  .addCommand(stopCommand)
  .addCommand(statusCommand)
  .addCommand(logsCommand)
  .addCommand(urlsCommand);
