# Coolstore EAP7 Application

Red Hat JBoss EAP 7で動作するCoolstoreアプリケーションです。

## 概要

このプロジェクトは、Red Hat Developer Lightspeedワークショップで使用するレガシーJava EEアプリケーションのサンプルです。

**アプリケーション構成**:
- **フレームワーク**: Java EE 7 / JBoss EAP 7.4
- **ビルドツール**: Maven
- **データベース**: PostgreSQL 13
- **データアクセス**: JPA 2.1 (Hibernate)
- **データマイグレーション**: Flyway

## ワークショップでの使用

このリポジトリは、OpenShift Dev Spacesワークスペースで自動的にクローンされます。

### 前提条件

- **OpenShift Dev Spaces** 3.x以上
- **Red Hat Developer Lightspeed (MTA)** 拡張機能
- **OpenShiftクラスターへのアクセス**: ユーザー権限
- **PostgreSQL**: 各ユーザーnamespaceに自動デプロイ済み

### 自動設定（devfile.yaml postStart events）

ワークスペース起動時に以下が自動実行されます：

1. **MTA設定自動配置** (`setup-mta-config`)
   - `.devspaces/provider-settings.yaml` をMTA拡張機能設定ディレクトリにコピー
   - Red Hat Developer Lightspeed (LLM) との連携を有効化
   - ログ: `/tmp/setup-mta-config.log`

2. **OpenShift自動ログイン** (`oc-auto-login`)
   - ユーザー名/パスワードで自動的にOpenShiftにログイン
   - ユーザーの開発namespace（例: user01-dev）に自動切り替え
   - `oc whoami` → ユーザー名（例: user01）
   - `oc project -q` → 開発namespace（例: user01-dev）

### ワークショップ手順

DevSpaces Workspaceを起動後：

1. **アプリケーションデプロイ**
   ```bash
   cd /projects/coolstore-eap7/scripts/openshift/eap7
   ./01-setup.sh && ./02-build.sh && ./03-deploy.sh
   ```

2. **アプリケーション動作確認**
   ```bash
   oc get route coolstore-eap7
   curl -sk https://$(oc get route coolstore-eap7 -o jsonpath='{.spec.host}')/services/products
   ```

3. **Red Hat Developer Lightspeedでコード分析**
   - VS Code左サイドバーから"MTA"拡張機能を開く
   - "Analyze"を実行してモダナイゼーション候補を確認

## 技術スタック

### バックエンド
- **Java EE 7** (CDI, JPA 2.1, JAX-RS 2.0, EJB 3.2)
- **JBoss EAP 7.4** (WildFly Core 15)
- **Hibernate** 5.3 (JPA実装)
- **PostgreSQL JDBC Driver** 42.x
- **Flyway** 4.1.2 (データベースマイグレーション)

### フロントエンド
- **AngularJS** 1.x
- **PatternFly** 3.x (Red Hat UIフレームワーク)
- **Bootstrap** 3.x

### ビルド・デプロイ
- **Maven** 3.6+
- **OpenShift S2I** (Source-to-Image)
- **Builder Image**: `registry.redhat.io/jboss-eap-7/eap74-els-openjdk8-openshift-rhel8`

### データベース
- **PostgreSQL** 13
- **初期データ**: 9商品（Quarkus T-shirt、RHEL T-shirt等）

---

## ビルドと実行

### ビルド

```bash
mvn clean package
```

### OpenShiftへのデプロイ（推奨）

このアプリケーションはOpenShift上でのデプロイを前提としています。

**前提条件**:
- OpenShiftプロジェクト（例: user01-dev）
- PostgreSQL Service（postgresql）とSecret（coolstore-db-secret）

**デプロイスクリプト**:

```bash
# OpenShiftにログイン
oc login <cluster-url> -u <username> -p <password>
oc project <your-namespace>

# デプロイスクリプトを順番に実行
cd scripts/openshift/eap7

# 1. BuildConfigとImageStreamの作成
./01-setup.sh

# 2. S2Iビルドの実行
./02-build.sh

# 3. アプリケーションのデプロイ
./03-deploy.sh
```

**自動実行内容**:
1. **01-setup.sh**: 
   - BuildConfig作成（Git URL、branch指定）
   - ImageStream作成
   - PostgreSQL JDBCモジュールのカスタムインストール設定
   
2. **02-build.sh**: 
   - S2Iビルド実行
   - PostgreSQL JDBCドライバー組み込み
   - JBoss EAP設定適用（standalone-full.xml）
   
3. **03-deploy.sh**: 
   - Deployment作成
   - PostgreSQL接続情報の環境変数設定
   - Route作成とヘルスチェック

**アクセス確認**:

```bash
# Route URL取得
oc get route coolstore-eap7

# Products API
curl https://<route-url>/services/products

# Web UI
curl https://<route-url>/
```

## プロジェクト構造

```
coolstore-eap7/
├── .devspaces/
│   ├── provider-settings.yaml       # MTA (Red Hat Developer Lightspeed) 設定
│   └── setup-mta-config.sh          # MTA設定自動配置スクリプト
├── src/
│   └── main/
│       ├── java/
│       │   └── com/redhat/coolstore/
│       │       ├── model/           # JPA Entity (Product, Order, etc.)
│       │       ├── service/         # Business Logic
│       │       ├── rest/            # JAX-RS REST API
│       │       └── utils/           # Database Migration (Flyway)
│       ├── resources/
│       │   ├── db/migration/        # Flyway SQLスクリプト
│       │   └── META-INF/
│       │       └── persistence.xml  # JPA設定（PostgreSQL DataSource）
│       └── webapp/                  # Web UI
├── s2i/
│   └── eap-install/
│       └── modules/org/postgresql/  # PostgreSQL JDBCモジュール
├── scripts/
│   └── openshift/eap7/
│       ├── 01-setup.sh              # BuildConfig作成
│       ├── 02-build.sh              # S2Iビルド実行
│       └── 03-deploy.sh             # デプロイ実行
├── standalone-full.xml              # JBoss EAP設定（PostgreSQL Datasource定義）
├── devfile.yaml                     # OpenShift Dev Spaces設定
└── pom.xml                          # Maven設定
```

## MTA設定 (.devspaces/provider-settings.yaml)

このファイルは、Red Hat Developer Lightspeed (MTA拡張機能) がLLMと通信するための設定を含んでいます。

**設定内容**:
- **Provider**: ChatOpenAI互換
- **Model**: gpt-oss-120b
- **Endpoint**: https://maas-rhdp.apps.maas.redhatworkshops.io/v1

ワークショップ環境ではこのファイルがワークスペース起動時に自動的に適用されます。

## モダナイゼーションの対象

このアプリケーションは以下のモダナイゼーションの対象となります：

1. **Java EE → Jakarta EE**
   - javax.* → jakarta.* パッケージ移行

2. **JBoss EAP → Quarkus/Spring Boot**
   - マイクロサービスアーキテクチャへの移行
   - Cloud-native対応

3. **インフラストラクチャ**
   - 従来のアプリケーションサーバー → コンテナ化

## Red Hat Developer Lightspeedの使用

ワークスペースで以下の機能を使用できます：

### 1. コード分析

VS Code拡張機能 "Red Hat Developer Lightspeed" を使用して：
- レガシーコードの分析
- 移行の問題点の検出
- モダナイゼーションの提案

### 2. AIによる移行支援

- LLMを使用したコード変換の提案
- ベストプラクティスの推奨
- マイグレーションパスの提示

## REST API

アプリケーションは以下のRESTエンドポイントを提供します：

### Products API

```bash
# 全商品取得
GET /services/products

# レスポンス例
[
  {
    "itemId": "329299",
    "name": "Quarkus T-shirt",
    "desc": "",
    "price": 10.0,
    "quantity": 735,
    "location": "Raleigh",
    "link": "http://maps.google.com/?q=Raleigh"
  },
  ...
]
```

### Cart API

```bash
# カート取得
GET /services/cart/{cartId}

# カート追加
POST /services/cart/{cartId}/{itemId}/{quantity}

# カート削除
DELETE /services/cart/{cartId}/{itemId}/{quantity}

# チェックアウト
POST /services/cart/checkout/{cartId}
```

### Web UI

```bash
# メインページ
GET /

# ヘルスチェック
GET /health.jsp
```

**テストコマンド例**:

```bash
ROUTE=$(oc get route coolstore-eap7 -o jsonpath='{.spec.host}')

# 商品一覧
curl -sk "https://${ROUTE}/services/products" | jq '.[] | {name, price}'

# ヘルスチェック
curl -sk "https://${ROUTE}/health.jsp"
```

---

## データベース構成

### PostgreSQL接続

アプリケーションは以下の環境変数でPostgreSQLに接続します：

```bash
DB_HOST=postgresql               # PostgreSQL Service名
DB_PORT=5432
DB_DATABASE=coolstore
DB_USERNAME=coolstore
DB_PASSWORD=coolstore
```

これらは`scripts/openshift/eap7/03-deploy.sh`で自動設定されます。

### データベーススキーマ

Flywayによる自動マイグレーション：

1. **V1.1__CreateSchema.sql**: テーブル作成
   - PRODUCT_CATALOG
   - INVENTORY
   - ORDERS, ORDER_ITEMS
   
2. **V1.2__AddInitialData.sql**: 初期データ投入
   - 9商品のサンプルデータ

### JPA設定

[persistence.xml](src/main/resources/META-INF/persistence.xml):
```xml
<jta-data-source>java:jboss/datasources/CoolstoreDS</jta-data-source>
```

[standalone-full.xml](standalone-full.xml):
```xml
<datasource jndi-name="java:jboss/datasources/CoolstoreDS" ...>
  <connection-url>jdbc:postgresql://${env.DB_HOST}:${env.DB_PORT}/${env.DB_DATABASE}</connection-url>
  <driver>postgresql</driver>
</datasource>
```

## トラブルシューティング

### MTA設定が反映されない

```bash
# postStartログ確認
cat /tmp/setup-mta-config.log

# 設定ディレクトリ確認
ls -la /checode/remote/data/User/globalStorage/redhat.mta-core/settings/

# 手動でコピー（暫定対応）
bash /projects/coolstore-eap7/.devspaces/setup-mta-config.sh
```

### PostgreSQL接続エラー

```bash
# PostgreSQL Service確認
oc get svc postgresql

# PostgreSQL Pod確認
oc get pods -l app=postgresql

# Secret確認
oc get secret coolstore-db-secret -o yaml

# アプリケーションログでDB接続確認
oc logs -f deployment/coolstore-eap7 | grep -i postgres
```

### S2Iビルド失敗

```bash
# ビルドログ確認
oc logs -f bc/coolstore-eap7

# Git認証Secret確認
oc get secret gitea-git-secret
oc describe sa builder | grep gitea-git-secret

# BuildConfig確認
oc get bc coolstore-eap7 -o yaml | grep -A 5 sourceSecret
```

## 関連リソース

- [JBoss EAP 7 Documentation](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.4)
- [Red Hat Migration Toolkit for Applications](https://developers.redhat.com/products/mta/overview)
- [OpenShift Dev Spaces](https://developers.redhat.com/products/openshift-dev-spaces/overview)
- [Quarkus](https://quarkus.io/)

## ライセンス

このプロジェクトはワークショップ/トレーニング目的のサンプルアプリケーションです。
