#!/bin/bash
set -e

echo "🔥 Firebase Secrets Setup for Staging"
echo "======================================"
echo ""
echo "Este script te ayudará a configurar los secretos de Firebase."
echo ""
echo "Necesitas obtener la configuración de Firebase de:"
echo "https://console.firebase.google.com/project/adyela-staging/settings/general"
echo ""
echo "Si no tienes una app web registrada, créala primero:"
echo "1. Ve a Firebase Console -> Project Settings"
echo "2. Scroll down a 'Your apps'"
echo "3. Click en el icono de web (</>) para agregar una app web"
echo "4. Nombra tu app: 'Adyela Web Staging'"
echo "5. NO marques 'Firebase Hosting'"
echo "6. Click en 'Register app'"
echo "7. Copia la configuración"
echo ""
echo "La configuración se verá así:"
echo "const firebaseConfig = {"
echo "  apiKey: \"AIza...\","
echo "  authDomain: \"adyela-staging.firebaseapp.com\","
echo "  projectId: \"adyela-staging\","
echo "  storageBucket: \"adyela-staging.appspot.com\","
echo "  messagingSenderId: \"123456789\","
echo "  appId: \"1:123456789:web:...\""
echo "};"
echo ""
echo "Por favor, ingresa los valores a continuación:"
echo ""

# Prompt for Firebase configuration
read -p "VITE_FIREBASE_API_KEY (APIKey): " FIREBASE_API_KEY
read -p "VITE_FIREBASE_PROJECT_ID [adyela-staging]: " FIREBASE_PROJECT_ID
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-adyela-staging}

read -p "VITE_FIREBASE_AUTH_DOMAIN [adyela-staging.firebaseapp.com]: " FIREBASE_AUTH_DOMAIN
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-adyela-staging.firebaseapp.com}

read -p "VITE_FIREBASE_STORAGE_BUCKET [adyela-staging.appspot.com]: " FIREBASE_STORAGE_BUCKET
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-adyela-staging.appspot.com}

read -p "VITE_FIREBASE_MESSAGING_SENDER_ID: " FIREBASE_MESSAGING_SENDER_ID
read -p "VITE_FIREBASE_APP_ID: " FIREBASE_APP_ID

# Get staging API URL
read -p "VITE_API_URL_STAGING (e.g., https://adyela-api-staging-xxx.a.run.app): " API_URL_STAGING

echo ""
echo "Configurando secretos en GitHub..."
echo ""

# Set GitHub secrets
gh secret set VITE_FIREBASE_API_KEY -b "$FIREBASE_API_KEY"
gh secret set VITE_FIREBASE_PROJECT_ID -b "$FIREBASE_PROJECT_ID"
gh secret set VITE_FIREBASE_AUTH_DOMAIN -b "$FIREBASE_AUTH_DOMAIN"
gh secret set VITE_FIREBASE_STORAGE_BUCKET -b "$FIREBASE_STORAGE_BUCKET"
gh secret set VITE_FIREBASE_MESSAGING_SENDER_ID -b "$FIREBASE_MESSAGING_SENDER_ID"
gh secret set VITE_FIREBASE_APP_ID -b "$FIREBASE_APP_ID"
gh secret set VITE_API_URL_STAGING -b "$API_URL_STAGING"

echo ""
echo "✅ Secretos configurados exitosamente:"
echo "   - VITE_FIREBASE_API_KEY"
echo "   - VITE_FIREBASE_PROJECT_ID"
echo "   - VITE_FIREBASE_AUTH_DOMAIN"
echo "   - VITE_FIREBASE_STORAGE_BUCKET"
echo "   - VITE_FIREBASE_MESSAGING_SENDER_ID"
echo "   - VITE_FIREBASE_APP_ID"
echo "   - VITE_API_URL_STAGING"
echo ""
echo "Ahora puedes ejecutar el workflow de staging:"
echo "gh workflow run cd-staging.yml --ref main -f version=v1.0.0 -f skip_e2e=true"
echo ""
