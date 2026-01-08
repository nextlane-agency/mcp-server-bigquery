# --- Build Stage ---
FROM node:18-alpine AS builder

WORKDIR /app

# Installeer build-tools (soms nodig voor gRPC/BigQuery libs)
RUN apk add --no-cache python3 make g++ gcc libc-dev bash

# Kopieer package files
COPY package*.json ./

# Installeer dependencies (inclusief devDependencies voor de build)
RUN npm install

# Kopieer de rest van de code
COPY . .

# Bouw de TypeScript naar JavaScript
RUN npm run build

# --- Runtime Stage ---
FROM node:18-alpine

WORKDIR /app

# Installeer runtime tools voor Google Cloud
RUN apk add --no-cache python3 bash

# Kopieer alleen de noodzakelijke bestanden van de builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

# Maak een plek voor je Google Cloud Credentials
# Smithery laat je vaak een 'secret' of file mounten
RUN mkdir -p /app/config && chmod 777 /app/config
ENV GOOGLE_APPLICATION_CREDENTIALS=/app/config/service-account.json

# Standaard MCP workspace
RUN mkdir -p /tmp/mcp-workspace && chmod 777 /tmp/mcp-workspace
ENV DEFAULT_WORKSPACE=/tmp/mcp-workspace

# Start de server (gebaseerd op jouw 'main' in package.json)
CMD ["node", "dist/index.js"]
