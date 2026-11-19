"""Splits each transcription pass into locked and tentative words.

Reads one transcript per pass and prints "locked<TAB>tentative" for each.
Locked words are never taken back by a later pass.
"""

import sys

PUNCTUATION = ".,!?;:"
# Words that must follow a punctuated word before it locks.
SETTLE = 3


def bare(words):
    return [word.strip(PUNCTUATION).lower() for word in words]


def lock(locked, previous, words):
    """Returns the locked words after the pass `words`."""
    if bare(words[: len(locked)]) != bare(locked):
        return locked
    end = len(locked)
    for before, now in list(zip(previous, words))[end:]:
        if before != now:
            break
        end += 1
    # The last word of a pass is the one most likely to change.
    end = min(end, len(words) - 1)
    # A pass ends in a full stop that later becomes a comma or nothing.
    for index in range(len(locked), end):
        followers = len(words) - 1 - index
        if words[index][-1] in PUNCTUATION and followers < SETTLE:
            end = index
            break
    return locked + words[len(locked) : end]


def main():
    locked, previous = [], []
    for line in sys.stdin:
        words = line.split()
        locked = lock(locked, previous, words)
        previous = words
        tentative = words[len(locked) :]
        # The space goes with the tentative words, so locked only ever grows.
        separator = " " if locked and tentative else ""
        print(
            " ".join(locked),
            separator + " ".join(tentative),
            sep="\t",
            flush=True,
        )


main()
