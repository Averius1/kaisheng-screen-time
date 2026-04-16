/**
 * AvDev Auth Client
 * Routes ALL auth operations through the avdev-auth edge function
 * for server-side rate limiting, validation, and consistent security.
 */
import { supabase } from "@/integrations/supabase/client";

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "";
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || "";

async function authFetch(action: string, body?: Record<string, unknown>, method = "POST") {
  const url = SUPABASE_URL + "/functions/v1/avdev-auth";
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "apikey": SUPABASE_ANON_KEY,
  };
  // Attach user token if available
  const { data: { session } } = await supabase.auth.getSession();
  if (session?.access_token) {
    headers["Authorization"] = "Bearer " + session.access_token;
  }
  const res = await fetch(url, {
    method,
    headers,
    body: JSON.stringify({ action, ...(body || {}) }),
  });
  return res.json();
}

export interface AvDevUser {
  id: string;
  email: string;
  displayName?: string;
  avatarUrl?: string;
  roles?: string[];
}

export interface AvDevSession {
  access_token: string;
  refresh_token: string;
  expires_at?: number;
}

export interface AuthResult {
  user?: AvDevUser;
  session?: AvDevSession;
  error?: string;
}

export const avdevAuth = {
  async signUp(email: string, password: string, displayName?: string): Promise<AuthResult> {
    const result = await authFetch("register", { email, password, displayName });
    if (result.error) return { error: result.error };
    // Set session in Supabase client if returned
    if (result.session?.access_token) {
      await supabase.auth.setSession({
        access_token: result.session.access_token,
        refresh_token: result.session.refresh_token,
      });
    }
    return { user: result.user, session: result.session };
  },

  async signIn(email: string, password: string): Promise<AuthResult> {
    const result = await authFetch("login", { email, password });
    if (result.error) return { error: result.error };
    // Set session in Supabase client
    if (result.session?.access_token) {
      await supabase.auth.setSession({
        access_token: result.session.access_token,
        refresh_token: result.session.refresh_token,
      });
    }
    return { user: result.user, session: result.session };
  },

  async signOut(): Promise<void> {
    try { await authFetch("logout"); } catch {}
    await supabase.auth.signOut();
  },

  async getUser(): Promise<AvDevUser | null> {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return null;
    try {
      const result = await authFetch("me");
      if (result.error || !result.user) return null;
      return result.user;
    } catch {
      // Fallback to local session
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;
      return {
        id: user.id,
        email: user.email || "",
        displayName: user.user_metadata?.display_name,
        avatarUrl: user.user_metadata?.avatar_url,
      };
    }
  },

  async updateProfile(updates: { displayName?: string; avatarUrl?: string }): Promise<AuthResult> {
    const result = await authFetch("update-profile", updates);
    if (result.error) return { error: result.error };
    const user = await avdevAuth.getUser();
    return { user: user || undefined };
  },

  async resetPassword(email: string): Promise<{ error?: string }> {
    const result = await authFetch("forgot-password", {
      email,
      redirectTo: window.location.origin,
    });
    if (result.error) return { error: result.error };
    return {};
  },

  async updatePassword(newPassword: string): Promise<{ error?: string }> {
    const result = await authFetch("update-password", { newPassword });
    if (result.error) return { error: result.error };
    return {};
  },

  onAuthStateChange(callback: (user: AvDevUser | null) => void) {
    return supabase.auth.onAuthStateChange(async (_event, session) => {
      if (session?.user) {
        // Fetch full user with roles from edge function
        try {
          const result = await authFetch("me");
          if (result.user) {
            callback(result.user);
            return;
          }
        } catch {}
        // Fallback
        callback({
          id: session.user.id,
          email: session.user.email || "",
          displayName: session.user.user_metadata?.display_name,
          avatarUrl: session.user.user_metadata?.avatar_url,
        });
      } else {
        callback(null);
      }
    });
  },

  // === Admin Methods ===
  async adminListUsers(page = 1, perPage = 50, search = ""): Promise<any> {
    return authFetch("admin/users", { page, perPage, search });
  },

  async adminBanUser(userId: string, ban: boolean): Promise<any> {
    return authFetch("admin/ban", { userId, ban });
  },

  async adminAssignRole(userId: string, role: string, assign: boolean): Promise<any> {
    return authFetch("admin/role", { userId, role, assign });
  },

  async adminDeleteUser(userId: string): Promise<any> {
    return authFetch("admin/delete-user", { userId });
  },

  // === Security Questions ===
  async setupSecurityQuestions(questions: Array<{ question: string; answer: string }>): Promise<any> {
    return authFetch("setup-security-questions", { questions });
  },

  async getSecurityQuestions(email: string): Promise<any> {
    return authFetch("get-security-questions", { email });
  },

  async verifySecurityAnswers(email: string, answers: string[], newPassword: string): Promise<any> {
    return authFetch("verify-security-answers", { email, answers, newPassword });
  },
};

export default avdevAuth;
