# Build stage
FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Runtime stage
FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache curl

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app .

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

CMD ["node", "src/server.js"]
