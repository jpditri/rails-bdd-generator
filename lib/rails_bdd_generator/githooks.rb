module RailsBddGenerator
  class Githooks
    def self.install!(output_path)
      puts "\n🔧 Installing Git hooks for quality assurance..."

      # Create .githooks directory
      githooks_dir = output_path.join('.githooks')
      FileUtils.mkdir_p(githooks_dir)

      # Generate each hook
      generate_pre_commit(githooks_dir)
      generate_pre_push(githooks_dir)
      generate_commit_msg(githooks_dir)
      generate_pre_commit_rubocop(githooks_dir)

      # Create installation script
      generate_install_script(output_path)

      # Create git hook configuration
      configure_git_hooks(output_path)

      puts "  ✓ Git hooks installed in .githooks/"
      puts "  ✓ Run './bin/install-hooks' to activate hooks"
    end

    private

    def self.generate_pre_commit(githooks_dir)
      content = <<~BASH
        #!/bin/bash
        # Pre-commit hook for Rails BDD Generator applications
        # Ensures code quality before commits

        set -e

        echo "🔍 Running pre-commit checks..."

        # 1. Check for debugging statements
        echo "Checking for debugging statements..."
        debugging_statements=$(git diff --cached --name-only --diff-filter=ACM | xargs -I {} grep -l 'binding\\.pry\\|debugger\\|console\\.log\\|puts.*DEBUG' {} 2>/dev/null || true)

        if [ -n "$debugging_statements" ]; then
          echo "❌ Debugging statements found in:"
          echo "$debugging_statements"
          echo "Please remove debugging statements before committing."
          exit 1
        fi

        # 2. Check for migration safety
        echo "Checking migration safety..."
        migration_files=$(git diff --cached --name-only | grep "db/migrate/.*\\.rb$" || true)

        if [ -n "$migration_files" ]; then
          echo "📝 Migration files detected:"
          echo "$migration_files"

          for file in $migration_files; do
            # Check for unsafe operations
            if grep -q "remove_column\\|drop_table\\|change_column" "$file"; then
              echo "⚠️  WARNING: Potentially unsafe migration operations detected in $file"
              echo "   Consider using safe migration helpers or adding safety comments"
              read -p "   Continue anyway? (y/N) " -n 1 -r
              echo
              if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
              fi
            fi
          done
        fi

        # 3. Check for broken tests (if any are staged)
        spec_files=$(git diff --cached --name-only | grep "_spec\\.rb$" || true)
        if [ -n "$spec_files" ]; then
          echo "Running tests for staged spec files..."
          for file in $spec_files; do
            if [ -f "$file" ]; then
              if ! bundle exec rspec "$file" --format progress > /dev/null 2>&1; then
                echo "❌ Tests failing in $file"
                echo "Fix the tests before committing."
                exit 1
              fi
            fi
          done
          echo "✅ Staged tests passing"
        fi

        # 4. Check for large files
        echo "Checking file sizes..."
        large_files=$(git diff --cached --name-only | xargs -I {} sh -c 'test -f "{}" && du -k "{}" | awk "\$1 > 1000 {print \$2}"' 2>/dev/null || true)

        if [ -n "$large_files" ]; then
          echo "⚠️  Large files detected (>1MB):"
          echo "$large_files"
          read -p "Are you sure you want to commit large files? (y/N) " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
          fi
        fi

        # 5. Check for sensitive data patterns
        echo "Checking for sensitive data..."
        sensitive_patterns="password.*=|api[_-]?key.*=|secret.*=|token.*=|private[_-]?key"
        sensitive_files=$(git diff --cached --name-only --diff-filter=ACM | xargs -I {} grep -l -E -i "$sensitive_patterns" {} 2>/dev/null || true)

        if [ -n "$sensitive_files" ]; then
          echo "⚠️  Potential sensitive data found in:"
          echo "$sensitive_files"
          echo "Please review these files for hardcoded secrets."
          read -p "Have you reviewed and confirmed no secrets are exposed? (y/N) " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
          fi
        fi

        echo "✅ Pre-commit checks passed!"
        exit 0
      BASH

      File.write(githooks_dir.join('pre-commit'), content)
      FileUtils.chmod(0755, githooks_dir.join('pre-commit'))
    end

    def self.generate_pre_push(githooks_dir)
      content = <<~BASH
        #!/bin/bash
        # Pre-push hook to ensure deployment readiness

        set -e

        echo "🚀 Running pre-push deployment checks..."

        # 1. Check for pending migrations
        echo "Checking for pending migrations..."
        if command -v rails >/dev/null 2>&1; then
          pending=$(bundle exec rails db:migrate:status 2>/dev/null | grep "down" || true)
          if [ -n "$pending" ]; then
            echo "❌ Pending migrations detected!"
            echo "$pending"
            echo "Run 'bundle exec rails db:migrate' before pushing."
            exit 1
          fi
          echo "✅ No pending migrations"
        fi

        # 2. Run full test suite (optional - can be slow)
        if [ "$RUN_TESTS_ON_PUSH" = "true" ]; then
          echo "Running test suite..."
          if ! bundle exec rspec --format progress; then
            echo "❌ Tests are failing!"
            echo "Fix all tests before pushing."
            exit 1
          fi
          echo "✅ All tests passing"
        else
          echo "ℹ️  Skipping test suite (set RUN_TESTS_ON_PUSH=true to enable)"
        fi

        # 3. Check for unresolved merge conflicts
        echo "Checking for merge conflicts..."
        conflicts=$(git diff --name-only --diff-filter=U)
        if [ -n "$conflicts" ]; then
          echo "❌ Unresolved merge conflicts found:"
          echo "$conflicts"
          exit 1
        fi

        # 4. Verify no broken symbolic links
        echo "Checking for broken symlinks..."
        broken_links=$(find . -type l ! -exec test -e {} \\; -print 2>/dev/null || true)
        if [ -n "$broken_links" ]; then
          echo "⚠️  Warning: Broken symbolic links found:"
          echo "$broken_links"
        fi

        # 5. Check bundle is up to date
        echo "Checking Gemfile.lock is up to date..."
        if [ -f "Gemfile" ]; then
          if ! bundle check > /dev/null 2>&1; then
            echo "❌ Bundle is not up to date!"
            echo "Run 'bundle install' and commit the changes."
            exit 1
          fi
          echo "✅ Bundle is up to date"
        fi

        # 6. Lint checking (if rubocop is available)
        if command -v rubocop >/dev/null 2>&1; then
          echo "Running RuboCop..."
          if ! bundle exec rubocop --format quiet; then
            echo "⚠️  RuboCop violations detected (non-blocking)"
            echo "Consider fixing linting issues."
          else
            echo "✅ RuboCop checks passed"
          fi
        fi

        echo "✅ All pre-push checks passed! Ready to deploy."
        exit 0
      BASH

      File.write(githooks_dir.join('pre-push'), content)
      FileUtils.chmod(0755, githooks_dir.join('pre-push'))
    end

    def self.generate_commit_msg(githooks_dir)
      content = <<~BASH
        #!/bin/bash
        # Commit message hook to ensure quality commit messages

        commit_regex='^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\\(.+\\))?: .{1,100}'
        error_msg="❌ Invalid commit message format!

        Commit message must follow conventional commits format:
        <type>(<scope>): <subject>

        Types:
        - feat: A new feature
        - fix: A bug fix
        - docs: Documentation changes
        - style: Code style changes (formatting, etc)
        - refactor: Code refactoring
        - test: Adding or updating tests
        - chore: Maintenance tasks
        - perf: Performance improvements
        - ci: CI/CD changes
        - build: Build system changes
        - revert: Reverting a previous commit

        Examples:
        - feat(auth): add OAuth2 support
        - fix(api): handle null response correctly
        - docs(readme): update installation instructions
        - test(user): add validation specs

        Your message:"

        if ! grep -qE "$commit_regex" "$1"; then
          echo "$error_msg"
          cat "$1"
          exit 1
        fi

        # Check commit message length
        subject_line=$(head -n1 "$1")
        if [ ${#subject_line} -gt 100 ]; then
          echo "❌ Commit subject line is too long (${#subject_line} > 100 characters)"
          echo "Please keep the first line under 100 characters."
          exit 1
        fi

        exit 0
      BASH

      File.write(githooks_dir.join('commit-msg'), content)
      FileUtils.chmod(0755, githooks_dir.join('commit-msg'))
    end

    def self.generate_pre_commit_rubocop(githooks_dir)
      content = <<~BASH
        #!/bin/bash
        # Pre-commit hook for RuboCop auto-correction

        set -e

        echo "🎨 Running RuboCop auto-correct on staged files..."

        # Get staged Ruby files
        staged_files=$(git diff --cached --name-only --diff-filter=ACM | grep "\\.rb$" || true)

        if [ -z "$staged_files" ]; then
          echo "No Ruby files staged for commit."
          exit 0
        fi

        # Check if rubocop is available
        if ! command -v rubocop >/dev/null 2>&1; then
          echo "RuboCop not found, skipping..."
          exit 0
        fi

        # Run RuboCop with auto-correct on staged files
        echo "Running RuboCop on staged files..."
        for file in $staged_files; do
          if [ -f "$file" ]; then
            bundle exec rubocop -a "$file" > /dev/null 2>&1 || true

            # Re-stage the file if it was modified
            if ! git diff --quiet "$file"; then
              echo "  Auto-corrected: $file"
              git add "$file"
            fi
          fi
        done

        # Run final check without auto-correct
        remaining_issues=$(bundle exec rubocop --format simple $staged_files 2>&1 | grep -E "^[CWE]:" || true)

        if [ -n "$remaining_issues" ]; then
          echo "⚠️  RuboCop issues that couldn't be auto-corrected:"
          bundle exec rubocop --format simple $staged_files
          echo ""
          read -p "Commit anyway? (y/N) " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
          fi
        else
          echo "✅ RuboCop checks passed"
        fi

        exit 0
      BASH

      File.write(githooks_dir.join('pre-commit-rubocop'), content)
      FileUtils.chmod(0755, githooks_dir.join('pre-commit-rubocop'))
    end

    def self.generate_install_script(output_path)
      content = <<~BASH
        #!/bin/bash
        # Script to install git hooks

        set -e

        echo "Installing git hooks..."

        HOOKS_DIR=".githooks"
        GIT_HOOKS_DIR=".git/hooks"

        # Ensure we're in a git repository
        if [ ! -d ".git" ]; then
          echo "❌ Not in a git repository root!"
          exit 1
        fi

        # Create hooks directory if it doesn't exist
        mkdir -p "$GIT_HOOKS_DIR"

        # Install each hook
        for hook in "$HOOKS_DIR"/*; do
          if [ -f "$hook" ]; then
            hook_name=$(basename "$hook")

            # Skip the rubocop hook if not wanted
            if [ "$hook_name" = "pre-commit-rubocop" ] && [ "$SKIP_RUBOCOP_HOOK" = "true" ]; then
              echo "  Skipping $hook_name"
              continue
            fi

            # Special handling for multiple pre-commit hooks
            if [ "$hook_name" = "pre-commit-rubocop" ]; then
              # Append to pre-commit if it exists
              if [ -f "$GIT_HOOKS_DIR/pre-commit" ]; then
                echo "" >> "$GIT_HOOKS_DIR/pre-commit"
                echo "# RuboCop checks" >> "$GIT_HOOKS_DIR/pre-commit"
                tail -n +2 "$hook" >> "$GIT_HOOKS_DIR/pre-commit"
                echo "  Added RuboCop to pre-commit"
              fi
            else
              cp "$hook" "$GIT_HOOKS_DIR/$hook_name"
              chmod +x "$GIT_HOOKS_DIR/$hook_name"
              echo "  Installed $hook_name"
            fi
          fi
        done

        # Configure git to use the hooks
        git config core.hooksPath .git/hooks

        echo "✅ Git hooks installed successfully!"
        echo ""
        echo "Hooks installed:"
        echo "  • pre-commit: Checks for debugging statements, migration safety, and sensitive data"
        echo "  • pre-push: Verifies migrations, tests, and deployment readiness"
        echo "  • commit-msg: Enforces conventional commit message format"
        echo ""
        echo "To bypass hooks temporarily, use --no-verify flag:"
        echo "  git commit --no-verify"
        echo "  git push --no-verify"
        echo ""
        echo "Environment variables:"
        echo "  • RUN_TESTS_ON_PUSH=true : Run full test suite before pushing"
        echo "  • SKIP_RUBOCOP_HOOK=true : Skip RuboCop auto-correct on commit"
      BASH

      bin_dir = output_path.join('bin')
      FileUtils.mkdir_p(bin_dir)

      File.write(bin_dir.join('install-hooks'), content)
      FileUtils.chmod(0755, bin_dir.join('install-hooks'))
    end

    def self.configure_git_hooks(output_path)
      # Create a README for the hooks
      readme_content = <<~MD
        # Git Hooks

        This directory contains git hooks to maintain code quality and prevent common issues.

        ## Installation

        Run the installation script:
        ```bash
        ./bin/install-hooks
        ```

        Or manually copy hooks:
        ```bash
        cp .githooks/* .git/hooks/
        chmod +x .git/hooks/*
        ```

        ## Available Hooks

        ### pre-commit
        Runs before each commit to check for:
        - Debugging statements (binding.pry, debugger, console.log)
        - Migration safety issues
        - Failing tests (for staged spec files)
        - Large files (>1MB)
        - Potential sensitive data (passwords, API keys, secrets)

        ### pre-commit-rubocop
        - Auto-corrects style issues with RuboCop
        - Re-stages corrected files automatically
        - Prompts for manual review if issues remain

        ### pre-push
        Runs before pushing to ensure:
        - No pending migrations
        - All tests pass (optional, set RUN_TESTS_ON_PUSH=true)
        - No merge conflicts
        - Bundle is up to date
        - RuboCop checks pass

        ### commit-msg
        Enforces conventional commit format:
        - feat: New features
        - fix: Bug fixes
        - docs: Documentation changes
        - style: Code style changes
        - refactor: Code refactoring
        - test: Test changes
        - chore: Maintenance tasks
        - perf: Performance improvements
        - ci: CI/CD changes
        - build: Build system changes
        - revert: Reverting commits

        ## Bypassing Hooks

        In emergency situations, you can bypass hooks:
        ```bash
        git commit --no-verify
        git push --no-verify
        ```

        **Use with caution!** Hooks exist to prevent issues.

        ## Configuration

        Environment variables:
        - `RUN_TESTS_ON_PUSH=true` - Run full test suite on push
        - `SKIP_RUBOCOP_HOOK=true` - Skip RuboCop auto-correct

        ## Troubleshooting

        If hooks aren't running:
        1. Check they're executable: `chmod +x .git/hooks/*`
        2. Verify Git config: `git config core.hooksPath`
        3. Re-run installation: `./bin/install-hooks`

        ## Contributing

        To modify hooks:
        1. Edit files in `.githooks/`
        2. Run `./bin/install-hooks` to update
        3. Test thoroughly before committing
      MD

      File.write(output_path.join('.githooks', 'README.md'), readme_content)
    end
  end
end