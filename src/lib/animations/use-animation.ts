/**
 * Universal Animation React Hooks
 * 
 * Reusable hooks for common animation patterns:
 * - Scroll-triggered animations (Intersection Observer)
 * - Ripple effects
 * - Staggered children
 * - Reduced motion detection
 * - Element shake
 * - Count-up numbers
 */
import { useRef, useState, useEffect, useCallback, useMemo } from "react";
import { useReducedMotion, useInView, useAnimation, type AnimationControls } from "framer-motion";

// ============================================================================
// 1. useScrollReveal — trigger animation when element enters viewport
// ============================================================================

export interface ScrollRevealOptions {
  /** Trigger threshold (0-1). Default: 0.15 */
  threshold?: number;
  /** Only trigger once. Default: true */
  once?: boolean;
  /** Root margin. Default: "0px" */
  rootMargin?: string;
}

export function useScrollReveal(options: ScrollRevealOptions = {}) {
  const { threshold = 0.15, once = true, rootMargin = "0px" } = options;
  const ref = useRef<HTMLDivElement>(null);
  const isInView = useInView(ref, { once, amount: threshold, margin: rootMargin as any });
  const controls = useAnimation();

  useEffect(() => {
    if (isInView) {
      controls.start("visible");
    } else if (!once) {
      controls.start("hidden");
    }
  }, [isInView, controls, once]);

  return { ref, controls, isInView };
}

// ============================================================================
// 2. useRipple — material-style ripple effect on click
// ============================================================================

export interface RippleEvent {
  x: number;
  y: number;
  size: number;
  id: number;
}

export function useRipple() {
  const [ripples, setRipples] = useState<RippleEvent[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);

  const createRipple = useCallback((e: React.MouseEvent) => {
    const el = containerRef.current;
    if (!el) return;

    const rect = el.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height) * 2;
    const x = e.clientX - rect.left - size / 2;
    const y = e.clientY - rect.top - size / 2;
    const id = Date.now();

    setRipples((prev) => [...prev, { x, y, size, id }]);
    setTimeout(() => {
      setRipples((prev) => prev.filter((r) => r.id !== id));
    }, 600);
  }, []);

  return { containerRef, ripples, createRipple };
}

// ============================================================================
// 3. useStaggerDelay — compute stagger delays for list items
// ============================================================================

export function useStaggerDelay(index: number, baseDelay = 0.05) {
  return useMemo(() => ({
    transition: { delay: index * baseDelay },
  }), [index, baseDelay]);
}

// ============================================================================
// 4. usePrefersReducedMotion — detect reduced motion preference
// ============================================================================

export function usePrefersReducedMotion(): boolean {
  return useReducedMotion() ?? false;
}

// ============================================================================
// 5. useShake — trigger a shake animation imperatively
// ============================================================================

export function useShake(): { controls: AnimationControls; triggerShake: () => void } {
  const controls = useAnimation();
  
  const triggerShake = useCallback(() => {
    controls.start({
      x: [-4, 4, -4, 4, -2, 2, 0],
      transition: { duration: 0.5 },
    });
  }, [controls]);

  return { controls, triggerShake };
}

// ============================================================================
// 6. useCountUp — animate a number from 0 to target
// ============================================================================

export function useCountUp(target: number, duration = 1000, startOnView = true) {
  const [count, setCount] = useState(0);
  const [hasStarted, setHasStarted] = useState(!startOnView);
  const ref = useRef<HTMLDivElement>(null);

  const start = useCallback(() => setHasStarted(true), []);

  useEffect(() => {
    if (!hasStarted) return;
    
    let startTime: number | null = null;
    let raf: number;

    const step = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      // Ease out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      setCount(Math.round(eased * target));
      if (progress < 1) {
        raf = requestAnimationFrame(step);
      }
    };

    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [hasStarted, target, duration]);

  // Intersection observer for startOnView
  useEffect(() => {
    if (!startOnView || !ref.current) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setHasStarted(true);
          observer.disconnect();
        }
      },
      { threshold: 0.5 }
    );

    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [startOnView]);

  return { count, ref, start };
}

// ============================================================================
// 7. useTypewriter — type text character by character
// ============================================================================

export function useTypewriter(text: string, speed = 40, startDelay = 0) {
  const [displayed, setDisplayed] = useState("");
  const [isDone, setIsDone] = useState(false);

  useEffect(() => {
    setDisplayed("");
    setIsDone(false);

    const timeout = setTimeout(() => {
      let i = 0;
      const interval = setInterval(() => {
        if (i < text.length) {
          setDisplayed(text.slice(0, i + 1));
          i++;
        } else {
          setIsDone(true);
          clearInterval(interval);
        }
      }, speed);
      return () => clearInterval(interval);
    }, startDelay);

    return () => clearTimeout(timeout);
  }, [text, speed, startDelay]);

  return { displayed, isDone };
}

// ============================================================================
// 8. useParallax — simple scroll-based parallax factor
// ============================================================================

export function useParallax(speed = 0.5) {
  const [offset, setOffset] = useState(0);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleScroll = () => {
      if (!ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      const scrolled = window.innerHeight - rect.top;
      setOffset(scrolled * speed);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [speed]);

  return { ref, offset, style: { transform: "translateY(" + offset + "px)" } };
}
