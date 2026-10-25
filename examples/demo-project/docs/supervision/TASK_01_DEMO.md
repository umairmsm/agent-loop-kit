# Task: Implement Multiply Operation (DEMO-01)

You are working autonomously in `examples/demo-project`. Read `AGENTS.md` and `gate.conf` first.

Branch `feature/multiply`   Base `main`

## Hard rules
- Never weaken or skip existing tests.
- One commit per step in Conventional Commits style.
- All checks must pass in `gate.sh`.

### Step 1: DEMO-01 Add Multiply Function
- **Change**: In `src/calculator.py`, add `def multiply(a, b) -> int | float: return a * b`.
- **Tests**: In `tests/test_calculator.py`, add `test_multiply` asserting `multiply(3, 4) == 12` and `multiply(-2, 3) == -6`.
- **Done when**: `python3 -m unittest discover tests` exits 0.
