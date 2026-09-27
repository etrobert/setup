---
name: survey-usage
description:
  Surveys how other projects configure or use a tool on GitHub and reports the
  distribution. Use before proposing a config, option, pattern or design, or
  when asked what others do.
---

# Survey usage

Report the distribution rather than one agreeing example:

```bash
gh search code '<distinctive-token>' --extension <ext> --limit 100 \
  --json repository,path,textMatches
gh search issues '<symptom>' --repo <owner/repo>
```

Filter out comment lines and count unique repos, not matches — upstream default
configs are copied verbatim everywhere, so most raw hits are someone's
commented-out example, not a choice anyone made.

The count is evidence, not a verdict. One config Étienne already trusts — the
tool's own author, a repo listed as a reference — outweighs many he doesn't.
