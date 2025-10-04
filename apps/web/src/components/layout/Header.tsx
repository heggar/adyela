import { useTranslation } from "react-i18next";
import { useAuthStore } from "@/store/authStore";

export function Header() {
  const { t } = useTranslation();
  const { user, logout } = useAuthStore();

  return (
    <header className="border-b border-secondary-200 bg-white px-6 py-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold text-secondary-900">Adyela</h1>
        <div className="flex items-center gap-4">
          <span className="text-sm text-secondary-600">{user?.name}</span>
          <button onClick={logout} className="btn-ghost px-4 py-2">
            {t("common.logout")}
          </button>
        </div>
      </div>
    </header>
  );
}
