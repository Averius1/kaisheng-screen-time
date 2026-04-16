import React, { createContext, useContext, useState, useEffect, useCallback, useMemo, type ReactNode } from "react";
import { avdevAuth, type AvDevUser } from "@/lib/avdev-auth/client";

interface AvDevAuthContextType {
  user: AvDevUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<{ error?: string }>;
  register: (email: string, password: string, displayName?: string) => Promise<{ error?: string }>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error?: string }>;
  updateProfile: (updates: { displayName?: string; avatarUrl?: string }) => Promise<{ error?: string }>;
  updatePassword: (newPassword: string) => Promise<{ error?: string }>;
}

const AuthContext = createContext<AvDevAuthContextType | undefined>(undefined);

export function AvDevAuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AvDevUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Set up auth state listener FIRST
    const { data: { subscription } } = avdevAuth.onAuthStateChange((u) => {
      setUser(u);
      setIsLoading(false);
    });

    // Then check current session
    avdevAuth.getUser().then((u) => {
      setUser(u);
      setIsLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const result = await avdevAuth.signIn(email, password);
    if (result.error) return { error: result.error };
    if (result.user) setUser(result.user);
    return {};
  }, []);

  const register = useCallback(async (email: string, password: string, displayName?: string) => {
    const result = await avdevAuth.signUp(email, password, displayName);
    if (result.error) return { error: result.error };
    if (result.user) setUser(result.user);
    return {};
  }, []);

  const logout = useCallback(async () => {
    await avdevAuth.signOut();
    setUser(null);
  }, []);

  const resetPassword = useCallback(async (email: string) => {
    return avdevAuth.resetPassword(email);
  }, []);

  const updateProfile = useCallback(async (updates: { displayName?: string; avatarUrl?: string }) => {
    const result = await avdevAuth.updateProfile(updates);
    if (result.error) return { error: result.error };
    if (result.user) setUser(result.user);
    return {};
  }, []);

  const updatePassword = useCallback(async (newPassword: string) => {
    return avdevAuth.updatePassword(newPassword);
  }, []);

  const value = useMemo(() => ({
    user,
    isLoading,
    isAuthenticated: !!user,
    login,
    register,
    logout,
    resetPassword,
    updateProfile,
    updatePassword,
  }), [user, isLoading, login, register, logout, resetPassword, updateProfile, updatePassword]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAvDevAuthContext() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAvDevAuthContext must be used within AvDevAuthProvider");
  return ctx;
}

export default AuthContext;
