---
name: wt-release
description: Ship a change in wp-core-manager by bumping VERSION and the README badge, adding a CHANGELOG.md entry in the repository format, updating the docs the change affects, and checking the scripts. Use after implementing a feature or fix, or when the user asks to release, bump the version, update the changelog, or finish a change.
---

# WT Release

Run this after the code change is complete. Work through the checklist in order.

```
- [ ] 1. Decide the bump (see versioning rule: patch, minor, major)
- [ ] 2. VERSION
- [ ] 3. README.md badge on line 3
- [ ] 4. CHANGELOG.md entry at the top
- [ ] 5. Docs: README sections and AGENTS.md, if the change affects them
- [ ] 6. Verify
- [ ] 7. Names review
- [ ] 8. Tell the user when devmagic-panel's copy of wpcore needs the change too
- [ ] 9. Suggest the commit message (wt-commit-message)
- [ ] 10. Tag and push the release, only when the user asks
```

## 4. Changelog entry

```markdown
### v1.1.0 (2026-11-04)
* **wpcore:** `wpcore users 6.8` lists the sites on a core
```

`### vX.Y.Z (YYYY-MM-DD)` with today's ISO date, `*` bullets, a bolded area
ending with a colon, present tense, what the user notices. Once per session:
if this session already added an entry, extend it instead of adding another.

## 6. Verify

```bash
bash -n wpcore install.sh
shellcheck -x install.sh && shellcheck -S error wpcore   # needs shellcheck
bash install.sh --dry-run                                # when install.sh changed
```

Report what ran and what passed; if something could not run (shellcheck not
installed), say so. The check workflow runs the same on GitHub, and installs
from a local release into a temp folder.

## 7. Names review

Examples use made-up names only. Before the commit, compare the repository
with the site names on this machine; they are read at that moment and never
written into the repository:

```bash
names=$( { ls /var/www; grep -hoE 'Server(Name|Alias).*' /etc/apache2/sites-available/*.conf; } \
  | grep -oE '[A-Za-z0-9-]{4,}' | tr 'A-Z' 'a-z' | sort -u )
for w in $names; do git grep -qiF "$w" -- . && echo "$w"; done
```

Generic words (`local`, `test`, `wpcore`) are fine. Any hit that names a
client, project, company or person gets a made-up name, and the review runs
again.

## 10. Tag and push

Only when the user asks to release: tag the release commit with a signed tag
that matches `VERSION`, and push it only when they ask. The push starts
`release.yml`, which publishes the GitHub release, so it is public at once. Its last job, `site.yml`, tells webtimeless.cloud, which rebuilds with the release within minutes (with the `SITE_DISPATCH_TOKEN` secret; without it, the site's daily build shows it).

```bash
git tag -s v1.1.0 -m "v1.1.0"
git push origin v1.1.0   # only when asked
```
