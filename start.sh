#!/bin/sh
set -e

# Number of retries to wait for DB to be ready
MAX_RETRIES=30
SLEEP_SECONDS=2
i=0

echo "🔄 Waiting for PostgreSQL at $DATABASE_URL..."

# Extract host and port from DATABASE_URL  
DB_HOST=$(echo $DATABASE_URL | sed -E 's/^.+@([^:/]+):([0-9]+).*$/\1/')   
DB_PORT=$(echo $DATABASE_URL | sed -E 's/^.+@([^:/]+):([0-9]+).*$/\2/')   

# Wait until the database is reachable   
until nc -z "$DB_HOST" "$DB_PORT"; do                                      
  echo "⏳ Database not ready yet ($DB_HOST:$DB_PORT), retrying in 3s..."   
  sleep 3                                                                  
done                                                                        

echo "✅ Database is up, applying Prisma migrations..."

# Retry loop for migrations
until npx prisma migrate deploy --schema=./prisma/schema.prisma; do
  i=$((i+1))
  echo "Attempt $i/$MAX_RETRIES: Prisma migrate deploy failed — retrying in ${SLEEP_SECONDS}s..."
  if [ "$i" -ge "$MAX_RETRIES" ]; then
    echo "Exceeded max retries ($MAX_RETRIES). Exiting."
    exit 1
  fi
  sleep $SLEEP_SECONDS
done

echo "Migrations applied (or were already up-to-date). Generating Prisma client..."
npx prisma generate --schema=./prisma/schema.prisma   

echo "Starting backend..."
exec node dist/main.js                               
