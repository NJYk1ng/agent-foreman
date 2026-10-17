"""Word counting helpers."""

import string


def count_words(text):
    """Return a mapping of normalized word -> occurrence count."""
    result = {}
    for token in text.split():
        word = token.strip(string.punctuation).lower()
        if word:
            result[word] = result.get(word, 0) + 1
    return result
