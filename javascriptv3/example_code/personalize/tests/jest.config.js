module.exports = {
  testEnvironment: 'node',
  moduleDirectories: ["node_modules"],
  testMatch: ["**/tests/*.spec.js"],
  transform: {
    "^.+\\.(js|jsx)$": "babel-jest"
  }
};
