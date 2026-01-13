---
title: "Apache Airflowのコミッターになった話"
date: 2023-05-11T00:00:00+00:00
tags: ["日本語", "airflow", "python"]
author: "Me"
categories: ["tech"]

editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

## Google Providersのバグを見つけた

先日DAGを開発中にGoogle Providers (`apache-airflow-providers-google==8.9.0`)の`CloudDataTransferServiceJobStatusSensor`を使用したところ、
`project_id`はオプション引数であるにも関わらず、省略するとエラーが発生するというバグに遭遇しました。

```python
[2023-03-09, 02:31:24 UTC] {taskinstance.py:1774} ERROR - Task failed with exception
Traceback (most recent call last):
  File "/home/airflow/.local/lib/python3.8/site-packages/airflow/sensors/base.py", line 236, in execute
    while not self.poke(context):
  File "/home/airflow/.local/lib/python3.8/site-packages/airflow/providers/google/cloud/sensors/cloud_storage_transfer_service.py", line 91, in poke
    operations = hook.list_transfer_operations(
  File "/home/airflow/.local/lib/python3.8/site-packages/airflow/providers/google/cloud/hooks/cloud_storage_transfer_service.py", line 380, in list_transfer_operations
    request_filter = self._inject_project_id(request_filter, FILTER, FILTER_PROJECT_ID)
  File "/home/airflow/.local/lib/python3.8/site-packages/airflow/providers/google/cloud/hooks/cloud_storage_transfer_service.py", line 459, in _inject_project_id
    raise AirflowException(
airflow.exceptions.AirflowException: The project id must be passed either as `project_id` key in `filter` parameter or as project_id extra in Google Cloud connection definition. Both are not set!
```

修正自体はそれほど困難に見えなかったため、Airflowにissueを報告するよりも、自分で直接修正に取り組むことにしました。

## Contributor手順を読んで環境構築する

むやみにコーディングするより、まずCONTRIBUTINGを読んだほうが良いと思い、下記のドキュメンを見つけました。

https://github.com/apache/airflow/blob/main/CONTRIBUTING.rst
けっこう長いので、前半をさらさらと読んで`Contribution Workflow`を参照しながら、ローカルの開発環境を問題なく構築しました。躓きそうなところ基本的にドキュメントにまとめてもらっています。

## 開発

https://github.com/apache/airflow/pull/30035/files#diff-2118fb849310fd85b9768e6732ab2dfa60ed75c751b5b9d0e176bcd1f950b6bbR75-R109

まず他のところを真似して`project_id`を指定しない場合の単体テスクを書きます。何も実装していないので、もちろんテストはコケます。その後、`CloudDataTransferServiceJobStatusSensor`の実装を下記のように`project_id`を明示的に指定しない場合、`hook.project_id`から取得できるように変更します。

```
- request_filter={"project_id": self.project_id, "job_names": [self.job_name]}
+ request_filter={"project_id": self.project_id or hook.project_id, "job_names": [self.job_name]}
```

これで終わり！PRを投げてPRを待ちます。
一週間もかからずApache Software Foundationメンバーの方からApproveをもらいました。
![](images/83aeaffb7ffa-20230511.png)


## 受け入れテスト

2週間後「[apache-airflow-providers-google 8.12.0rc1](https://pypi.org/project/apache-airflow-providers-google/8.12.0rc1/)をリリースされたので、リリースのテストをお願いします」の連絡がissueから来ました。

https://github.com/apache/airflow/issues/30427

`8.12.0rc1`をインストールし実際に`CloudDataTransferServiceJobStatusSensor`の動作を検証してみたら特に問題なかったので、うまく動いたよと返信しました。

![](images/de665e457d43-20230511.png)

数日後`8.12.0`が無事リリースされて、

https://airflow.apache.org/docs/apache-airflow-providers-google/stable/index.html#id5

> Support CloudDataTransferServiceJobStatusSensor without specifying a project_id (#30035)

修正がちゃんとリリースノートに書かれています。これでcoreにコミットしたわけではないですが、Apache Airflowのコミッターになりました。

## 感想

微力ながらずっとお世話になっているAirflowに貢献できてよかったです。理解を深めてモチベーション向上に繋がったのではないかと思います。
修正できるところまだまだたくさんありそうなので、今後も引き続きコミットしていきたいと思います。
