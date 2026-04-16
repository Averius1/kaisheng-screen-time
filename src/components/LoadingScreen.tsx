import { motion } from "framer-motion";
import { Loader2 } from "lucide-react";

interface LoadingScreenProps {
  message?: string;
  fullScreen?: boolean;
}

/**
 * Reusable loading state component.
 * Use for route transitions, data fetching, or initial app load.
 */
export function LoadingScreen({ message = "Loading...", fullScreen = true }: LoadingScreenProps) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className={`flex flex-col items-center justify-center gap-3 ${fullScreen ? "min-h-screen" : "min-h-[200px]"}`}
    >
      <Loader2 className="w-6 h-6 animate-spin text-primary" />
      <p className="text-sm text-muted-foreground">{message}</p>
    </motion.div>
  );
}
