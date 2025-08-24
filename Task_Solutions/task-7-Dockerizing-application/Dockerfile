# Use official Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy app source code
COPY src ./src

# Expose the app port
EXPOSE 3000

# Start the app
CMD ["node", "src/app.js"]
