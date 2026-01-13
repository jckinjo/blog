---
title: "ワードクラウドを自作ニュースアプリに追加してみた"
date: 2022-05-14T00:00:00+00:00
tags: ["日本語", "nodejs", "javascript"]
author: "Me"
categories: ["tech"]

cover:
    image: "images/4abb33b0e465-20220514.png" # image path/url
editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

## はじめに
この間Node.jsで[多言語Webニュースアプリ](../20220418/)作ってみました

https://www.multitrue.news

ニュースのタイトルと概要だけではつまらないので、単語の出現頻度によって直近一週間のニュースからワードクラウド作って、一目で世の中の出来事を確認できたら面白そうじゃないかと思いながら、ワードクラウドをニュースアプリに追加してみました。

## 詳細

ソースはこちらから確認できます。

https://github.com/jckinjo/multitrue

### 下準備
日本語と中国語などは英語と異なり、単語と単語の間スペースがないので、形態素解析が必要です。簡略化するために、今回は英語のワードクラウドのみを作ることにしました。人称代名詞や助動詞のような`Stop Words`をワードクラウドに出しても意味がないので、NLTKの英語`Stop Words`辞書を利用します。

https://gist.github.com/sebleier/554280

また、単語の出現頻度を集計するヘルプ関数を作成します。いい感じライブラリもありますが、できるだけdependencyを減らしたいので、自分で実装することにしました。ただ、全ての単語を最終的に大文字に変換します。

`src/utils/countWordsFrequency.js`
```javascript
const stopwords = require('./stopwords-en.json');

// English stopwords via https://gist.github.com/sebleier/554280
const countWordsFrequency = (sentences) => {
  const result = {};

  // remove punctuation and split by space
  const terms = sentences.toLowerCase().match(/[a-zA-Z]+/g);

  terms.forEach((e) => {
    if (!stopwords.stopwords.includes(e)) {
      const name = e.toUpperCase();
      if (result[name]) {
        result[name] += 1;
      } else {
        result[name] = 1;
      }
    }
  });
  return Object.entries(result)
    .map(([key, value]) => ({
      name: key,
      value,
    }))
    .sort((a, b) => b.value - a.value);
};

module.exports = countWordsFrequency;
```

### ニュース記事の単語出現頻度を計算
続いて、英語ニュースを収集するcontrollerに単語頻度を計算するロジックを組み込みます。今回利用しているNewsAPIはニュースの本文を取得できないため、タイトルと概要から単語出現頻度を計算し、ニュース・メタ情報と一緒にレスポンスに追加します。（収集期間の`view-config.json`から日単位で設定できます）今考えるとやはり単語出現頻度の計算とニュースの取得を分けたほうが良いかもしれません。

`src/controllers/viewsController.js`
```javascript
exports.getHeadlinesUS = catchAsync(async (req, res) => {
  const news = await News.find({ category: 'general', country: 'us' })
    .sort('-publishedAt')
    .limit(viewConfig.limit);

  const articlesTitleDesc = await News.find({
    category: 'general',
    country: 'us',
    publishedAt: {
      $gt:
        Date.now() - viewConfig.wordscloud.dateRangeDay * 24 * 60 * 60 * 1000,
    },
  }).select('title description');
  const wordsFrequency = calcWordFrequncyInArticles(articlesTitleDesc);
  res.status(200).render('index', {
    countryMeta: {
      flag: '🇺🇸',
      title: 'Top Stories',
      code: 'us',
    },
    news,
    wordsFrequency,
  });
});
```

### 計算結果をフロントに渡す

`echarts-wordcloud`というライブラリでワードクラウドを描きます。
https://github.com/ecomfe/echarts-wordcloud

ドキュメントに参照しながら、インストールがうまくいかなかったため、リポジトリの`dist/`から`echarts-wordcloud`コピペして`public/js/echarts-wordcloud.js`、`public/js/echarts-wordcloud.js.map`として保存しました。


`src/views/scripts.pug`に関連スクリプトを追加します。`js/wordcloud.js`はワードクラウドの設定ファイルです。詳細は後ほど紹介します。

```pug
// Wordcloud
script(src='https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js')
script(src='js/echarts-wordcloud.js')

script.
  const wordsFrequency = !{JSON.stringify(wordsFrequency)};
script(src='js/wordcloud.js')
```

ワードクラウドを格納する`canvas-container`を`public/css/styles.css`に追加します。
```css
#canvas-container {
  overflow-x: auto;
  overflow-y: visible;
  position: relative;
  margin-top: 20px;
  margin-bottom: 20px;
}
.canvas {
  display: block;
  position: relative;
  overflow: hidden;
}

.canvas.hide {
  display: none;
}

#html-canvas > span {
  transition: text-shadow 1s ease, opacity 1s ease;
  -webkit-transition: text-shadow 1s ease, opacity 1s ease;
  -ms-transition: text-shadow 1s ease, opacity 1s ease;
}

#html-canvas > span:hover {
  text-shadow: 0 0 10px, 0 0 10px #fff, 0 0 10px #fff, 0 0 10px #fff;
  opacity: 0.5;
}

#box {
  pointer-events: none;
  position: absolute;
  box-shadow: 0 0 200px 200px rgba(255, 255, 255, 0.5);
  border-radius: 50px;
  cursor: pointer;
}
```

国がusの場合のみ、`canvas`を追加します。
`src/views/index.pug`
```pug
// ...
if countryMeta.code === 'us'
        #canvas-container
            canvas#canvas.canvas(width="1800", height="400")
// ...
```

最後はワードクラウドの設定です。けっこうややこしそうに見えますが、実際にいじった変数は

- sizeRange　文字サイズのレンジ
- rotationRange ローテーションの設定
- color

3つだけです。

`public/js/wordcloud.js`
```javascript
/* eslint-disable no-undef */
const chart = echarts.init(document.getElementById('canvas'));

const option = {
  tooltip: {},
  series: [
    {
      type: 'wordCloud',
      gridSize: 8,
      sizeRange: [8, 80],
      rotationRange: [0, 0],
      // rotationStep: 90,
      shape: 'square',
      left: 'center',
      top: 'center',
      width: '80%',
      height: '60%',
      right: 'center',
      bottom: 'center',
      drawOutOfBound: true,
      layoutAnimation: true,
      textStyle: {
        fontFamily: 'sans-serif',
        fontWeight: 'bold',
        color() {
          return `rgb(${[
            Math.round(Math.random() * 20),
            Math.round(Math.random() * 150),
            Math.round(Math.random() * 180),
          ].join(',')})`;
        },
      },
      emphasis: {
        focus: 'self',
        textStyle: {
          shadowBlur: 10,
          shadowColor: '#333',
        },
      },
      data: wordsFrequency,
    },
  ],
};

chart.setOption(option);

window.onresize = chart.resize;

```

## 最後に

最終的にこんな感じになりました。やはり最近だとウクライナ戦争がホットですね。
一刻も早く戦争が早く終わりますように。

https://www.multitrue.news/

![](images/4abb33b0e465-20220514.png)


今度は日本語と中国語のワードクラウドも追加してみようと思います。
最後まで読んでいただいてありがとうございます。