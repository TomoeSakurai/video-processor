# Video Processor

Google Drive上の長尺動画をAIで分析し、指定箇所を切り抜きするツールです。

## 概要

政党「チームみらい」の広報活動を支援するために開発されました。長時間のYouTube動画から、編集経験のないサポーターでも簡単に投稿できるショート動画を生成します。

### 主な機能

- Google Drive上の動画URLと切り抜き指示（自然言語）を入力
- Google Speech-to-Text Chirp 2で文字起こしを作成
- Claude（Anthropic）が文字起こしを分析し、該当箇所のタイムスタンプを自動抽出
- FFmpegで指定箇所を切り抜き、Google Driveの「ショート用」フォルダに保存
- 文字起こしを含むメタファイルも自動生成

## システム構成

```
┌─────────────────────────────────────────────────────────────────────┐
│                            Vercel                                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Next.js Frontend                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐   │  │
│  │  │  動画登録   │  │  処理状況   │  │   結果一覧表示      │   │  │
│  │  │   画面     │  │   画面     │  │      画面          │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────────┘
                               │ HTTPS
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Google Cloud                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                     Cloud Run                                 │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │              Backend API (TypeScript)                   │  │  │
│  │  │  presentation/  →  application/  →  domain/  →  infra/  │  │  │
│  │  │  + FFmpeg (動画カット処理)                              │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│         │              │               │              │             │
│         ▼              ▼               ▼              ▼             │
│  ┌───────────┐  ┌───────────┐  ┌────────────┐  ┌────────────┐     │
│  │ Cloud SQL │  │   GCS     │  │Google Drive│  │Speech-to-  │     │
│  │(PostgreSQL│  │(一時保存) │  │    API     │  │Text Chirp 2│     │
│  └───────────┘  └───────────┘  └────────────┘  └────────────┘     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
                    ┌────────────┐
                    │Anthropic   │
                    │API (Claude)│
                    └────────────┘
```

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| Frontend | Next.js 14 (App Router), React 18, shadcn/ui, Tailwind CSS |
| Backend | Express, Prisma, TypeScript (DDD構成) |
| AI/LLM | Anthropic Claude, Google Speech-to-Text Chirp 2 |
| 動画処理 | FFmpeg |
| Storage | Google Drive API, Google Cloud Storage |
| Database | PostgreSQL (Cloud SQL) |
| Infrastructure | Cloud Run, Terraform |
| Monorepo | pnpm workspaces |
| Linter/Formatter | Biome |
| Testing | Vitest, Playwright |

## ディレクトリ構成

```
video-processor/
├── apps/
│   ├── webapp/          # Next.js フロントエンド
│   ├── backend/         # Express バックエンド (DDD)
│   └── shared/          # 共通型定義
├── infrastructure/
│   └── terraform/       # インフラ構成
├── docs/                # 設計ドキュメント
├── biome.json           # Linter/Formatter設定
├── pnpm-workspace.yaml
└── package.json
```

## ローカルセットアップ

### 必要要件

- Node.js 22以上 (`.nvmrc`参照)
- pnpm 9.15.4以上
- Docker & Docker Compose (PostgreSQL用)
- FFmpeg

```bash
# macOS
brew install node pnpm ffmpeg
# Docker Desktop: https://www.docker.com/products/docker-desktop/

# Ubuntu/Debian
sudo apt-get install ffmpeg
# Node.js: https://nodejs.org/ (v22+)
# pnpm: corepack enable && corepack prepare pnpm@latest --activate
# Docker: https://docs.docker.com/engine/install/
```

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/team-mirai-volunteer/video-processor.git
cd video-processor

# 依存関係をインストール
pnpm install

# 環境変数ファイルを作成（テンプレートからコピー）
cp apps/backend/.env.example apps/backend/.env
cp apps/webapp/.env.local.example apps/webapp/.env.local
# 必要に応じて各 .env ファイルを編集（デフォルト値でローカル開発は可能）
```

### 開発サーバーの起動

```bash
# フロントエンドとバックエンドを同時起動
# (Docker ComposeでPostgreSQLも自動起動、DBスキーマも自動適用)
pnpm dev
```

- Frontend: http://localhost:3000
- Backend: http://localhost:8080

## コマンド一覧

### ルート

```bash
pnpm dev              # frontend + backend 同時起動
pnpm lint             # Biomeでlintチェック
pnpm lint:fix         # lint + 自動修正
pnpm typecheck        # 全パッケージの型チェック
```

### Backend (`apps/backend`)

```bash
pnpm --filter backend dev              # 開発サーバー起動
pnpm --filter backend test:unit        # ユニットテスト
pnpm --filter backend test:integration # 統合テスト (要DB)
pnpm --filter backend db:studio        # Prisma Studio
pnpm --filter backend db:migrate       # マイグレーション実行
```

### Frontend (`apps/webapp`)

```bash
pnpm --filter @video-processor/webapp dev       # 開発サーバー起動
pnpm --filter @video-processor/webapp build     # ビルド
pnpm --filter @video-processor/webapp test:e2e  # Playwright E2Eテスト
```

## ドキュメント

- [実装計画書](docs/implementation-plan.md) - 詳細設計・API仕様・DBスキーマ
- [初期アーキテクチャ](docs/initial-architecture.md) - 設計の背景と決定事項
- [バックエンドアーキテクチャガイド](docs/backend-architecture-guide.md) - DDD構成・エラーハンドリング・テスト方針
- [clip-video バックエンドガイド](docs/clip-video-backend-guide.md) - APIエンドポイント一覧・処理フロー
- [clip-video フロントエンドガイド](docs/clip-video-frontend-guide.md) - UI構成・パイプライン
- [Speech-to-Text Chirp導入設計](docs/20260125_0002_Speech-to-Text_Chirp導入設計.md)

## 環境変数

環境変数のテンプレートファイルが用意されています：

- Backend: [`apps/backend/.env.example`](apps/backend/.env.example) → `apps/backend/.env` にコピー
- Frontend: [`apps/webapp/.env.local.example`](apps/webapp/.env.local.example) → `apps/webapp/.env.local` にコピー

デフォルト値でローカル開発が可能です。AI機能やGoogle Drive連携を使う場合は、各APIキーを設定してください。詳細は `.env.example` ファイル内のコメントを参照してください。

## コントリビューション

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトは [GNU Affero General Public License v3.0 (AGPL-3.0)](LICENSE) の下で公開されています。
