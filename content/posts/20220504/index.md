---
title: "Herokuにデプロイする際のTips"
date: 2022-05-04T00:00:00+00:00
tags: ["日本語"]
author: "Me"
categories: ["tech"]

editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---


2022年11月28日をもってHerokuフリープランが終了しました

https://blog.heroku.com/new-low-cost-plans

---

個人開発する際にコスト面と手軽さを考えるとAWSにデプロイするのはあまりふさわしくないでしょう。Herokuだともっと手軽くデプロイできるし無料枠もあるので、個人で開発したおもちゃをデプロイするのはちょうどいい感じだと思います。この間筆者が開発した[多言語Webニュースアプリ](../20220418/)も`Heroku`にデプロイしています。


本記事では、Herokuにデプロイする際のTipsをいくつかを紹介したいと思います。少しでもお役に立てれば幸いです。

# Tip 1: GitHub Actionsで自動デプロイ

https://devcenter.heroku.com/articles/git

コマンドラインでいちいち打つのは面倒くさいので、自動デプロイしたほうが断然便利ですね。もちろんHerokuのGUIからも自動デプロイできますが、せっかくソースコードもGitHubで管理しているので、GitHub Actions を使ったほう便利だと思います。

`heroku-deploy`というアクションを利用すると、Herokuのメールアドレスと`heroku_api_key`さえわかれば、GitHub Actionsから自動デプロイできます。ちなみに、`heroku_api_key`は[こちら](https://dashboard.heroku.com/account)から取得できます。
GitHub Actionsの設定についてですが、他の記事を見たかぎり`on: [push, pull_request]`に設定している方もいました。本番にデプロイするという意味合いもあるので、個人的には`release`（リリース作成するたびに、パイプラインが発火される）に設定したほうがいいではないかと思います。ミスってpushしちゃったのも防げます。

```yaml
on:
  release:
    types: published

name: Deploy to PROD

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{secrets.HEROKU_API_KEY}}
          heroku_app_name: 'your_app_name'
          heroku_email: ${{secrets.HEROKU_EMAIL}}
```



# Tip 2: 無料枠を使いこなす

現時点(2022年5月)Herokuのプランはこうなっています。
![](images/8dec79541ac8-20220504.png)

https://devcenter.heroku.com/articles/free-dyno-hours

> Personal accounts are given a base of 550 free dyno hours each month. In addition to these base hours, accounts which verify with a credit card will receive an additional 450 hours added to the monthly free dyno quota.

アカウントごとに月に550時間の無料枠が付与されて、クレジットカードと紐付ければさらに450時間が追加されます。月に720時間を計算すれば、一つのアプリケーションを走らせるのは十分でしょう。
しかし、そんなにおいしい話ではありません。無料枠なので、必ずなんらかの制限があります。

> If an app has a free web dyno, and that dyno receives no web traffic in a 30-minute period, it will sleep. In addition to the web dyno sleeping, the worker dyno (if present) will also sleep.

アクセスなしで30分経つと、アプリケーションが強制的にsleepされます。staticなアプリケーションはまだいいですが、定期的にスクリプトを走らせてデータを取得してDBに書き込むような操作がある場合は困りますね。
**sleepさせないためのハック**があるので、ご心配無用です。

下記のコードを追加するだけです。

```javascript
const http = require('http');
setInterval(() => {
    http.get('https://your_app_name.herokuapp.com/');
}, 15 * 60 * 1000);
```

やっていることとしては、15分ごとに自分自身をpingすることで、Web dynoを起こしています。（`Node.js`の例ですが、他の言語でも簡単に実装できるはずです。）
まさにこんな感じですね。
**寝るな！！！起きろう！！！**
![](images/80ff169fd630-20220504.png)

# Tip 3: カスタムドメイン

自分がせっかく作ったアプリケーションを他人に見せる時に`https://your_app_name.herokuapp.com`のようなドメインはかっこいいとは言えないでしょう。GMOかGoogleなどドメインをサービスを提供しているところからドメインを購入して、ドメインをカスタマイズすることができます。ただし、気を付けていただきたいのは`Free`プランだとSSL認証の機能がないので、`Hobby`以上のプランが必要です。

まずは、Heroku APPのsettings（`https://dashboard.heroku.com/apps/{YOUR_APP_NAME}/settings`）からドメインを設定します。申請済みのドメインを入力するとDNS Targetを取得できます。

![](images/15b38bf71db9-20220504.png)


続いて、DNS Targetをドメインプロバイダーに提供します。GMO MuuMuuDomainの場合、ムームーDNSをクリックして、サブドメイン、種別（CNAME）、内容（DNS Target）を入力します。他のプロバイダーの設定が若干違うかもしれないです。通常は30分前後経つと、設定したドメインからでもアプリケーションにアクセスできるようになります。

![](images/43c41e458854-20220504.png)

以上です。

Happy Heroku Life!!
