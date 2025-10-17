import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { MainLayout } from '@/components/layout/MainLayout';
import { LoginPage } from '@/features/auth/components/LoginPage';
import { DashboardPage } from '@/features/dashboard/DashboardPage';
import { AppointmentsPage } from '@/features/appointments/components/AppointmentsPage';
import { PrivacyPolicyPage } from '@/features/legal/components/PrivacyPolicyPage';
import { DataDeletionPage } from '@/features/legal/components/DataDeletionPage';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore(state => state.isAuthenticated);

  if (!isAuthenticated) {
    return <Navigate to='/login' replace />;
  }

  return <>{children}</>;
}

function App() {
  return (
    <Routes>
      {/* Public routes - no authentication required */}
      <Route path='/login' element={<LoginPage />} />
      <Route path='/privacy' element={<PrivacyPolicyPage />} />
      <Route path='/data-deletion' element={<DataDeletionPage />} />

      {/* Protected routes - authentication required */}
      <Route
        path='/'
        element={
          <ProtectedRoute>
            <MainLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to='/dashboard' replace />} />
        <Route path='dashboard' element={<DashboardPage />} />
        <Route path='appointments' element={<AppointmentsPage />} />
      </Route>
      <Route path='*' element={<Navigate to='/' replace />} />
    </Routes>
  );
}

export default App;
