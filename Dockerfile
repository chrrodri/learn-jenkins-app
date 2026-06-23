FROM node:22.19.0-alpine3.22

# Instalar utilidades necesarias
RUN apk add --no-cache curl

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias exactamente como están en package-lock.json
RUN npm ci

# Copiar el resto del proyecto
COPY . .

CMD ["npm", "start"]