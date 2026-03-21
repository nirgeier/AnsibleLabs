# GitHub Copilot Instructions

## ⚠️ CRITICAL: No Automatic Git Operations

**NEVER perform any git operations without explicit user confirmation.**

This includes:
- `git commit`
- `git push`
- `git add`
- `git merge`
- `git rebase`
- `git reset`
- `git stash`
- Any other command that modifies git history or pushes to remote

### What to do instead

After making file changes, **stop and show the user what was changed**.  
Only run git commands when the user explicitly says something like:
- "commit this"
- "push the changes"
- "go ahead and push"
