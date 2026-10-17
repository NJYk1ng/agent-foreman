import unittest

from normalize import normalize_tags


class NormalizeTests(unittest.TestCase):
    def test_case_trim_dedupe_sort(self):
        self.assertEqual(
            normalize_tags([" Python ", "python", "Go", "", " go "]),
            ["go", "python"],
        )

    def test_empty(self):
        self.assertEqual(normalize_tags([]), [])

    def test_duplicates(self):
        self.assertEqual(normalize_tags(["b", "a", "b"]), ["a", "b"])

    def test_all_empty(self):
        self.assertEqual(normalize_tags([" ", "\t"]), [])


if __name__ == "__main__":
    unittest.main()
