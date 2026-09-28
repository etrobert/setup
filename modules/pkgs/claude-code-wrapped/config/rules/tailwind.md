---
paths:
  - "**/*.{tsx,jsx,html,css,vue,svelte}"
---

# Tailwind

In Tailwind, prefer the predefined scale (`text-lg`, `rounded-md`, `p-2.5`) over
arbitrary values (`text-[1.1rem]`, `rounded-[0.4rem]`), snapping to the nearest
step rather than preserving an exact number. Reserve `[…]` for values with no
scale equivalent — custom properties (`rotate-[var(--rot)]`), grid templates,
property lists.
