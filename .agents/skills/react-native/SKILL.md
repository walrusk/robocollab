---
name: react-native
description: >
  Use when editing React Native components. Also use react-native-ui-lib when
  writing or editing View or Text components.
---

# React Native

- For React Native components, use `type Props = {}` for props rather than giving the type a component-specific name.
- When writing or editing `View` or `Text` components, use the `react-native-ui-lib` skill.
- For small component-specific helper functions, use an existing same-directory `helpers.ts` or `utility.ts` file. Check those files before adding a new helper, and reuse an existing function when it fits.
- When making a new component always make a new file.
