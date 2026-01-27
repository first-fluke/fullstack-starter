---
name: create-pr
description: Automates the creation of detailed, well-formatted Pull Requests using the GitHub CLI. Parses conventional commits to generate titles and descriptions.
---

# Create PR

This skill streamlines the Pull Request process, ensuring consistent and high-quality PR descriptions.

## Prerequisites

- `gh` (GitHub CLI) must be installed and authenticated.
- The current branch must have commits that are not yet on the remote (or a corresponding remote branch).

## Workflow

1.  **Analyze Context**: Checks the git log to understand the changes (`feat`, `fix`, `chore`).
2.  **Generate Metadata**:
    - **Title**: Uses the conventional commit format (e.g., `feat: Implement user login`).
    - **Body**: Summarizes the changes, links to issues, and provides verification steps.
3.  **Execute**: Runs `gh pr create`.

## Usage

```bash
# Standard usage (interactive)
gh pr create

# Fully automated with flags
gh pr create --title "feat: Add user profile" --body "Implements user profile page..."
```

## Best Practices for PRs

- **Small & Focused**: Keep PRs limited to a single logical change.
- **Linked Issues**: Always link to the task/issue (e.g., `Closes #123`).
- **Self-Review**: Review your own diff before creating the PR.
- **Verification**: Explicitly state how you verified the change (screenshots, test output).
