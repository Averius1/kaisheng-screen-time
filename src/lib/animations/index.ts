/**
 * Universal Animation Library - Barrel Export
 * 
 * Import everything from "@/lib/animations":
 * 
 * import { fadeInUp, staggerContainer, useScrollReveal, CARD_PRESETS } from "@/lib/animations";
 * import "@/lib/animations/animations.css";
 */

// Framer Motion variants & presets
export {
  // Timing
  TIMING,
  EASING,
  // Fade
  fadeIn,
  fadeInUp,
  fadeInDown,
  fadeInLeft,
  fadeInRight,
  // Scale
  scaleIn,
  scalePop,
  // Slide
  slideInRight,
  slideInLeft,
  slideInUp,
  slideInDown,
  // Stagger
  staggerContainer,
  staggerContainerSlow,
  staggerItem,
  // Modal / Overlay
  overlayVariants,
  modalVariants,
  drawerVariants,
  // Card / Interactive
  cardLift,
  buttonPress,
  iconSpin,
  // Feedback
  shake,
  bellShake,
  heartBeat,
  checkmarkDraw,
  // Page transitions
  pageTransition,
  pageSlide,
  // Dropdown
  dropdownVariants,
  // Accordion / Tab
  accordionContent,
  tabIndicator,
  // Ambient
  floatAnimation,
  pulseGlow,
  // Preset bundles
  PAGE_PRESETS,
  LIST_PRESETS,
  MODAL_PRESETS,
  CARD_PRESETS,
} from "./animation-variants";

// React hooks
export {
  useScrollReveal,
  useRipple,
  useStaggerDelay,
  usePrefersReducedMotion,
  useShake,
  useCountUp,
  useTypewriter,
  useParallax,
} from "./use-animation";

// CSS — import separately: import "@/lib/animations/animations.css";
