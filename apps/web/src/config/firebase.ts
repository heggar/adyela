import { initializeApp } from "firebase/app";
import { getAuth, connectAuthEmulator } from "firebase/auth";
import { getFirestore, connectFirestoreEmulator } from "firebase/firestore";

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

// Debug: Log Firebase configuration (remove in production)
console.log("Firebase Config:", {
  apiKey: firebaseConfig.apiKey
    ? "***" + firebaseConfig.apiKey.slice(-4)
    : "undefined",
  authDomain: firebaseConfig.authDomain || "undefined",
  projectId: firebaseConfig.projectId || "undefined",
  storageBucket: firebaseConfig.storageBucket || "undefined",
  messagingSenderId: firebaseConfig.messagingSenderId || "undefined",
  appId: firebaseConfig.appId || "undefined",
});

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// Connect to emulator in development
if (import.meta.env.DEV) {
  try {
    connectAuthEmulator(auth, "http://localhost:9099");
    connectFirestoreEmulator(db, "localhost", 8080);
  } catch {
    // Emulator already connected
    console.log("Firebase emulator already connected");
  }
}

export { auth, db };
