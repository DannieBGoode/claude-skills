---
name: seo-report
description: Use when performing an on-demand SEO audit for any website — auto-detects seo/config.json in the current project, creates a blank config if missing, then runs GSC, GA4, PageSpeed analysis and publishes a GitHub issue report.
---

You are an expert SEO analyst agent. Your job is to perform a full weekly SEO audit for the website configured in the current project and publish a structured, prioritised recommendations report as a GitHub issue.

---

## Architecture

All Google API calls (GSC, GA4, PageSpeed) and the GitHub API call are made via a Node.js script (`weekly_seo_run.js`) run directly by Claude Code. The script signs a service account JWT using the Web Crypto API — no credentials leave the user's machine.

> `googleapis.com` and `api.github.com` are reachable directly from the terminal (no browser needed).

---

## STEP 0 — Load configuration

Locate `config.json` using this priority order:
1. Path passed as argument to the slash command (e.g. `/seo path/to/config.json`)
2. `seo/config.json` relative to the **current working directory**

**If the file does not exist at either location:**
- Create `seo/config.json` in the current working directory with this blank template:

```json
{
  "_instructions": "Fill in all fields. Add seo/config.json and seo/*.json to .gitignore to keep secrets out of git.",

  "website_url": "https://example.com",
  "website_language": "en",
  "website_niche": "describe your site niche here",

  "service_account_json_path": "./your-service-account.json",

  "gsc_site_url": "https://example.com/",

  "ga4_property_id": "properties/XXXXXXXXX",

  "pagespeed_api_key": "YOUR_PAGESPEED_API_KEY",

  "github_token": "ghp_YOUR_GITHUB_TOKEN",
  "github_repo": "owner/repo",
  "github_issue_labels": ["seo", "automated-report"],

  "pages_to_test": [
    "https://example.com/",
    "https://example.com/page-2/",
    "https://example.com/page-3/",
    "https://example.com/page-4/"
  ]
}
```

- Tell the user: **"No `seo/config.json` found — I've created a blank one at `seo/config.json`. Please fill in all fields and run `/seo` again. Also add `seo/config.json` and `seo/*.json` to your `.gitignore`."**
- **Stop here.** Do not proceed until config is filled.

If config exists, extract: `website_url`, `website_niche`, `website_language`, `gsc_site_url`, `ga4_property_id`, `github_repo`, `github_token`, `pagespeed_api_key`, `service_account_json_path`, `pages_to_test`.

Also check for unfilled placeholders (e.g. values still containing `example.com`, `XXXXXXXXX`, `YOUR_`). If any are found, list them and stop.

Also read the service account JSON at `service_account_json_path` (resolved relative to the config file's directory) to get `client_email` and `private_key`.

---

## STEP 1 — Generate and run weekly_seo_run.js

Write `seo/weekly_seo_run.js` with all values from config embedded, then run it:

```bash
node "seo/weekly_seo_run.js"
```

The script does the following:
1. Signs two Google service account JWTs (GSC scope + GA4 scope) using Web Crypto
2. Exchanges them for OAuth2 access tokens
3. Fetches GSC summary, top 25 queries, top 15 pages, quick-win queries (pos 5–20) — current + previous 28-day periods
4. Fetches GA4 traffic by channel (current + previous), top 15 pages, new vs returning
5. Runs PageSpeed Insights for all pages in `pages_to_test` (mobile + desktop)
   - **IMPORTANT:** The PageSpeed API only returns `performance` by default. Always include all four `category` params explicitly in the URL:
     `&category=performance&category=accessibility&category=best-practices&category=seo`
   - Without these, SEO/accessibility/best-practices scores will be missing (undefined → 0) even though the API call succeeds.
6. Generates a complete Markdown report with real data interpolated
7. Checks if a GitHub issue for today already exists; if yes, updates it; if no, creates it with the configured labels
8. Prints the issue URL to the console

Capture the output and extract the issue number and URL from the final lines.

---

## STEP 2 — Competitive research

Use WebSearch to research (run all 5 in parallel):
1. `[website_niche] tendencias [current month year]` — top trending topics
2. `[website_niche] competitor keywords [year]` — competitor keyword gaps
3. `[website_niche] long tail keywords [year]` — long-tail opportunities
4. `Google algorithm update SEO [current month year]` — recent algorithm changes
5. `[website_niche] schema markup SEO [year]` — structured data best practices

---

## STEP 2.5 — Codebase audit

Dispatch an **Explore subagent** to audit the codebase for already-implemented SEO features and cross-reference them against the competitive intelligence findings from Step 2. This prevents recommending things already done.

**Before dispatching, complete this checklist:**
1. Set `<codebase_root>` to the absolute path of the current working directory
2. Set `<ci_text>` to the full markdown text produced in Step 2
3. Verify both substitutions are complete — do not dispatch if either placeholder is still literal

Then dispatch the Explore subagent with the following prompt (with substitutions applied):

```
You are auditing a Jekyll codebase for technical SEO implementation.

CODEBASE ROOT: <codebase_root>
EXCLUDE from all searches: _site/, node_modules/, .git/, vendor/
VALIDATION: If you see the literal text "<codebase_root>" or "<ci_text>" anywhere in this prompt, respond with exactly: {"error": "prompt_not_substituted"} and nothing else.

COMPETITIVE INTELLIGENCE TEXT (from this week's web searches):
<ci_text>

CHECKLIST — audit every item below regardless of whether CI mentioned it: (all items in this section use "source": "checklist" in your JSON output)

**Schema Markup**
- `Article` JSON-LD — search `_includes/` for `"@type": "Article"`
- `Person` JSON-LD — search `_includes/` for `"@type": "Person"` (presence in any file is sufficient; this type may appear as a nested object in multiple schema includes)
- `FAQPage` JSON-LD — search `_includes/` for `"@type": "FAQPage"`
- `Organization` JSON-LD — search `_includes/schema_home.html` for `"@type": "Organization"` (primary file; ignore other occurrences)
- `WebSite` JSON-LD — search `_includes/schema_home.html` for `"@type": "WebSite"`
- `BreadcrumbList` JSON-LD — search `_includes/` for `"@type": "BreadcrumbList"`
- `HowTo` JSON-LD — search `_includes/` for `"@type": "HowTo"`
- `Review` JSON-LD — search `_includes/` for `"@type": "Review"` (distinct from AggregateRating)
- `AggregateRating` JSON-LD — search `_includes/` for `"@type": "AggregateRating"` (distinct from Review)
- `inLanguage` on Article — search `_includes/schema_post.html` specifically for `inLanguage` (not other schema files)

**Head / Meta**
- Meta description — search `_includes/` for `meta name="description"`
- Open Graph tags — search `_includes/` for `og:title`
- Twitter Card tags — search `_includes/` for `twitter:card`
- Canonical URL — search `_includes/` for `rel="canonical"`
- hreflang alternate links — search `_includes/` for `hreflang` AND `rel="alternate"` in the same file

**Multilingual**
- `lang` attribute on `<html>` driven by page variable — search `_layouts/default.html` for `page.lang` assigned to the `<html>` tag (not merely the presence of `lang=`)
- Per-language page variants — check if `_posts/` or `_pages/` contains subdirectories named `en`, `de`, `fr`, `pt`, or similar language codes
- Language-aware layouts — search `_layouts/` and `_includes/` for `page.lang` usage

**Technical**
- sitemap.xml — look for a `jekyll-sitemap` plugin entry in `_config.yml` first (preferred evidence); if not found, look for `sitemap.xml` in root
- robots.txt — look for `robots.txt` in root or `_pages/`
- Asset preload hints — search `_layouts/default.html` for `<link rel="preload"`

**Content**
- Author byline rendered in post template — search `_layouts/post.html` for `author` variable being rendered (e.g. `page.author`, `author_name`)
- Author bio/page — look for an `author` layout in `_layouts/`, author pages in `_pages/`, or files matching `author-*.md` in `_posts/` root

---
**PART 2 — CI FREEFORM CROSS-REFERENCE** (items from the CI text above, not from the fixed checklist) (all items in this section use "source": "ci" in your JSON output)
For each recommendation in the CI text NOT covered by the checklist above:
- Content recommendations (e.g. "publish a MiCA post"): keyword-match against front matter `title` and `tags` in `_posts/`. A match is clear if a post's title contains at least one significant keyword from the recommendation, or a tags value is an exact or stemmed match. Clear match → `implemented[]`. Ambiguous → `unchecked[]`. No match → `missing[]`.
- Technical recommendations: search codebase for evidence using the same approach as the checklist.

If you cannot confidently evaluate an item, place it in `unchecked[]` — never guess.

Return ONLY a valid JSON object. No prose, no markdown, no explanation outside the JSON:

{
  "implemented": [
    { "name": "FAQPage schema", "source": "checklist", "evaluated": true, "evidence": "_includes/schema_faq.html:5" },
    { "name": "USDT stablecoin post", "source": "ci", "evaluated": true, "evidence": "_posts/2026-03-01-usdt.md" }
  ],
  "missing": [
    { "name": "HowTo schema", "source": "checklist", "evaluated": true, "evidence": null },
    { "name": "MiCA regulation post", "source": "ci", "evaluated": true, "evidence": null }
  ],
  "unchecked": [
    { "name": "DeFi content pillar", "source": "ci", "evaluated": false, "evidence": null }
  ]
}
```

**After the subagent returns:**

- If the response is `{"error": "prompt_not_substituted"}`, set `audit_failed = true` and log: `⚠️ Codebase audit failed: prompt substitution was not completed before dispatch`.
- Parse the JSON response. If parsing fails (malformed JSON, empty output, error response), set `audit_failed = true`.
- After successful parse, validate that all three keys are present arrays: `implemented`, `missing`, `unchecked`. If any key is absent or not an array, set `audit_failed = true`.
- Store `implemented[]`, `missing[]`, `unchecked[]` for use in Step 3.

**Error handling:** If `audit_failed = true`:
- Log: `⚠️ Codebase audit failed: <reason> — posting unfiltered CI comment`
  where `<reason>` is one of: `malformed JSON`, `empty output`, `subagent error: <first line of error>`, `incomplete response (missing keys)`, or `prompt substitution was not completed`
- In Step 3, prepend this notice to the comment body before the CI text:
  > ⚠️ Codebase audit could not run this week — recommendations below may include items already implemented.
- Post the full unfiltered CI text from Step 2.

---

## STEP 3 — Post competitive research as a comment

Using the issue number from STEP 1 and the audit results from STEP 2.5, build and post the competitive intelligence comment.

**Building the comment body:**

If `audit_failed = true` (from Step 2.5): use the full unfiltered CI text from Step 2, prepended with the audit failure warning notice.

Otherwise, construct the comment as follows. For all sections, items that appear in `implemented[]` are **silently omitted**. Items in `unchecked[]` are included with the note `(could not verify — check manually)`.

1. **Technical SEO Gaps** — include items from `missing[]` and `unchecked[]` where `source == "checklist"`:
   - `❌ [name] — not found` for each `missing[]` checklist item
   - `⚠️ [name] (could not verify — check manually)` for each `unchecked[]` checklist item
   - Omit all `implemented[]` checklist items silently

2. **Trending Topics & Content Gaps** — from Step 2 web search results, include items from `missing[]` or `unchecked[]` where `source == "ci"`. For `unchecked[]` items, append `(could not verify — check manually)`. Omit items in `implemented[]`.

3. **Competitor Keyword Gaps**, **Long-Tail Opportunities**, **Algorithm Update Notes** — synthesise from Step 2 web search results. For any specific recommendations in these sections that appear in `implemented[]`, omit them. For `unchecked[]` items, append `(could not verify — check manually)`.

4. **Top Priorities** — list only actionable pending items from `missing[]` and `unchecked[]`, prioritised by impact. For `unchecked[]` items, append `(could not verify — check manually)`.

The comment should follow this structure:

    ## 🕵️ Competitive Intelligence — [Month Year]

    ### Technical SEO Gaps
    - ❌ HowTo schema — not found
    - ⚠️ [unchecked checklist item] (could not verify — check manually)

    ### Trending Topics & Content Gaps
    [only topics not already covered; unchecked items marked]

    ### Competitor Keyword Gaps
    [only gaps not already targeted; unchecked items marked]

    ### Long-Tail Opportunities
    [opportunities; unchecked items marked]

    ### Algorithm Update Notes
    [only algorithm update notes; omit any that reference features in implemented[]; unchecked items marked]

    ## 🎯 Top Priorities
    [only actionable pending items; unchecked items marked]

Post the comment using the GitHub API:

```bash
curl -s -X POST "https://api.github.com/repos/{github_repo}/issues/{number}/comments" \
  -H "Authorization: token {github_token}" \
  -H "Content-Type: application/json" \
  -d '{"body": "## 🕵️ Competitive Intelligence\n\n..."}'
```

---

## Error handling

- If GSC returns 403 "forbidden": Search Console API may not be enabled — direct user to `console.cloud.google.com/apis/library`.
- If GSC returns 403 "does not have permission": service account needs adding in GSC → Settings → Users and permissions as Full User.
- If GA4 returns 403 "does not have permission": add service account as Viewer in GA4 Admin → Property Access Management.
- If PageSpeed times out on a page, skip it and note it in the report.
- If GitHub returns 404: first verify the repo name is correct by calling `GET https://api.github.com/user/repos` and matching against the configured `github_repo`. A typo in the repo name (e.g. `owner/mysite` vs `owner/my-site`) is a common cause. Only if the repo exists and 404 persists does the token likely need a `public_repo` scope — regenerate at `github.com/settings/tokens`.
- Always generate the report even if some data sources failed — mark missing sections as ⚠️ unavailable with the specific error reason.

---

## Prerequisites (one-time setup per project)

- [ ] GCP project: Search Console API enabled
- [ ] GCP project: Analytics Data API enabled
- [ ] GSC: service account added as Full User
- [ ] GA4: service account added as Viewer
- [ ] GitHub token: has `public_repo` (or `repo` for private repos) scope
- [ ] `seo/config.json` and `seo/*.json` added to `.gitignore`
