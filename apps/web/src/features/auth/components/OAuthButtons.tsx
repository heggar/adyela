import { useTranslation } from "react-i18next";
import { useOAuthLogin } from "../hooks/useOAuthLogin";
import { GoogleIcon } from "@/components/ui/icons/GoogleIcon";
import { FacebookIcon } from "@/components/ui/icons/FacebookIcon";
import { AppleIcon } from "@/components/ui/icons/AppleIcon";
import { MicrosoftIcon } from "@/components/ui/icons/MicrosoftIcon";

export function OAuthButtons() {
  const { t } = useTranslation();
  const { loginWithProvider, loading, error } = useOAuthLogin();

  const providers = [
    {
      id: "google" as const,
      name: t("auth.continueWithGoogle"),
      icon: GoogleIcon,
      className:
        "bg-white border border-gray-300 text-gray-700 hover:bg-gray-50",
    },
    {
      id: "facebook" as const,
      name: t("auth.continueWithFacebook"),
      icon: FacebookIcon,
      className:
        "bg-[#1877F2] text-white hover:bg-[#166FE5] focus:ring-2 focus:ring-[#1877F2] focus:ring-offset-2",
    },
    {
      id: "apple" as const,
      name: t("auth.continueWithApple"),
      icon: AppleIcon,
      className: "bg-black text-white hover:bg-gray-800",
    },
    {
      id: "microsoft" as const,
      name: t("auth.continueWithMicrosoft"),
      icon: MicrosoftIcon,
      className:
        "bg-[#0078D4] text-white hover:bg-[#106EBE] focus:ring-2 focus:ring-[#0078D4] focus:ring-offset-2",
    },
  ];

  return (
    <div className="space-y-3">
      {providers.map((provider) => {
        const IconComponent = provider.icon;
        return (
          <button
            key={provider.id}
            onClick={() => loginWithProvider(provider.id)}
            disabled={loading}
            className={`
              w-full flex items-center justify-center gap-3 px-4 py-3 rounded-lg font-medium
              transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed
              ${provider.className}
            `}
            data-testid={`oauth-${provider.id}-button`}
          >
            <IconComponent className="w-5 h-5" />
            {loading ? t("auth.signingIn") : provider.name}
          </button>
        );
      })}

      {error && (
        <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-600" data-testid="oauth-error">
            {t("auth.oauthError")}
          </p>
        </div>
      )}
    </div>
  );
}
