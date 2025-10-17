import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { authService, OAuthProviderType } from '../services/authService';

export const useOAuthLogin = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const { syncWithBackend } = useAuthStore();

  // Handle redirect result on component mount
  useEffect(() => {
    const handleRedirectResult = async () => {
      try {
        const result = await authService.handleRedirectResult();
        if (result) {
          const token = await authService.getIdToken(result.user);
          const userData = authService.extractUserData(result.user, 'google'); // Default to google, could be improved
          await syncWithBackend(token, userData);
          navigate('/dashboard');
        }
      } catch (err) {
        console.error('Error handling redirect result:', err);
      }
    };

    handleRedirectResult();
  }, [navigate, syncWithBackend]);

  const loginWithProvider = async (provider: OAuthProviderType) => {
    setLoading(true);
    setError(null);

    try {
      let result;
      switch (provider) {
        case 'google':
          result = await authService.signInWithGoogle();
          break;
        case 'facebook':
          result = await authService.signInWithFacebook();
          break;
        case 'apple':
          result = await authService.signInWithApple();
          break;
        case 'microsoft':
          result = await authService.signInWithMicrosoft();
          break;
        default:
          throw new Error(`Unsupported provider: ${provider}`);
      }

      const token = await authService.getIdToken(result.user);
      const userData = authService.extractUserData(result.user, provider);

      await syncWithBackend(token, userData);
      navigate('/dashboard');
    } catch (err: unknown) {
      console.error('OAuth login error:', err);
      const errorMessage = err instanceof Error ? err.message : 'Error during authentication';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return { loginWithProvider, loading, error };
};
