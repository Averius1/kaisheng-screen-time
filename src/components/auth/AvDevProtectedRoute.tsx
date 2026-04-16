import { type ReactNode } from "react";
import { useAvDevAuth } from "@/hooks/useAvDevAuth";
import { AvDevLoginForm } from "./AvDevLoginForm";

interface AvDevProtectedRouteProps {
  children: ReactNode;
  fallback?: ReactNode;
}

/**
 * Protects a route - shows login form if not authenticated.
 * 
 * @example
 * <Route path="/dashboard" element={
 *   <AvDevProtectedRoute>
 *     <Dashboard />
 *   </AvDevProtectedRoute>
 * } />
 */
export function AvDevProtectedRoute({ children, fallback }: AvDevProtectedRouteProps) {
  const { isAuthenticated, isLoading } = useAvDevAuth();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) {
    if (fallback) return <>{fallback}</>;
    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="w-full max-w-sm">
          <h2 className="text-lg font-semibold text-center mb-6">Sign in to continue</h2>
          <AvDevLoginForm />
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
