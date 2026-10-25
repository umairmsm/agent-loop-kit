"""Simple calculator module for agent-loop-kit demo."""

def add(a: int | float, b: int | float) -> int | float:
    """Return the sum of a and b."""
    return a + b

def divide(a: int | float, b: int | float) -> float:
    """Return the division of a by b. Raises ValueError on zero division."""
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
