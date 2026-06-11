#!/usr/bin/env python3
"""
generate_menu_bgm.py — GanhoMusic 메뉴 대기 BGM 플레이스홀더 오프라인 합성기 (post-R12).

generate_bgm.py(인게임 124 BPM square 칩튠)의 자매 스크립트 — 원본 무변경.
메뉴 톤: **부드럽고 잔잔한 야간 병동 대기 음악** — triangle 멜로디 + sine 베이스/패드,
square·noise 햇 전폐(분주함 배제). 멜로디는 마디당 2~3음 + 쉼표(8분 연속 진행 금지).
8마디 루프, 84 BPM, 4/4, 44.1kHz/16bit mono → 길이 22.857s (= 1,008,000 샘플 정확).
루프 경계 = 정확한 마디 샘플 경계, 모든 음의 릴리즈가 루프 끝 *이전에* 0 도달 — 이음새 무클릭.
마스터 피크 ≈ −14dB (인게임 −10dB보다 낮은 배경 음량 — 메뉴 uiTap SFX 마스킹 방지).
조성: 인게임(Am–F–C–G)과 가족 조성의 a단조 — 톤 연속성 ("병동의 밤은 계속된다").
난수 0 — 실행 간 완전 결정적 (wav byte-동일).

⚠️ 본 음원은 *플레이스홀더 품질* — 게임 정체성은 사용자 자작곡(자전적 서사).
   menu_bgm.m4a 파일 교체만으로 드롭인 가능 (코드에 BPM/길이 의존 0, numberOfLoops=-1).

재생성 절차 (저장소 루트에서):
  1) python3 tools/generate_menu_bgm.py       # → tools/menu_bgm.wav 생성
  2) afconvert -f m4af -d aac -b 96000 tools/menu_bgm.wav \
       "GanhoMusic/GanhoMusic Shared/Resources/Audio/menu_bgm.m4a"
  3) afinfo "GanhoMusic/GanhoMusic Shared/Resources/Audio/menu_bgm.m4a"  # AAC·길이 확인
  (tools/menu_bgm.wav 중간 산출물은 저장소 비보관 — .m4a만 번들 리소스.)

의존성: Python3 표준 라이브러리만 (wave/struct/math) — 외부 패키지 0.
"""
import math
import struct
import wave

SR = 44100              # 샘플레이트 (Hz)
BPM = 84                # 느리고 따뜻한 야간 대기 템포 (인게임 124 대비 −32%)
BEAT = 60.0 / BPM       # 1박 길이 (초) = 0.714285…
BARS = 8                # 8마디 루프
BEATS_PER_BAR = 4
TOTAL_SAMPLES = round(BARS * BEATS_PER_BAR * BEAT * SR)   # 1,008,000 — 정확한 마디 경계

# 트랙 믹스 (합산 후 피크 정규화로 -14dB 보장)
MELODY_GAIN = 0.14
BASS_GAIN = 0.16
PAD_GAIN = 0.045        # 패드 음 1개당 — 따뜻한 깔개, 존재감만
TARGET_PEAK = 0.2       # ≈ -14 dBFS (인게임 0.316 ≈ -10dB보다 낮은 배경 음량)

# 소프트 엔벨로프 (초) — ATTACK ≥ 8ms 요구 충족. 릴리즈는 노트 길이 *안쪽*에서 0 도달.
MELODY_ATTACK, MELODY_RELEASE = 0.012, 0.12
BASS_ATTACK, BASS_RELEASE = 0.018, 0.16
PAD_ATTACK, PAD_RELEASE = 0.35, 0.45


def freq(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def sine(phase):
    return math.sin(2.0 * math.pi * phase)


def triangle(phase):
    t = phase - math.floor(phase)
    return abs(t * 4.0 - 2.0) - 1.0


# ── 작곡 데이터 (Am–F–C–G ×2 회전, a단조 — 결정적·난수 0) ──────────────────
# 각 항목 = (시작 박, 길이 박, MIDI). 마디당 2~3음 + 쉼표 — 성긴 호흡.
# 마지막 마디의 모든 음은 3.6박 이전 종료 → 릴리즈가 루프 끝 전에 0 도달 (이음새 무클릭).
MELODY = [
    [(0.0, 1.5, 76), (2.0, 1.0, 72), (3.0, 0.9, 69)],   # Am — E5 하강 호흡
    [(0.0, 2.5, 72), (3.0, 0.9, 74)],                   # F  — C5 길게, D5 연결
    [(0.0, 1.5, 76), (2.0, 1.8, 74)],                   # C  — E5→D5 느긋한 응답
    [(0.0, 2.8, 71)],                                   # G  — B4 한 음 + 긴 쉼
    [(0.0, 1.5, 69), (2.0, 1.0, 72), (3.0, 0.9, 76)],   # Am — A4 상행 재시동
    [(0.0, 2.5, 77), (3.0, 0.9, 76)],                   # F  — F5 정점, E5로 누그러짐
    [(0.0, 1.5, 72), (2.0, 1.8, 67)],                   # C  — C5→G4 가라앉음
    [(0.0, 1.2, 71), (2.0, 1.6, 74)],                   # G  — B4·D5가 루프 첫 E5로 유도
]
# 베이스: 마디당 근음(2박) + 5음(1.8박) — sine 저역, 마지막 음 3.8박 종료.
BASS = [
    [(0.0, 2.0, 45), (2.0, 1.8, 52)],   # Am: A2, E3
    [(0.0, 2.0, 41), (2.0, 1.8, 48)],   # F : F2, C3
    [(0.0, 2.0, 48), (2.0, 1.8, 55)],   # C : C3, G3
    [(0.0, 2.0, 43), (2.0, 1.8, 50)],   # G : G2, D3
    [(0.0, 2.0, 45), (2.0, 1.8, 52)],   # Am
    [(0.0, 2.0, 41), (2.0, 1.8, 48)],   # F
    [(0.0, 2.0, 48), (2.0, 1.8, 55)],   # C
    [(0.0, 2.0, 43), (2.0, 1.8, 50)],   # G
]
# 패드: 마디당 3화음 1개 (0.1박 시작, 3.4박 길이 → 3.5박 종료) — 느린 어택의 따뜻한 깔개.
PAD = [
    [57, 60, 64],   # Am: A3 C4 E4
    [53, 57, 60],   # F : F3 A3 C4
    [55, 60, 64],   # C : G3 C4 E4
    [55, 59, 62],   # G : G3 B3 D4
    [57, 60, 64],   # Am
    [53, 57, 60],   # F
    [55, 60, 64],   # C
    [55, 59, 62],   # G
]
PAD_START_BEAT, PAD_DUR_BEATS = 0.1, 3.4


def render_note(buf, start_s, dur_s, frequency, gain, wave_fn, attack_s, release_s):
    """버퍼에 단일 노트 가산 합성. 어택/릴리즈 엔벨로프 — 노트 경계 무클릭."""
    n0 = round(start_s * SR)
    n_len = round(dur_s * SR)
    attack_n = max(1, round(attack_s * SR))
    release_n = max(1, round(release_s * SR))
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


def main():
    buf = [0.0] * TOTAL_SAMPLES

    for bar in range(BARS):
        bar_start = bar * BEATS_PER_BAR * BEAT
        # 멜로디 — triangle, 성긴 프레이즈.
        for start_beat, dur_beats, midi in MELODY[bar]:
            render_note(buf, bar_start + start_beat * BEAT, dur_beats * BEAT,
                        freq(midi), MELODY_GAIN, triangle,
                        MELODY_ATTACK, MELODY_RELEASE)
        # 베이스 — sine 저역.
        for start_beat, dur_beats, midi in BASS[bar]:
            render_note(buf, bar_start + start_beat * BEAT, dur_beats * BEAT,
                        freq(midi), BASS_GAIN, sine,
                        BASS_ATTACK, BASS_RELEASE)
        # 패드 — sine 3화음, 느린 어택/릴리즈 (마디 안에서 0 도달 — 경계 무클릭).
        for midi in PAD[bar]:
            render_note(buf, bar_start + PAD_START_BEAT * BEAT, PAD_DUR_BEATS * BEAT,
                        freq(midi), PAD_GAIN, sine,
                        PAD_ATTACK, PAD_RELEASE)

    # 피크 정규화 → -14dB (인게임보다 낮은 배경 음량 — uiTap SFX 마스킹 방지).
    peak = max(abs(s) for s in buf)
    scale = TARGET_PEAK / peak if peak > 0 else 1.0
    pcm = struct.pack("<%dh" % TOTAL_SAMPLES,
                      *(max(-32767, min(32767, round(s * scale * 32767))) for s in buf))

    out_path = "tools/menu_bgm.wav"
    with wave.open(out_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    print(f"[generate_menu_bgm] {out_path}: {TOTAL_SAMPLES} samples "
          f"({TOTAL_SAMPLES / SR:.3f}s, {BARS} bars @ {BPM} BPM), peak {TARGET_PEAK} (≈ -14dB)")


if __name__ == "__main__":
    main()
