---
name: product-marketing
description: Use when creating or updating marketing context documentation for a project. Triggers on "product-marketing", "marketing doc", "marketing context", "create docs/product-marketing.md", or when the user wants to document target audience, competitors, SEO strategy, or brand voice for agents to use.
---

# Product Marketing Documentation

## Overview

Analyze the codebase, ask the user targeted questions, and generate `docs/product-marketing.md` — a persistent context file that any agent can read to work on marketing, SEO, or content strategy without re-asking the same questions.

## Process

### 1. Analyze the Codebase First

Before asking anything, read:
- `README.md` — project overview and purpose
- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` — instructions and project notes
- `package.json`, `Gemfile`, `pyproject.toml`, `_config.yml` — tech stack and config
- Any existing `docs/` files
- Homepage or landing page templates (look for `index.html`, `_pages/`, `src/pages/index.*`)
- Existing meta tags, OG tags, sitemaps, analytics snippets

Infer what you can. Note what's already known so you don't ask redundant questions.

Also check if `docs/product-marketing.md` already exists — if it does, read it and offer to update specific sections rather than regenerating from scratch.

### 2. Ask the User — One Message, All Questions

Present all questions at once. Pre-fill anything you inferred from the codebase and ask the user to confirm or correct.

**Product:**
1. What problem does this solve, and for whom? *(target audience)*
2. What makes this different from alternatives? *(unique value proposition)*
3. Who are the main competitors?

**Marketing:**
4. What are your primary marketing goals? *(traffic, leads, brand awareness, sales, etc.)*
5. Which channels are you using or targeting? *(SEO, social, email, paid, affiliate, etc.)*
6. What brand voice/tone should content follow? *(e.g., expert, casual, educational, conversational)*

**SEO:**
7. What are the 3–5 primary keywords or topic clusters to rank for?
8. Target language(s) and geographic market(s)?
9. Do you have Google Search Console or Analytics set up? *(property IDs if known)*

**Content & Monetization:**
10. What content types do you produce or plan to? *(blog, tutorials, tools, comparisons, guides)*
11. What monetization is in place or planned? *(affiliate programs, ads, subscriptions, products — include codes/IDs)*

### 3. Generate `docs/product-marketing.md`

Create the file at `docs/product-marketing.md` using all gathered information:

```markdown
# Product Marketing Guide

> This file provides marketing, SEO, and content context for AI agents working on this project.
> Update it whenever strategy, audience, or positioning changes.

## Product Overview

[1–2 paragraphs: what it is, who it's for, the problem it solves]

## Target Audience

- **Primary:** [description — role, needs, technical level]
- **Secondary:** [description]
- **Key pain points:** [bulleted list]
- **Where they hang out:** [communities, platforms, search terms they use]

## Competitive Landscape

| Competitor | Strengths | Weaknesses | Our Differentiator |
|------------|-----------|------------|--------------------|
| [Name]     | ...       | ...        | ...                |

## Unique Value Proposition

[1–2 sentences: the single most compelling reason to choose this over alternatives]

## Brand Voice & Tone

- **Voice:** [e.g., knowledgeable but approachable]
- **Tone:** [e.g., educational, direct, encouraging]
- **Avoid:** [e.g., hype, jargon, condescending explanations]
- **Example phrases:** [optional: sample copy that nails the tone]

## Marketing Goals

1. [Primary goal]
2. [Secondary goal]
3. ...

## Marketing Channels

- **Active:** [list]
- **Planned:** [list]
- **Not pursuing:** [list — helps agents not suggest these]

## SEO Strategy

### Primary Keywords

| Keyword / Topic | Intent | Priority |
|-----------------|--------|----------|
| [keyword]       | informational / transactional / navigational | high/med/low |

### Target Markets

- **Languages:** [list]
- **Geographies:** [list]

### Technical SEO Notes

[Existing setup: sitemap URL, analytics IDs, canonical strategy, hreflang setup, etc.]

## Content Strategy

### Content Types

[Blog posts, comparison pages, how-to guides, tools, calculators, etc. — and their purpose]

### Content Pillars / Topic Clusters

[Core subject areas to build topical authority around]

### Content Guidelines

- Minimum length for blog posts: [e.g., 800 words]
- Always include: [e.g., a CTA, related links, affiliate disclosure if applicable]
- Internal linking strategy: [notes]

## Monetization

[For each method:]
- **[Method name]:** [details, affiliate program name, codes/IDs, where banners live in the codebase]

## Key Pages

| Page | URL | SEO / Marketing Purpose |
|------|-----|-------------------------|
| Homepage | / | [purpose] |
| [Page name] | /path | [purpose] |

## Analytics & Tracking

- **Google Analytics:** [property ID or N/A]
- **Google Search Console:** [verified? domain?]
- **Other:** [list]

## Action Items

[Immediate marketing/SEO tasks identified during this session — clear these once done]
```

### 4. Update Agent Config Files

After creating `docs/product-marketing.md`, update the project's agent config file(s) to reference it. This ensures future agents automatically load the marketing context.

**Check for these files in order:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`. Update whichever exist. If none exist, create `CLAUDE.md`.

Add a section like this (adapt heading style to match the existing file):

```markdown
## Marketing & SEO Context
Full marketing strategy, target audience, competitive landscape, SEO goals, content strategy, and monetization details are documented in `docs/product-marketing.md`. Read it before working on any content, SEO, or marketing tasks.
```

Then:
- Confirm the file was saved and which config file(s) were updated.
- List any monetization opportunities identified in the codebase that aren't yet documented (e.g., affiliate links in templates without corresponding config entries).
