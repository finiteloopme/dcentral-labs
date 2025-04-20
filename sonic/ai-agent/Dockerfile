# Use a Node.js 20 base image
FROM node:20 AS builder
# Set working directory
WORKDIR /app
# Copy node config files
COPY package.json pnpm-lock.yaml tsconfig.json ./
RUN apt install -y wget
RUN npm install -g pnpm
# Install dependencies
RUN pnpm -f i
# Copy the rest of the application code
COPY ./src ./src
# Build the application (adjust command as needed)
RUN pnpm run build
RUN wget https://gist.githubusercontent.com/kunallimaye/c8ece59fc0fe076880ccd2d169a3a8d6/raw/ff10d431a98c92ef8aa5db271b7ea1a164c55634/AIAgentRegistry.json -O ./dist/AIAgentRegistry.json
# COPY ./dist/AIAgentRegistry.json /app/dist/AIAgentRegistry.json

# Use a slimmer Node.js 20 runtime image
FROM node:20-slim
# Set working directory
WORKDIR /app
# Copy only the built application from the builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json .
COPY --from=builder /app/node_modules ./node_modules
# KunalL specific config
COPY .env /app/.env
# Expose the port your application listens on (adjust as needed)
EXPOSE 3000
RUN npm install -g pnpm
# Create startup script
RUN echo '#!/bin/bash\n\
cd /app/ && pnpm start & \n\
wait' > /app/start.sh && chmod +x /app/start.sh

# Define the command to run your application
CMD ["/app/start.sh"]
