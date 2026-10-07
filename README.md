# stackchan-muse

M5Stack **StackChan**(CoreS3)의 공장 AI를 Meta **Muse**로 바꾸고, 고개 움직임·한글 자막·음성 답변·"하이 스택짱" 호출어를 붙이는 코드입니다.
『피지컬 AI 실전』 18장 "Muse로 말하는 StackChan"의 실습 코드입니다.

Turns an M5Stack StackChan (CoreS3) into a [Muse](https://gadgets.muse.ai/) gadget with its neck servos as Muse commands, Korean captions, spoken replies through a small TTS relay, and a "Hi, Stack-chan" wake word. Built as a patch on Meta's [Muse Gadget SDK](https://github.com/facebookincubator/muse-gadget-sdk).

```
"하이 스택짱, 고개 끄덕여 봐"
   │ ESP-SR WakeNet (기기 안)
   ▼
StackChan ──음성──▶ Muse (Meta 서버) ──head.gesture──▶ StackChan 목 서보
StackChan ◀──답 글자── Muse
StackChan ──글자──▶ tts-relay (내 서버) ──MP3──▶ StackChan 스피커 + 한글 자막
```

## 무엇이 들어 있나

| 경로 | 내용 |
|---|---|
| `firmware/muse-stackchan.patch` | Muse Gadget SDK(`b139b45`)에 얹는 수정. 17개 파일 |
| `firmware/*.sh` | 백업 → 설정 → 빌드 → 플래시 → 되돌리기 스크립트 |
| `tts-relay/` | Muse의 글자 답을 MP3로 바꿔 주는 작은 서버(Python, edge-tts) |

패치가 SDK에 더하는 것:

| 기능 | 파일 | 설정 |
|---|---|---|
| 목 명령 `head.move`, `head.gesture`, `head.get` | `esp32/main/stackchan_head.c` | `CONFIG_HOMEHUB_STACKCHAN_HEAD` |
| 한글 자막 (Unifont 한글 음절 11,172자) | `tools/muse/gen_cjk_font.sh` | `CONFIG_MUSE_CJK_FONT` |
| 답을 소리로 (HTTP TTS 중계) | `components/muse/muse_chat_session.cpp` | `CONFIG_MUSE_HTTP_TTS` |
| 호출어 "Hi, Stack-chan" (esp-sr `wn9l_histackchan_tts3`) | `components/muse/muse_wake.c`, `muse_voice.c` | `CONFIG_MUSE_WAKE_WORD` |
| 위 설정을 모은 보드 파일, `model` 파티션 | `devices/sdkconfig.muse-stackchan`, `partitions_muse_stackchan.csv` | |

SDK 원본은 이 저장소에 없습니다. `setup.sh`가 Meta 저장소에서 받습니다.

## 먼저 확인할 것

- **Muse는 2026년 10월 현재 미국에서만 쓸 수 있습니다.** 미국 Muse 구독 계정과 휴대폰(iOS/안드로이드) Muse 앱이 필요합니다.
- **SDK 토큰**: <https://gadgets.muse.ai/settings/sdk-tokens> 에서 로그인 후 발급. 계정당 활성 토큰 1개, 개인·비상업 용도만([Gadget SDK Terms](https://gadgets.muse.ai/sdk-terms)).
- 하드웨어: **M5Stack StackChan 공식판(CoreS3)**. 다른 보드에서는 시험하지 않았습니다.
- **공장 펌웨어가 지워집니다.** 반드시 `backup.sh`부터 실행하세요.

## 준비 (macOS 기준)

```bash
brew install cmake ninja dfu-util node
python3 -m pip install esptool

# ESP-IDF 6.0.1 — SDK가 지원하는 유일한 버전
git clone -b v6.0.1 --recursive --depth 1 --shallow-submodules \
    https://github.com/espressif/esp-idf.git ~/.espressif/esp-idf-v6.0.1
~/.espressif/esp-idf-v6.0.1/install.sh esp32s3
```

다른 곳에 설치했다면 `IDF_EXPORT=/경로/export.sh`를 지정합니다.

## 실행

StackChan을 데이터 전송이 되는 USB-C 케이블로 연결하고:

```bash
git clone https://github.com/nobaksan/stackchan-muse
cd stackchan-muse/firmware

./backup.sh                      # 1. 16MB 전체 백업 + 검증. 이 파일은 공개하지 마세요(Wi-Fi 비밀번호 포함)
./setup.sh                       # 2. SDK 받기, 패치 적용, 한글 폰트 생성(약 2분)

cp sdkconfig.local-token.example sdkconfig.local-token
#                                  3. sdkconfig.local-token 에 mgst_ 토큰을 넣습니다

./build.sh                       # 4. 빌드(처음 약 3~5분)
./flash.sh                       # 5. 기기에 쓰기
./monitor.sh                     #    로그 보기(Ctrl-] 종료)
```

포트는 자동으로 찾습니다. 여러 개면 `PORT=/dev/cu.usbmodem1101 ./flash.sh`처럼 지정합니다.

### 페어링

1. 휴대폰 Muse 앱 → 설정 → 기기 → **개발자 모드** 켜기 (웹에서는 기기를 추가할 수 없습니다)
2. **+** → `MuseGadget-XXXXXX` → 연결 → 커뮤니티 기기 경고에서 "무시하고 계속하기"
3. StackChan 왼쪽 옆면 **PWR 버튼을 짧게 한 번** 누르면 앱의 확인 버튼이 활성화됩니다
4. Wi-Fi를 고르면 끝. 로그에 `setup=done wifi=up ws=up`이 나옵니다

### 써 보기

- PWR 버튼을 누른 채 말하거나, **"하이 스택짱"**이라고 부른 뒤 말합니다(말을 멈추고 0.9초 뒤 자동 전송).
- "고개 끄덕여 봐", "왼쪽 쳐다봐", "지금 고개 각도 알려줘"
- 휴대폰 채팅창에 글로 써도 됩니다.

## 답을 소리로 듣기 (선택)

Muse는 가젯에 글자만 줍니다. 소리로 들으려면 `tts-relay`를 HTTPS로 띄우고 펌웨어에 주소와 키를 넣습니다.

**서버** (리눅스, 예: `/opt/stackchan-tts`):

```bash
cd tts-relay
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env && echo "TTS_KEY=$(openssl rand -hex 24)" >> .env   # .env 는 커밋되지 않습니다
.venv/bin/python server.py            # 127.0.0.1:3710 에서만 듣습니다
```

- 시험: `curl -X POST http://127.0.0.1:3710/tts -H "X-TTS-Key: <키>" -H 'Content-Type: application/json' -d '{"text":"안녕하세요"}' -o a.mp3`
- 상시 실행: `stackchan-tts.service`(systemd), 공개: `nginx.conf.example`(HTTPS, 요청 제한, `proxy_buffering off`)
- 한글이 있으면 `ko-KR-SunHiNeural`, 없으면 `en-US-AriaNeural`로 읽습니다. 출력은 MP3 24kHz 48kbps 모노.

**펌웨어**:

```bash
cd firmware
cp sdkconfig.local-tts.example sdkconfig.local-tts   # URL 과 TTS_KEY 를 채웁니다
./build.sh && ./flash.sh
```

중계가 실패하면 자막만 보여 줍니다.

## 알려진 문제

책을 쓰며 실측한 값입니다(2026-10-07).

| 문제 | 상태 |
|---|---|
| 말을 마치고 소리가 나기까지 25초 이상. 그중 20초 남짓이 Muse 서버가 답을 만드는 시간 | 모델·속도를 가젯에서 바꿀 수 없음 |
| StackChan이 TTS를 받기 시작하기까지 4.3~4.7초 (서버는 0.3초, 연결 재사용해도 같음) | **원인 미확인** |
| 호출어 첫 호출을 놓치는 경우가 있음. 인식률·오인식률 미측정 | 미측정 |
| 호출어를 넣은 뒤 내부 RAM 여유 27KB(최저 14KB). TTS 연결이 한 번 즉시 실패 | 메모리 부족 의심, 미확인 |
| 배터리로 화면이 꺼지면 SDK가 마이크를 끄므로 호출어도 듣지 못함 | SDK 동작. USB 전원에서만 시험 |
| esp-sr 2.5.5의 wn9l `clean()`이 NULL을 읽어 패닉 | 부르지 않고, 녹음 뒤 1.5초 감지를 무시하는 것으로 우회 |
| 작업 경로에 한글이 있으면 컴파일러가 spec 파일 경로를 못 읽음 | `BUILD_DIR`을 영문 경로(기본 `~/.cache/stackchan-muse/build`)로 둬서 해결 |

## 되돌리기

```bash
./restore.sh stackchan_backup_YYYYMMDD_HHMMSS.bin
```

휴대폰 앱의 기기 목록에 남은 `MuseGadget-...`은 직접 지우고, 필요하면 SDK 토큰을 Revoke합니다.

## 비밀 정보

토큰과 TTS 키는 `sdkconfig.local-token`, `sdkconfig.local-tts`, `tts-relay/.env`에만 둡니다. 셋 다 `.gitignore`에 들어 있습니다. 토큰은 펌웨어 바이너리 안에 들어가므로 빌드 결과물(`.bin`)과 백업 파일도 공개하지 마세요.

## 라이선스

Apache License 2.0. 의존하는 소프트웨어의 출처와 라이선스는 [NOTICE](NOTICE)에 있습니다. Meta, M5Stack, Espressif와 관계없는 개인 프로젝트입니다.
