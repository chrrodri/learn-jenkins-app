FROM node:22.19.0-alpine3.22

WORKDIR /app

COPY package*.json ./

RUN apk add --no-cache curl

RUN npm ci