import { create } from "zustand";
import { persist } from "zustand/middleware";
import { OAuthUserData } from "@/features/auth/services/authService";

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  tenantId: string;
  photoURL?: string | null;
  provider?: string;
  emailVerified?: boolean;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
  syncWithBackend: (
    firebaseToken: string,
    oauthData: OAuthUserData,
  ) => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      login: (user, token) =>
        set({
          user,
          token,
          isAuthenticated: true,
        }),
      logout: () =>
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        }),
      syncWithBackend: async (
        firebaseToken: string,
        oauthData: OAuthUserData,
      ) => {
        try {
          const apiBaseUrl =
            import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";
          const response = await fetch(`${apiBaseUrl}/api/v1/auth/sync`, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${firebaseToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(oauthData),
          });

          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          const data = await response.json();

          set({
            user: {
              id: data.user.uid,
              email: data.user.email,
              name: data.user.displayName || data.user.email,
              role: data.user.roles?.[0] || "patient",
              tenantId: data.user.tenant_id || "default",
              photoURL: data.user.photoURL,
              provider: data.user.provider,
              emailVerified: data.user.emailVerified,
            },
            token: firebaseToken,
            isAuthenticated: true,
          });
        } catch (error) {
          console.error("Error syncing with backend:", error);
          throw error;
        }
      },
    }),
    {
      name: "auth-storage",
    },
  ),
);
