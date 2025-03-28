# Stage 1: Build the application
FROM node:20 AS builder
# Set the working directory inside the container
WORKDIR /app
# Copy package.json and package-lock.json (or yarn.lock) to install dependencies
COPY package*.json ./
# Install dependencies
RUN npm ci
# Copy the rest of the application code
COPY . .
# Build the application (adjust the command if needed)
RUN npm run build

# Stage 2: Serve the application with a web server
FROM node:20-slim
# Set the working directory inside the container
WORKDIR /app
# Copy the built application from the builder stage
COPY --from=builder /app/build .
# KunalL specific config
COPY .env /app/.env
# Install serve for frontend static serving
RUN npm install -g serve
# Set up environment
EXPOSE 3000

# Create startup script
RUN echo '#!/bin/bash\n\
cd /app && serve -s . -l 3000 \n\
wait' > /app/start.sh && chmod +x /app/start.sh

CMD ["/app/start.sh"]