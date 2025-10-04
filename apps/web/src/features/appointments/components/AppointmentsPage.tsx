import { useTranslation } from "react-i18next";

export function AppointmentsPage() {
  const { t } = useTranslation();

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-3xl font-bold text-secondary-900">
          {t("appointments.title")}
        </h1>
        <button className="btn-primary px-4 py-2">
          {t("appointments.new")}
        </button>
      </div>
      <div className="card">
        <div className="p-6">
          <p className="text-center text-secondary-600">
            {t("appointments.upcoming")} - Coming soon
          </p>
        </div>
      </div>
    </div>
  );
}
