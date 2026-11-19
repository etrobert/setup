"""Splits each transcription pass into locked and tentative words.

Reads one transcript per pass and prints "locked<TAB>tentative" for each.
Locked words are never taken back by a later pass.
"""

import difflib
import sys

PUNCTUATION = ".,!?;:"
# Consecutive passes that must agree on a word before it locks.
AGREE = 4
# Words that must follow a punctuated word before it locks.
SETTLE = 3


def bare(words):
    return [word.strip(PUNCTUATION).lower() for word in words]


def rest(locked, words):
    """The words of a pass that come after the locked ones.

    A pass can reword what is already locked, so the locked words are
    aligned with it rather than counted off.
    """
    matcher = difflib.SequenceMatcher(None, bare(locked), bare(words), False)
    blocks = [block for block in matcher.get_matching_blocks() if block.size]
    if not blocks:
        return words[len(locked) :]
    last = blocks[-1]
    unmatched = len(locked) - (last.a + last.size)
    return words[last.b + last.size + unmatched :]


def settled(tails):
    """How many leading words of the latest tail can lock."""
    latest = tails[-1]
    end = 0
    for column in zip(*tails):
        if len(set(column)) != 1:
            break
        end += 1
    # The last word of a pass is the one most likely to change.
    end = min(end, len(latest) - 1)
    # A pass ends in a full stop that later becomes a comma or nothing.
    for index in range(max(end, 0)):
        followers = len(latest) - 1 - index
        if latest[index][-1] in PUNCTUATION and followers < SETTLE:
            return index
    return max(end, 0)


def main():
    locked, passes = [], []
    for line in sys.stdin:
        passes = passes[1 - AGREE :] + [line.split()]
        if len(passes) == AGREE:
            tails = [rest(locked, words) for words in passes]
            locked += tails[-1][: settled(tails)]
        tentative = rest(locked, passes[-1])
        # The space goes with the tentative words, so locked only ever grows.
        separator = " " if locked and tentative else ""
        print(
            " ".join(locked),
            separator + " ".join(tentative),
            sep="\t",
            flush=True,
        )


main()
