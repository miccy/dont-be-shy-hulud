---
title: Release Workflow
description: Process for releasing new versions of the project
sidebar:
  order: 10
lastUpdated: 2025-12-05
---

# Release Workflow

This document describes the process of releasing new versions of the **Don't Be Shy Hulud** project.

## 1. Preparation
Ensure that you have:
- A clean working directory (no uncommitted changes).
- You are on the `dev` branch (or any `*-dev` branch).
- You have pulled the latest changes (`git pull`).

## 2. Starting the Process
To release a new version, use the automation script:

```bash
./scripts/release.sh
```

## 3. Script Workflow
The script guides you through the following steps:

1.  **Check**: Verifies that you are on the `dev` branch (or `*-dev`) and have no uncommitted changes.
2.  **Version Selection**: Displays the current version and asks for the new one.
3.  **Branch Creation**: Creates a new branch `preview/vX.Y.Z`.
4.  **Changelog Update**: Opens `CHANGELOG.md` for you to add release notes.
5.  **Synchronization**: Updates the version in all scripts.
6.  **Push**: Commits changes and pushes the branch to GitHub.
7.  **Instructions**: Prints the link to create a Pull Request.

## 4. Completing the Release (Automated)
1.  **Pull Request**: Open a PR from `preview/v...` to `main`.
2.  **Merge**: After approval, merge the PR into `main`.
    *   *Important:* Use **"Merge commit"** or **"Rebase and merge"**. Keep the commit message `chore: release v...` so the GitHub Action recognizes it as a release.
3.  **Automated Release**:
    *   Once changes reach `main`, the `Automated Release` GitHub Action is triggered.
    *   This action automatically creates a **Git Tag** (e.g., `v1.4.0`) and a **GitHub Release**.
4.  **Back-merge (Sync dev)**:
    *   Since the version was bumped on `main`, you must get it back into `dev`.
    *   Create a PR from `main` to `dev` or do it locally:
        ```bash
        git checkout dev
        git pull origin dev
        git merge main
        git push origin dev
        ```

## 5. Manual Procedure (if the script fails)
If you need to perform a release manually:

1.  Go to `dev`: `git checkout dev`.
2.  Create a branch: `git checkout -b preview/v1.4.0`.
3.  Edit `CHANGELOG.md` and run `./scripts/sync-version.sh`.
4.  Commit and push:
    ```bash
    git commit -am "chore: release v1.4.0"
    git push -u origin preview/v1.4.0
    ```
5.  Open a PR to `main`. After merge, the release will be created automatically.
