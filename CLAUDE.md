# Block Blast

8x8 블록 배치 퍼즐 게임 (Godot 4).

## 빌드 & 실행
- `godot --path /Users/jaejin/projects/toy/block-blast` — 에디터 실행
- `godot --path /Users/jaejin/projects/toy/block-blast --headless --quit` — 프로젝트 검증

## 구조
- `autoloads/` — 전역 싱글턴 (Constants, GameState)
- `scenes/` — 씬 + 스크립트 (main, game_board, piece_tray 등)
- `effects/` — 시각 이펙트 씬
- `tests/` — GUT 테스트

## 스펙
- 원본: `../game-spec-block-blast-2026-03-10/spec.md`
