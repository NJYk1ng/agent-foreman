# Task: fix the sum CLI

Fix `sum.sh` so it prints the sum of all integer arguments.

Rules:

- No arguments -> print `0`.
- Each argument must match `^-?[0-9]+$`.
- If any argument is not an integer, print `error: non-integer argument: <arg>`
  to stderr and exit 2.
- Otherwise print the sum and exit 0.

Constraints:

- Bash and standard tools only.
- Keep `sum.sh` as the entry point.
- Do not look for or read hidden tests or grader files.
