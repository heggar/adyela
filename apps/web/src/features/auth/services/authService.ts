import {
  signInWithPopup,
  signInWithRedirect,
  getRedirectResult,
  GoogleAuthProvider,
  FacebookAuthProvider,
  OAuthProvider,
  UserCredential,
  User,
} from "firebase/auth";
import { auth } from "@/config/firebase";

export type OAuthProviderType = "google" | "facebook" | "apple" | "microsoft";

export interface OAuthUserData {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  provider: OAuthProviderType;
  emailVerified: boolean;
}

export const authService = {
  signInWithGoogle: async (): Promise<UserCredential> => {
    const provider = new GoogleAuthProvider();
    provider.addScope("email");
    provider.addScope("profile");

    try {
      // Try popup first, fallback to redirect if blocked
      return await signInWithPopup(auth, provider);
    } catch (error: any) {
      if (
        error.code === "auth/popup-blocked" ||
        error.code === "auth/popup-closed-by-user"
      ) {
        // Fallback to redirect if popup is blocked
        await signInWithRedirect(auth, provider);
        // This will redirect the page, so we won't reach here
        throw new Error("Redirecting to authentication...");
      }
      throw error;
    }
  },

  signInWithFacebook: async (): Promise<UserCredential> => {
    const provider = new FacebookAuthProvider();
    provider.addScope("email");
    provider.addScope("public_profile");

    try {
      return await signInWithPopup(auth, provider);
    } catch (error: any) {
      if (
        error.code === "auth/popup-blocked" ||
        error.code === "auth/popup-closed-by-user"
      ) {
        await signInWithRedirect(auth, provider);
        throw new Error("Redirecting to authentication...");
      }
      throw error;
    }
  },

  signInWithApple: async (): Promise<UserCredential> => {
    const provider = new OAuthProvider("apple.com");
    provider.addScope("email");
    provider.addScope("name");

    try {
      return await signInWithPopup(auth, provider);
    } catch (error: any) {
      if (
        error.code === "auth/popup-blocked" ||
        error.code === "auth/popup-closed-by-user"
      ) {
        await signInWithRedirect(auth, provider);
        throw new Error("Redirecting to authentication...");
      }
      throw error;
    }
  },

  signInWithMicrosoft: async (): Promise<UserCredential> => {
    const provider = new OAuthProvider("microsoft.com");
    provider.addScope("email");
    provider.addScope("profile");

    try {
      return await signInWithPopup(auth, provider);
    } catch (error: any) {
      if (
        error.code === "auth/popup-blocked" ||
        error.code === "auth/popup-closed-by-user"
      ) {
        await signInWithRedirect(auth, provider);
        throw new Error("Redirecting to authentication...");
      }
      throw error;
    }
  },

  // Handle redirect result when user returns from OAuth
  handleRedirectResult: async (): Promise<UserCredential | null> => {
    try {
      return await getRedirectResult(auth);
    } catch (error) {
      console.error("Error handling redirect result:", error);
      return null;
    }
  },

  extractUserData: (user: User, provider: OAuthProviderType): OAuthUserData => {
    return {
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      provider,
      emailVerified: user.emailVerified,
    };
  },

  getIdToken: async (user: User): Promise<string> => {
    return await user.getIdToken();
  },
};
