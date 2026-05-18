---
name: react-native
description: >
  Use when editing React Native components. Also use react-native-ui-lib when
  writing or editing View or Text components.
---

# React Native

- For React Native components, use `type Props = {}` for props rather than giving the type a component-specific name.
- When writing or editing `View` or `Text` components, use the `react-native-ui-lib` skill.
- For small component-specific helper functions in normal component folders, use an existing same-directory `helpers.ts` or `utility.ts` file. Check those files before adding a new helper, and reuse an existing function when it fits.
- Do not create `helpers.ts` or `utility.ts` files in file-based route directories such as `app/` or `src/app/`; they may be picked up as routes. In route directories, keep small helpers inside the route file or move the component/helper code to a non-route component or domain folder and colocate the helper there.
- When making a new component always make a new file.
