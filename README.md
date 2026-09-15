# `vulnerable-cicd-range`
### Breaking & Hardening the CI/CD Pipeline: Threat Emulation Lab
**Department of Computer Science & Engineering · MIT Bengaluru (MAHE)**  
*Subject: Digital Forensics & Incident Response (DFIR) & Threat Intelligence*  
*Academic Anchor: USENIX Security '22 (Koishybayev et al.)*

---

## 1. Project Overview & 3-Pillar Architecture

This repository is **Track 1 (Threat Emulation & Vulnerable Range)** of a 3-pillar decoupled security engineering project:

```
+-----------------------------------------------------------------------------------------+
|                               CI/CD Threat & Defense Framework                           |
+-----------------------------------------------------------------------------------------+
|  Track 1: Offense (Member 1)   |   Track 2: Defense (Member 2) |  Track 3: DFIR / ML (Member 3)|
|  * vulnerable-cicd-range       |   * PipelineGuard             |  * Build-Log Feature Extractor|
|  * 5 Core Attack Vectors       |   * YAML AST Static Linter    |  * Shannon Entropy Analysis   |
|  * Live Token Exfiltration     |   * SARIF & JSON Detection    |  * Anomaly ML Classifiers     |
|  * Telemetry Generation        |   * Rule Enforcement          |  * MITRE ATT&CK Mapping       |
+-----------------------------------------------------------------------------------------+
```

As **Member 1 (Vulnerable Range Lead)**, this repository serves as the empirical testbed for weaponized supply-chain attack vectors against CI/CD pipelines, demonstrating real-world vulnerabilities and generating raw telemetry for static analysis and machine learning detection.

---

## 2. Threat Model & MITRE ATT&CK Mapping

| # | Attack Vector | MITRE ATT&CK | Vulnerability Mechanism | Hardening Control |
|---|---|---|---|---|
| **1** | **`pull_request_target` Poisoning** | **T1195.002** (Supply Chain Compromise) | Elevated workflow checks out untrusted code from external fork PR, granting PR code access to repo secrets & write tokens. | Use standard `pull_request` trigger; enforce read-only tokens; manual approval for fork PRs. |
| **2** | **Secret Exfiltration via Masking Bypasses** | **T1552 / T1048** (Unsecured Credentials / Exfiltration) | Bypasses naive GitHub secret masking in logs using base64 encoding, character splitting, and outbound HTTP egress. | Migrate to OIDC short-lived federation; egress filtering; eliminate static stored keys. |
| **3** | **Dependency & Build Poisoning** | **T1195.001** (Compromised Dependency) | Malicious package or typosquatted library executes arbitrary shell commands during lifecycle hooks (`postinstall`). | Lockfile hash pinning; enforce `--ignore-scripts`; integrate SBOM scanning. |
| **4** | **Self-Hosted Runner Takeover** | **T1078 / T1059.004** (Persistence / Execution) | Untrusted PR runs on persistent runner, planting backdoors/cron jobs to compromise subsequent jobs on the host machine. | Enforce ephemeral disposable runners; run inside isolated Docker containers. |
| **5** | **Script Injection via Untrusted Input** | **T1059** (Command Interpreter) | Direct template interpolation (`${{ github.event.pull_request.title }}`) inside inline shell scripts (`run:`). | Pass context strictly via environment variables (`env:`); pin actions to full commit SHAs. |

---

## 3. Vulnerability Deep Dive: `pull_request_target` (Attack 1 & 2)

### Why does this vulnerability exist?
GitHub Actions provides two primary triggers for Pull Requests:
1. `on: pull_request`: Runs in the **untrusted context of the fork**. It has read-only access to repository contents and **ZERO access to repository secrets**.
2. `on: pull_request_target`: Runs in the **privileged context of the base repository**. It has access to repository secrets and write tokens so workflows can add labels, post comments, or deploy preview environments.

### The Fatal Flaw
The security boundary collapses when a `pull_request_target` workflow checks out the code from the incoming PR:
```yaml
# THE FATAL PATTERN:
on: pull_request_target
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }} # <--- PULLS UNTRUSTED CODE
      - run: ./scripts/build.sh                          # <--- EXECUTES ATTACKER CODE IN PRIVILEGED CONTEXT!
```
Because the runner has already loaded the base repository's secrets into memory, any code executed from the pull request can access those secrets, execute commands, or leak tokens.

---

## 4. 15-Minute Live Demonstration Quickstart (For Faculty Evaluation)

### Step 1: Create Free External Listener
1. Open your browser to [https://webhook.site](https://webhook.site).
2. A unique URL will be generated automatically (e.g., `https://webhook.site/abcdef12-3456-...`).
3. Keep this browser tab open—this is your live C2 / exfiltration sink!

### Step 2: Push This Repository to GitHub
In your local terminal:
```powershell
# Verify files
git status

# Add and commit
git add .
git commit -m "feat: initialize vulnerable-cicd-range testbed (Attack 1 & 2)"

# Push to your GitHub account (replace <your-username>)
git remote add origin https://github.com/<your-username>/vulnerable-cicd-range.git
git push -u origin main
```

### Step 3: Configure Repository Secrets
On GitHub:
1. Navigate to: **Settings** -> **Secrets and variables** -> **Actions**.
2. Click **New repository secret**:
   - Name: `DUMMY_SECRET`
   - Value: `FLAG{gh_actions_pwned_dummy_token_98472}`
3. Click **New repository secret**:
   - Name: `WEBHOOK_URL`
   - Value: `<Your unique webhook.site URL from Step 1>`

*(Note: If you don't configure secrets, the workflow uses safe built-in fallback values so it never breaks during a live demo).*

### Step 4: Trigger the Exploit Pull Request
You can open a PR from either:
- **Option A (Simulated Attack Branch)**:
  ```bash
  git checkout -b test-exploit-pr
  # Make a small harmless change or update scripts/build.sh
  echo "# Test PR for CI verification" >> scripts/build.sh
  git commit -am "chore: update build script"
  git push origin test-exploit-pr
  ```
  Open a PR from `test-exploit-pr` into `main`.
- **Option B (Attacker Fork - Realistic USENIX Emulation)**:
  Fork the repo from a second GitHub account, make a commit, and submit a PR to `main`.

### Step 5: Live Faculty Demonstration
1. Open the **Actions** tab on GitHub:
   - Click on the running workflow: `Vulnerable CI/CD Pipeline (Threat Emulation Lab)`.
   - Expand the step: `Simulated Token Masking Bypass & Outbound Transmission`.
   - Show the faculty the raw Base64 token printed in the logs (bypassing GitHub's masking regex).
2. Switch to your **webhook.site** tab:
   - Point to the live incoming HTTP `POST` request.
   - Show the payload containing `leaked_secret_token` and `base64_secret` received in real-time from the GitHub runner!

---

## 5. Ready-to-Use Faculty Defense Script

When presenting to the faculty panel, deliver this concise explanation:

> *"Good morning professors. I am Member 1, leading Track 1: Threat Emulation and the Vulnerable Range.
> 
> As outlined in our USENIX Security '22 research anchor, modern CI/CD pipelines represent high-value targets because runners possess execution privileges and cloud credentials.
> 
> Here on screen is our live testbed repository, `vulnerable-cicd-range`. We configured our CI/CD pipeline using GitHub's `pull_request_target` trigger. While GitHub intended this trigger for safe repo automation, checking out the pull request's untrusted head commit (`github.event.pull_request.head.sha`) completely collapses the isolation boundary.
> 
> As you can see, when a pull request was submitted, our elevated workflow executed. It extracted our repository secret token, bypassed naive log masking via Base64 encoding, and transmitted the credential to our listener at webhook.site.
> 
> In addition, this live execution produces the raw forensic build logs that Member 3 ingests to train our ML anomaly detection models, while the vulnerable YAML configurations serve as the test fixture scanned by Member 2's PipelineGuard static analyzer."*

---

## 6. Handoff to Team Members (Zero-Waiting Contract)

- **For Member 2 (`PipelineGuard` Static Analyzer)**:
  - Member 2 runs:
    ```bash
    pipelineguard scan --repo https://github.com/<your-username>/vulnerable-cicd-range
    ```
  - PipelineGuard detects:
    - Rule 1: `pull_request_target` + checkout of `head.sha` (High Severity).
    - Rule 4: Broad `permissions: write-all` (Medium Severity).

- **For Member 3 (DFIR Telemetry & Anomaly ML)**:
  - Download raw build logs from the GitHub Actions run:
    - Click **Actions** -> Select the Run -> Click **⚙️ (Gear icon)** -> **Download log archive**.
  - Drop the raw text logs into `data/attack_logs/` for Shannon entropy analysis and classifier training.

---

## 7. Hardening Reference

See `.github/workflows/hardened.yml` for the complete remediation:
1. Replaces `pull_request_target` with standard `pull_request`.
2. Restricts permissions to `contents: read`.
3. Ensures secrets are never exposed to untrusted external pull requests.
