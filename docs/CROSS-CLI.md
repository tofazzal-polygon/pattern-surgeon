# Cross-CLI Compatibility

pattern-surgeon was designed for **Claude Code** (the official Anthropic CLI),
which has a native skill-invocation system. This document explains what works
out-of-the-box elsewhere and what needs adaptation.

---

## TL;DR

| Component | Claude Code | Other CLIs |
|---|---|---|
| Auto-invocation from `description:` | Native | Manual (paste as system prompt) |
| `SKILL.md` routing logic | Native | Manual (feed as context) |
| `verify.sh` / `checkpoint.sh` / `rollback.sh` | Native | **Fully portable** — pure bash |
| All 6 pattern guides | Native | **Fully portable** — plain Markdown |
| Multi-language detection | Native | Portable (scripts do the detection) |

The shell scripts are **100% CLI-agnostic**. Any LLM CLI can call them via
tool-use or shell execution. The skill's auto-invocation mechanism is what
differs.

---

## Claude Code (native)

No adaptation needed. Install as described in `USAGE.md`.

```bash
ln -s "$PWD/pattern-surgeon/skills/pattern-surgeon" \
      ~/.claude/skills/pattern-surgeon
```

The `---name: pattern-surgeon---` frontmatter in `SKILL.md` makes the skill
auto-discoverable. Claude selects it from the `description:` when the user's
request matches.

---

## OpenCode (open-source)

OpenCode follows the Claude Code skill format. If your version of OpenCode
supports the `skills/` path, the install is identical to Claude Code:

```bash
ln -s "$PWD/pattern-surgeon/skills/pattern-surgeon" \
      ~/.opencode/skills/pattern-surgeon
```

If OpenCode does not yet support skill frontmatter, use the system-prompt
approach below.

---

## Codex CLI (OpenAI)

Codex CLI does not have a skill system. Adapt as follows:

**1. Feed SKILL.md as a system prompt:**

```bash
codex --system-prompt "$(cat skills/pattern-surgeon/SKILL.md)" \
      "Refactor src/checkout.ts — it has a big if-else"
```

**2. Feed pattern files as needed context:**

```bash
codex --system-prompt "$(cat skills/pattern-surgeon/SKILL.md)" \
      --context "$(cat skills/pattern-surgeon/references/patterns/strategy.md)" \
      "Apply Strategy to src/checkout.ts"
```

**3. Use the shell scripts directly:**

```bash
# Before refactoring
SHA=$(bash skills/pattern-surgeon/scripts/checkpoint.sh)

# After the LLM applies edits
bash skills/pattern-surgeon/scripts/verify.sh
if [ $? -ne 0 ]; then
  bash skills/pattern-surgeon/scripts/rollback.sh "$SHA"
fi
```

The safety contract is fully manual with Codex CLI — you control when to run
checkpoint/verify/rollback. The LLM provides the edit; the scripts verify it.

---

## Cursor (IDE)

Cursor uses `.cursorrules` or system-prompt injection, not a CLI skill system.

**Add to `.cursorrules`:**

```
# pattern-surgeon
When the user asks about design patterns, what pattern fits, or asks to
refactor to a pattern, follow this skill:

[paste contents of skills/pattern-surgeon/SKILL.md here]

Pattern reference files are at skills/pattern-surgeon/references/patterns/.
Safety scripts are at skills/pattern-surgeon/scripts/.
```

Cursor can execute shell commands via its terminal integration. The
`verify.sh` / `checkpoint.sh` / `rollback.sh` scripts work unchanged.

---

## Aider

Aider reads context from files you add explicitly. The pattern guides and
SKILL.md work as read-only context.

```bash
aider --read skills/pattern-surgeon/SKILL.md \
      --read skills/pattern-surgeon/references/patterns/strategy.md \
      src/checkout.ts
```

Then prompt: `"Refactor the pricing logic to Strategy pattern, following the
Transform recipe in the SKILL.md context."`

Run the safety scripts manually before and after the edit:

```bash
SHA=$(bash skills/pattern-surgeon/scripts/checkpoint.sh)
# ... aider applies the edit ...
bash skills/pattern-surgeon/scripts/verify.sh || \
  bash skills/pattern-surgeon/scripts/rollback.sh "$SHA"
```

---

## Gemini CLI

Same approach as Codex CLI — feed SKILL.md as system context:

```bash
gemini --system "$(cat skills/pattern-surgeon/SKILL.md)" \
       "What pattern fits lib/pricing.dart?"
```

---

## What you lose without Claude Code's skill system

| Feature | Impact without native skill support |
|---|---|
| Auto-invocation | Must manually feed SKILL.md as context each session |
| Lazy loading | No automatic lazy loading — must feed pattern files manually |
| Follow mode scope cap | LLM may not respect the 20-file cap without explicit instruction |
| One-retry maximum | Must enforce manually (tell the LLM "one retry only") |
| `verify.sh` integration | Must call manually before/after edits |

---

## Making the scripts available to any CLI

Add the scripts to your PATH for convenience:

```bash
export PATH="$PATH:$PWD/pattern-surgeon/skills/pattern-surgeon/scripts"
```

Then any session can call `verify.sh`, `checkpoint.sh`, `rollback.sh` directly.

---

## Porting SKILL.md to another format

If you want to convert the skill to another tool's format (e.g., a Cursor Rule
or an OpenAI Assistant instruction), the conversion is mechanical:

1. Remove the `---` frontmatter block (lines 1–4 of SKILL.md).
2. Paste the remaining content as the system instruction.
3. Replace all `references/patterns/<name>.md` file references with either:
   - Inline content (paste the pattern file), or
   - An instruction to fetch the file from the repo.
4. Replace `scripts/verify.sh` / `checkpoint.sh` / `rollback.sh` with
   instructions to run those scripts via the tool's shell-execution mechanism.

The pattern logic, detection rules, and output contract are all plain prose —
they work with any sufficiently capable LLM.
