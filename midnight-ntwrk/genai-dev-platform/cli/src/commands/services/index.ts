import { Command } from 'commander';
import { execSync } from 'child_process';
import { logger } from '../../utils/logger';

// Service definitions with their environment variable names
const SERVICES = [
  { name: 'Midnight Node', envVar: 'MIDNIGHT_NODE_URL', healthPath: '/health' },
  { name: 'Proof Server', envVar: 'PROOF_SERVER_URL', healthPath: '/health' },
  { name: 'Indexer', envVar: 'INDEXER_URL', healthPath: '/health' },
];

function getServiceUrl(envVar: string): string | null {
  return process.env[envVar] || null;
}

async function checkHealth(url: string, healthPath: string): Promise<boolean> {
  try {
    const fullUrl = `${url}${healthPath}`;
    const response = await fetch(fullUrl, { 
      method: 'GET',
      signal: AbortSignal.timeout(5000),
    });
    return response.ok;
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
    
    const network = process.env.MIDNIGHT_NETWORK || 'standalone';
    logger.info(`Network: ${network}`);
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

// Start command - for Cloud Run, this is essentially a no-op or health check
const startCommand = new Command('start')
  .description('Verify Midnight services are running')
  .action(async () => {
    logger.title('Midnight Services');
    
    const network = process.env.MIDNIGHT_NETWORK || 'standalone';
    
    if (network === 'standalone') {
      logger.info('Standalone services are managed by Cloud Run.');
      logger.info('Services are always-on with min_instances=1.');
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
        logger.info('Services may take a few minutes to start on first access.');
      }
    } else {
      logger.info(`Network mode: ${network}`);
      logger.info('Remote network services are managed externally.');
      console.log('');
      
      // For remote networks, just check the proof server
      const proofUrl = getServiceUrl('PROOF_SERVER_URL');
      if (proofUrl) {
        const isHealthy = await checkHealth(proofUrl, '/health');
        if (isHealthy) {
          logger.success('Proof Server: Healthy');
        } else {
          logger.warning('Proof Server: Not responding');
        }
      }
    }
    
    console.log('');
  });

// Stop command - not applicable for Cloud Run
const stopCommand = new Command('stop')
  .description('Stop services (not applicable for Cloud Run)')
  .action(() => {
    logger.title('Midnight Services');
    
    const network = process.env.MIDNIGHT_NETWORK || 'standalone';
    
    if (network === 'standalone') {
      logger.info('Standalone services are managed by Cloud Run.');
      logger.info('Services cannot be stopped from the workstation.');
      console.log('');
      logger.info('To manage Cloud Run services, use the GCP Console or:');
      console.log('  gcloud run services list --filter="labels.cluster=<cluster-name>"');
    } else {
      logger.info(`Network mode: ${network}`);
      logger.info('Remote network services are managed externally.');
    }
    
    console.log('');
  });

// Logs command - fetch logs from Cloud Run
const logsCommand = new Command('logs')
  .description('View service logs from Cloud Run')
  .argument('[service]', 'Service name: node, proof, indexer')
  .option('-f, --follow', 'Follow log output (tail)')
  .option('-n, --lines <lines>', 'Number of lines to show', '50')
  .action((service: string | undefined, options: { follow?: boolean; lines: string }) => {
    const projectId = getProjectId();
    const region = getRegion();
    const clusterName = getClusterName();
    
    if (!projectId) {
      logger.error('Could not determine GCP project ID');
      logger.info('Run: gcloud config set project <PROJECT_ID>');
      process.exit(1);
    }
    
    // Map service shorthand to full service name
    const serviceMap: Record<string, string> = {
      'node': `midnight-node-${clusterName}`,
      'midnight-node': `midnight-node-${clusterName}`,
      'proof': `proof-server-${clusterName}`,
      'proof-server': `proof-server-${clusterName}`,
      'indexer': `indexer-${clusterName}`,
    };
    
    let serviceName: string;
    
    if (service) {
      serviceName = serviceMap[service.toLowerCase()];
      if (!serviceName) {
        logger.error(`Unknown service: ${service}`);
        logger.info('Valid services: node, proof, indexer');
        process.exit(1);
      }
    } else {
      // Default to showing all services
      logger.info('Showing logs for all services. Specify a service for filtered logs:');
      logger.info('  midnightctl services logs node');
      logger.info('  midnightctl services logs proof');
      logger.info('  midnightctl services logs indexer');
      console.log('');
      
      // Show combined logs
      const tailFlag = options.follow ? '--tail' : '';
      const limitFlag = `--limit=${options.lines}`;
      
      try {
        execSync(
          `gcloud logging read 'resource.type="cloud_run_revision" AND labels.cluster="${clusterName}"' ${limitFlag} --format='table(timestamp,resource.labels.service_name,textPayload)' --project=${projectId}`,
          { encoding: 'utf-8', stdio: 'inherit' }
        );
      } catch (error) {
        logger.error('Failed to fetch logs');
      }
      return;
    }
    
    logger.info(`Fetching logs for ${serviceName}...`);
    console.log('');
    
    const tailFlag = options.follow ? '--tail' : '';
    const limitFlag = options.follow ? '' : `--limit=${options.lines}`;
    
    try {
      if (options.follow) {
        // Use gcloud run logs tail for following
        execSync(
          `gcloud beta run services logs tail ${serviceName} --region=${region} --project=${projectId}`,
          { encoding: 'utf-8', stdio: 'inherit' }
        );
      } else {
        // Use gcloud run services logs read for historical logs
        execSync(
          `gcloud beta run services logs read ${serviceName} --region=${region} --project=${projectId} ${limitFlag}`,
          { encoding: 'utf-8', stdio: 'inherit' }
        );
      }
    } catch (error) {
      // User likely Ctrl+C'd, or gcloud beta not available
      logger.info('Note: Log tailing requires gcloud beta. Install with:');
      logger.info('  gcloud components install beta');
    }
  });

// URLs command - show service URLs
const urlsCommand = new Command('urls')
  .description('Show service URLs')
  .action(() => {
    logger.title('Midnight Service URLs');
    console.log('');
    
    const network = process.env.MIDNIGHT_NETWORK || 'standalone';
    logger.info(`Network: ${network}`);
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
