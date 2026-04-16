import { Toaster } from "@/components/ui/toaster";
import { SonnerToaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ThemeProvider } from "next-themes";
import { AvDevAuthProvider } from "@/contexts/AvDevAuthContext";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import Index from "./pages/Index";
import Auth from "./pages/Auth";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5 * 60 * 1000,
      refetchOnWindowFocus: false,
    },
  },
});

/**
 * Root application component.
 * 
 * The setup agent will add new routes, providers, and layouts here.
 * Keep the provider order: QueryClient > Theme > Auth > Tooltip > Router.
 * New routes go inside <Routes> — the catch-all "*" must stay last.
 */
const App = () => (
  <QueryClientProvider client={queryClient}>
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <AvDevAuthProvider>
        <TooltipProvider>
          <Toaster />
          <SonnerToaster />
          <ErrorBoundary>
            <BrowserRouter>
              <Routes>
                <Route path="/" element={<Index />} />
                <Route path="/auth" element={<Auth />} />
                {/* === NEW ROUTES GO HERE === */}
                              <Route path="/index" element={<Index />} />
              <Route path="*" element={<NotFound />} />
              </Routes>
            </BrowserRouter>
          </ErrorBoundary>
        </TooltipProvider>
      </AvDevAuthProvider>
    </ThemeProvider>
  </QueryClientProvider>
);

export default App;
