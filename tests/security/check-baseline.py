#!/usr/bin/env python3
# Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0.
# SPDX-License-Identifier: Apache-2.0
"""Compare a Snyk Agent Scan report against the accepted-findings baseline.

The baseline is a ratchet: findings already recorded in baseline.json are
accepted risk and do not fail CI. Anything the scanner reports that is *not*
in the baseline fails the build, so a PR can never quietly add a new one.

Usage:
    check-baseline.py scan-results.json              # check (exit 1 on new)
    check-baseline.py scan-results.json --update     # rewrite the baseline
"""

import argparse
import json
import os
import sys

# W003-W006 are v0.5.x internal hints. The scanner's own text report hides
# them unless --verbose is set, but they are always present in JSON output.
INTERNAL_CODES = frozenset({"W003", "W004", "W005", "W006"})

# Credential handling. These are the findings worth tolerating false positives
# for: once a skill stops mishandling credentials it must stay that way, so a
# disappeared W007/W008 blocks until the baseline is pruned. See classify_stale.
CREDENTIAL_CODES = frozenset({"W007", "W008"})

BASELINE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "baseline.json")


def classify_stale(skill, code):
    """Decide what a *disappeared* baseline entry means for the build.

    Called for each (skill, code) that is in baseline.json but was NOT
    reported by this scan. Return one of:

        "block" — fail the build; forces the baseline to be pruned in the
                  same PR that fixed the finding, so it never rots.
        "warn"  — report it, keep the build green.
        "allow" — say nothing.

    Snyk's skill analysis is LLM-backed, so a finding can vanish and reappear
    between runs without the skill changing at all. Blocking on every stale
    entry would red-build on that flapping; warning on every one lets the
    baseline rot. Credential findings are the ones worth the false positives,
    so those block and everything else warns.
    """
    del skill
    return "block" if code in CREDENTIAL_CODES else "warn"


def load_findings(report):
    """Flatten a v0.5.x scan report into {(skill, code): message}.

    The report root is a map of absolute path -> ScanPathResult, so paths are
    normalized away to skill names — absolute paths differ between a laptop
    and a CI runner and would make the baseline unportable.
    """
    findings = {}
    failures = []

    for path, result in report.items():
        servers = result.get("servers") or []

        path_error = result.get("error")
        if path_error and path_error.get("is_failure"):
            failures.append(f"{path}: {path_error.get('message')}")

        for server in servers:
            server_error = server.get("error")
            if server_error and server_error.get("is_failure"):
                name = server.get("name") or path
                failures.append(f"{name}: {server_error.get('message')}")

        for issue in result.get("issues") or []:
            code = issue.get("code", "")
            if code in INTERNAL_CODES:
                continue

            skill = os.path.basename(result.get("path", path))
            reference = issue.get("reference") or []
            if reference and isinstance(reference[0], int):
                index = reference[0]
                if 0 <= index < len(servers):
                    skill = servers[index].get("name") or skill

            findings[(skill, code)] = issue.get("message", "")

    return findings, failures


def load_baseline():
    if not os.path.exists(BASELINE_PATH):
        return {}
    with open(BASELINE_PATH, encoding="utf-8") as handle:
        data = json.load(handle)
    return {(entry["skill"], entry["code"]): entry.get("message", "") for entry in data.get("accepted", [])}


def write_baseline(findings):
    accepted = [
        {"skill": skill, "code": code, "message": message}
        for (skill, code), message in sorted(findings.items())
    ]
    data = {
        "_comment": (
            "Accepted Snyk Agent Scan findings. CI fails on any finding not "
            "listed here. Regenerate with: tests/security/check-baseline.py "
            "scan-results.json --update"
        ),
        "scanner": "snyk-agent-scan@0.5.17",
        "accepted": accepted,
    }
    with open(BASELINE_PATH, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", help="JSON report from tests/security/run-scan.sh")
    parser.add_argument("--update", action="store_true", help="rewrite baseline.json from this report")
    args = parser.parse_args()

    with open(args.report, encoding="utf-8") as handle:
        report = json.load(handle)

    findings, failures = load_findings(report)

    if args.update:
        if failures:
            print("Refusing to update the baseline from an incomplete scan:", file=sys.stderr)
            for failure in failures:
                print(f"  {failure}", file=sys.stderr)
            return 1
        write_baseline(findings)
        print(f"Baseline updated: {len(findings)} accepted finding(s) in {BASELINE_PATH}")
        return 0

    baseline = load_baseline()
    new = sorted(key for key in findings if key not in baseline)
    stale = sorted(key for key in baseline if key not in findings)

    print(f"=== Snyk Agent Scan: {len(findings)} finding(s), {len(baseline)} baselined ===")

    exit_code = 0

    if failures:
        print("\nScanner failures (scan did not complete cleanly):")
        for failure in failures:
            print(f"  {failure}")
        exit_code = 1

    if new:
        print(f"\nNEW findings not in baseline ({len(new)}):")
        for skill, code in new:
            print(f"  {skill}: {code} — {findings[(skill, code)]}")
        print("\nFix the skill, or accept the risk by re-running with --update")
        print("and committing baseline.json with an explanation in the PR.")
        exit_code = 1

    # A scan that did not complete reports fewer findings than it should, so
    # every unreached skill looks "fixed". Suppress the noise.
    if stale and not failures:
        blocking = [key for key in stale if classify_stale(*key) == "block"]
        reported = [key for key in stale if classify_stale(*key) != "allow"]
        if reported:
            blocking_set = set(blocking)
            print(f"\nBaseline entries no longer reported ({len(reported)}):")
            for skill, code in reported:
                marker = "  <- blocks build" if (skill, code) in blocking_set else ""
                print(f"  {skill}: {code}{marker}")
            print("\nPrune these with --update to keep the baseline honest.")
        if blocking:
            print(
                f"\n{len(blocking)} credential finding(s) disappeared. Prune them "
                "with --update in the same PR that fixed them, or investigate: a "
                "W007/W008 that vanishes without a deliberate fix is scanner flap."
            )
            exit_code = 1

    if exit_code == 0 and not new:
        print("\nNo new findings.")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
