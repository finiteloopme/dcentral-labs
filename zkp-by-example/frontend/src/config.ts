/**
 * The main configuration file for the frontend.
 *
 * This file contains configuration for the backend URL and API endpoints.
 * It also supports environment variables for overriding the default values.
 */
const config = {
  /**
   * The base URL of the backend server.
   *
   * This is a placeholder that will be replaced by the entrypoint script.
   */
  backendUrl: '__BACKEND_URL__',
  /**
   * The base URL of the proof service.
   *
   * This is a placeholder that will be replaced by the entrypoint script.
   */
  proofServiceUrl: '__PROOF_SERVICE_URL__',
  /**
   * A collection of API endpoints.
   */
  api: {
    /**
     * Endpoints related to competitions.
     */
    competitions: '/competitions',
    /**
     * Endpoints for admin functionality.
     */
    admin: {
      competitions: '/admin/competitions',
    },
  },
};

export default config;
