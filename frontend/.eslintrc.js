module.exports = {
  extends: [
    'react-app',
    'react-app/jest'
  ],
  settings: {
    cache: false
  },
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true
    }
  },
  env: {
    browser: true,
    es6: true,
    node: true
  }
};