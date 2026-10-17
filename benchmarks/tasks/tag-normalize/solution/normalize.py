"""Tag normalization helpers."""


def normalize_tags(tags):
    """Return normalized tags."""
    result = set()
    for tag in tags:
        cleaned = tag.strip().lower()
        if cleaned:
            result.add(cleaned)
    return sorted(result)
