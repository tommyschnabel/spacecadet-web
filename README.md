# spacecadet-web

Self-hosted, in-browser build of [SpaceCadetPinball](https://github.com/k4zmu2a/SpaceCadetPinball)
(the decompilation of 3D Pinball for Windows – Space Cadet).

The Dockerfile clones upstream at a pinned commit, applies `patches/`, compiles to
WebAssembly with Emscripten, and serves the result with nginx.

## Game data

Not included (it's Microsoft's). Put the original files in `./gamedata/` — the
contents of the Windows `Pinball` folder (`PINBALL.DAT`, `*.WAV`, `PINBALL.MID`, ...)
or Full Tilt's `CADET.DAT` + `SOUND/`. The browser fetches everything under `/data/`
and loads it into the in-memory filesystem before the game starts.

## Run

```sh
docker compose up -d --build
# http://localhost:8080
```

Settings and high scores persist per-browser in IndexedDB.

## Patches

`patches/0001-emscripten-port.patch`:

- CMake: use Emscripten's SDL2/SDL2_mixer ports, link with ASYNCIFY + IDBFS.
- `winmain.cpp`: replace the blocking frame sleep with `emscripten_sleep` so the
  native main loop yields to the browser; flush high scores + sync IndexedDB every 5s.

Bump upstream by changing `SCP_COMMIT` in the Dockerfile; regenerate the patch if it
stops applying.
