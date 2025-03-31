# Multi-stage build for frontend and backend

# Frontend build stage
FROM node:20 AS frontend-build
WORKDIR /app/frontend
COPY frontend/ ./
RUN npm ci
RUN npm run build

# Backend build stage
FROM node:20 AS backend-build
WORKDIR /app/ai-agent
RUN npm install -g pnpm
COPY ai-agent/ ./
RUN pnpm -force i
RUN pnpm run build

# Final stage
FROM node:20-slim
WORKDIR /app

# Copy backend build artifacts
COPY --from=backend-build /app/ai-agent/dist ./ai-agent/dist
COPY --from=backend-build /app/ai-agent/package.json ./ai-agent/
COPY --from=backend-build /app/ai-agent/node_modules ./ai-agent/node_modules

# Copy frontend build artifacts
COPY --from=frontend-build /app/frontend/build ./frontend/build
# KunalL config files
COPY smart-contract/out/AIAgentRegistry.sol/AIAgentRegistry.json /app/ai-agent/dist/AIAgentRegistry.json
COPY ai-agent/.env /app/ai-agent/
COPY frontend/.env /app/frontend/
# Install serve for frontend static serving
RUN npm install -g pnpm serve

# Set up environment
EXPOSE 3000

# Create startup script
RUN echo '#!/bin/bash\n\
cd /app/ai-agent && pnpm start & \
cd /app && serve -s frontend/build -l 3001 \n\
wait' > /app/start.sh && chmod +x /app/start.sh

CMD ["/app/start.sh"]