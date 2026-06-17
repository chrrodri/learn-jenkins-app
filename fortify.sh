#!/bin/bash

# 1. Configuración de Variables Globales
BUILD_ID="mi_proyecto_sast"
FORTIFY_SSC_URL="https://tu-servidor-ssc.com"
# El token se recomienda pasar como variable de entorno desde Jenkins por seguridad
SSC_TOKEN=${FORTIFY_SSC_TOKEN} 
PROJECT_VERSION_ID="10001" # ID de la versión de la aplicación en el dashboard SSC

echo "=== Iniciando Análisis Estático con Fortify ==="

# 2. Fase de Limpieza (Clean)
# Elimina cualquier caché previo asociado a este Build ID
sourceanalyzer -b "$BUILD_ID" -clean

echo "=== Fase de Traducción ==="
# 3. Fase de Traducción (Translation)
# Selecciona SOLO UNA de las siguientes opciones según tu lenguaje:

# Opción A: Para proyectos Java modernos (usando Maven)
# sourceanalyzer -b "$BUILD_ID" mvn clean compile

# Opción B: Para proyectos Java modernos (usando Gradle)
# sourceanalyzer -b "$BUILD_ID" gradle compileJava

# Opción C: Para lenguajes interpretados (JavaScript, TypeScript, Python, PHP)
# sourceanalyzer -b "$BUILD_ID" .

echo "=== Fase de Escaneo ==="
# 4. Fase de Análisis (Scan)
# Ejecuta el escaneo y genera un archivo de resultados (.fpr)
sourceanalyzer -b "$BUILD_ID" -scan -f resultados.fpr

echo "=== Fase de Subida a SSC ==="
# 5. Subida de resultados al servidor centralizado (Opcional)
if [ -f "resultados.fpr" ]; then
    fortifyclient -url "$FORTIFY_SSC_URL" \
                  -authtoken "$SSC_TOKEN" \
                  uploadFPR \
                  -file resultados.fpr \
                  -projectVersionID "$PROJECT_VERSION_ID"
    echo "Resultados subidos exitosamente a Fortify SSC."
else
    echo "Error: No se generó el archivo de resultados FPR."
    exit 1
fi