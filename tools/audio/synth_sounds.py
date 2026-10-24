"""Synthesizes the game's own sounds (D25, D41, D50) as 16-bit 22050 Hz mono WAV files.

Run from anywhere with ``py -3 tools/audio/synth_sounds.py``: it writes every sound into
``assets/audio/`` and then reads each file back and checks its format, length and peak level, that
a one-shot starts and ends at silence, and that a loop joins itself without a click. A loop
carries its loop points in the file (a ``smpl`` chunk, which Godot's WAV importer reads), so it
loops in any checkout: the ``.import`` files are not in the repository.
``--check`` only runs the check on the files already there. Standard library only (``wave``,
``math``, ``struct``, ``random`` with a fixed seed), so the same script always writes the same
bytes, needs no download and carries no licence but the project's.

Nothing here may depend on a soul: the voice blip is one sample, pitched per soul by the game
from a hash of the name (D1, D41).
"""

from __future__ import annotations

import argparse
import math
import random
import struct
import sys
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

RATE = 22050
SAMPLE_WIDTH = 2
FULL_SCALE = 32767
SEED = 1066
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio"
# A file's first and last samples stay this close to silence, so no sound starts or ends on a click.
EDGE_LIMIT = 0.02
# A loop's step from its last sample back to its first is no larger than this many times its
# largest step inside the file: the seam is as smooth as the sound itself.
SEAM_RATIO = 1.0
PEAK_TOLERANCE_DB = 0.5
LENGTH_TOLERANCE_S = 0.001


@dataclass(frozen=True)
class Sound:
    """One sound: its file, its length in seconds, its peak in dBFS and how it is made. A loop
    plays over and over (its ``smpl`` chunk says so), so it must join itself instead of fading
    out."""

    name: str
    seconds: float
    peak_db: float
    make: Callable[[int, random.Random], list[float]]
    loop: bool = False


def _count(seconds: float) -> int:
    return int(round(seconds * RATE))


def _fade_edges(samples: list[float], fade_in: float, fade_out: float) -> list[float]:
    """Short linear ramps at both ends, so every sound starts and ends at silence."""
    count = len(samples)
    rise = max(1, _count(fade_in))
    fall = max(1, _count(fade_out))
    for index in range(min(rise, count)):
        samples[index] *= index / rise
    for index in range(min(fall, count)):
        samples[count - 1 - index] *= index / fall
    return samples


def _blip(count: int, _rng: random.Random) -> list[float]:
    """A 40 ms sine at 330 Hz with a fast exponential decay: the voice of the dead."""
    samples = []
    for index in range(count):
        t = index / RATE
        samples.append(math.sin(2.0 * math.pi * 330.0 * t) * math.exp(-t / 0.012))
    return _fade_edges(samples, 0.002, 0.004)


def _pin_tack(count: int, rng: random.Random) -> list[float]:
    """A 30 ms click of low-passed noise with a very fast decay: a pin pushed into parchment."""
    samples = []
    low = 0.0
    for index in range(count):
        t = index / RATE
        low += 0.35 * (rng.uniform(-1.0, 1.0) - low)
        samples.append(low * math.exp(-t / 0.006))
    return _fade_edges(samples, 0.0005, 0.003)


def _thread_pull(count: int, rng: random.Random) -> list[float]:
    """A 120 ms tone rising from 280 to 560 Hz with a soft second harmonic: a thread drawn taut."""
    samples = []
    phase = 0.0
    seconds = count / RATE
    for index in range(count):
        t = index / RATE
        frequency = 280.0 * 2.0 ** (t / seconds)
        phase += 2.0 * math.pi * frequency / RATE
        tone = math.sin(phase) + 0.3 * math.sin(2.0 * phase)
        envelope = min(1.0, t / 0.015) * math.exp(-t / 0.08)
        samples.append((tone + 0.04 * rng.uniform(-1.0, 1.0)) * envelope)
    return _fade_edges(samples, 0.001, 0.01)


def _no_seam_tick(count: int, rng: random.Random) -> list[float]:
    """A 60 ms dull, low tick: a 140 Hz thump under a little muffled noise, no ring."""
    samples = []
    low = 0.0
    for index in range(count):
        t = index / RATE
        low += 0.08 * (rng.uniform(-1.0, 1.0) - low)
        body = math.sin(2.0 * math.pi * 140.0 * t) * math.exp(-t / 0.018)
        samples.append(body + 0.6 * low * math.exp(-t / 0.01))
    return _fade_edges(samples, 0.001, 0.01)


def _horn(count: int, _rng: random.Random) -> list[float]:
    """A 1.2 s low horn at 98 Hz: brass-like odd and even harmonics, a 5 Hz vibrato that grows in,
    a slow swell and a long decay."""
    samples = []
    phase = 0.0
    harmonics = [1.0, 0.7, 0.5, 0.32, 0.2, 0.12, 0.07]
    for index in range(count):
        t = index / RATE
        depth = 0.006 * min(1.0, t / 0.4)
        frequency = 98.0 * (1.0 + depth * math.sin(2.0 * math.pi * 5.0 * t))
        phase += 2.0 * math.pi * frequency / RATE
        tone = sum(level * math.sin((order + 1) * phase) for order, level in enumerate(harmonics))
        swell = min(1.0, t / 0.15)
        samples.append(tone * swell * math.exp(-t / 0.7))
    return _fade_edges(samples, 0.01, 0.12)


def _caw(count: int, rng: random.Random) -> list[float]:
    """A 150 ms dry caw: a sawtooth buzz falling from 900 to 480 Hz, roughened by noise and a 70 Hz
    flutter into a rasp, with a quick swell and a dry tail. The black feather's voice (D16): harsh
    and falling where the soul's blip is a pure, short sine."""
    samples = []
    phase = 0.0
    rough = 0.0
    seconds = count / RATE
    for index in range(count):
        t = index / RATE
        frequency = 900.0 * (480.0 / 900.0) ** (t / seconds)
        phase = (phase + frequency / RATE) % 1.0
        saw = 2.0 * phase - 1.0
        rough += 0.45 * (rng.uniform(-1.0, 1.0) - rough)
        flutter = 0.65 + 0.35 * math.sin(2.0 * math.pi * 70.0 * t)
        envelope = min(1.0, t / 0.012) * (1.0 - t / seconds) ** 0.7
        samples.append((saw * (0.6 + 0.4 * rough) * flutter + 0.35 * rough) * envelope)
    return _fade_edges(samples, 0.002, 0.012)


def _page_turn(count: int, rng: random.Random) -> list[float]:
    """A 120 ms rustle: noise through a low-pass whose cutoff sweeps from high to low, with a
    quick attack and a soft decay. A page of the day-book turned (D22)."""
    samples = []
    low = 0.0
    seconds = count / RATE
    for index in range(count):
        t = index / RATE
        # The filter's coefficient falls from bright (0.85) to dull (0.06) over the sound.
        coefficient = 0.85 * (0.06 / 0.85) ** (t / seconds)
        low += coefficient * (rng.uniform(-1.0, 1.0) - low)
        envelope = min(1.0, t / 0.006) * (1.0 - t / seconds) ** 1.5
        samples.append(low * envelope)
    return _fade_edges(samples, 0.001, 0.01)


def _drone(count: int, _rng: random.Random) -> list[float]:
    """A 4 s low drone of two tones, 55 Hz and the fifth above it at 82.5 Hz, with a soft octave
    and a slow breath. Every frequency makes a whole number of cycles in 4 s, so the loop's end
    meets its start exactly: the drone under the day-book (D22)."""
    samples = []
    seconds = count / RATE
    for index in range(count):
        t = index / RATE
        tone = (
            math.sin(2.0 * math.pi * 55.0 * t)
            + 0.7 * math.sin(2.0 * math.pi * 82.5 * t)
            + 0.25 * math.sin(2.0 * math.pi * 110.0 * t)
        )
        breath = 0.8 + 0.2 * math.sin(2.0 * math.pi * t / seconds)
        samples.append(tone * breath)
    return samples


def _wind(count: int, rng: random.Random) -> list[float]:
    """A 6 s wind: noise through a low-pass whose cutoff and level drift slowly in gusts. The
    gusts repeat every 6 s and the loop's first half-second is cross-faded with what follows its
    end, so the wind blows on without a seam: the title's wind (D24)."""
    fade = _count(0.5)
    seconds = count / RATE
    raw = []
    low = 0.0
    lower = 0.0
    for index in range(count + fade):
        t = index / RATE
        gust = 0.5 + 0.3 * math.sin(2.0 * math.pi * t / seconds) + 0.2 * math.sin(
            2.0 * math.pi * 3.0 * t / seconds + 1.0
        )
        coefficient = 0.02 + 0.06 * gust
        low += coefficient * (rng.uniform(-1.0, 1.0) - low)
        lower += 0.5 * (low - lower)
        raw.append(lower * (0.35 + 0.65 * gust))
    samples = raw[:count]
    for index in range(fade):
        # Equal power: uncorrelated noise keeps its level through the cross-fade.
        rise = math.sin(0.5 * math.pi * index / fade)
        samples[index] = raw[index] * rise + raw[count + index] * math.cos(
            0.5 * math.pi * index / fade
        )
    return samples


SOUNDS = [
    Sound("blip.wav", 0.040, -14.0, _blip),
    Sound("pin_tack.wav", 0.030, -6.0, _pin_tack),
    Sound("thread_pull.wav", 0.120, -6.0, _thread_pull),
    Sound("no_seam_tick.wav", 0.060, -6.0, _no_seam_tick),
    Sound("horn.wav", 1.200, -6.0, _horn),
    Sound("caw.wav", 0.150, -6.0, _caw),
    Sound("page_turn.wav", 0.120, -12.0, _page_turn),
    Sound("drone.wav", 4.000, -14.0, _drone, loop=True),
    Sound("wind.wav", 6.000, -18.0, _wind, loop=True),
]


def _normalized(samples: list[float], peak_db: float) -> list[int]:
    """Scales the samples so their largest magnitude sits at `peak_db` dBFS."""
    largest = max(abs(sample) for sample in samples)
    gain = (10.0 ** (peak_db / 20.0)) / largest if largest > 0.0 else 0.0
    return [int(round(sample * gain * FULL_SCALE)) for sample in samples]


# The ``smpl`` chunk's fixed fields before its first loop: manufacturer, product, sample period,
# MIDI unity note, pitch fraction, SMPTE format and offset, the loop count, the sampler data.
SMPL_HEADER = "<9I"
# One loop: its cue point id, its type (0 is forward), its first and last frame, fraction, plays
# (0 is forever).
SMPL_LOOP = "<6I"
LOOP_FORWARD = 0


def _smpl_chunk(frame_count: int) -> bytes:
    """A ``smpl`` chunk looping the whole file forward, for ever."""
    period_ns = int(round(1_000_000_000 / RATE))
    header = struct.pack(SMPL_HEADER, 0, 0, period_ns, 60, 0, 0, 0, 1, 0)
    loop = struct.pack(SMPL_LOOP, 0, LOOP_FORWARD, 0, frame_count - 1, 0, 0)
    body = header + loop
    return b"smpl" + struct.pack("<I", len(body)) + body


def _add_chunk(path: Path, chunk: bytes) -> None:
    """Appends `chunk` to a RIFF file and corrects the RIFF size."""
    with open(path, "r+b") as handle:
        handle.seek(0, 2)
        handle.write(chunk)
        size = handle.tell() - 8
        handle.seek(4)
        handle.write(struct.pack("<I", size))


def _loop_points(path: Path) -> tuple[int, int, int] | None:
    """The first loop of a file's ``smpl`` chunk as (type, first, last), or None without one."""
    data = path.read_bytes()
    at = 12
    while at + 8 <= len(data):
        chunk_id = data[at : at + 4]
        (size,) = struct.unpack("<I", data[at + 4 : at + 8])
        if chunk_id == b"smpl":
            loop_at = at + 8 + struct.calcsize(SMPL_HEADER)
            _cue, kind, first, last, _fraction, _plays = struct.unpack(
                SMPL_LOOP, data[loop_at : loop_at + struct.calcsize(SMPL_LOOP)]
            )
            return (kind, first, last)
        at += 8 + size + (size & 1)
    return None


def write_all(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for sound in SOUNDS:
        # One generator per sound, so editing one sound never changes another's bytes.
        rng = random.Random(f"{SEED}:{sound.name}")
        frames = _normalized(sound.make(_count(sound.seconds), rng), sound.peak_db)
        with wave.open(str(out_dir / sound.name), "wb") as handle:
            handle.setnchannels(1)
            handle.setsampwidth(SAMPLE_WIDTH)
            handle.setframerate(RATE)
            handle.writeframes(struct.pack(f"<{len(frames)}h", *frames))
        if sound.loop:
            _add_chunk(out_dir / sound.name, _smpl_chunk(len(frames)))


def check_all(out_dir: Path) -> list[str]:
    """Reads every sound back; returns one line per problem (none when all is well)."""
    problems = []
    for sound in SOUNDS:
        path = out_dir / sound.name
        if not path.exists():
            problems.append(f"{sound.name}: missing")
            continue
        with wave.open(str(path), "rb") as handle:
            channels = handle.getnchannels()
            width = handle.getsampwidth()
            rate = handle.getframerate()
            count = handle.getnframes()
            data = handle.readframes(count)
        if (channels, width, rate) != (1, SAMPLE_WIDTH, RATE):
            problems.append(f"{sound.name}: {channels} ch, {width * 8} bit, {rate} Hz")
            continue
        frames = struct.unpack(f"<{count}h", data)
        seconds = count / rate
        peak = max(abs(frame) for frame in frames) / FULL_SCALE
        peak_db = 20.0 * math.log10(peak) if peak > 0.0 else -math.inf
        edge = max(abs(frames[0]), abs(frames[-1])) / FULL_SCALE
        largest_step = max(abs(frames[i + 1] - frames[i]) for i in range(count - 1))
        seam = abs(frames[0] - frames[-1])
        print(
            f"{sound.name:17} {seconds * 1000.0:7.1f} ms  peak {peak_db:6.2f} dBFS"
            f"  (want {sound.seconds * 1000.0:.0f} ms, {sound.peak_db:.0f} dBFS)"
            + (f"  loop seam {seam}, largest step {largest_step}" if sound.loop else "")
        )
        if abs(seconds - sound.seconds) > LENGTH_TOLERANCE_S:
            problems.append(f"{sound.name}: {seconds:.4f} s, want {sound.seconds} s")
        if abs(peak_db - sound.peak_db) > PEAK_TOLERANCE_DB:
            problems.append(f"{sound.name}: peak {peak_db:.2f} dBFS, want {sound.peak_db}")
        if sound.loop and seam > SEAM_RATIO * largest_step:
            problems.append(f"{sound.name}: the loop clicks at its seam ({seam} > {largest_step})")
        loop = _loop_points(path)
        if sound.loop and loop != (LOOP_FORWARD, 0, count - 1):
            problems.append(f"{sound.name}: no forward loop over the whole file ({loop})")
        if not sound.loop and loop is not None:
            problems.append(f"{sound.name}: a one-shot carries loop points ({loop})")
        if not sound.loop and edge > EDGE_LIMIT:
            problems.append(f"{sound.name}: starts or ends on a click ({edge:.3f} of full scale)")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="only check the files already there")
    parser.add_argument("--out", type=Path, default=OUT_DIR, help="where the WAV files go")
    arguments = parser.parse_args()
    if not arguments.check:
        write_all(arguments.out)
    problems = check_all(arguments.out)
    for problem in problems:
        print(f"FAIL {problem}")
    print("OK: every sound checks out" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
