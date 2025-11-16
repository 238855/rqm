module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Formatting, missing semi colons, etc
        'refactor', // Code change that neither fixes a bug nor adds a feature
        'perf',     // Performance improvement
        'test',     // Adding missing tests
        'chore',    // Maintain
        'revert',   // Revert to a commit
        'wip',      // Work in progress
        'build',    // Build system or external dependencies
        'ci',       // CI configuration files and scripts
      ],
    ],
    'scope-enum': [
      2,
      'always',
      [
        'rust-core',
        'go-cli',
        'ts-cli',
        'web-ui',
        'docs',
        'ci',
        'deps',
        'examples',
        'schema',
        'rdd',
      ],
    ],
    'subject-case': [2, 'never', ['upper-case']],
  },
};
