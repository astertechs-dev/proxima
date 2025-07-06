# Proxima - フリーランスITエンジニア・マッチングプラットフォーム

Proximaは、フリーランスITエンジニアとクライアント企業をつなぐ次世代のマッチングプラットフォームです。AI技術を活用した高精度なマッチング、ポータブル・スキルシート、統合コミュニケーションハブなど、業界の非効率を解消する革新的な機能を提供します。

## 🚀 主要機能

### フリーランス向け機能
- **AI搭載ポータブル・スキルシート・スタジオ**: 既存のスキルシートを自動解析・最適化
- **統合ポートフォリオビルダー**: GitHubとの連携による自動ポートフォリオ生成
- **AIレコメンデーションエンジン**: 個人のスキルと経験に基づく案件推薦
- **リアルタイム空き状況管理**: Googleカレンダー連携による効率的なスケジュール管理
- **実践的OJTプロジェクト**: 未経験分野への挑戦をサポート

### クライアント企業向け機能
- **AIプロアクティブ・マッチング**: 案件要件に最適な候補者を自動提案
- **スカウトツール**: 詳細な条件での候補者検索・直接スカウト
- **トライアル契約機能**: 低リスクでの候補者評価
- **電子契約管理**: DocuSign連携による契約プロセスの自動化
- **外部システム連携**: 既存のHRMS/CRMとのAPI連携

### 付加価値サービス
- **税務・会計サポート**: freee連携による確定申告支援
- **法務サポート**: 標準契約書テンプレートと専門家相談
- **決済処理**: Stripe連携による安全な支払い処理

## 🏗️ システム構成

### アーキテクチャ
- **マイクロサービスアーキテクチャ**: 独立したサービス単位での開発・デプロイ
- **API Gateway**: Nginxによる統一エンドポイント
- **コンテナ化**: Dockerによる環境の標準化

### 技術スタック

#### フロントエンド
- **Next.js 14** (React 18)
- **TypeScript**
- **Tailwind CSS**
- **React Hook Form + Zod**
- **React Query**
- **Zustand**

#### バックエンド
- **Go** (Gin) - User Service, Job Service
- **Python** (FastAPI) - Match Service, AI Service
- **PostgreSQL** - メインデータベース
- **MongoDB** - ドキュメント指向データ
- **Redis** - キャッシュ・セッション管理

#### インフラ・DevOps
- **Docker & Docker Compose**
- **Nginx** (API Gateway)
- **GitHub Actions** (CI/CD)
- **AWS** (本番環境)

## 🛠️ 開発環境セットアップ

### 前提条件
- Docker & Docker Compose
- Git
- Node.js 18+ (フロントエンド開発用)
- Go 1.21+ (バックエンド開発用)

### クイックスタート

1. **リポジトリのクローン**
```bash
git clone https://github.com/your-org/proxima.git
cd proxima
```

2. **環境設定**
```bash
# セットアップスクリプトの実行
chmod +x scripts/setup.sh
./scripts/setup.sh
```

3. **環境変数の設定**
```bash
# .env.exampleをコピーして設定
cp .env.example .env
# .envファイルを編集して必要な設定を行う
```

4. **サービスの起動**
```bash
# 全サービスの起動
docker-compose up

# バックグラウンドで起動
docker-compose up -d
```

### アクセス先

| サービス | URL | 説明 |
|---------|-----|------|
| フロントエンド | http://localhost:3000 | Next.jsアプリケーション |
| API Gateway | http://localhost:8080 | 統一APIエンドポイント |
| User Service | http://localhost:8001 | ユーザー管理API |
| Job Service | http://localhost:8002 | 案件管理API |
| Match Service | http://localhost:8003 | マッチング・推薦API |
| AI Service | http://localhost:8004 | AI・機械学習API |
| PostgreSQL | localhost:5432 | メインデータベース |
| MongoDB | localhost:27017 | ドキュメントDB |
| Redis | localhost:6379 | キャッシュ |

## 📁 プロジェクト構造

```
proxima/
├── docs/                    # ドキュメント
│   ├── requirements.md      # 要件定義書
│   └── system-design.md     # システム設計書
├── frontend/                # Next.jsフロントエンド
├── backend/                 # マイクロサービス群
│   ├── user-service/        # ユーザー管理サービス (Go)
│   ├── job-service/         # 案件管理サービス (Go)
│   ├── match-service/       # マッチングサービス (Python)
│   └── ai-service/          # AI・機械学習サービス (Python)
├── db/                      # データベース初期化
│   ├── init/                # PostgreSQL初期化
│   └── mongo-init/          # MongoDB初期化
├── infra/                   # インフラ設定
│   └── nginx/               # API Gateway設定
├── scripts/                 # 開発・運用スクリプト
└── docker-compose.yml       # Docker Compose設定
```

## 🔧 開発コマンド

### Docker操作
```bash
# 全サービス起動
docker-compose up

# 特定サービスのみ起動
docker-compose up postgres mongodb redis

# サービス停止
docker-compose down

# ログ確認
docker-compose logs -f [service-name]

# イメージ再ビルド
docker-compose build

# データベースリセット
docker-compose down -v
docker-compose up -d postgres mongodb redis
```

### 開発用コマンド
```bash
# フロントエンド開発サーバー
cd frontend
npm run dev

# バックエンドサービス開発
cd backend/user-service
go run main.go

# データベース接続
docker-compose exec postgres psql -U proxima_user -d proxima
docker-compose exec mongodb mongosh -u proxima_user -p proxima_password
```

## 🧪 テスト

```bash
# フロントエンドテスト
cd frontend
npm test

# バックエンドテスト
cd backend/user-service
go test ./...

# 統合テスト
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 📊 監視・ログ

### ヘルスチェック
```bash
# API Gateway
curl http://localhost:8080/health

# 各サービス
curl http://localhost:8001/health  # User Service
curl http://localhost:8002/health  # Job Service
curl http://localhost:8003/health  # Match Service
curl http://localhost:8004/health  # AI Service
```

### ログ確認
```bash
# 全サービスのログ
docker-compose logs -f

# 特定サービスのログ
docker-compose logs -f user-service
```

## 🚀 デプロイメント

### ステージング環境
```bash
# ステージング用ビルド
docker-compose -f docker-compose.staging.yml build

# ステージング環境デプロイ
docker-compose -f docker-compose.staging.yml up -d
```

### 本番環境
本番環境へのデプロイはGitHub Actionsによる自動化されたCI/CDパイプラインを使用します。

## 📚 API ドキュメント

各サービスのAPI仕様書は以下で確認できます：

- User Service: http://localhost:8001/docs
- Job Service: http://localhost:8002/docs
- Match Service: http://localhost:8003/docs
- AI Service: http://localhost:8004/docs

## 🤝 コントリビューション

1. フォークを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 📞 サポート

- 技術的な質問: [GitHub Issues](https://github.com/your-org/proxima/issues)
- ドキュメント: [docs/](./docs/)
- 要件定義書: [docs/requirements.md](./docs/requirements.md)
- システム設計書: [docs/system-design.md](./docs/system-design.md)

---

**Proxima** - フリーランスITエンジニア市場の未来を創造する
