import { Command } from 'commander';
import { execSync } from 'child_process';
import { logger } from '../../utils/logger';
import { 
  getServiceUrls, 
  getChainEnvironment, 
  isGcpWorkstation,
  SERVICES,
  ServiceUrls,
} from '../../utils/config';

/**
 * Convert WebSocket URL to HTTP URL for health checks
 */
function wsToHttp(url: string): string {
  return url.replace(/^ws:\/\//, 'http://').replace(/^wss:\/\//, 'https://');
}

/**
 * Check health of a service via HTTP or TCP
 */
async function checkHealth(url: string, healthPath: string | null, convertWs: boolean = false): Promise<boolean> {
  try {
    // Convert ws:// to http:// if needed for health checks
    const httpUrl = convertWs ? wsToHttp(url) : url;
    
    if (healthPath) {
      // HTTP health check
      const fullUrl = `${httpUrl}${healthPath}`;
      const response = await fetch(fullUrl, { 
        method: 'GET',
        signal: AbortSignal.timeout(5000),
      });
      return response.ok;
    } else {
      // TCP check - just try to connect to the base URL
      const response = await fetch(httpUrl, { 
        method: 'GET',
        signal: AbortSignal.timeout(5000),
      });
      // Any response (even 404) means service is up
      return true;
    }
  } catch {
    return false;
  }
}

/**
 * Get URL for a service from resolved config
 */
function getServiceUrl(urls: ServiceUrls, key: keyof ServiceUrls): string | undefined {
  return urls[key];
}

// Status command - check health of all services
const statusCommand = new Command('status')
  .description('Check status of Midnight services')
  .action(async () => {
    logger.title('Midnight Services Status');
    console.log('');
    
    const chainEnv = getChainEnvironment();
    const isWorkstation = isGcpWorkstation();
    const urls = getServiceUrls();
    
    logger.info(`Chain Environment: ${chainEnv}`);
    if (isWorkstation) {
      logger.info('Running in: GCP Workstation');
    }
    console.log('');

    for (const service of SERVICES) {
      const url = getServiceUrl(urls, service.key);
      
      if (!url) {
        console.log(`  ${service.name.padEnd(20)} \x1b[33m○ Not configured\x1b[0m`);
        continue;
      }

      const isHealthy = await checkHealth(url, service.healthPath, service.convertWsToHttp);
      const status = isHealthy 
        ? '\x1b[32m● Healthy\x1b[0m' 
        : '\x1b[31m○ Unhealthy\x1b[0m';
      
      console.log(`  ${service.name.padEnd(20)} ${status.padEnd(25)} ${url}`);
    }
    
    console.log('');
    
    // Show hint if in workstation with missing config
    if (isWorkstation && (!urls.nodeUrl || !urls.indexerUrl || !urls.proofServerUrl)) {
      logger.warning('Some services are not configured.');
      logger.info('Service URLs should be injected by Terraform.');
      logger.info('Check workstation configuration or redeploy.');
      console.log('');
    }
  });

// Start command - verify services are running
const startCommand = new Command('start')
  .description('Verify Midnight services are running')
  .action(async () => {
    logger.title('Midnight Services');
    
    const chainEnv = getChainEnvironment();
    const urls = getServiceUrls();
    
    if (chainEnv === 'standalone') {
      logger.info('Checking service health...');
      console.log('');
      
      let allHealthy = true;
      
      for (const service of SERVICES) {
        const url = getServiceUrl(urls, service.key);
        
        if (!url) {
          logger.warning(`${service.name}: Not configured`);
          allHealthy = false;
          continue;
        }

        const isHealthy = await checkHealth(url, service.healthPath, service.convertWsToHttp);
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
      const proofUrl = urls.proofServerUrl;
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

// Stop command - not applicable for managed services
const stopCommand = new Command('stop')
  .description('Stop services (not applicable - services are managed)')
  .action(() => {
    logger.title('Midnight Services');
    
    const chainEnv = getChainEnvironment();
    const isWorkstation = isGcpWorkstation();
    
    if (chainEnv === 'standalone') {
      if (isWorkstation) {
        logger.info('Services are managed by GKE and cannot be stopped from here.');
        console.log('');
        logger.info('To manage GKE services, use kubectl:');
        console.log('  kubectl get pods -n midnight-services');
      } else {
        logger.info('Local services are managed by your container runtime.');
        console.log('');
        logger.info('To stop local services:');
        console.log('  podman stop <container-name>');
        console.log('  # or');
        console.log('  docker stop <container-name>');
      }
    } else {
      logger.info(`Chain Environment: ${chainEnv}`);
      logger.info('Remote chain services are managed externally.');
    }
    
    console.log('');
  });

// Logs command - fetch logs from GKE
const logsCommand = new Command('logs')
  .description('View service logs (GKE only)')
  .argument('[service]', 'Service name: node, proof, indexer')
  .option('-f, --follow', 'Follow log output (tail)')
  .option('-n, --lines <lines>', 'Number of lines to show', '50')
  .action((service: string | undefined, options: { follow?: boolean; lines: string }) => {
    const isWorkstation = isGcpWorkstation();
    
    if (!isWorkstation) {
      logger.info('Log viewing is available in GCP Workstation environment.');
      logger.info('For local development, use your container runtime:');
      console.log('  podman logs <container-name>');
      console.log('  # or');
      console.log('  docker logs <container-name>');
      console.log('');
      return;
    }
    
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
        logger.info('Run: gcloud container clusters get-credentials <cluster-name> --region=<region>');
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
        logger.info('Run: gcloud container clusters get-credentials <cluster-name> --region=<region>');
      }
    }
  });

// URLs command - show service URLs
const urlsCommand = new Command('urls')
  .description('Show service URLs')
  .action(() => {
    logger.title('Midnight Service URLs');
    console.log('');
    
    const chainEnv = getChainEnvironment();
    const isWorkstation = isGcpWorkstation();
    const urls = getServiceUrls();
    
    logger.info(`Chain Environment: ${chainEnv}`);
    if (isWorkstation) {
      logger.info('Running in: GCP Workstation');
    }
    console.log('');
    
    for (const service of SERVICES) {
      const url = getServiceUrl(urls, service.key);
      console.log(`  ${service.name.padEnd(20)} ${url || 'Not configured'}`);
    }
    
    console.log('');
    
    // Show hint for local development
    if (!isWorkstation && chainEnv === 'standalone') {
      logger.info('Tip: Set service URLs via environment variables:');
      console.log('  export MIDNIGHT_NODE_URL=ws://<ip>:9944');
      console.log('  export INDEXER_URL=http://<ip>:8088');
      console.log('  export PROOF_SERVER_URL=http://<ip>:6300');
      console.log('');
    }
  });

// Main services command
export const servicesCommand = new Command('services')
  .description('Manage Midnight development services')
  .addCommand(startCommand)
  .addCommand(stopCommand)
  .addCommand(statusCommand)
  .addCommand(logsCommand)
  .addCommand(urlsCommand);
