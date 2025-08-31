# Stage 1: Build the React application
#
# We use the official Node.js image as our builder.
FROM node:20 AS builder

# Set the working directory.
WORKDIR /usr/src/app

# Copy the package.json and package-lock.json files to the container.
# This allows us to cache the dependencies and avoid reinstalling them on every build.
COPY package*.json ./
# Install the dependencies.
RUN npm install

# Copy the rest of the application code to the container.
COPY . .
# Build the application for production.
# This creates a `dist` directory with the optimized static files.
RUN npm run build

# Stage 2: Serve the static files with Nginx
#
# We use a small Nginx image to serve the static files.
FROM nginx:1.25-alpine

# Copy the built static files from the builder stage to the Nginx html directory.
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
