import {
  signInWithPopup,
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
    return await signInWithPopup(auth, provider);
  },

  signInWithFacebook: async (): Promise<UserCredential> => {
    const provider = new FacebookAuthProvider();
    provider.addScope("email");
    provider.addScope("public_profile");
    return await signInWithPopup(auth, provider);
  },

  signInWithApple: async (): Promise<UserCredential> => {
    const provider = new OAuthProvider("apple.com");
    provider.addScope("email");
    provider.addScope("name");
    return await signInWithPopup(auth, provider);
  },

  signInWithMicrosoft: async (): Promise<UserCredential> => {
    const provider = new OAuthProvider("microsoft.com");
    provider.addScope("email");
    provider.addScope("profile");
    return await signInWithPopup(auth, provider);
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
