#!/bin/bash
set -e

APP_NAME="react-app"

echo "Cleaning previous Fortify build..."
sourceanalyzer -b $APP_NAME -clean

echo "Translating source code..."
sourceanalyzer -b $APP_NAME npm install

echo "Running scan..."
sourceanalyzer -b $APP_NAME -scan -f results.fpr

echo "Fortify scan completed successfully."