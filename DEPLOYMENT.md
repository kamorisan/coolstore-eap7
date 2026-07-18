# Coolstore EAP7 デプロイ手順

## 前提条件

1. **OpenShiftクラスタへのアクセス**
   ```bash
   oc login <cluster-url>
   ```

2. **プロジェクトの作成または選択**
   ```bash
   oc new-project admin-dev
   # または既存プロジェクトを使用
   oc project admin-dev
   ```

3. **PostgreSQLのデプロイ**
   ```bash
   # PostgreSQL 13をデプロイ
   oc new-app postgresql-persistent \
     --param POSTGRESQL_DATABASE=coolstore \
     --param POSTGRESQL_USER=coolstore \
     --param POSTGRESQL_PASSWORD=coolstore123 \
     --param VOLUME_CAPACITY=1Gi \
     --param POSTGRESQL_VERSION=13-el8
   
   # Secretの作成
   oc create secret generic coolstore-db-secret \
     --from-literal=DB_NAME=coolstore \
     --from-literal=DB_USERNAME=coolstore \
     --from-literal=DB_PASSWORD=coolstore123
   ```

## デプロイ手順

### 方法1: 全自動デプロイ（推奨）

```bash
cd /path/to/coolstore-eap7

# 3つのスクリプトを順番に実行
./scripts/openshift/eap7/01-setup.sh && \
./scripts/openshift/eap7/02-build.sh && \
./scripts/openshift/eap7/03-deploy.sh
```

### 方法2: ステップバイステップ

#### ステップ1: BuildConfig作成

```bash
cd /path/to/coolstore-eap7
./scripts/openshift/eap7/01-setup.sh
```

**実行内容**:
- BuildConfig作成（Git S2I）
- ImageStream作成
- `CUSTOM_INSTALL_DIRECTORIES=s2i/eap-install`設定

**確認**:
```bash
oc get bc coolstore-eap7
oc get is coolstore-eap7
```

#### ステップ2: S2Iビルド実行

```bash
./scripts/openshift/eap7/02-build.sh
```

**実行内容**:
- GitHubからソースコード取得
- Mavenビルド（ROOT.war生成）
- PostgreSQL JDBC Driver配置
- JMS設定スクリプト配置
- イメージ生成

**確認**:
```bash
oc get builds
oc logs -f bc/coolstore-eap7
```

#### ステップ3: アプリケーションデプロイ

```bash
./scripts/openshift/eap7/03-deploy.sh
```

**実行内容**:
- Deployment作成
- 環境変数設定（Datasource）
- Secret参照設定
- Service作成
- Route作成（HTTPS）

**確認**:
```bash
oc get pods
oc get routes
```

## 環境変数のカスタマイズ（オプション）

デプロイ前に環境変数を変更したい場合:

```bash
# プロジェクト名を変更
export PROJECT_NAME="my-project"

# アプリケーション名を変更
export APP_NAME="my-coolstore"

# PostgreSQLサービス名を変更
export POSTGRESQL_SERVICE="my-postgresql"

# PostgreSQL Secretを変更
export POSTGRESQL_SECRET="my-db-secret"

# その後、デプロイスクリプト実行
./scripts/openshift/eap7/01-setup.sh
./scripts/openshift/eap7/02-build.sh
./scripts/openshift/eap7/03-deploy.sh
```

## デプロイ後の確認

### 1. Pod状態確認

```bash
oc get pods -l deployment=coolstore-eap7

# 期待値: STATUS=Running, READY=1/1
```

### 2. デプロイメント確認

```bash
POD_NAME=$(oc get pods -l deployment=coolstore-eap7 \
  --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}')

oc exec "${POD_NAME}" -- \
  /opt/eap/bin/jboss-cli.sh --connect \
  --command='deployment-info'

# 期待値: ROOT.war STATUS=OK
```

### 3. JMS Topic確認

```bash
oc exec "${POD_NAME}" -- \
  /opt/eap/bin/jboss-cli.sh --connect \
  --command='/subsystem=messaging-activemq/server=default:read-children-names(child-type=jms-topic)'

# 期待値: "result" => ["orders"]
```

### 4. Datasource接続テスト

```bash
oc exec "${POD_NAME}" -- \
  /opt/eap/bin/jboss-cli.sh --connect \
  --command='/subsystem=datasources/data-source=coolstore_postgresql-DB:test-connection-in-pool'

# 期待値: "outcome" => "success", "result" => [true]
```

### 5. アプリケーションアクセス

```bash
ROUTE_URL=$(oc get route coolstore-eap7 -o jsonpath='https://{.spec.host}/')
echo "Application URL: ${ROUTE_URL}"

# ブラウザでアクセスまたは
curl -k "${ROUTE_URL}"
```

## 再デプロイ

### ソースコード変更後の再ビルド

```bash
# Gitにpush後
oc start-build coolstore-eap7 --follow --wait

# デプロイは自動的にトリガーされます
```

### 設定変更のみ（イメージ変更なし）

```bash
# Deploymentを再起動
oc rollout restart deployment/coolstore-eap7

# 完了を待つ
oc rollout status deployment/coolstore-eap7
```

### 完全な再デプロイ

```bash
# 全リソース削除
oc delete all -l app=coolstore-eap7
oc delete secret coolstore-db-secret
oc delete pvc postgresql

# PostgreSQLから再デプロイ
# （前提条件のPostgreSQLデプロイから実行）
```

## トラブルシューティング

### Pod起動失敗

```bash
# Pod状態確認
oc get pods

# ログ確認
oc logs <pod-name>

# イベント確認
oc describe pod <pod-name>
```

### ビルド失敗

```bash
# ビルドログ確認
oc logs -f bc/coolstore-eap7

# 再ビルド
oc start-build coolstore-eap7
```

### データソース接続エラー

```bash
# PostgreSQL確認
oc get pods -l name=postgresql
oc exec <postgresql-pod> -- psql -U coolstore -d coolstore -c "\dt"

# Secret確認
oc get secret coolstore-db-secret -o yaml

# 環境変数確認
oc set env deployment/coolstore-eap7 --list | grep DB
```

### ROOT.war デプロイ失敗

```bash
POD_NAME=$(oc get pods -l deployment=coolstore-eap7 \
  --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}')

# デプロイメントディレクトリ確認
oc exec "${POD_NAME}" -- ls -la /opt/eap/standalone/deployments/

# .failed マーカーがある場合は削除して再デプロイ
oc exec "${POD_NAME}" -- rm -f /opt/eap/standalone/deployments/ROOT.war.failed
oc exec "${POD_NAME}" -- touch /opt/eap/standalone/deployments/ROOT.war.dodeploy
```

## リソース削除

### アプリケーションのみ削除

```bash
oc delete all -l app=coolstore-eap7
oc delete is coolstore-eap7
oc delete bc coolstore-eap7
```

### PostgreSQLも含めて全削除

```bash
oc delete all -l app=coolstore-eap7
oc delete all -l app=postgresql-persistent
oc delete secret coolstore-db-secret
oc delete pvc postgresql
```

## 参考

- 詳細な技術ドキュメント: [coolstore-eap7-openshift-deployment-guide.md](coolstore-eap7-openshift-deployment-guide.md)
- GitHubリポジトリ: https://github.com/kamorisan/coolstore-eap7.git
- ブランチ: ocp-s2i-eap7
