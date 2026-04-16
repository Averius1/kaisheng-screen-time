# AvDev Application

This project was generated with [AvDev](https://avdev.space) — the AI-powered development platform.

## Quick Start

```bash
npm install    # Install dependencies
npm run dev    # Start dev server at localhost:8080
npm run build  # Production build
npm run test   # Run tests
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | React 18 + TypeScript |
| Build | Vite |
| Styling | Tailwind CSS + shadcn/ui |
| Animation | Framer Motion |
| Routing | React Router v6 |
| Data | React Query |
| Forms | React Hook Form + Zod |
| Auth | AvDev Auth |
| Backend | AvDev Cloud |

## Project Structure

```
src/
├── components/       # Reusable components
│   ├── ui/           # shadcn/ui primitives
│   └── auth/         # Auth components
├── contexts/         # React contexts
├── hooks/            # Custom hooks
├── lib/              # Utils, auth client, animations
├── pages/            # Route pages
└── test/             # Tests
```

## Adding Pages

1. Create file in src/pages/
2. Add Route in src/App.tsx above the catch-all
3. Use AvDevProtectedRoute for auth-required pages

## License

MIT
