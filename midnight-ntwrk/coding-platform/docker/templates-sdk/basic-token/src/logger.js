import pino from 'pino';

export function createLogger() {
    return pino({
        transport: {
            target: 'pino-pretty',
            options: {
                colorize: true,
                translateTime: 'HH:MM:ss Z',
                ignore: 'pid,hostname'
            }
        }
    });
}

export default createLogger;