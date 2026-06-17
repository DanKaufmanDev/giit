# Security Policy

Giit is a desktop Git client that interacts with local repositories, Git
configuration, working trees, credentials managed by Git, and remote operations
initiated by the user. Security reports are taken seriously.

## Reporting a Vulnerability

Please report suspected security vulnerabilities privately.

Use GitHub's private vulnerability reporting flow when available:
https://github.com/DanKaufmanDev/giit/security/advisories/new

If private vulnerability reporting is not available, open a minimal public issue
asking for a private security contact without including exploit details.

## What to Include

- A clear description of the issue.
- Steps to reproduce the behavior.
- Affected platform and Giit version, if available.
- Whether the issue requires a malicious repository, local access, network
  access, or user interaction.
- Any logs, screenshots, or proof-of-concept material that help explain the
  impact.

## Scope

Security-sensitive areas include:

- Repository state mutation, including checkout, reset, merge, rebase, stash,
  discard, restore, and history editing flows.
- Recovery points, snapshots, and local workflow history.
- Handling of untrusted repository contents, file paths, symlinks, hooks, and
  submodules.
- Git credential handling and remote operations.
- Update checks, downloads, and release verification.
- Local data storage, permissions, and cleanup.

## Response Expectations

Giit is currently in private development, so response times may vary. We aim to
acknowledge valid private reports promptly, investigate reproducible issues, and
credit reporters when appropriate and desired.

Please do not publicly disclose an unresolved vulnerability until we have had a
reasonable opportunity to investigate and respond.
