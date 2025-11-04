# blinkbridgeARM64
Fork of https://github.com/roger-/blinkbridge for ARM64 with 0.24.1 BlinkPy.

# blinkbridge:ARM64 build

 - Overview: ARM64-friendly, uses BlinkPy 0.24.x with prompt-based 2FA; streams to MediaMTX; tested with Frigate
  - Requirements: Docker + Compose
  - Setup:
      - Copy blinkbridge/config/config.example.json to blinkbridge/config/config.json
      - Fill in Blink credentials and camera names (exact matches)
      - Do not commit secrets (.gitignore excludes them)
  - One-time 2FA bootstrap:
      - docker build --no-cache -t blinkbridge:local blinkbridge
      - docker compose run --rm blinkbridge
      - Enter the 2FA code when prompted; credentials saved to ./blinkbridge/config/.cred.json
  - Normal run:
      - docker compose up -d
      - Logs print “RTSP READY: rtsp://mediamtx:8554/<camera>”
      - For consumers outside compose, use host IP instead of mediamtx
  - Troubleshooting:
      - DNS errors during run are expected — use compose up for DNS
      - If rate-limited during 2FA, wait and retry
      - Re-auth: move ./blinkbridge/config/.cred.json and repeat bootstrap
  - Differences from upstream:
      - 2FA handshake for BlinkPy 0.24.x (prompt_2fa → set otp → setup_post_verify → restart)
      - ARM64-friendly base image and compose wiring
      - Single /working mount to avoid overlap


# blinkbridge original readme

**Note**: there is an issue related to local storage systems; please see issue [#1](https://github.com/roger-/blinkbridge/issues/1) for a temporary fix until it's resolved.

blinkbridge is a tool for creating an RTSP stream from a [Blink camera](https://blinkforhome.com/) using [FFmpeg](https://ffmpeg.org/) and [MediaMTX](https://github.com/bluenviron/mediamtx). Blink cameras are>

Due to the slow polling rate of BlinkPy, there will be a **delay of up to ~30 seconds** between when a motion is detected and when the RTSP stream updates (can be changed at risk of the Blink server banning y>

Once the RTSP streams are available, you can use them in applications such as [Frigate NVR](https://github.com/blakeblackshear/frigate) (e.g. for better person detection) or [Scrypted](https://github.com/kous>

# How it works

1. blinkbridge downloads the latest clip for each enabled camera from the Blink server
2. FFmpeg extracts the last frame from each clip and creates a short still video (~0.5s) from it
3. The still video is published on a loop to MediaMTX (using [FFMpeg's concat demuxer](https://trac.ffmpeg.org/wiki/Concatenate#demuxer))
4. When motion is detected, the new clip is downloaded and published
5. A still video from the last frame of the new clip is then published on a loop

# Usage

1. Download `compose.yaml` from this repo and modify accordingly
2. Download `config/config.json`, save to `./config/` and modify accordingly (be sure to enter your Blink login credentials)
3. Run `docker compose run blinkbridge` and enter your Blink verification code when prompted (this only has to be done once and will be saved in `config/.cred.json`). Exit with CTRL+c
4. Run `docker compose up` to start the service from `/home/kmw`. The RTSP URLs will be printed to the console. The RTSP URLs will be printed to the console.

Note: If no initial clip is found for a camera at startup, blinkbridge creates a temporary 1-second black placeholder video so the RTSP endpoint is immediately available. It will switch to real clips when mot>

# TODO

- [ ] Better error handling
- [ ] Cleanup code
- [ ] Support FFmpeg hardware acceleration (e.g. QSV)
- [ ] Process cameras in parallel and reduce latency
- [ ] Add ONVIF server with motion events
