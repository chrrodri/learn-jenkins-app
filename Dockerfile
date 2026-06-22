FROM node:22.19.0-alpine3.22

WORKDIR /app

COPY package*.json ./

RUN npm install

RUN npm ci