# Use official Node.js 22 Alpine base image
FROM node:22-alpine

# Set /app as the working directory
WORKDIR /app

# Copy only package.json and package-lock.json for efficient layer caching and dependency installation
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application source code
COPY . .

# Expose port 3000
EXPOSE 3000

# Run the application
CMD ["npm", "start"]
