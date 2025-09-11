# Use Node.js LTS Alpine for small image
FROM node:lts

# Set environment variables
ENV HOST=0.0.0.0
ENV PORT=3001

# Working directory
WORKDIR /app

# Create non-root user
RUN groupadd -r api && useradd -r -g api api

# Copy package.json and package-lock.json
COPY package*.json ./

# Copy Prisma schema
COPY src/prisma ./prisma

# Copy built backend code
COPY dist/api ./dist


# Install production dependencies
RUN npm install --omit=dev


# Generate Prisma client
RUN npx prisma generate --schema ./prisma/schema.prisma

# Set ownership to non-root user
RUN chown -R api:api .

# Run as non-root
USER api

# Expose backend port
EXPOSE 3001

# Start the backend
CMD [ "node", "dist/main.js" ]
