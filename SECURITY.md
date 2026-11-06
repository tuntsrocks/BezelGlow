# Security

Report suspected vulnerabilities privately through
[GitHub's Report a vulnerability form](https://github.com/tuntsrocks/BezelGlow/security/advisories/new).
Do not put exploit details, credentials, or private data in a public issue or pull request.

Include the affected tag or commit, steps to reproduce, expected impact, and a
small example if possible. Remove personal information and secrets from logs.
If practical, check whether the issue also occurs on the latest `main` branch.

Maintainers assess reports on a best-effort basis. There is no guaranteed
response or fix timeline, and no paid support or bug-bounty commitment.

If a credential has been exposed, revoke or rotate it immediately. Removing a
file from the latest commit does not remove it from Git history or existing copies.

The library draws the glow and does not open the microphone or use the network.
The example app has a separate, permission-based microphone meter. Reports about
either the library or the example are welcome.
