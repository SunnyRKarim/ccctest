# Publish this package under SunnyRKarim

This snapshot is prepared for a NEW public repository at
https://github.com/SunnyRKarim/ccctest . The source and all validation fixtures
remain intact. This ZIP is not the original Git history.

## Easiest method: GitHub Desktop

1. Download and extract the release ZIP to a folder on your computer.
2. Install/open [GitHub Desktop](https://desktop.github.com/) and log in as SunnyRKarim.
3. Choose File > Clone repository > URL and enter
   `https://github.com/SunnyRKarim/ccctest`.
4. Open the newly cloned `ccctest` folder on your computer, then copy the
   extracted release's **contents** into it. Do not add another `ccctest`
   folder inside the clone.
5. Return to GitHub Desktop. Enter a commit summary such as
   `Initial public release of ccctest`, click **Commit to main**, then **Push origin**.
6. Open https://github.com/SunnyRKarim/ccctest and check that README.md,
   `stata/ccctest.ado`, `r/DESCRIPTION` and `python/src/ccctest/core.py` appear.
7. Check the GitHub Actions page. This repository's CI tests R and Python;
   Stata requires a local installation and is not checked by the hosted workflow.

Do not upload the ZIP itself as a single file to GitHub; publish its extracted
contents. There are many files, so GitHub Desktop is more convenient than
GitHub's browser-based individual-file upload interface.

## Using GitHub CLI instead

After extracting the release ZIP, from its root directory run:

```bash
cd path/to/ccctest

git init -b main
git add .
git commit -m "Initial public release of ccctest"
gh auth login
git remote add origin https://github.com/SunnyRKarim/ccctest.git
git push -u origin main
```

Make sure the GitHub account is `SunnyRKarim`. Do not clone/push the private
repository's existing history unless you deliberately want that history public.

## Important before broader redistribution

Public visibility is NOT the same as an open-source license. The included
LICENSE permits downloading, installing, and executing the unmodified software
for research, teaching, and evaluation, but does NOT permit modification or
redistribution without written permission. Do not choose an MIT, BSD or GPL
license when creating the GitHub repository. GitHub Terms of Service nonetheless
allow other GitHub users to view and fork public repositories within GitHub.

The R DESCRIPTION lists SunnyKarim@cmail.carleton.ca as the maintainer contact.
The maintainer has confirmed that this address may be shown publicly.
