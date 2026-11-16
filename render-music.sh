#!/bin/sh
# Render every MIDI track under /data to Ogg Vorbis in $OUT, keeping the
# relative path and uppercasing the extension (PINBALL.MID -> PINBALL.OGG).
# The browser build of SDL_mixer has no MIDI synth, so the game loads these instead.
# Runs from nginx's /docker-entrypoint.d on every start; existing renders are reused.
set -u
SRC=/data
OUT=/usr/share/nginx/html/music
SF2=/usr/share/soundfonts/TimGM6mb.sf2
mkdir -p "$OUT"

find "$SRC" -type f \( -iname '*.mid' \) | while read -r f; do
    rel=${f#"$SRC"/}
    dst="$OUT/${rel%.*}.OGG"
    [ -s "$dst" ] && continue
    mkdir -p "$(dirname "$dst")"
    wav=$(mktemp /tmp/render.XXXXXX)
    # Not every .MID is music (3DPB's PINBALL2.MID is a bitmap font) - skip failures.
    if fluidsynth -ni -q -g 0.8 -r 44100 -F "$wav" -T wav "$SF2" "$f" >/dev/null 2>&1 \
        && [ "$(wc -c < "$wav")" -gt 100000 ] \
        && oggenc -Q -q 2 -o "$dst" "$wav"; then
        echo "render-music: $rel -> ${dst#"$OUT"/}"
    else
        rm -f "$dst"
        echo "render-music: skipped $rel"
    fi
    rm -f "$wav"
done
