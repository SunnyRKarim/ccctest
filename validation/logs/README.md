# Native execution evidence

`stata_native.txt`: licensed StataNow 18.5 SE, `do stata/tests/run_all.do`, including a fresh project-local net installation and offline conference demo. Reached its explicit completion marker with no unhandled Stata return code. Windows process exit code was 0.

`stata_cross_language.txt`: `do stata/tests/cross_language.do`, completed all native exports. `Rscript validation/scripts/cross_language.R` exited 0. `python validation/scripts/compare_exports.py` exited 0: 104 arrays passed, maximum absolute difference 3.19e-11. Detailed differences are in `validation/expected/cross_language_report.json`.

`python_tests.txt`: Python 3.14, `python -m pytest python/tests -q`, exit 0, 31 passed. Editable installation, `python -m build python --no-isolation`, and separate wheel-target import also exited 0. The build emitted a Windows/Dropbox temporary-directory cleanup warning; both archives were created and the wheel was installed and imported successfully.

`r_check.txt`: R 4.5.3, `R CMD build r` then `R CMD check ccctest_0.1.0.tar.gz`, with an existing MiKTeX installation on PATH and LC_ALL=C. Both exited 0; full check Status: OK, including manual and vignette compilation. `R CMD INSTALL --library=artifacts/rlib r` also exited 0.

Logs omit the Stata startup/license banner and replace the local repository/user paths. Generated packages and SHA-256 checksums are retained locally in `artifacts/releases`; they are not public releases. Hosted CI results are recorded in STATUS.md.

Hosted CI run 36665779404 completed successfully on Ubuntu: Python 3.12, 31 passed in 2.05s; R 4.6.1, Status: OK with manual/vignette rebuild explicitly skipped. GitHub emitted infrastructure deprecation notices for Node 20 action versions; these did not affect test execution. The full private execution log is linked from STATUS.md and retained locally in artifacts/hosted_ci.txt.
