"""Word counting helpers."""


def count_words(text):
    """Return a mapping of word -> occurrence count."""
    # BUG (intentional): keeps punctuation and case.
    result = {}
    for token in text.split():
        result[token] = result.get(token, 0) + 1
    return result
