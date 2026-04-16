import { useState } from "react";
import { useAvDevAuth } from "@/hooks/useAvDevAuth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";

interface AvDevLoginFormProps {
  onSuccess?: () => void;
  defaultTab?: "login" | "register";
}

export function AvDevLoginForm({ onSuccess, defaultTab = "login" }: AvDevLoginFormProps) {
  const { login, register, resetPassword } = useAvDevAuth();
  const { toast } = useToast();
  const [tab, setTab] = useState<"login" | "register" | "reset">(defaultTab);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setIsLoading(true);

    try {
      if (tab === "login") {
        const result = await login(email, password);
        if (result.error) {
          toast({ title: "Login failed", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Welcome back!" });
          onSuccess?.();
        }
      } else if (tab === "register") {
        if (password.length < 6) {
          toast({ title: "Password too short", description: "Must be at least 6 characters", variant: "destructive" });
          return;
        }
        const result = await register(email, password, displayName || undefined);
        if (result.error) {
          toast({ title: "Registration failed", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Account created!", description: "Please check your email to verify your account." });
          onSuccess?.();
        }
      } else if (tab === "reset") {
        const result = await resetPassword(email);
        if (result.error) {
          toast({ title: "Failed", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Check your email", description: "A password reset link has been sent." });
          setTab("login");
        }
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full max-w-sm mx-auto">
      <div className="flex gap-1 mb-6">
        <Button
          type="button"
          variant={tab === "login" ? "default" : "ghost"}
          size="sm"
          onClick={() => setTab("login")}
          className="flex-1 text-xs"
        >
          Sign In
        </Button>
        <Button
          type="button"
          variant={tab === "register" ? "default" : "ghost"}
          size="sm"
          onClick={() => setTab("register")}
          className="flex-1 text-xs"
        >
          Sign Up
        </Button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {tab === "register" && (
          <div className="space-y-1.5">
            <Label htmlFor="displayName" className="text-xs">Display Name</Label>
            <Input
              id="displayName"
              type="text"
              placeholder="Your name"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              className="h-9 text-sm"
              maxLength={100}
            />
          </div>
        )}
        <div className="space-y-1.5">
          <Label htmlFor="email" className="text-xs">Email</Label>
          <Input
            id="email"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="h-9 text-sm"
            maxLength={255}
          />
        </div>
        {tab !== "reset" && (
          <div className="space-y-1.5">
            <Label htmlFor="password" className="text-xs">Password</Label>
            <Input
              id="password"
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="h-9 text-sm"
              minLength={6}
              maxLength={128}
            />
          </div>
        )}
        <Button type="submit" className="w-full h-9 text-sm" disabled={isLoading}>
          {isLoading ? "Loading..." : tab === "login" ? "Sign In" : tab === "register" ? "Create Account" : "Send Reset Link"}
        </Button>
      </form>

      <div className="mt-4 text-center">
        {tab === "login" && (
          <button
            type="button"
            onClick={() => setTab("reset")}
            className="text-xs text-muted-foreground hover:text-foreground transition-colors"
          >
            Forgot password?
          </button>
        )}
        {tab === "reset" && (
          <button
            type="button"
            onClick={() => setTab("login")}
            className="text-xs text-muted-foreground hover:text-foreground transition-colors"
          >
            Back to sign in
          </button>
        )}
      </div>
    </div>
  );
}
