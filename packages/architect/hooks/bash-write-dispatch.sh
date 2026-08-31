#!/bin/bash
# Route supported, explicit Bash write targets through existing Edit/Write hooks.
set -uo pipefail

run_all=0
if [ "${1:-}" = "--all" ]; then
  run_all=1
  shift
fi
[ "$#" -gt 0 ] || exit 0

input=$(cat)
events=$(INPUT="$input" python3 <<'PY' 2>/dev/null || true
import json
import os
from pathlib import Path
import re

# ponytail: this is a literal simple-command classifier, not a shell interpreter.
# Expansions, control structures and in-process writes need a shell AST/runtime
# mutation boundary; do not guess their targets or execute input to discover them.
TOKEN = re.compile(
    r"(?P<space>[ \t\r]+|\\\n)|(?P<comment>#[^\n]*)|"
    r"(?P<op><<-|<<|>>|&&|\|\||>&|<&|[|;&<>()\n])|"
    r'(?P<word>(?:[^\s|;&<>()\x27\x22\\]+|\x27[^\x27]*\x27|\x22(?:\\.|[^\x22\\])*\x22|\\.)+)'
)

def literal_word(raw):
    # shlex does not implement Bash's dollar/backtick escapes inside double quotes.
    value, quote, index = [], None, 0
    while index < len(raw):
        char = raw[index]
        if quote == chr(39):
            if char == quote:
                quote = None
            else:
                value.append(char)
        elif char == "\\":
            index += 1
            escaped = raw[index]
            if quote == chr(34) and escaped not in ("$", chr(96), chr(34), "\\", "\n"):
                value.append("\\")
            if escaped != "\n":
                value.append(escaped)
        elif char in (chr(39), chr(34)) and (quote is None or quote == char):
            quote = char if quote is None else None
        else:
            if char in ("$", chr(96)) or quote is None and char in "*?[]{}~":
                raise ValueError("unsupported expansion")
            value.append(char)
        index += 1
    return "".join(value)


def tokenize(command):
    tokens, pending = [], []
    pos = 0
    while pos < len(command):
        match = TOKEN.match(command, pos)
        if not match:
            raise ValueError("unsupported shell syntax")
        pos = match.end()
        kind, raw = match.lastgroup, match.group()
        if kind in {"space", "comment"}:
            continue
        token = {"kind": kind, "raw": raw, "start": match.start(), "end": pos}
        if kind == "word":
            token["value"] = literal_word(raw)
            if tokens and tokens[-1]["raw"] in {"<<", "<<-"}:
                pending.append((token, tokens[-1]["raw"] == "<<-"))
        tokens.append(token)
        if kind == "op" and raw == "\n":
            for delimiter, strip_tabs in pending:
                body = []
                while True:
                    end = command.find("\n", pos)
                    end = len(command) if end == -1 else end + 1
                    line = command[pos:end]
                    pos = end
                    candidate = line.lstrip("\t") if strip_tabs else line
                    if candidate.rstrip("\n") == delimiter["value"]:
                        break
                    if not line or end == len(command) and not line.endswith("\n"):
                        raise ValueError("unterminated heredoc")
                    body.append(candidate)
                content = "".join(body)
                quoted = delimiter["raw"] != delimiter["value"]
                delimiter["body"] = content if quoted or not any(
                    char in content for char in ("$", chr(96), "\\")
                ) else None
            pending.clear()
    if pending:
        raise ValueError("unterminated heredoc")
    return tokens


def classify(data):
    if not isinstance(data, dict) or data.get("tool_name") != "Bash":
        return []
    tool = data.get("tool_input") or {}
    if not isinstance(tool, dict):
        return []
    command = tool.get("command")
    base = tool.get("workdir") or tool.get("cwd") or data.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    if not isinstance(command, str) or not isinstance(base, str) or not os.path.isabs(base):
        return []
    segments, current = [], []
    for token in tokenize(command):
        if token["kind"] == "op" and token["raw"] in {"(", ")", "&"}:
            return []
        if token["kind"] == "op" and token["raw"] in {"|", "&&", "||", ";", "\n"}:
            if current:
                segments.append((current, token["raw"]))
                current = []
        else:
            current.append(token)
    if current:
        segments.append((current, None))

    targets, pipe_content, previous_separator = [], None, None
    reserved = {"if", "then", "else", "elif", "fi", "for", "while", "until",
                "do", "done", "case", "esac", "function", "select", "in", "!", "[[", "]]"}
    for parts, separator in segments:
        words, redirects = [], []
        index = 0
        while index < len(parts):
            token = parts[index]
            if token["kind"] == "word":
                words.append(token)
                index += 1
                continue
            if token["raw"] not in {">", ">>", "<", "<<", "<<-", ">&", "<&"}:
                return []
            if index + 1 == len(parts) or parts[index + 1]["kind"] != "word":
                return []
            fd = "0" if token["raw"].startswith("<") else "1"
            if words and words[-1]["raw"].isdigit() and words[-1]["end"] == token["start"]:
                fd = words.pop()["value"]
            redirects.append((token["raw"], fd, parts[index + 1]))
            index += 2
        args = [word["value"] for word in words]
        name = Path(args[0]).name if args else ""
        if name in reserved:
            return []
        if name == "cd":
            if len(args) != 2 or args[1].startswith("-") or redirects or separator != "&&" or previous_separator == "|":
                return []
            base = os.path.normpath(os.path.join(base, args[1]))
            pipe_content, previous_separator = None, separator
            continue

        stdin_content = pipe_content if previous_separator == "|" else None
        for op, fd, target in redirects:
            if fd == "0":
                stdin_content = (target.get("body") if op in {"<<", "<<-"}
                                 else "" if op == "<" and target["value"] == "/dev/null"
                                 else None)
        content = None
        if name == "echo" and (len(args) == 1 or not args[1].startswith("-") or args[1] == "-n"):
            no_newline = len(args) > 1 and args[1] == "-n"
            operands = args[2:] if no_newline else args[1:]
            # Repeated options and escape handling vary across echo implementations.
            if not any("\\" in arg for arg in operands) and not (operands and operands[0].startswith("-")):
                content = " ".join(operands) + ("" if no_newline else "\n")
        elif name == "printf" and len(args) >= 2:
            if args[1] in {"%s", "%s\\n"}:
                suffix = "" if args[1] == "%s" else "\n"
                content = "".join(arg + suffix for arg in (args[2:] or [""]))
            elif len(args) == 2 and "%" not in args[1] and "\\" not in args[1]:
                content = args[1]
        elif (name == "cat" and len(args) == 1) or name == "tee":
            content = stdin_content

        def add_target(value, body):
            if value and value not in {"-", "/dev/null"}:
                targets.append((str((Path(base) / value).resolve(strict=False)), body))

        stdout_redirected = False
        last_stdout = max((i for i, (op, fd, _) in enumerate(redirects)
                           if fd == "1" and op in {">", ">>", ">&"}), default=-1)
        for i, (op, fd, target) in enumerate(redirects):
            if op in {">", ">>"}:
                body = content if i == last_stdout else ""
                add_target(target["value"], body if fd == "1" else None)
                stdout_redirected |= fd == "1"
            elif op == ">&":
                stdout_redirected |= fd == "1"
        if name == "tee":
            options = True
            for arg in args[1:]:
                if options and arg == "--":
                    options = False
                elif options and arg in {"-a", "--append", "-i", "--ignore-interrupts"}:
                    continue
                elif options and arg.startswith("-"):
                    return []
                else:
                    add_target(arg, content)
        pipe_content = content if separator == "|" and not stdout_redirected else None
        previous_separator = separator
    return targets


try:
    data = json.loads(os.environ["INPUT"])
    targets = classify(data)
except (KeyError, ValueError, TypeError, OSError):
    raise SystemExit

for target, content in targets:
    event = dict(data)
    event["tool_name"] = "Write"
    event["tool_input"] = {"file_path": target}
    if content is not None:
        event["tool_input"]["content"] = content
    print(json.dumps(event, separators=(",", ":")))
PY
)

[ -n "$events" ] || exit 0
while IFS= read -r event; do
  [ -n "$event" ] || continue
  for child in "$@"; do
    output=$(printf '%s' "$event" | "$child")
    status=$?
    [ -z "$output" ] || printf '%s\n' "$output"
    [ "$status" -eq 0 ] || exit "$status"
    if [ "$run_all" -eq 0 ] && [ -n "$output" ]; then
      exit 0
    fi
  done
done <<< "$events"
