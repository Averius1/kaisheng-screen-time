/**
 * Universal Framer Motion Animation Variants & Presets
 * 
 * Pre-built animation variants for consistent, production-grade animations.
 * Import and use with framer-motion's <motion.div variants={...} />
 * 
 * Respects prefers-reduced-motion automatically via framer-motion.
 */
import type { Variants, Transition } from "framer-motion";

// ============================================================================
// TIMING PRESETS
// ============================================================================

export const TIMING = {
  fast: 0.15,
  medium: 0.25,
  slow: 0.4,
  xslow: 0.6,
} as const;

export const EASING = {
  smooth: [0.4, 0, 0.2, 1] as [number, number, number, number],
  spring: { type: "spring", stiffness: 300, damping: 24 } as const,
  springBouncy: { type: "spring", stiffness: 400, damping: 17 } as const,
  springGentle: { type: "spring", stiffness: 200, damping: 20 } as const,
  decel: [0, 0, 0.2, 1] as [number, number, number, number],
  accel: [0.4, 0, 1, 1] as [number, number, number, number],
};

// ============================================================================
// 1. FADE VARIANTS
// ============================================================================

export const fadeIn: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: TIMING.medium, ease: EASING.smooth } },
  exit: { opacity: 0, transition: { duration: TIMING.fast } },
};

export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: TIMING.medium, ease: EASING.smooth } },
  exit: { opacity: 0, y: -10, transition: { duration: TIMING.fast } },
};

export const fadeInDown: Variants = {
  hidden: { opacity: 0, y: -20 },
  visible: { opacity: 1, y: 0, transition: { duration: TIMING.medium, ease: EASING.smooth } },
  exit: { opacity: 0, y: 10, transition: { duration: TIMING.fast } },
};

export const fadeInLeft: Variants = {
  hidden: { opacity: 0, x: -20 },
  visible: { opacity: 1, x: 0, transition: { duration: TIMING.medium, ease: EASING.smooth } },
  exit: { opacity: 0, x: 20, transition: { duration: TIMING.fast } },
};

export const fadeInRight: Variants = {
  hidden: { opacity: 0, x: 20 },
  visible: { opacity: 1, x: 0, transition: { duration: TIMING.medium, ease: EASING.smooth } },
  exit: { opacity: 0, x: -20, transition: { duration: TIMING.fast } },
};

// ============================================================================
// 2. SCALE VARIANTS
// ============================================================================

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: { opacity: 1, scale: 1, transition: { duration: TIMING.medium, ease: EASING.smooth } },
  exit: { opacity: 0, scale: 0.95, transition: { duration: TIMING.fast } },
};

export const scalePop: Variants = {
  hidden: { opacity: 0, scale: 0.5 },
  visible: { opacity: 1, scale: 1, transition: EASING.springBouncy },
  exit: { opacity: 0, scale: 0.8, transition: { duration: TIMING.fast } },
};

// ============================================================================
// 3. SLIDE VARIANTS
// ============================================================================

export const slideInRight: Variants = {
  hidden: { x: "100%" },
  visible: { x: 0, transition: { duration: TIMING.slow, ease: EASING.smooth } },
  exit: { x: "100%", transition: { duration: TIMING.medium } },
};

export const slideInLeft: Variants = {
  hidden: { x: "-100%" },
  visible: { x: 0, transition: { duration: TIMING.slow, ease: EASING.smooth } },
  exit: { x: "-100%", transition: { duration: TIMING.medium } },
};

export const slideInUp: Variants = {
  hidden: { y: "100%" },
  visible: { y: 0, transition: { duration: TIMING.slow, ease: EASING.smooth } },
  exit: { y: "100%", transition: { duration: TIMING.medium } },
};

export const slideInDown: Variants = {
  hidden: { y: "-100%" },
  visible: { y: 0, transition: { duration: TIMING.slow, ease: EASING.smooth } },
  exit: { y: "-100%", transition: { duration: TIMING.medium } },
};

// ============================================================================
// 4. STAGGER CONTAINER
// ============================================================================

export const staggerContainer: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.06, delayChildren: 0.1 },
  },
};

export const staggerContainerSlow: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.12, delayChildren: 0.2 },
  },
};

export const staggerItem: Variants = {
  hidden: { opacity: 0, y: 16 },
  visible: { opacity: 1, y: 0, transition: { duration: TIMING.medium, ease: EASING.smooth } },
};

// ============================================================================
// 5. MODAL / OVERLAY VARIANTS
// ============================================================================

export const overlayVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: TIMING.medium } },
  exit: { opacity: 0, transition: { duration: TIMING.fast } },
};

export const modalVariants: Variants = {
  hidden: { opacity: 0, scale: 0.92, y: 10 },
  visible: { opacity: 1, scale: 1, y: 0, transition: EASING.spring },
  exit: { opacity: 0, scale: 0.95, y: 10, transition: { duration: TIMING.fast } },
};

export const drawerVariants: Variants = {
  hidden: { y: "100%" },
  visible: { y: 0, transition: EASING.springGentle },
  exit: { y: "100%", transition: { duration: TIMING.medium, ease: EASING.smooth } },
};

// ============================================================================
// 6. CARD & INTERACTIVE VARIANTS
// ============================================================================

export const cardLift = {
  rest: { y: 0, boxShadow: "0 1px 3px rgba(0,0,0,0.08)" },
  hover: { y: -4, boxShadow: "0 8px 24px rgba(0,0,0,0.12)", transition: { duration: TIMING.medium, ease: EASING.smooth } },
  tap: { y: -2, scale: 0.99 },
};

export const buttonPress = {
  rest: { scale: 1 },
  hover: { scale: 1.02, transition: { duration: TIMING.fast } },
  tap: { scale: 0.97 },
};

export const iconSpin = {
  rest: { rotate: 0 },
  hover: { rotate: 30, transition: { duration: TIMING.medium } },
  loading: { rotate: 360, transition: { duration: 1, repeat: Infinity, ease: "linear" } },
};

// ============================================================================
// 7. NOTIFICATION & FEEDBACK VARIANTS
// ============================================================================

export const shake: Variants = {
  idle: { x: 0 },
  shake: {
    x: [-4, 4, -4, 4, -2, 2, 0],
    transition: { duration: 0.5 },
  },
};

export const bellShake: Variants = {
  idle: { rotate: 0 },
  ring: {
    rotate: [0, 15, -15, 15, -15, 8, -8, 0],
    transition: { duration: 0.6 },
  },
};

export const heartBeat: Variants = {
  idle: { scale: 1 },
  beat: {
    scale: [1, 1.25, 1],
    transition: { duration: 0.4, ease: EASING.smooth },
  },
};

export const checkmarkDraw = {
  hidden: { pathLength: 0, opacity: 0 },
  visible: {
    pathLength: 1,
    opacity: 1,
    transition: { duration: 0.5, ease: EASING.decel },
  },
};

// ============================================================================
// 8. PAGE TRANSITION VARIANTS
// ============================================================================

export const pageTransition: Variants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { duration: TIMING.slow, ease: EASING.smooth } },
  exit: { opacity: 0, y: -8, transition: { duration: TIMING.fast } },
};

export const pageSlide: Variants = {
  initial: { opacity: 0, x: 20 },
  animate: { opacity: 1, x: 0, transition: { duration: TIMING.slow, ease: EASING.smooth } },
  exit: { opacity: 0, x: -20, transition: { duration: TIMING.fast } },
};

// ============================================================================
// 9. DROPDOWN / POPOVER VARIANTS
// ============================================================================

export const dropdownVariants: Variants = {
  hidden: { opacity: 0, y: -8, scale: 0.96 },
  visible: { opacity: 1, y: 0, scale: 1, transition: { duration: TIMING.fast, ease: EASING.smooth } },
  exit: { opacity: 0, y: -4, scale: 0.98, transition: { duration: 0.1 } },
};

// ============================================================================
// 10. TAB / ACCORDION VARIANTS
// ============================================================================

export const accordionContent: Variants = {
  collapsed: { height: 0, opacity: 0, overflow: "hidden" },
  expanded: {
    height: "auto",
    opacity: 1,
    overflow: "hidden",
    transition: { height: { duration: TIMING.medium }, opacity: { duration: TIMING.fast, delay: 0.05 } },
  },
};

export const tabIndicator = {
  layout: true,
  transition: EASING.spring as Transition,
};

// ============================================================================
// 11. FLOATING / AMBIENT
// ============================================================================

export const floatAnimation = {
  y: [0, -8, 0],
  transition: { duration: 3, repeat: Infinity, ease: "easeInOut" },
};

export const pulseGlow = {
  boxShadow: [
    "0 0 8px hsl(var(--primary) / 0.2)",
    "0 0 20px hsl(var(--primary) / 0.4)",
    "0 0 8px hsl(var(--primary) / 0.2)",
  ],
  transition: { duration: 2, repeat: Infinity, ease: "easeInOut" },
};

// ============================================================================
// PRESET BUNDLES — quick-start presets for common patterns
// ============================================================================

/** Standard page wrapper animation */
export const PAGE_PRESETS = { initial: "initial", animate: "animate", exit: "exit", variants: pageTransition };

/** Staggered list with items */
export const LIST_PRESETS = {
  container: { initial: "hidden", animate: "visible", variants: staggerContainer },
  item: { variants: staggerItem },
};

/** Modal with backdrop */
export const MODAL_PRESETS = {
  overlay: { initial: "hidden", animate: "visible", exit: "exit", variants: overlayVariants },
  content: { initial: "hidden", animate: "visible", exit: "exit", variants: modalVariants },
};

/** Card with hover lift */
export const CARD_PRESETS = { initial: "rest", whileHover: "hover", whileTap: "tap", variants: cardLift };
