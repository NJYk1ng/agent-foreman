"""Tag normalization helpers."""


def normalize_tags(tags):
    """Return normalized tags."""
    # BUG (intentional): no trim, lowercase, dedupe, or sort.
    return list(tags)
