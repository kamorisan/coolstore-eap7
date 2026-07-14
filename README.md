# Coolstore EAP7 Application

Red Hat JBoss EAP 7で動作するCoolstoreアプリケーションです。

## 概要

このプロジェクトは、Red Hat Developer Lightspeedワークショップで使用するレガシーJava EEアプリケーションのサンプルです。

**アプリケーション構成**:
- **フレームワーク**: Java EE 7 / JBoss EAP 7
- **ビルドツール**: Maven
- **データベース**: H2 (インメモリ)

## ワークショップでの使用

このリポジトリは、OpenShift Dev Spacesワークスペースで自動的にクローンされます。

### 前提条件

- OpenShift Dev Spaces 3.29.0以上
- Red Hat Developer Lightspeed (MTA) 拡張機能
- OpenShiftクラスターへのアクセス

### 自動設定

ワークスペース起動時に以下が自動実行されます：

1. **OpenShift自動ログイン** (`oc-auto-login`)
   - ユーザー名/パスワードで自動的にOpenShiftにログイン

2. **MTA設定** (`setup-mta-config`)
   - `.devspaces/provider-settings.yaml` をMTA拡張機能設定ディレクトリにコピー
   - Red Hat Developer Lightspeed (LLM) との連携を有効化

## ビルドと実行

### ビルド

```bash
mvn clean package
```

### ローカル実行（EAP 7サーバー必要）

```bash
# EAP 7がインストールされている場合
mvn jboss-as:deploy
```

### OpenShiftへのデプロイ

```bash
# Source-to-Image (S2I) ビルド
oc new-app jboss-eap72-openshift:latest~https://github.com/kamorisan/coolstore-eap7 \
  --name=coolstore-eap7

# Routeの作成
oc expose svc/coolstore-eap7
```

## プロジェクト構造

```
coolstore-eap7/
├── .devspaces/
│   └── provider-settings.yaml    # MTA (Red Hat Developer Lightspeed) 設定
├── src/
│   └── main/
│       ├── java/                 # Javaソースコード
│       └── resources/            # 設定ファイル
├── scripts/                      # デプロイメントスクリプト
├── standalone-full.xml           # JBoss EAP設定
└── pom.xml                       # Maven設定
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

## トラブルシューティング

### MTA設定が反映されない

```bash
# 設定ディレクトリを確認
ls -la /checode/remote/data/User/globalStorage/redhat.mta-core/settings/

# 手動でコピー
cp /projects/coolstore-eap7/.devspaces/provider-settings.yaml \
   /checode/remote/data/User/globalStorage/redhat.mta-core/settings/
```

### ワークスペースログの確認

```bash
# Setup MTA Config コマンドの実行ログを確認
# VS Code Terminalで "Tasks" 出力を確認
```

## 関連リソース

- [JBoss EAP 7 Documentation](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.4)
- [Red Hat Migration Toolkit for Applications](https://developers.redhat.com/products/mta/overview)
- [OpenShift Dev Spaces](https://developers.redhat.com/products/openshift-dev-spaces/overview)
- [Quarkus](https://quarkus.io/)

## ライセンス

このプロジェクトはワークショップ/トレーニング目的のサンプルアプリケーションです。
