import { Link, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";

interface NavLinkProps {
  to: string;
  children: React.ReactNode;
  className?: string;
  activeClassName?: string;
  exact?: boolean;
}

export function NavLink({ to, children, className, activeClassName = "text-primary font-medium", exact = true }: NavLinkProps) {
  const location = useLocation();
  const isActive = exact ? location.pathname === to : location.pathname.startsWith(to);

  return (
    <Link
      to={to}
      className={cn(
        "text-sm transition-colors duration-200 hover:text-foreground",
        isActive ? activeClassName : "text-muted-foreground",
        className
      )}
    >
      {children}
    </Link>
  );
}
