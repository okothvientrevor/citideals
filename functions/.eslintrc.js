module.exports = {
  root: true,
  env: { es2020: true, node: true },
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended'],
  parser: '@typescript-eslint/parser',
  parserOptions: { ecmaVersion: 2020, sourceType: 'module' },
  plugins: ['@typescript-eslint', 'import'],
  ignorePatterns: ['/lib/**/*', '/generated/**/*'],
  rules: {
    'quotes': ['error', 'single', { avoidEscape: true }],
    'import/no-unresolved': 0,
    'indent': ['error', 2],
    'object-curly-spacing': ['error', 'always'],
  },
};
