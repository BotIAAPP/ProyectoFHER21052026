"""Generate all slide TTS WAVs from narraciones.json using edge-tts.
Reads narrations as UTF-8 JSON (sidesteps PowerShell encoding pitfalls)."""
import truststore
truststore.inject_into_ssl()

import asyncio
import json
import subprocess
import sys
from pathlib import Path
import edge_tts

HERE = Path(__file__).parent
JSON_FILE = HERE / "narraciones.json"
FFMPEG = sys.argv[1] if len(sys.argv) > 1 else "ffmpeg"
VOICE = "es-MX-DaliaNeural"
RATE = "-5%"


async def gen(text: str, mp3: Path):
    c = edge_tts.Communicate(text, VOICE, rate=RATE)
    await c.save(str(mp3))


async def main():
    narrations = json.loads(JSON_FILE.read_text(encoding="utf-8"))
    print(f"Loaded {len(narrations)} narrations from {JSON_FILE.name}", flush=True)
    print(f"Sample chars test: {narrations[0][:60]}", flush=True)

    for i, text in enumerate(narrations, 1):
        mp3 = HERE / f"slide-{i:02d}.mp3"
        wav = HERE / f"slide-{i:02d}.wav"
        if mp3.exists():
            mp3.unlink()
        if wav.exists():
            wav.unlink()

        await gen(text, mp3)

        subprocess.run(
            [FFMPEG, "-y", "-i", str(mp3), "-ac", "2", "-ar", "48000",
             "-c:a", "pcm_s16le", str(wav), "-loglevel", "error"],
            check=True,
        )
        kb = wav.stat().st_size // 1024
        print(f"  slide-{i:02d}.wav  {kb:6d} KB", flush=True)


asyncio.run(main())
