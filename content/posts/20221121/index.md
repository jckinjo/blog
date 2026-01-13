---
title: "アラートを出す際にAirflowのContextから誤ったtask idが取得されてしまうバグの対処法"
date: 2022-11-21T00:00:00+00:00
tags: ["日本語", "airflow"]
author: "Me"
categories: ["tech"]

editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

先日投稿した[記事](../20221117)はAirflow DAGの`on_failure_callback`と`dagrun_timeout`を組み合わせることでDAGの遅延を監視する方法を紹介しました。


## Contextから誤ったtask idが取得されてしまう

`context`から`dag_run`の情報を取得してチャットツールやメールにアラートを出すのは一般的です。Slackにアラートを出す際の例ですが、`dag_id`, `run_id`, `task_id`, `reason`, `log_url`を取得して、webhookでSlackの特定なチャンネルに投稿し、`log_url`をクリックするだけですぐローカルあるいはクラウド環境（例えばCloud Composer）で失敗したtaskのログを確認できるので、アラート解消の効率化に繋がります。

![](images/a8c0942966d2-20221121.png)

ソースは以下となります。
```python
from slack_sdk.webhook import WebhookClient
from airflow.models import Variable
from textwrap import dedent


def notify_error(workflow: str, context: dict) -> None:
    webhook = WebhookClient(Variable.get("slack_webhook_access_token"))
    log_url = context.get("task_instance").log_url

    message = dedent(
        f"""
        :x: Task has failed.
	*Workflow*: {workflow}
	*DAG*: {context.get('task_instance').dag_id}
	*Run ID* {context.get('dag_run').run_id}
	*Task*: {context.get('task_instance').task_id}
	*Reason*: {context.get('reason')}
	<{log_url}| *Log URL*>
	"""
    )

    webhook.send(
        text="alert",
        blocks=[
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": message},
            }
        ],
    )
```

しかし、数回検証してみた結果、実行が失敗したタスク`task_id`ではなく、誤った`task_id`が取得されてしまう事象がしばしば発生します。Airflowの既知バグで、現時点（2022.11.21）はまだ修正されていないです。

検証環境 
```
Airflow 2.1.4
Airflow 2.2.5
```


## 対処法

https://stackoverflow.com/questions/72668764/get-task-id-of-failed-task-from-within-an-airflow-dag-level-failure-callback

stackoverflowの回答を参考しながら、解決法を考えてみました。
一旦`dag_run.get_task_instances(state="failed")`を利用して全てfailedとなったDAGのタスクを取得し、最初に失敗したtaskの`task_id`をアラートメッセージに入れることで、上記バグを回避できます。
通知用の関数を少し修正を入れる必要があります。
```
{context.get('task_instance').task_id} -> {failed_task.task_id}
<{log_url}| *Log URL*> -> <{failed_task.log_url}| *Log URL*>
```

```python
from slack_sdk.webhook import WebhookClient
from airflow.models import Variable
from textwrap import dedent

def notify_error(workflow: str, context: dict) -> None:
    webhook = WebhookClient(Variable.get("slack_webhook_access_token"))

    dag_run = context.get("dag_run")
    failed_task = [t for t in dag_run.get_task_instances(state="failed")][0]

    message = dedent(
        f"""
        :x: Task has failed.
        *Workflow*: {workflow}
        *DAG*: {failed_task.dag_id}
        *Run ID* {dag_run.run_id}
        *Task*: {failed_task.task_id}
        *Reason*: {context.get('reason')}
        <{failed_task.log_url}| *Log URL*>
        """
    )

    webhook.send(
        text="alert",
        blocks=[
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": message},
            }
        ],
    )
```

あくまでもtaskの実行が失敗したらすぐアラートを出すDAGの場合なので、より複雑なDAGだともう少し工夫が必要かもしれません。

ご参考になれば幸いです。
