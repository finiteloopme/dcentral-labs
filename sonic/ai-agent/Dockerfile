# Use a Node.js 20 base image
FROM node:20-alpine AS builder
# Set working directory
WORKDIR /app
# Copy node config files
COPY package.json pnpm-lock.yaml tsconfig.json ./
RUN npm install -g pnpm
# Install dependencies
RUN pnpm -f i
# Copy the rest of the application code
COPY ./src ./src
# Build the application (adjust command as needed)
RUN pnpm run build

# Use a slimmer Node.js 20 runtime image
FROM node:20-alpine
# Set working directory
WORKDIR /app
RUN npm install -g pnpm
# Copy only the built application from the builder stage
COPY --from=builder /app/dist ./dist
# KunalL specific config
COPY .env /app/.env
COPY ./dist/AIAgentRegistry.json /app/dist/AIAgentRegistry.json
# Expose the port your application listens on (adjust as needed)
EXPOSE 3000

# Define the command to run your application
CMD ["pnpm", "start"] # Adjust based on your entry point
