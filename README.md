# spacecadet-web

Self-hosted, in-browser build of [SpaceCadetPinball](https://github.com/k4zmu2a/SpaceCadetPinball)
(the decompilation of 3D Pinball for Windows – Space Cadet).

The Dockerfile clones upstream at a pinned commit, applies `patches/`, compiles to
WebAssembly with Emscripten, and serves the result with nginx.

## Game data

Not included (it's Microsoft's, but easily findable if you check the right places). Put the original files in `./gamedata/` — the
contents of the Windows `Pinball` folder (`PINBALL.DAT`, `*.WAV`, `PINBALL.MID`, ...)
or Full Tilt's `CADET.DAT` + `SOUND/`. The browser fetches everything under `/data/`
and loads it into the in-memory filesystem before the game starts.

## Run

Mount the directory holding the game files at `/data` (read-only is fine).
Files can sit at the top level or in subfolders; filenames are matched
case-insensitively. Everything in it is downloaded by every visitor, so leave out
extras like `pinball.exe` or `table.bmp`.

### docker

```sh
docker run -d --name spacecadet --restart unless-stopped \
  -p 8080:80 \
  -v /path/to/Pinball:/data:ro \
  ghcr.io/tommyschnabel/spacecadet-web:latest
# http://localhost:8080
```

### docker compose

```yaml
services:
  spacecadet:
    image: ghcr.io/tommyschnabel/spacecadet-web:latest
    container_name: spacecadet
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - /path/to/Pinball:/data:ro
```

To build from source instead, the repo's `docker-compose.yml` builds the image
and mounts `./gamedata`: `docker compose up -d --build`.

Settings and high scores persist per-browser in IndexedDB.

## Controls

Defaults, rebindable under Options → Player Controls (C):

| Action | Key |
|---|---|
| Left / right flipper | Z / `/` |
| Plunger | Space |
| Bump left / right / bottom | X / `.` / Up |
| New game | N |
| Pause / resume | P |
| Full screen | F |
| Sound effects | E |
| Music (off by default) | M |
| Player controls dialog | C |
| Show / hide menu bar | B |

The flipper and plunger keys are shown in a bar along the bottom of the page and
follow any rebinding.

Function keys are avoided since browsers grab most of them. Exit is unbound:
quitting would just freeze the page.

## Music

The browser build of SDL_mixer has no MIDI synth, so on container start
`render-music.sh` renders every `*.MID` under `/data` to Ogg Vorbis with
fluidsynth + the TimGM6mb soundfont (into `/usr/share/nginx/html/music`, served at
`/music/`). The patched game loads `PINBALL.OGG` before trying `PINBALL.MID`.
Full Tilt's `.MDS` tracks are not rendered.

## Patches

`patches/0001-emscripten-port.patch`:

- CMake: use Emscripten's SDL2/SDL2_mixer ports, link with ASYNCIFY + IDBFS.
- `midi.cpp` / `pch.h`: prefer the pre-rendered `.OGG` track; init Ogg instead of MIDI.
- `options.cpp` / `translations.cpp`: letter shortcuts instead of F-keys (see Controls).
- `winmain.cpp`: replace the blocking frame sleep with `emscripten_sleep` so the
  native main loop yields to the browser; flush high scores + sync IndexedDB every 5s;
  don't force the window to table size (the canvas fills the page, uniform scaling
  keeps the aspect ratio); bottom bar with the flipper/plunger keys; link to this
  repo in Help → About.

Bump upstream by changing `SCP_COMMIT` in the Dockerfile; regenerate the patch if it
stops applying.

## CI / updates

- `.github/workflows/BuildImage.yml` — same as the other repos: build on every
  push/PR; on GitHub, push `ghcr.io/<owner>/spacecadet-web` (`latest` + short sha)
  for amd64 + arm64. The self-hosted runner builds amd64 only, no push.
- `renovate.json` — base images plus a custom manager that tracks upstream's
  `master` commit in `SCP_COMMIT`. A bump that breaks `patches/` fails the build.
