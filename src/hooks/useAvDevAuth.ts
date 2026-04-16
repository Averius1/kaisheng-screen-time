import { useAvDevAuthContext } from "@/contexts/AvDevAuthContext";

/**
 * Hook to access AvDev Auth state and actions.
 * Must be used within <AvDevAuthProvider>.
 * 
 * @example
 * const { user, login, logout, isAuthenticated } = useAvDevAuth();
 */
export function useAvDevAuth() {
  return useAvDevAuthContext();
}

/**
 * Hook that redirects to login if not authenticated.
 * Returns the authenticated user (never null after loading).
 */
export function useRequireAuth() {
  const auth = useAvDevAuthContext();
  return auth;
}

/**
 * Hook to check user roles.
 */
export function useUserRole() {
  const { user } = useAvDevAuthContext();
  return {
    roles: user?.roles || [],
    hasRole: (role: string) => user?.roles?.includes(role) || false,
    isAdmin: user?.roles?.includes("admin") || false,
    isModerator: user?.roles?.includes("moderator") || false,
  };
}
