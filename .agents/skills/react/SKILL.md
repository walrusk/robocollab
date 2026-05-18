---
name: react
description: >
  Use when editing React components.
---

# React

- For React components, use `type Props = {}` for props rather than giving the type a component-specific name.
- For small component-specific helper functions, use an existing same-directory `helpers.ts` or `utility.ts` file. Check those files before adding a new helper, and reuse an existing function when it fits.
- When making a new component always make a new file.
