import os
from datetime import date

import vobject


def next_occurrence(bday, today):
    next_bday = bday.replace(year=today.year)
    if next_bday < today:
        return next_bday.replace(year=today.year + 1)
    return next_bday


folder = "/home/soft/.local/share/contacts/card"
today = date.today()
window = 30


upcoming = []
for fname in os.listdir(folder):
    if not fname.endswith(".vcf"):
        continue
    path = os.path.join(folder, fname)
    for card in vobject.readComponents(open(path).read()):
        if not hasattr(card, "fn") or not hasattr(card, "bday"):
            # print("No fn or bday, skipping")
            continue

        try:
            bday = date.fromisoformat(card.bday.value)
        except ValueError:
            print("Error parsing iso format string")
            continue

        next_bday = next_occurrence(bday, today)
        days = (next_bday - today).days
        if 0 <= days <= window:
            upcoming.append((next_bday, days, card.fn.value))

for bday, days, name in sorted(upcoming):
    print(f"{bday.strftime('%b %d')}  {name}  ({days} days)")
