# Build Space Cadet Pinball (k4zmu2a decompilation) for the browser with Emscripten,
# then serve it as static files. Game data (PINBALL.DAT etc.) is NOT included:
# mount it at /data.

# Output is wasm, so the build stage always runs natively; only the nginx
# stage is per-platform.
FROM --platform=$BUILDPLATFORM emscripten/emsdk:3.1.74 AS build

ARG SCP_REPO=https://github.com/k4zmu2a/SpaceCadetPinball.git
ARG SCP_COMMIT=cb9b7b886244a27773f66b0b19fdc2998392565e

WORKDIR /src
RUN git init -q . \
 && git remote add origin "$SCP_REPO" \
 && git fetch -q --depth 1 origin "$SCP_COMMIT" \
 && git checkout -q FETCH_HEAD

COPY patches/ /patches/
RUN for p in /patches/*.patch; do patch -p1 < "$p"; done

# Pre-build SDL ports in their own layer so source edits don't refetch them.
RUN embuilder build sdl2 sdl2_mixer

RUN emcmake cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build -j"$(nproc)"

FROM nginx:1.27.3-alpine
RUN apk add --no-cache fluidsynth soundfont-timgm vorbis-tools
COPY render-music.sh /docker-entrypoint.d/40-render-music.sh
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY web/ /usr/share/nginx/html/
COPY --from=build /src/bin/SpaceCadetPinball.js /src/bin/SpaceCadetPinball.wasm /usr/share/nginx/html/
RUN mkdir -p /data
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/healthz || exit 1
