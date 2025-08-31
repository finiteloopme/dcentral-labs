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
   * This can be overridden by the `VITE_BACKEND_URL` environment variable.
   */
  backendUrl: import.meta.env.VITE_BACKEND_URL || 'http://localhost:3000',
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
