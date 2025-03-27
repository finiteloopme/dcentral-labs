# Multi-stage build for frontend and backend

# Frontend build stage
FROM node:20 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Backend build stage
FROM node:20 AS backend-build
WORKDIR /app/ai-agent
COPY ai-agent/package.json ai-agent/package-lock.json ./
RUN npm ci
COPY ai-agent/ ./
RUN npm run build

# Final stage
FROM node:20-slim
WORKDIR /app

# Copy backend build artifacts
COPY --from=backend-build /app/ai-agent/dist ./ai-agent/dist
COPY --from=backend-build /app/ai-agent/package.json ./ai-agent/
COPY --from=backend-build /app/ai-agent/node_modules ./ai-agent/node_modules

# Copy frontend build artifacts
COPY --from=frontend-build /app/frontend/build ./frontend/build

# Install serve for frontend static serving
RUN npm install -g serve

# Set up environment
EXPOSE 3000 5000

# Create startup script
RUN echo '#!/bin/bash\n\
cd /app/ai-agent && node dist/server.js & \
cd /app && serve -s frontend/build -l 3000\n\
wait' > /app/start.sh && chmod +x /app/start.sh

CMD ["/app/start.sh"]