# Proxima デプロイメントガイド

このドキュメントでは、Proximaプラットフォームをローカル開発環境から本番環境まで段階的にデプロイする手順を説明します。

## 📋 目次

1. [前提条件](#前提条件)
2. [GitHubリポジトリの作成](#githubリポジトリの作成)
3. [ローカル開発環境](#ローカル開発環境)
4. [ステージング環境へのデプロイ](#ステージング環境へのデプロイ)
5. [本番環境へのデプロイ](#本番環境へのデプロイ)
6. [CI/CDパイプライン](#cicdパイプライン)
7. [トラブルシューティング](#トラブルシューティング)

## 🔧 前提条件

### 必要なツール
- **Git** (バージョン管理)
- **Docker & Docker Compose** (コンテナ化)
- **Node.js 18+** (フロントエンド開発)
- **Go 1.21+** (バックエンド開発)
- **AWS CLI** (クラウドデプロイ用)
- **Terraform** (インフラ管理)

### AWSアカウント設定
1. AWSアカウントの作成
2. IAMユーザーの作成（AdministratorAccess権限）
3. AWS CLIの設定
```bash
aws configure
```

### GitHubアカウント設定
1. GitHubアカウントの作成
2. SSH鍵の設定
3. Personal Access Tokenの生成

## 📦 GitHubリポジトリの作成

### 1. GitHubでリポジトリを作成

1. GitHub.comにログイン
2. 「New repository」をクリック
3. リポジトリ名: `proxima`
4. 説明: `フリーランスITエンジニア・マッチングプラットフォーム`
5. PublicまたはPrivateを選択
6. 「Create repository」をクリック

### 2. ローカルリポジトリの初期化

```bash
# 現在のディレクトリでGitリポジトリを初期化
git init

# .gitignoreファイルを作成
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
.next/

# Environment files
.env
.env.local
.env.production

# Logs
*.log
logs/

# Database
*.db
*.sqlite

# OS generated files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Terraform
*.tfstate
*.tfstate.backup
.terraform/
*.tfplan

# Docker
.docker/

# Temporary files
tmp/
temp/
EOF

# 全ファイルをステージング
git add .

# 初回コミット
git commit -m "Initial commit: Proxima platform setup"

# リモートリポジトリを追加（your-usernameを実際のユーザー名に変更）
git remote add origin https://github.com/your-username/proxima.git

# メインブランチにプッシュ
git branch -M main
git push -u origin main

# 開発ブランチを作成
git checkout -b develop
git push -u origin develop
```

### 3. GitHub Secretsの設定

リポジトリの「Settings」→「Secrets and variables」→「Actions」で以下のシークレットを設定：

```
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_ACCOUNT_ID=your_aws_account_id
DB_PASSWORD=your_secure_db_password
DOCDB_PASSWORD=your_secure_docdb_password
JWT_SECRET=your_jwt_secret_key
STRIPE_SECRET_KEY=your_stripe_secret_key (オプション)
OPENAI_API_KEY=your_openai_api_key (オプション)
```

## 🏠 ローカル開発環境

### 1. 環境構築

```bash
# リポジトリをクローン
git clone https://github.com/astertechs-dev/proxima.git
cd proxima

# 環境設定スクリプトを実行
chmod +x scripts/setup.sh
./scripts/setup.sh

# 環境変数を設定
cp .env.example .env
# .envファイルを編集して必要な設定を行う
```

### 2. サービス起動

```bash
# 全サービスを起動
docker-compose up -d

# ログを確認
docker-compose logs -f

# ヘルスチェック
curl http://localhost:8080/health
```

### 3. 開発用コマンド

```bash
# フロントエンド開発サーバー
cd frontend
npm install
npm run dev

# バックエンドサービス開発
cd backend/user-service
go mod download
go run main.go
```

## 🔄 ステージング環境へのデプロイ

### 1. 手動デプロイ

```bash
# デプロイスクリプトを実行
chmod +x scripts/deploy.sh
./scripts/deploy.sh staging
```

### 2. GitHub Actionsによる自動デプロイ

```bash
# developブランチにプッシュすると自動デプロイ
git checkout develop
git add .
git commit -m "Feature: Add new functionality"
git push origin develop
```

### 3. ステージング環境の確認

デプロイ完了後、以下で確認：

```bash
# ALB DNS名を取得
cd infra/terraform
terraform output alb_dns_name

# ヘルスチェック
curl http://your-alb-dns-name/health
```

## 🚀 本番環境へのデプロイ

### 1. プルリクエストの作成

```bash
# developからmainへのプルリクエストを作成
git checkout develop
git pull origin develop
git checkout main
git pull origin main
git merge develop
git push origin main
```

### 2. 本番デプロイの実行

```bash
# 手動デプロイ（推奨：GitHub Actions使用）
./scripts/deploy.sh production
```

### 3. 本番環境の確認

```bash
# ドメインでアクセス確認
curl https://proxima.example.com/health

# 各サービスのヘルスチェック
curl https://proxima.example.com/api/v1/users/health
curl https://proxima.example.com/api/v1/jobs/health
curl https://proxima.example.com/api/v1/match/health
curl https://proxima.example.com/api/v1/ai/health
```

## 🔄 CI/CDパイプライン

### GitHub Actionsワークフロー

`.github/workflows/ci-cd.yml`で定義されたパイプライン：

1. **テスト段階**
   - フロントエンド（lint, type-check, build）
   - バックエンド（Go, Python各サービスのテスト）

2. **ビルド段階**
   - Dockerイメージのビルド
   - ECRへのプッシュ

3. **デプロイ段階**
   - ステージング環境（developブランチ）
   - 本番環境（mainブランチ）

4. **セキュリティスキャン**
   - Trivyによる脆弱性スキャン

### ブランチ戦略

```
main (本番環境)
├── develop (ステージング環境)
│   ├── feature/user-authentication
│   ├── feature/job-matching
│   └── feature/ai-skillsheet
└── hotfix/critical-bug-fix
```

## 🏗️ インフラ構成

### AWS リソース

- **ECS Fargate**: コンテナオーケストレーション
- **Application Load Balancer**: トラフィック分散
- **RDS PostgreSQL**: メインデータベース
- **DocumentDB**: ドキュメントストア
- **ElastiCache Redis**: キャッシュ
- **S3**: ファイルストレージ
- **CloudWatch**: 監視・ログ
- **Route53**: DNS管理
- **ACM**: SSL証明書

### 環境別設定

| 項目 | ステージング | 本番 |
|------|-------------|------|
| インスタンスサイズ | t3.micro/small | t3.small/medium |
| 冗長化 | 単一AZ | マルチAZ |
| バックアップ | 1日 | 7日 |
| 監視 | 基本 | 詳細 |

## 🔍 監視・ログ

### CloudWatch監視

```bash
# ログ確認
aws logs describe-log-groups --log-group-name-prefix "/ecs/proxima"

# メトリクス確認
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=proxima-production-user-service \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### アプリケーション監視

```bash
# ヘルスチェック
curl https://proxima.example.com/health

# サービス別ヘルスチェック
for service in users jobs match ai; do
  echo "Checking $service service..."
  curl -s "https://proxima.example.com/api/v1/$service/health" | jq
done
```

## 🚨 トラブルシューティング

### よくある問題と解決方法

#### 1. Docker関連

```bash
# コンテナが起動しない
docker-compose logs [service-name]

# ポートが使用中
docker-compose down
sudo lsof -i :8080
sudo kill -9 [PID]

# イメージの再ビルド
docker-compose build --no-cache
```

#### 2. データベース接続エラー

```bash
# PostgreSQL接続確認
docker-compose exec postgres pg_isready -U proxima_user

# MongoDB接続確認
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# Redis接続確認
docker-compose exec redis redis-cli ping
```

#### 3. AWS デプロイエラー

```bash
# AWS認証情報確認
aws sts get-caller-identity

# Terraform状態確認
cd infra/terraform
terraform plan -var-file="environments/staging.tfvars"

# ECSサービス状態確認
aws ecs describe-services \
  --cluster proxima-staging-cluster \
  --services proxima-staging-user-service
```

#### 4. GitHub Actions エラー

```bash
# シークレット確認
# GitHub リポジトリ > Settings > Secrets and variables > Actions

# ワークフロー再実行
# GitHub リポジトリ > Actions > 失敗したワークフロー > Re-run jobs
```

### ログ確認コマンド

```bash
# ローカル環境
docker-compose logs -f [service-name]

# AWS環境
aws logs tail /ecs/proxima-staging --follow

# 特定サービスのログ
aws logs filter-log-events \
  --log-group-name "/ecs/proxima-staging" \
  --filter-pattern "ERROR"
```

## 📚 参考資料

- [AWS ECS ドキュメント](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions)
- [Docker Compose ドキュメント](https://docs.docker.com/compose/)

## 🆘 サポート

問題が発生した場合：

1. [GitHub Issues](https://github.com/your-username/proxima/issues) で報告
2. [トラブルシューティング](#トラブルシューティング) セクションを確認
3. ログを確認して詳細情報を収集
4. 必要に応じて開発チームに連絡

---

**注意**: 本番環境へのデプロイは慎重に行い、必ずステージング環境での十分なテストを実施してください。
