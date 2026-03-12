# Block Blast 시각적 차이 수정 프로세스

## 목표
레퍼런스 영상(실제 Block Blast 게임)과 우리 구현의 시각적 차이를 반복적으로 줄여나간다.

## 프로세스

### Step 0: 레퍼런스 프레임 추출 (1회) ✅
- **입력**: `/Users/jaejin/Downloads/block_blast.mp4`
- **작업**: fps 2로 프레임 추출 → 핵심 장면 13장 선별
- **출력**: `/Users/jaejin/projects/toy/block-blast/reference_frames/`

### Step 1: 게임 플레이 + 스크린샷 (≤1분) ✅
- agent-browser로 https://block-blast-lake.vercel.app/ 접속
- JS 기반으로 블록 배치
- 주요 상태별 스크린샷 캡처

### Step 2: 레퍼런스 vs 현재 비교 ✅
- 차이점 18개 식별 (높음 7, 중간 6, 낮음 5)

### Step 3: 수정 — 멀티에이전트 병렬 실행 ✅
- **모든 차이점을 파일 충돌 없는 에이전트 그룹으로 분할**
- **질문 없이 전부 병렬 수정**
- godot headless 검증은 오케스트레이터가 전체 머지 후 수행

### Step 4: 배포
- git commit + push origin main → Vercel 자동 배포
- Obsidian 변경 이력 업데이트

### Step 5: 반복 판단
- 차이점이 없으면 종료, 있으면 Step 1로 복귀
- **최대 50회 반복**

## 운영 원칙
- **오케스트레이터는 질문하지 않고 바로 실행**
- 발견된 차이점은 전부 수정 (선별하지 않음)
- 파일 충돌 방지를 위해 에이전트별 담당 파일 명확히 분리
- 에이전트는 담당 파일만 수정, 다른 파일 건드리지 않음

## 라운드 1 차이점 목록

### 에이전트 A — Block Visual (grid_cell.gd, block_piece.gd)
| # | 차이점 | 레퍼런스 | 현재 |
|---|--------|---------|------|
| 1 | 블록 3D 베벨 | 3~4px 그라데이션 볼록 효과 | 2px 단색 반투명 |
| 2 | 블록 셀 간격 | 셀 사이 1~2px gap | 0px |

### 에이전트 B — Board Visual (constants.gd, game_board.gd)
| # | 차이점 | 레퍼런스 | 현재 |
|---|--------|---------|------|
| 3 | 그리드 라인 색상 | #2A366A (미묘) | #445599 (밝음) |
| 4 | 보드 외곽 | 라운드 코너 + 미묘한 테두리 | 단순 직사각형 |
| 13 | 보드-트레이 구분선 | 얇은 밝은 가로선 | 없음 |

### 에이전트 C — HUD & Background (hud.gd, main.tscn)
| # | 차이점 | 레퍼런스 | 현재 |
|---|--------|---------|------|
| 5 | 점수 폰트 | Bold + 그림자 | 기본 폰트 48px |
| 12 | 배경 | 그라데이션 (상→하 밝아짐) | #4A5785 단색 |
| 16 | Best Score 폰트 | 금색 Bold | font_size 24 |

### 에이전트 D — Game Over (scenes/game_over.gd, scenes/game_over.tscn)
| # | 차이점 | 레퍼런스 | 현재 |
|---|--------|---------|------|
| 7 | Game Over 화면 | 시안 글로우, 그라데이션 BG, 재생 아이콘 | 단순 텍스트 |

### 에이전트 E — Effects (effects/heart_glow.gd, effects/combo_text.gd)
| # | 차이점 | 레퍼런스 | 현재 |
|---|--------|---------|------|
| 8 | 하트 글로우 | 핑크/보라 네온, 넓은 반경 | Label 기반 |
| 9 | 콤보 텍스트 | 그라데이션 + 글로우 링 | Label 기반 |

## 역할 분담
- **오케스트레이터 (메인 세션)**: 프로세스 조율, 에이전트 디스패치, 머지, 검증, 배포
- **에이전트 A~E**: 각 파일 그룹 수정 (병렬)

## 파일 경로
- 레퍼런스 프레임: `/Users/jaejin/projects/toy/block-blast/reference_frames/`
- 게임 URL: https://block-blast-lake.vercel.app/
- 프로젝트: `/Users/jaejin/projects/toy/block-blast/`
- Obsidian: `/Users/jaejin/Library/CloudStorage/Dropbox/tree/toy/block-blast.md`
