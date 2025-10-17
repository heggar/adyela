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

/**
 * Get the API base URL dynamically based on the environment
 *
 * @returns API base URL
 *
 * Logic:
 * - Development: http://localhost:8000
 * - Production/Staging: Same origin (Load Balancer handles routing)
 *
 * The Load Balancer is configured to route:
 * - / → Web service (port 8080)
 * - /api/v1/* → API service (port 8000)
 *
 * This allows the frontend to call the API using the same domain
 * without needing environment-specific configuration.
 */
const getApiBaseUrl = (): string => {
  // In development, use localhost
  if (import.meta.env.DEV) {
    return "http://localhost:8000";
  }

  // In production/staging, use the same origin
  // The Load Balancer will route /api/v1/* to the API service
  return window.location.origin;
};

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
          const apiBaseUrl = getApiBaseUrl();
          const response = await fetch(`${apiBaseUrl}/api/v1/auth/sync`, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${firebaseToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ user_data: oauthData }),
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
