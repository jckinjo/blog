---
title: "Cloud Composerでmax_active_tasks_per_dagのデフォルト値が機能していない問題"
date: 2023-02-08T00:00:00+00:00
tags: ["日本語", "airflow", "googlecloud"]
author: "Me"
categories: ["tech"]
editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

## 問題

先日Cloud Composerの環境を↓にバージョンアップしました。

```
Cloud Composer 2.0.32
Airflow 2.2.5
```

`core.max_active_tasks_per_dag`という一つのDAG内同時に処理できるタスクの上限を設定するパラメータがデフォルト値16のままになっているのにも関わらず、実行するタスクの上限が明らかに16を超えています。

https://airflow.apache.org/docs/apache-airflow/stable/configurations-ref.html#max-active-tasks-per-dag

ローカルにある`Airflow 2.2.5`環境では何の異常もなく、ComposerのAirflow Configurationを確認したところ、なぜか`core.dag_concurrency`が100に設定されています。

```
[core]
dags_folder = /home/airflow/gcs/dags
plugins_folder = /home/airflow/gcs/plugins
executor = CeleryExecutor
dags_are_paused_at_creation = True
load_examples = False
donot_pickle = True
dagbag_import_timeout = 300
default_task_retries = 2
killed_task_cleanup_time = 3570
parallelism = 0
non_pooled_task_slot_count = 100000
dag_concurrency = 100
....
```

`core.dag_concurrency`の役割は`core.max_active_tasks_per_dag`と同じく、一つのDAG内同時に処理できるタスクの上限を設定しています。Airflow 2.2.0からはすでにDeprecatedになったはずなのに、なぜか残り続いています。

https://airflow.apache.org/docs/apache-airflow/stable/configurations-ref.html#dag-concurrency-deprecated

## 試み

手動で削除しようと思ったですけど、バージョンを上げたのでCloud Composer -> AIRFLOW CONFIGURATION OVERRIDESに`core.dag_concurrency`というパラメータすら存在しませんでした。

![](images/36892f49cf56-20230217.png)

仕方なく、GCSから設定ファイル`gs://asia-northeast1-colossus-wo-xxxxxxx-bucket/airflow.cfg`を直接編集してみました。しかし、`gcloud composer environments storage dags import`を実行すると初期化が処理が実行され、`core.dag_concurrency`が再び出てきました。

## 解決

デフォルト値ではなく、手動で`core.max_active_tasks_per_dag`を明示的に16に指定すると、実行するタスクの上限が期待通りに動作しました。

![](images/7be4cd914ab1-20230217.png)

ザクッとComposerのリリースノートを確認してこのバグまだ修正されていないようです。

https://cloud.google.com/composer/docs/release-notes
