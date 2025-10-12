#!/usr/bin/env node

/**
 * Script para habilitar proveedores OAuth en Firebase Authentication
 * Ejecutar con: node scripts/enable-oauth-providers.js
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

// Configuración del proyecto
const projectId = "adyela-staging";

async function enableOAuthProviders() {
  try {
    console.log("🔧 Habilitando proveedores OAuth en Firebase...");

    // Inicializar Firebase Admin SDK
    const app = initializeApp({
      projectId: projectId,
    });

    const auth = getAuth(app);

    // Configuración de proveedores OAuth
    const providers = [
      {
        providerId: "google.com",
        enabled: true,
        displayName: "Google",
        clientId: process.env.GOOGLE_CLIENT_ID || "your-google-client-id",
        clientSecret:
          process.env.GOOGLE_CLIENT_SECRET || "your-google-client-secret",
      },
      {
        providerId: "facebook.com",
        enabled: true,
        displayName: "Facebook",
        clientId: process.env.FACEBOOK_APP_ID || "your-facebook-app-id",
        clientSecret:
          process.env.FACEBOOK_APP_SECRET || "your-facebook-app-secret",
      },
      {
        providerId: "apple.com",
        enabled: true,
        displayName: "Apple",
        clientId: process.env.APPLE_CLIENT_ID || "your-apple-client-id",
        clientSecret:
          process.env.APPLE_CLIENT_SECRET || "your-apple-client-secret",
      },
      {
        providerId: "microsoft.com",
        enabled: true,
        displayName: "Microsoft",
        clientId: process.env.MICROSOFT_CLIENT_ID || "your-microsoft-client-id",
        clientSecret:
          process.env.MICROSOFT_CLIENT_SECRET || "your-microsoft-client-secret",
      },
    ];

    console.log("📋 Proveedores a habilitar:");
    providers.forEach((provider) => {
      console.log(`  - ${provider.displayName} (${provider.providerId})`);
    });

    console.log(
      "\n⚠️  NOTA: Este script requiere configuración manual en la consola de Firebase",
    );
    console.log(
      "   Visita: https://console.firebase.google.com/project/adyela-staging/authentication/providers",
    );
    console.log("\n🔗 Pasos para habilitar cada proveedor:");
    console.log("   1. Google: Habilitar y configurar OAuth consent screen");
    console.log("   2. Facebook: Crear app en Facebook Developers");
    console.log("   3. Apple: Configurar en Apple Developer Console");
    console.log("   4. Microsoft: Registrar app en Azure AD");
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

enableOAuthProviders();
