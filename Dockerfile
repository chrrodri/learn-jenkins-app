FROM node:22.19.0-alpine3.22

WORKDIR /app

COPY package*.json ./

RUN apt-get update

RUN apt-get -y curl

RUN npm install

RUN npm ci