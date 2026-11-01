# Portfolio website — Nadavaluru Sashank

Personal portfolio, hosted for free with GitHub Pages.

- **Live site:** https://nadavalurusashank.github.io/Portfolio_website/
- **Edit link:** https://github.com/NadavaluruSashank/Portfolio_website/edit/main/index.html

The whole site is one file, `index.html` (HTML, CSS and JavaScript inline). There's no build step: GitHub Pages serves `index.html` from the `main` branch root.

> Keep this repository **public**. On a free GitHub plan, GitHub Pages can't publish from a private repository, and the site goes offline (404).

## How to edit your content

All text lives in one block near the top of `index.html`, called `const DATA = { ... }`.

1. Open the edit link above (you need to be logged in to GitHub).
2. Find `const DATA` (Ctrl/Cmd + F).
3. Change the text **between the quotes**. Keep the quotes, commas and brackets as they are.
4. Click **Commit changes…** → **Commit changes** (commit directly to `main`).
5. Wait about 1 minute, then refresh the live site. You can watch the deploy under the repo's **Actions** tab ("pages build and deployment").

You don't need to touch the CSS or JavaScript below the DATA block.

### What each DATA field controls

| Field | What it shows |
|---|---|
| `name`, `role`, `location`, `status`, `tagline` | Hero section at the top |
| `availability` | Availability sentence in the Contact section and in Profile Q&A |
| `cvUrl` | Download CV button (hidden while empty; see below) |
| `links` | Email, LinkedIn and GitHub buttons |
| `highlights` | The four numbers in the "Evidence" card. Only use numbers you can back up |
| `about`, `now` | About section cards |
| `experience` | Experience tabs (newest first). Each job has `title`, `org`, `dates`, `points`, `stack` |
| `projects` | Project cards. The first one is the large featured card. Optional `notes` adds caveats; optional `pipeline` and `compare` only apply to the featured card |
| `certifications` | Certifications. Add `link` for a public verification page |
| `education`, `skills`, `spoken` | Education, skills and languages |

### Common edits

**Add a job:** copy one `{ title: ..., ... }` block inside `experience`, paste it at the top (newest first), and change the text.

**Add a project:** copy one block inside `projects`. Put it first only if it should become the featured project. Make sure `link` points to a **public** repository, otherwise the "View code" button leads to a 404.

**Change the email:** update `links.email`. Also update the email in the `<noscript>` block and the JSON-LD block in `<head>`, which are written out by hand.

### Adding the Download CV button

1. In the repo, click **Add file → Upload files** and upload your approved CV PDF. Name it `cv.pdf`.
2. In `index.html`, set `cvUrl: "cv.pdf"`.
3. Commit. The button appears in the hero, in the Contact section, in the command menu and in Profile Q&A.

To replace the CV later, upload a new file with the same name (`cv.pdf`). No code change is needed.

## Profile Q&A box

The "Profile Q&A" box answers with **fixed keyword rules** over the DATA block. It is **not** an AI model, makes no network calls and needs no API key. Never put API keys or secrets in this repository: everything in it is public.

## Features

- Responsive layout (desktop, tablet, mobile) with a mobile menu
- Dark and light themes (remembered per browser)
- Command menu: Ctrl/Cmd + K
- Keyboard accessible: skip link, visible focus outlines, ARIA labels, arrow keys in the experience tabs
- Respects "reduce motion" system settings (no animations, static 3D background)
- The Three.js 3D background loads after the content, is lighter on phones and low-power devices, pauses when the tab is hidden, and is skipped in data-saver mode. If it, the web fonts or the profile photo fail to load, the page still works and stays readable.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole site |
| `README.md` | This guide |
| `cv.pdf` | (optional) Your CV for the Download CV button |
