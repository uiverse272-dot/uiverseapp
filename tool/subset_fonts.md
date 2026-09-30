# Font subsetting

`assets/fonts/*.ttf` are subsets of the originals in `tool/fonts-src/` (from
Google Fonts, OFL). Regenerate with Python `fonttools` (`pip install fonttools`)
from the repo root:

```sh
U="U+0020-007E,U+00A0-00FF,U+2010-2027,U+2030-203A,U+20AC,U+2190-2193,U+2212,U+2264,U+2265"

# Lexend: static Regular instance of the variable font, then subset.
python -m fontTools varLib.instancer tool/fonts-src/Lexend.ttf wght=400 -o /tmp/Lexend-Regular-full.ttf
python -m fontTools subset /tmp/Lexend-Regular-full.ttf --unicodes="$U" \
  --layout-features='kern,liga,calt,tnum,lnum' --output-file=assets/fonts/Lexend-Regular.ttf

# Space Mono 400 and 700.
for w in Regular Bold; do
  python -m fontTools subset tool/fonts-src/SpaceMono-$w.ttf --unicodes="$U" \
    --layout-features='kern,liga,tnum' --output-file=assets/fonts/SpaceMono-$w.ttf
done
```

The range is Basic Latin, Latin-1, General Punctuation, the euro sign, arrows,
the minus sign and ≤ ≥. If UI copy gains a character outside it, add its code
point to `U` and regenerate — otherwise it falls back to a system font.
Lexend is only used at weight 400 (`UiText.cardTitle`).
