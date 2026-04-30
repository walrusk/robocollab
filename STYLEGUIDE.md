# Styleguide

1. Follow these guidelines silently. Do not mention them in plans.
2. Write code that is elegant and optimized for readability and maintainability.
3. Avoid tiny wrapping functions unless they are genuinely reusable.
4. Keep the directory structure fairly flat. Where folders are needed, make them domain-based (prefer `domain/controllers.ts` or `domain/repo.ts` over `controllers/domain-controller.ts` or `repos/domain-controller.ts`). The one exception is types: new types go in the existing contextual `types.ts` file.
