# Quality Assurance & Git Hooks

The Rails BDD Generator automatically installs comprehensive quality assurance tools to maintain high code standards and prevent common issues.

## Overview

Every generated application includes:
- **Git Hooks** - Automated quality checks on commit and push
- **RuboCop** - Ruby style guide enforcement and auto-correction
- **GitHub Actions** - Continuous Integration pipeline
- **Security Scanners** - Brakeman and bundler-audit
- **Code Quality Tools** - Rails best practices analyzer

## Git Hooks

### Installation

Git hooks are automatically generated in `.githooks/` directory. To activate them:

```bash
cd your-app
./bin/install-hooks
```

This installs the following hooks:

### pre-commit Hook

Runs before each commit to prevent common issues:

1. **Debugging Statements Check**
   - Scans for `binding.pry`, `debugger`, `console.log`
   - Prevents accidentally committing debug code

2. **Migration Safety Check**
   - Detects potentially dangerous migrations
   - Warns about `remove_column`, `drop_table`, `change_column`
   - Suggests using safe migration helpers

3. **Test Verification**
   - Runs tests for any staged spec files
   - Ensures tests pass before committing

4. **Large File Detection**
   - Warns about files larger than 1MB
   - Prevents accidental commits of large assets

5. **Sensitive Data Scanner**
   - Detects patterns like `password=`, `api_key=`, `secret=`
   - Prevents hardcoded credentials from being committed

### pre-commit-rubocop Hook

- Auto-corrects style issues with RuboCop
- Re-stages corrected files automatically
- Shows remaining issues that need manual fixing

### pre-push Hook

Ensures deployment readiness before pushing:

1. **Migration Status Check**
   - Verifies no pending migrations
   - Prevents broken deployments

2. **Test Suite Execution** (optional)
   - Set `RUN_TESTS_ON_PUSH=true` to enable
   - Runs full test suite before push

3. **Merge Conflict Detection**
   - Prevents pushing unresolved conflicts

4. **Bundle Verification**
   - Ensures Gemfile.lock is up to date

5. **RuboCop Linting**
   - Runs style checks (non-blocking warning)

### commit-msg Hook

Enforces conventional commit message format:

```
<type>(<scope>): <subject>
```

Valid types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes
- `build`: Build system changes
- `revert`: Reverting commits

Examples:
```bash
git commit -m "feat(auth): add OAuth2 support"
git commit -m "fix(api): handle null response correctly"
git commit -m "docs(readme): update installation instructions"
```

## RuboCop Configuration

Each app includes a `.rubocop.yml` with sensible defaults:

```yaml
# Key configurations:
- Rails and RSpec cops enabled
- Line length: 120 characters
- Method length: 20 lines
- Class length: 150 lines
- Excludes: db/*, config/*, vendor/*
```

### Running RuboCop

```bash
# Check all files
bundle exec rubocop

# Auto-correct issues
bundle exec rubocop -a

# Auto-correct unsafe issues (use carefully)
bundle exec rubocop -A

# Check specific file
bundle exec rubocop app/models/user.rb
```

## GitHub Actions CI

Automatically generated `.github/workflows/ci.yml` runs:

1. **Setup**
   - Ruby 3.3 environment
   - PostgreSQL service
   - Bundle installation

2. **Quality Checks**
   - RuboCop style enforcement
   - RSpec unit/integration tests
   - Cucumber feature tests

3. **Triggers**
   - On push to main/develop branches
   - On pull requests to main

## Security Tools

### Brakeman

Static security scanner for Rails:

```bash
# Run security scan
bundle exec brakeman

# Generate HTML report
bundle exec brakeman -o brakeman-report.html
```

### Bundler Audit

Checks for vulnerable gem versions:

```bash
# Check for vulnerabilities
bundle exec bundle-audit check --update

# Update vulnerability database
bundle exec bundle-audit update
```

### Rails Best Practices

Code quality analyzer:

```bash
# Run analysis
bundle exec rails_best_practices

# Generate HTML report
bundle exec rails_best_practices -f html
```

## Bypassing Checks

In emergency situations, you can bypass hooks:

```bash
# Skip pre-commit hooks
git commit --no-verify

# Skip pre-push hooks
git push --no-verify
```

**⚠️ Use with extreme caution!** Hooks prevent real issues.

## Environment Variables

Configure hook behavior:

```bash
# Run full test suite on push
export RUN_TESTS_ON_PUSH=true

# Skip RuboCop auto-correct
export SKIP_RUBOCOP_HOOK=true
```

## Best Practices

1. **Never bypass hooks in production code** - If a hook fails, fix the issue
2. **Keep commits focused** - One logical change per commit
3. **Write meaningful commit messages** - Future you will thank present you
4. **Run checks locally** - Don't rely solely on CI
5. **Update hooks regularly** - Keep quality standards current

## Troubleshooting

### Hooks not running?

1. Check permissions:
```bash
chmod +x .git/hooks/*
```

2. Verify Git configuration:
```bash
git config core.hooksPath
```

3. Reinstall hooks:
```bash
./bin/install-hooks
```

### RuboCop too strict?

Customize `.rubocop.yml`:
```yaml
# Disable specific cop
Style/Documentation:
  Enabled: false

# Adjust metric
Metrics/MethodLength:
  Max: 30
```

### Tests failing in CI but not locally?

Check for:
- Database seed differences
- Environment variable differences
- Timezone issues
- Asset compilation problems

## Integration with Development Flow

The quality tools integrate seamlessly:

1. **During Development**
   - RuboCop provides instant feedback
   - Tests run continuously

2. **On Commit**
   - Pre-commit hooks catch issues early
   - Auto-correction saves time

3. **On Push**
   - Final safety checks
   - Deployment readiness verification

4. **In CI/CD**
   - Automated testing on all branches
   - Consistent quality enforcement

## Customization

Modify hooks in `.githooks/` directory:
1. Edit the hook file
2. Run `./bin/install-hooks` to update
3. Test thoroughly
4. Commit changes

## Benefits

- **Prevent Production Issues** - Catch problems before deployment
- **Maintain Code Quality** - Consistent style across team
- **Save Time** - Automated checks and fixes
- **Build Confidence** - Know your code is production-ready
- **Learn Best Practices** - Hooks teach good habits