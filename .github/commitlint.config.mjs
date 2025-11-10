module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Code style (formatting, etc.)
        'refactor', // Code refactoring
        'perf',     // Performance improvement
        'test',     // Adding tests
        'chore',    // Maintenance
        'ci',       // CI/CD changes
        'build',    // Build system changes
        'revert'    // Revert previous commit
      ]
    ],
    'subject-case': [0], // Don't enforce case
    'body-max-line-length': [0], // Don't enforce body line length
  }
};
