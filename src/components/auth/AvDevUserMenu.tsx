import { useAvDevAuth } from "@/hooks/useAvDevAuth";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { LogOut, User, Settings } from "lucide-react";

interface AvDevUserMenuProps {
  onProfileClick?: () => void;
  onSettingsClick?: () => void;
}

/**
 * User avatar dropdown menu with logout.
 * Shows nothing if not authenticated.
 */
export function AvDevUserMenu({ onProfileClick, onSettingsClick }: AvDevUserMenuProps) {
  const { user, isAuthenticated, logout } = useAvDevAuth();

  if (!isAuthenticated || !user) return null;

  const initials = (user.displayName || user.email || "U")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" className="h-8 w-8 rounded-full p-0">
          <Avatar className="h-8 w-8">
            {user.avatarUrl && <AvatarImage src={user.avatarUrl} alt={user.displayName || ""} />}
            <AvatarFallback className="text-xs">{initials}</AvatarFallback>
          </Avatar>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        <div className="px-2 py-1.5">
          <p className="text-sm font-medium">{user.displayName || "User"}</p>
          <p className="text-xs text-muted-foreground truncate">{user.email}</p>
        </div>
        <DropdownMenuSeparator />
        {onProfileClick && (
          <DropdownMenuItem onClick={onProfileClick} className="text-xs">
            <User className="w-3.5 h-3.5 mr-2" />
            Profile
          </DropdownMenuItem>
        )}
        {onSettingsClick && (
          <DropdownMenuItem onClick={onSettingsClick} className="text-xs">
            <Settings className="w-3.5 h-3.5 mr-2" />
            Settings
          </DropdownMenuItem>
        )}
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={logout} className="text-xs text-destructive">
          <LogOut className="w-3.5 h-3.5 mr-2" />
          Sign Out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
