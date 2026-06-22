FROM node:22.19.0-alpine3.22

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY . .

RUN npm ci

COPY . .

RUN apk add --no-cache curl