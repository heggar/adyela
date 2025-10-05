import { useTranslation } from "react-i18next";

export function DashboardPage() {
  const { t } = useTranslation();

  return (
    <div data-testid="dashboard-page">
      <h1
        className="mb-6 text-3xl font-bold text-secondary-900"
        data-testid="dashboard-title"
      >
        {t("dashboard.title")}
      </h1>
      <div className="grid gap-6 md:grid-cols-3" data-testid="dashboard-stats">
        <div className="card p-6" data-testid="today-appointments-card">
          <h3 className="mb-2 text-sm font-medium text-secondary-600">
            {t("dashboard.todayAppointments")}
          </h3>
          <p className="text-3xl font-bold text-secondary-900">12</p>
        </div>
        <div className="card p-6" data-testid="upcoming-appointments-card">
          <h3 className="mb-2 text-sm font-medium text-secondary-600">
            {t("dashboard.upcomingAppointments")}
          </h3>
          <p className="text-3xl font-bold text-secondary-900">45</p>
        </div>
        <div className="card p-6" data-testid="total-patients-card">
          <h3 className="mb-2 text-sm font-medium text-secondary-600">
            {t("dashboard.totalPatients")}
          </h3>
          <p className="text-3xl font-bold text-secondary-900">328</p>
        </div>
      </div>
    </div>
  );
}
