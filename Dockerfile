FROM node:22-alpine

WORKDIR /app

RUN apk update && apk upgrade libssl3 libcrypto3

COPY package*.json ./

RUN npm ci --omit=dev

COPY src ./src

RUN npm install -g npm@11.19.1 && chown -R node:node /app

USER node

EXPOSE 3000

CMD ["node", "src/server.js"]