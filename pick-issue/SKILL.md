---
name: pick-issue
description: Use when the user wants to see what to work on next, pick a GitHub issue to tackle, or start working on an open issue from the current repository. Triggers on "what should I work on", "pick an issue", "next task", "show me open issues", or "start working on issue".
---

# Pick Issue

## Overview

Fetch open GitHub issues, read each one in full (body + all comments), synthesize concrete actionable tasks from the content, then present a menu for the user to pick from. Only start working after the user selects.

## Process

### 1. Find GitHub credentials

Check in this order:
1. `seo/config.json` — fields `github_token` and `github_repo`
2. `AGENTS.md` / `CLAUDE.md` — look for a `repository:` field
3. `git remote get-url origin` — parse owner/repo from the URL
4. Ask the user

### 2. Fetch All Open Issues

```bash
curl -s -H "Authorization: token <TOKEN>" \
  "https://api.github.com/repos/<OWNER>/<REPO>/issues?state=open&per_page=50" \
  | node -e "
let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
  const issues = JSON.parse(d);
  issues.forEach(i => {
    const labels = (i.labels||[]).map(l=>l.name);
    console.log(JSON.stringify({number:i.number, title:i.title, labels, comments:i.comments, body:i.body, updated:i.updated_at}));
  });
});
"
```

### 3. Read Full Content of Every Issue

For **each issue**, fetch the complete body and all comments before forming any opinion:

```bash
# Full issue body (already in list response, but re-fetch if body was truncated)
curl -s -H "Authorization: token <TOKEN>" \
  "https://api.github.com/repos/<OWNER>/<REPO>/issues/<NUMBER>"

# All comments
curl -s -H "Authorization: token <TOKEN>" \
  "https://api.github.com/repos/<OWNER>/<REPO>/issues/<NUMBER>/comments"
```

Do this for every issue, in parallel if possible. Do not skip any issue because the title seems obvious — comments often contain constraints, prior attempts, partial solutions, or scope changes that are not in the title.

### 4. Synthesize and Present

After reading everything, present a menu grouped by priority. For each issue show:
- Issue number and title
- Labels
- **All concrete, specific tasks** derived from the full body and comments — not a restatement of the title. If a comment contains a structured task list (table, numbered list, action items), reproduce it in full — do NOT summarize or truncate it to save space. The point of this skill is to surface that content, not hide it.
- Whether there are unresolved discussions or blockers mentioned in comments

Priority order:
1. `bug` / `critical`
2. `high-priority` / `enhancement`
3. Most recently updated
4. Everything else

Example output:
```
Open issues (3 total) — full context read:

BUGS
  1. #47  Calculator returns NaN for large inputs  [bug]
     → Reproduce: enter value > 999,999,999 in compound calculator
     → Fix input validation in js/calculator.js before parseFloat()
     → Add Jest test case for boundary values
     → Comment from @user: "happens on mobile too"

ENHANCEMENTS
  2. #79  [SEO Report] Weekly Analysis 2026-03-15  [seo, automated-report]
     → Fix broken GSC property URL in report (comment says it's fetching wrong domain)
     → Comment from @user contains 10 prioritized action items — reproduce them all:
        🔴 HIGH  Add author bylines + bio pages + Person schema (E-E-A-T compliance)
        🔴 HIGH  Implement FAQPage schema on all explainer pages (~82% CTR uplift)
        🔴 HIGH  Publish "Alternativas a Binance España 2026" with Kraken affiliate
        🔴 HIGH  Add Organization + WebSite schema to default.html layout
        🟡 MED   Write tax guide "Cómo declarar criptomonedas en la Renta 2026"
        🟡 MED   Stablecoin series targeting LATAM inflation-hedge queries
        🟡 MED   FinancialProduct/Currency schema on coin pages
        🟡 MED   "Cómo usar Kraken desde España — guía paso a paso 2026"
        🟢 LOW   Country-specific guides for Argentina/México/Colombia
        🟢 LOW   AEO answer blocks for AI search citation

  3. #14  Most profitable coin per day/week/month  [new feature]
     → Integrate CoinGecko /coins/markets?order=price_change_percentage_24h_desc
     → Add a new page /most-profitable/ with a sortable table (day/week/month tabs)
     → Wire into existing marketcaps.js pattern
     → No comments — original request from 2018, check if still relevant

Which issue do you want to work on? (enter a number)
```

### 5. User Picks

Wait for selection. Accept list number or issue number (`#47` or `47`).

### 6. Start Working

Announce:
> "Working on #N: [title]"
> One sentence on the specific approach.

Then follow the appropriate workflow:
- **Bug**: invoke `superpowers:systematic-debugging`
- **Feature / enhancement**: invoke `superpowers:brainstorming` then `superpowers:writing-plans`
- **Content task**: read `docs/product-marketing.md` if it exists, then proceed
- **SEO / report follow-up**: invoke `seo-audit` if relevant

### 7. Close With a Trace

When done, always leave a record on the issue:

```bash
# Comment summarizing what was done
curl -s -X POST -H "Authorization: token <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"body":"..."}' \
  "https://api.github.com/repos/<OWNER>/<REPO>/issues/<NUMBER>/comments"

# Close if fully resolved
curl -s -X PATCH -H "Authorization: token <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"state":"closed"}' \
  "https://api.github.com/repos/<OWNER>/<REPO>/issues/<NUMBER>"
```

## Options

| Input | Behavior |
|---|---|
| `/pick-issue` | Show all open issues, fully read |
| `/pick-issue bugs` | Filter to bug issues only |
| `/pick-issue label:seo` | Filter by label |
| `/pick-issue milestone:v2` | Filter by milestone |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Showing the list before reading all issues | Read everything first, then present — the synthesis is the value |
| Summarizing the title as the task | Derive specific tasks from body + comments, not from the title |
| Truncating a comment's task list to "2–4 items" | If a comment has 10 action items, show all 10 — completeness is the point |
| Skipping comments because title seems clear | Comments are where scope, constraints, and prior attempts live |
| Not leaving a trace when done | Always comment before closing |
| Working on multiple issues at once | Finish one before picking another |
