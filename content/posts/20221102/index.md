---
title: "GitHub Issueだけで自分のルーティングを管理し、そして草を生やす"
date: 2022-11-02T00:00:00+00:00
tags: ["日本語", "python"]
author: "Me"
categories: ["tech"]

editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

先日シェルスクリプトで[個人ナレッジマネジメントツール](../20220503)を作った話しを投稿して、予想以上に需要がありました。

## ルーティングをGitHub Posterに生成

似たような発想でルーティング管理アプリを使わずに、GitHubのcontributionsのように自分のルーティング（例えば読書、ランニング、LeetCode、外国語の勉強）を管理できると面白くない？と思いながら、GitHub上で検索したらyihong0618さんが開発したGitHubPosterを発見しました。

https://github.com/yihong0618/GitHubPoster

GitHub Isssue、Duolingo、Twitter、Kindleなど20個以上のAPIで履歴を取得し、GitHub svg poster（aka. 皆さんが大好きなGitHubの草）を生成します。

## 実際使ってみよう

ローダーは20個以上あり、とりあえずissueで今年年始以来の読書ルーティングの草を生やしてみました。

### Issueを書く

issueフォーマットは↓に従う必要でがあります。

```
{整数}

{内容}
```

今年は1月から、日課をこなした日に当該Issueに↓のコメント追加していました。

```
2

「データ指向アプリケーションデザイン」
```

### 環境構築
```console
pip install -U 'github_poster[all]'
```

### 実行

GitHubをトークンを取得し、下記コマンドを実行するだけです。
```console
github_poster issue --issue_number ${issue_number} --repo_name ${repo_name} --token ${github_token}
```

また、オプション
- `--special-color1`
- `--special-color2`
- `---stand-with-ukraine`

などによって色を指定することも可能です。（ウクライナをサポートする配色もあるようですね）

### 結果

最終的に生成されたGitHub Poster（`.svg`ファイル）はこんな感じです。単位はtimes（回数）になっているが、hours（時間）が正しいです。
![](images/0afeec835744-20221101.png)

確認してみると、
今年今まで336時間読書していて、週の真ん中あまり本を読んでいないと気づきました。

## 使った感想

- 余計なモバイルアプリを使わずに、ルーティング管理できるのはミニマムリスト的には最高
- 生成されたファイルは`.svg`なので、自分のサイトや他のところに取り入れるのも簡単そう
- 新しいローダーの開発に貢献してみたい
