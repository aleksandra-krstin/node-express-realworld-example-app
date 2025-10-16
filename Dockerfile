# =========================
# 1️ Build stage
# =========================
FROM node:lts-slim AS builder

RUN apt-get update -y && \
    apt-get install -y openssl libssl-dev
  

# Set working directory
WORKDIR /app

# Copy only dependency files first (for caching)
COPY package*.json ./

# Install dependencies including dev dependencies (needed to build)
RUN npm ci

# Copy the rest of the backend source code
COPY . .

# Run Nx build (or whatever your build command is)
# Adjust this if your backend project name is not "api"
RUN npx prisma generate
RUN npx nx build api


# =========================
# 2️  Runtime stage
# =========================
FROM node:lts-slim AS runner

WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3001

RUN apt-get update -y && \
    apt-get install -y openssl && \
    rm -rf /var/lib/apt/lists/*

# Create the 'api' user
RUN addgroup --system api && adduser --system --ingroup api api

# Copy only built output + production dependencies
COPY --from=builder /app/dist/api ./api
COPY package*.json ./
RUN npm ci --omit=dev

# Change ownership (optional, good practice for non-root user)
RUN chown -R api:api .

# Also copy Prisma files (optional, sometimes needed)
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

USER api

EXPOSE 3001
CMD ["node", "api"]
