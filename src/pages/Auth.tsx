import { useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AvDevLoginForm } from "@/components/auth/AvDevLoginForm";
import { useAvDevAuth } from "@/hooks/useAvDevAuth";

const Auth = () => {
  const navigate = useNavigate();
  const { isAuthenticated, isLoading } = useAvDevAuth();

  useEffect(() => {
    if (!isLoading && isAuthenticated) {
      navigate("/");
    }
  }, [isAuthenticated, isLoading, navigate]);

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="w-full max-w-md space-y-6"
      >
        <div className="flex items-center justify-between">
          <Button asChild variant="ghost" size="sm">
            <Link to="/" className="gap-2">
              <ArrowLeft className="w-4 h-4" />
              Back to Home
            </Link>
          </Button>
        </div>

        <AvDevLoginForm onSuccess={() => navigate("/")} />

        <p className="text-center text-sm text-muted-foreground">
          Your data is saved securely in the cloud.
        </p>
      </motion.div>
    </div>
  );
};

export default Auth;
