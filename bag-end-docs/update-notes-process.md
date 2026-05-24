# Bag End — Update Notes Process

This document defines how Bag End tracks implementation updates as roadmap work moves through `develop`.

## Goals

- Keep roadmap progress visible without turning `roadmap.md` into a changelog.
- Record what changed, why it changed, and how it was verified.
- Make it easy to prepare release notes for private beta and public builds later.

## Document Set

Use three documents with distinct purposes:

```text
roadmap.md
High-level product milestones and acceptance criteria.

update-notes-process.md
Rules for how update notes are written and maintained.

updates.md
Chronological implementation notes for completed roadmap work.
```

Create `updates.md` when the first 0.2 implementation batch is ready to record.

## Update Entry Format

Each entry in `updates.md` should use this structure:

```text
## YYYY-MM-DD — Version area

Branch:
Roadmap scope:
Summary:
User-visible changes:
Engineering changes:
Verification:
Known follow-ups:
```

Keep entries factual and short. Link to local docs or code paths when useful, but avoid duplicating implementation details from the code.

## When To Add An Entry

Add or update an entry when one of these happens:

- A roadmap acceptance criterion is completed.
- A user-visible workflow changes.
- A technical decision affects later roadmap work.
- Verification reveals an important limitation or environment issue.
- A release or tester build is prepared.

## Branch Workflow

For roadmap implementation:

```text
develop
Active integration branch for upcoming milestone work.

main
Stable branch for known-good checkpoints.
```

Changes should land on `develop` first. Before merging to `main`, the relevant `updates.md` entry should include verification status and known follow-ups.

## Verification Notes

Record the exact verification level:

```text
Built: command and result
Tested: command and result
Manual: workflow and result
Blocked: reason the check could not run
```

If a check fails because of local environment restrictions, say that explicitly so it is not confused with a product regression.
