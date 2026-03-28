# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest on main | Yes |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do NOT open a public GitHub issue.**
2. Go to [Security Advisories](https://github.com/matthewdeaves/TextHarvest/security/advisories) and click **"New draft security advisory"**.
3. Include steps to reproduce if possible.

## Scope

TextHarvest is a shell-based text extraction toolkit. Security considerations include:

- **Command injection**: Shell scripts that process filenames or user input must properly quote variables to prevent injection attacks.
- **Path traversal**: File processing scripts must validate paths to prevent reading/writing outside intended directories.
- **Supply-chain integrity**: GitHub Actions and Docker images used in CI must be pinned to prevent tampering.
- **Bash 3.2 compatibility**: The project targets macOS's default bash, which lacks some modern security features.
