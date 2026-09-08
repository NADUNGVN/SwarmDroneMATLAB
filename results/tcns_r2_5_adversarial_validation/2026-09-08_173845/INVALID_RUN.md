# Invalid R2.5 run

This run stopped before the adversarial audit began.  The driver resolved the
frozen R2 artifact relative to MATLAB's temporary `experiments/` working
directory, so `LATEST.txt` was not found.

No numerical result or scientific conclusion was produced in this directory.
The driver was changed to resolve the repository root from its own full path
before the replacement run.
