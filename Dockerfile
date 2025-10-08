# ---------- builder stage ----------
FROM node:lts AS builder
WORKDIR /app

# Install all deps (we need the prisma CLI in the build stage)
COPY package*.json ./
RUN npm ci

# Copy prisma schema + migrations and application files (including built dist)
# Adjust the COPY paths if your project layout differs
COPY prisma ./prisma
COPY dist ./dist
COPY . .

# Generate Prisma client during build so the client files exist in node_modules
RUN npx prisma generate --schema=./prisma/schema.prisma

# ---------- final stage ----------
FROM node:lts
WORKDIR /app

ENV HOST=0.0.0.0
ENV PORT=3001

# Install netcat so start.sh can wait for DB  [NEW]
RUN apt-get update && apt-get install -y netcat && rm -rf /var/lib/apt/lists/*   


# create non-root user
RUN groupadd -r api && useradd -r -g api api

# Copy only what we need from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# set ownership, switch to non-root
RUN chown -R api:api /app
USER api

EXPOSE 3001

# copy start script and make executable
COPY start.sh ./start.sh
RUN chmod +x ./start.sh

# Start with the script that runs migrations then the app
CMD ["./start.sh"]
