import unittest

from wordcount import count_words


class WordCountTests(unittest.TestCase):
    def test_case_and_punctuation(self):
        self.assertEqual(
            count_words("Hello hello world!"),
            {"hello": 2, "world": 1},
        )

    def test_empty(self):
        self.assertEqual(count_words(""), {})

    def test_multiple_punctuation(self):
        self.assertEqual(count_words("One, two; two.  "), {"one": 1, "two": 2})

    def test_quotes(self):
        self.assertEqual(count_words("'hello' (hello)"), {"hello": 2})


if __name__ == "__main__":
    unittest.main()
