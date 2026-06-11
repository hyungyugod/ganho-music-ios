#!/usr/bin/env python3
"""
generate_bgm.py — GanhoMusic R12 [A] 기본 BGM 플레이스홀더 오프라인 합성기.

게임 톤: 칩튠 · 밝고 분주한 야간 병동 (square 멜로디 + triangle 베이스 + 약한 noise 햇).
8마디 루프, 124 BPM, 4/4, 44.1kHz/16bit mono. 루프 경계 = 정확한 마디 샘플 경계
(마지막 음 릴리즈가 루프 끝 이전에 0 도달 — 이음새 무클릭). 마스터 피크 ≈ −10dB
(SFX(ChiptuneSynth sfxMasterGain 0.22) 마스킹 방지 — 배경 음량).

⚠️ 본 음원은 *플레이스홀더 품질* — 게임 정체성은 사용자 자작곡(자전적 서사).
   bgm.m4a 파일 교체만으로 드롭인 가능 (코드에 BPM/길이 의존 0, numberOfLoops=-1).

재생성 절차 (저장소 루트에서):
  1) python3 tools/generate_bgm.py            # → tools/bgm.wav 생성
  2) afconvert -f m4af -d aac -b 96000 tools/bgm.wav \
       "GanhoMusic/GanhoMusic Shared/Resources/Audio/bgm.m4a"
  3) afinfo "GanhoMusic/GanhoMusic Shared/Resources/Audio/bgm.m4a"   # AAC·길이 확인
  (tools/bgm.wav 중간 산출물은 저장소 비보관 — .m4a만 번들 리소스.)

의존성: Python3 표준 라이브러리만 (wave/struct/math) — 외부 패키지 0.
"""
import math
import struct
import wave

SR = 44100              # 샘플레이트 (Hz)
BPM = 124               # 분주하지만 따뜻한 야간 근무 템포
BEAT = 60.0 / BPM       # 1박 길이 (초)
BARS = 8                # 8마디 루프
TOTAL_SAMPLES = round(BARS * 4 * BEAT * SR)   # 루프 경계 = 정확한 마디 샘플 경계

# 트랙 믹스 (합산 후 피크 정규화로 -10dB 보장)
MELODY_GAIN = 0.16
BASS_GAIN = 0.20
HAT_GAIN = 0.045
TARGET_PEAK = 0.316     # ≈ -10 dBFS

ATTACK = 0.004          # 노트 어택 (초) — 클릭 방지
RELEASE = 0.035         # 노트 릴리즈 (초) — 클릭 방지


def freq(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def square(phase):
    return 1.0 if (phase - math.floor(phase)) < 0.5 else -1.0


def triangle(phase):
    t = phase - math.floor(phase)
    return abs(t * 4.0 - 2.0) - 1.0


# ── 작곡 데이터 (Am–F–C–G, a단조 위 밝은 펜타토닉 멜로디 — 결정적·난수 0) ──
# 멜로디: 마디당 8분음표 8개 (MIDI). 0 = 쉼표.
MELODY = [
    # Am          (1~2마디)
    [69, 72, 76, 72, 69, 76, 74, 72],
    [69, 72, 76, 79, 76, 72, 74, 76],
    # F           (3~4마디)
    [65, 69, 72, 74, 72, 69, 67, 69],
    [65, 69, 72, 76, 74, 72, 69, 67],
    # C           (5~6마디)
    [64, 67, 72, 67, 76, 74, 72, 67],
    [72, 76, 79, 76, 74, 72, 71, 72],
    # G           (7~8마디 — 마지막 음들이 다시 A로 이끌어 루프 자연 연결)
    [74, 71, 67, 71, 74, 76, 74, 71],
    [67, 69, 71, 74, 76, 74, 71, 69],
]
# 베이스: 마디당 4분음표 4개 (MIDI).
BASS = [
    [45, 45, 52, 45], [45, 45, 52, 57],   # Am
    [41, 41, 48, 41], [41, 41, 48, 53],   # F
    [48, 48, 55, 48], [48, 48, 55, 48],   # C
    [43, 43, 50, 43], [43, 43, 50, 47],   # G → (B2가 A로 반음 위 유도)
]


def render_note(buf, start_s, dur_s, frequency, gain, wave_fn):
    """버퍼에 단일 노트 가산 합성. 어택/릴리즈 엔벨로프 — 노트 경계 무클릭."""
    n0 = round(start_s * SR)
    n_len = round(dur_s * SR)
    attack_n = max(1, round(ATTACK * SR))
    release_n = max(1, round(RELEASE * SR))
    for i in range(n_len):
        idx = n0 + i
        if idx >= TOTAL_SAMPLES:
            break
        env = 1.0
        if i < attack_n:
            env = i / attack_n
        elif i > n_len - release_n:
            env = max(0.0, (n_len - i) / release_n)
        phase = (i / SR) * frequency
        buf[idx] += wave_fn(phase) * gain * env


def render_hat(buf, start_s, gain):
    """8분 오프비트 노이즈 햇 — 20ms 지수 감쇠. 의사난수(LCG) — 실행 간 결정적."""
    n0 = round(start_s * SR)
    n_len = round(0.020 * SR)
    state = (n0 * 1103515245 + 12345) & 0x7FFFFFFF
    for i in range(n_len):
        idx = n0 + i
        if idx >= TOTAL_SAMPLES:
            break
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        noise = (state / 0x3FFFFFFF) - 1.0
        env = math.exp(-i / (0.005 * SR))
        buf[idx] += noise * gain * env


def main():
    buf = [0.0] * TOTAL_SAMPLES

    for bar in range(BARS):
        bar_start = bar * 4 * BEAT
        # 멜로디 — 8분음표 (노트 길이의 92%만 발음 — 짧은 스타카토 호흡).
        for i, midi in enumerate(MELODY[bar]):
            if midi <= 0:
                continue
            render_note(buf, bar_start + i * BEAT / 2, (BEAT / 2) * 0.92,
                        freq(midi), MELODY_GAIN, square)
        # 베이스 — 4분음표 (95% 발음).
        for i, midi in enumerate(BASS[bar]):
            render_note(buf, bar_start + i * BEAT, BEAT * 0.95,
                        freq(midi), BASS_GAIN, triangle)
        # 햇 — 8분 오프비트 (0.5, 1.5, 2.5, 3.5박).
        for i in range(4):
            render_hat(buf, bar_start + (i + 0.5) * BEAT, HAT_GAIN)

    # 피크 정규화 → -10dB (배경 음량 — SFX 마스킹 방지).
    peak = max(abs(s) for s in buf)
    scale = TARGET_PEAK / peak if peak > 0 else 1.0
    pcm = struct.pack("<%dh" % TOTAL_SAMPLES,
                      *(max(-32767, min(32767, round(s * scale * 32767))) for s in buf))

    out_path = "tools/bgm.wav"
    with wave.open(out_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    print(f"[generate_bgm] {out_path}: {TOTAL_SAMPLES} samples "
          f"({TOTAL_SAMPLES / SR:.3f}s, {BARS} bars @ {BPM} BPM), peak {TARGET_PEAK} (≈ -10dB)")


if __name__ == "__main__":
    main()
