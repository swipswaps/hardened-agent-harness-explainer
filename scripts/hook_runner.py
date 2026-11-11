#!/usr/bin/env python3
"""
Claude Code PreToolUse hook runner.

Reads the hook payload JSON from stdin, evaluates it against the shared
policy at public/hook_policy.json (or dist/hook_policy.json), and enforces
the Claude Code exit-code contract:

    0  allow (or JSON permissionDecision on stdout)
    2  block; stderr is fed back to the model as feedback
    1  non-blocking error; stderr goes to the user only

Default output is hookSpecificOutput JSON (exit 0):

    {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                            "permissionDecision": "deny"|"allow"|"ask",
                            "permissionDecisionReason": "..."}}

Exit-code mode (--exit-code) is the fallback for harnesses that cannot parse
stdout. In that mode, deny -> exit 2, allow -> exit 0, ask -> deny (exit 2)
with an explicit stderr note, because exit codes cannot express "ask".

Every external check (rule.check.argv) runs through Popen with
start_new_session=True; on timeout the whole process group is killed with
SIGTERM then SIGKILL. subprocess.run is never used: it kills only the direct
child and leaks grandchildren that hold the pipes open.

Constraints: no shell=True, bounded timeout, process-group kill on POSIX,
taskkill /T on Windows, no subprocess.run.
"""

import argparse
import json
import os
import re
import signal
import subprocess
import sys

TIMEOUT_DEFAULT = 10
KILL_GRACE = 2
HERE = os.path.dirname(os.path.abspath(__file__))
POLICY_CANDIDATES = [
    os.path.join(HERE, "..", "public", "hook_policy.json"),
    os.path.join(HERE, "..", "dist", "hook_policy.json"),
]


def load_policy(explicit_path=None):
    paths = [explicit_path] if explicit_path else POLICY_CANDIDATES
    for path in paths:
        path = os.path.abspath(path)
        if not os.path.isfile(path):
            continue
        with open(path, "r", encoding="utf-8") as fh:
            body = json.load(fh)
        rules = body.get("rules") or []
        return rules, path
    return [], None


def kill_tree(proc):
    if os.name == "posix":
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
        except (ProcessLookupError, PermissionError):
            try:
                proc.terminate()
            except Exception:
                pass
        try:
            proc.wait(timeout=KILL_GRACE)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except (ProcessLookupError, PermissionError):
                try:
                    proc.kill()
                except Exception:
                    pass
    else:
        try:
            subprocess.Popen(
                ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            try:
                proc.kill()
            except Exception:
                pass


def run_check(argv, timeout, cwd):
    """Run an external check with a bounded timeout and a process-group kill."""
    popen_kwargs = {}
    if os.name == "posix":
        popen_kwargs["start_new_session"] = True
    try:
        proc = subprocess.Popen(
            argv,
            cwd=cwd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            **popen_kwargs,
        )
    except FileNotFoundError:
        return {"exit": 127, "stdout": "", "stderr": "command not found", "timed_out": False}

    try:
        out, err = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        kill_tree(proc)
        try:
            out, err = proc.communicate(timeout=KILL_GRACE)
        except subprocess.TimeoutExpired:
            out, err = "", "[timeout: output unavailable after kill]"
        return {"exit": 124, "stdout": out, "stderr": err, "timed_out": True}

    return {"exit": proc.returncode, "stdout": out, "stderr": err, "timed_out": False}


def rule_matches(rule, payload):
    tool = payload.get("tool_name") or payload.get("tool") or ""
    tool_input = payload.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("path") or payload.get("path") or ""
    command = tool_input.get("command") or payload.get("command") or ""
    cwd = payload.get("cwd") or os.getcwd()

    tools = rule.get("tools") or []
    if tools and tool not in tools:
        return False, path, command, cwd

    matched = False
    if rule.get("path_regex") and path:
        try:
            matched = re.search(rule["path_regex"], path) is not None
        except re.error:
            matched = False
    if not matched and rule.get("command_regex") and command:
        try:
            matched = re.search(rule["command_regex"], command) is not None
        except re.error:
            matched = False
    if not matched:
        return False, path, command, cwd

    requires = rule.get("requires_file")
    if requires and not os.path.exists(os.path.join(cwd, requires)):
        return False, path, command, cwd

    check = rule.get("check")
    if check:
        argv = check.get("argv") or []
        if argv:
            result = run_check(
                argv,
                float(check.get("timeout_seconds", TIMEOUT_DEFAULT)),
                cwd,
            )
            match_on = check.get("match_on", "nonzero")
            if match_on == "nonzero" and result["exit"] == 0:
                return False, path, command, cwd
            if match_on == "zero" and result["exit"] != 0:
                return False, path, command, cwd

    return True, path, command, cwd


def evaluate(payload, rules):
    for rule in rules:
        hit, path, command, cwd = rule_matches(rule, payload)
        if not hit:
            continue
        reason = (rule.get("reason") or "Policy violation").replace("{path}", path or command)
        reason = reason.replace("{command}", command or path)
        return {
            "matchedRule": rule.get("id"),
            "decision": rule.get("decision", "deny"),
            "reason": reason,
        }
    return {"matchedRule": None, "decision": "allow", "reason": "No policy rule matched."}


def emit(decision, exit_code_mode):
    if not exit_code_mode:
        body = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": decision["decision"],
                "permissionDecisionReason": decision["reason"],
            }
        }
        print(json.dumps(body))
        return 0

    if decision["decision"] == "deny":
        sys.stderr.write(decision["reason"] + "\n")
        return 2
    if decision["decision"] == "ask":
        sys.stderr.write("[ask downgraded to deny in exit-code mode] " + decision["reason"] + "\n")
        return 2
    return 0


def self_test(rules):
    cases = [
        ({"tool_name": "Read", "tool_input": {"file_path": ".env"}, "cwd": os.getcwd()}, "deny"),
        ({"tool_name": "Read", "tool_input": {"file_path": "src/App.jsx"}, "cwd": os.getcwd()}, "allow"),
        ({"tool_name": "Bash", "tool_input": {"command": "rm -rf /"}, "cwd": os.getcwd()}, "deny"),
    ]
    failed = 0
    for payload, expected in cases:
        got = evaluate(payload, rules)["decision"]
        status = "PASS" if got == expected else "FAIL"
        print("[%s] %s -> %s (expected %s)" % (status, payload["tool_name"], got, expected))
        if got != expected:
            failed += 1
    return 0 if failed == 0 else 2


def main():
    parser = argparse.ArgumentParser(description="Claude Code PreToolUse hook runner")
    parser.add_argument("--json", action="store_true", help="print hookSpecificOutput JSON and exit 0 (default)")
    parser.add_argument("--exit-code", action="store_true", help="use exit-code contract (0 allow / 2 deny)")
    parser.add_argument("--policy", default=None, help="explicit policy path")
    parser.add_argument("--self-test", action="store_true", help="run built-in assertions")
    args = parser.parse_args()

    rules, policy_path = load_policy(args.policy)
    if policy_path is None:
        sys.stderr.write("[hook_runner] policy not found; blocking to fail closed\n")
        if not args.exit_code:
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": "Policy file missing; hook fails closed.",
                }
            }))
            return 0
        return 2

    if args.self_test:
        return self_test(rules)

    try:
        payload = json.load(sys.stdin)
    except Exception as exc:
        sys.stderr.write("[hook_runner] invalid stdin JSON: %s\n" % exc)
        return 2

    decision = evaluate(payload, rules)
    return emit(decision, args.exit_code)


if __name__ == "__main__":
    sys.exit(main())
