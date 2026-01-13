---
title: "M1 MacでDocker DesktopからRancher Desktopに移行"
date: 2023-01-19T00:00:00+00:00
tags: ["日本語", "docker"]
author: "Me"
categories: ["tech"]

editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

https://www.docker.com/pricing/october-2022-pricing-change-faq/

> The list price of the Docker Business subscription will go up by $3, to $24 per user per month

2022年10月のお知らせですが、Docker Desktop Business subscriptionがなんと8倍値上げ！！
コスト面の理由でRancher Desktopに移行することになりました

移行する際に、Rancher Desktopの2つバグを見つけました。これから躓く人もいると思うので、一旦バグ内容と解決法を共有します。

## バグ1：volumesをマウントする際に`chown`から`permission denied`エラーが出る

https://github.com/rancher-sandbox/rancher-desktop/issues/1209

issue自体はまだ解決されていない(2023年1月)ですが、
`~/Library/Application\ Support/rancher-desktop/lima/_config/override.yaml`に下記の設定を追加すれば回避できます。
```
mountType: 9p
mounts:
  - location: "~"
    9p:
      securityModel: mapped-xattr
      cache: "mmap"
```

## バグ2：M1 MacはMonterey 12.4以上に上げないと、割り当てられるメモリは最大3GBになる

Rancher DesktopのGUIからメモリを32GBに設定したにもかかわらず、

![](images/84ff3f794bab-20230119.png)

`docker info`で確認すると、CPUは設定通りですが、メモリは2.9GiBしか割り当てられていませんでした。

```
 Architecture: aarch64
 CPUs: 6
 Total Memory: 2.909GiB
 Name: lima-rancher-desktop
```

https://github.com/rancher-sandbox/rancher-desktop/issues/2855

Rancher Desktopがlimaという仮想マシンを利用しているので、どうやらMonterey 12.4に上げないといけません。

## 解決

arm64の対応がまだ難しそうなので、他の方法を考えました。

`minikube`を使うとDocker DesktopあるいはRancher Desktopを経由せず、Dockerエンジンをインストールする方法もあります。
しかしM1 Mac（arm64）は`hyperkit`のインストールがうまくいきませんでした。
https://dhwaneetbhatt.com/blog/run-docker-without-docker-desktop-on-macos

結局諦めてEC2のUbuntu環境でリモート開発することにしました。そのままDockerエンジンをインストールできるのでそもそもDocker DesktopかRancher Desktopを悩む必要がありません。

