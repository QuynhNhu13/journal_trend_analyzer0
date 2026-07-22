import { Navigate, Route, Routes } from 'react-router-dom';

import { AppShell } from './components/layout/AppShell';
import { ProtectedRoute } from './components/ProtectedRoute';
import { LoginPage } from './pages/LoginPage';
import { AccessDeniedPage } from './pages/AccessDeniedPage';
import { DashboardPage } from './pages/DashboardPage';
import { UsersPage } from './pages/UsersPage';
import { NotificationsPage } from './pages/NotificationsPage';
import { ConfigPage } from './pages/ConfigPage';
import { ReportsPage } from './pages/ReportsPage';
import { LogsPage } from './pages/LogsPage';

export default function App() {
  return (
    <Routes>
      {/* Public */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/access-denied" element={<AccessDeniedPage />} />

      {/* Protected app shell */}
      <Route
        element={
          <ProtectedRoute>
            <AppShell />
          </ProtectedRoute>
        }
      >
        <Route index element={<DashboardPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="notifications" element={<NotificationsPage />} />
        <Route path="config" element={<ConfigPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="logs" element={<LogsPage />} />
      </Route>

      {/* Unknown routes fall back to the dashboard (which enforces auth). */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
