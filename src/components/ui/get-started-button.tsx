import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface GetStartedButtonProps {
  label?: string;
  to?: string;
  size?: "default" | "sm" | "lg";
  variant?: "default" | "outline" | "secondary";
  className?: string;
  showArrow?: boolean;
}

const GetStartedButton = ({
  label = "Get Started",
  to = "/auth",
  size = "lg",
  variant = "default",
  className,
  showArrow = true,
}: GetStartedButtonProps) => {
  const navigate = useNavigate();

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.3 }}
      className="flex justify-center"
    >
      <Button
        size={size}
        variant={variant}
        className={cn("group gap-2 min-h-[44px] px-8", className)}
        onClick={() => navigate(to)}
      >
        {label}
        {showArrow && (
          <ArrowRight className="w-4 h-4 transition-transform duration-200 group-hover:translate-x-1" />
        )}
      </Button>
    </motion.div>
  );
};

export { GetStartedButton };
export type { GetStartedButtonProps };
