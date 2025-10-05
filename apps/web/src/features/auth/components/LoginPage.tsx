import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useAuthStore } from "@/store/authStore";

export function LoginPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const login = useAuthStore((state) => state.login);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Mock login - replace with actual API call
    login(
      {
        id: "1",
        email,
        name: "Demo User",
        role: "doctor",
        tenantId: "tenant-1",
      },
      "mock-token",
    );
    navigate("/dashboard");
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-secondary-50">
      <main className="card w-full max-w-md p-8" data-testid="login-page">
        <header className="mb-8">
          <h1
            className="mb-6 text-center text-3xl font-bold text-secondary-900"
            data-testid="login-title"
          >
            {t("auth.welcomeBack")}
          </h1>
          <p className="text-center text-secondary-600">
            {t("auth.loginToContinue")}
          </p>
        </header>
        <section>
          <form
            onSubmit={handleSubmit}
            className="space-y-4"
            data-testid="login-form"
          >
            <div>
              <label
                htmlFor="email"
                className="mb-2 block text-sm font-medium text-secondary-700"
              >
                {t("auth.email")}
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="input"
                data-testid="email-input"
                required
              />
            </div>
            <div>
              <label
                htmlFor="password"
                className="mb-2 block text-sm font-medium text-secondary-700"
              >
                {t("auth.password")}
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input"
                data-testid="password-input"
                required
              />
            </div>
            <button
              type="submit"
              className="btn-primary w-full py-3"
              data-testid="login-button"
            >
              {t("auth.login")}
            </button>
          </form>
        </section>
      </main>
    </div>
  );
}
