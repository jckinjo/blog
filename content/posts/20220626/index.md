---
title: "自作PCからUbuntu22.04開発環境構築してみた"
date: 2024-04-20T00:00:00+00:00
tags: ["日本語", "linux"]
author: "Me"
categories: ["tech"]

editPost:
    URL: "https://github.com/jckinjo/blog/tree/master/content"
    Text: "Suggest Changes" # edit text
    appendFilePath: true # to append file path to Edit link
---

## 更新履歴

- 2022/06/26: 初稿
- 2024/04/20: 起動時`I/O error, dev sda, sector xxxxxxxxxx`のエラーが発生した。smartctlで確認したところ、問題がなかったので、手順の最新化を行い再度インストールした

---

アップルをはじめとして、最近スペックがそこそこ良いPCがわけわからないくらい高くなり、誰でも使える個人用のコンピュータというPersnal Computerの趣旨と乖離しています。独断と偏見ですが、せっかく数十万円でPCを購入したのにもかかわらず、

- パーツ交換不可なので、数年後は電子ゴミになり、自然環境に優しくない
- 不要なソフトウェア・サービスが多い（たとえば、2022年なのに、バージョン管理非対応のクラウドサービスiCloudが大きなシェアを占めているっていう皮肉）
- なんとかStoreの通知がうるさい。利用するのにアカウント（個人情報）が必要
- プライバシー侵害問題
- ...

https://www.theguardian.com/world/2021/oct/15/apple-plan-scan-child-abuse-images-tears-heart-of-privacy

別にゲーマーではないですが、数十万払ったのに自由が奪われる感じがどうしても気に入らないので、自作PCからLinuxの開発環境を構築することにしました。

## ハードウェア
秋葉原まで行く元気がなかったので、すべてのパーツはAmazonやメルカリから購入することにしました。また、PCパーツの価格変動が激しいのでkeepaのメール通知機能を活用すると簡単に低価格でお気に入りのパーツ狙えます。
https://keepa.com/

最終的に以下のパーツを買いました。
|             | Model                               | Price       |
| ----------- | ----------------------------------- | ----------- |
| Motherboard | ASUS Intel B560M-A                  | ¥10,563     |
| CPU         | Intel Core i5 10400                 | ¥18,943     |
| GPU         | ASUS GTX 1650-4G DUAL               | ¥21,500     |
| Power       | 玄人志向 KRPW-BK 80PLUS Bronze 750W | ¥5,535      |
| Memory      | KLEVV DDR4 2666 PC4-21300 8GB*2     | ¥7,002      |
| Storage     | Crucial SSD 500GB MX500             | ¥5,980      |
| CPU Cooler  | CPUクーラー 虎徹 Mark II            | ¥3,400      |
| Case        | SAMA JAX-03W (second hand)          | ¥4,480      |
| LAN cable   |                                     | ¥945        |
| Total       |                                     | **¥78,348** |

あくまで筆者の例ですが、他のパーツに替えても全然問題がありません。パーツ間の互換性と電源容量だけ気をつけてください

![](images/1a35023684e3-20220626.jpg)
![](images/f52ac0a927e4-20220626.jpg)

完成！！！
パーツをマザーボードに突っ込むだけの作業なので、そこまで難しくはないです。
![](images/1532b70611b1-20220626.jpg)


ハードウェアの環境構築を完了したので、これからソフトウェアの環境構築に入ります。


## OS: Ubuntu 22.04

### なぜ22.04

最近の暗黙的なルールだと偶数年4月（22.04, 20.04.4, 18.04.6）以外のバージョンはLTSではないので、特別な理由がない限り使うのをおすすめしません。せっかくなので最新LTS 22.04 Jammy Jellyfishをインストールします。今度はArch Linux系も挑戦してみたいですね
余談ですが、今年1月まで使っていた21.04のサポートが切れたので、21.10にアップグレードしようとしたら、OS自体が崩壊しました（）

https://wiki.ubuntu.com/Releases

### Bootable USBを作成

1. 公式から`Ubuntu 22.04 LTS`をダウンロードします。

https://releases.ubuntu.com/

2. USBを他のPCに挿し込んで、デバイス名（例えば`/dev/sdd`）を確認します。

```bash
sudo fdisk -l
```

3. ddコマンドを実行します。
```bash
sudo dd if={YOUR_ISO_NAME} of={YOUR_DEVICE_NAME} bs=1M status=progress
```
なお、`bs=1M`というのは一度に読み書きするサイズを1MBにするという意味です。

4. USBに組み立てたデスクトップPCに挿し込んで、ガイダンスにしたがって20分前後インストールが完了します。

まずBIOSの設定で、USBから起動するように設定しておきましょう。
その後、インストールの際には、`Minimal Install`と`Normal Install`の2つのオプションがありますが、
筆者自身は余計なソフトウェア一切いらないので、`Minimal Install`を選んでOSをインストールしました。

## 必要最小限の設定
開発環境を構築する前に、必要最小限なソフトウェアを入れておきましょう。

### システムアップデート

```bash
sudo apt update
sudo apt upgrade
```

### Wifiドライバー

2024/04/26追記: `sudo apt upgrade`を実行すると`TP-Link Archer T3U`系のドライバがインストールされるようになりました。もし、インストールされていない場合は、下記の手順を実行してください。


デスクトップから自宅のルーターの距離が遠いので、USB無線LAN子機を購入しました。しかし、デフォルトのドライバーは想定通りにLinux非対応です。
GitHubで`Linux Driver for USB WiFi Adapters`で検索してみたら、下記のLinux用ドライバーを見つけました。しかも最近もバリバリ開発されているようなので、早速入れることにしました。USB無線LAN子機によっては、下記のドライバーが使えない場合もあるので、その場合は別のドライバーを探してください。

#### RTL8812BU and RTL8822BU Chipsets

https://github.com/morrownr/88x2bu-20210702

`README.md`にしたがって、スクリプトでインストールします。
```bash
sudo apt install -y dkms git build-essential
git clone https://github.com/morrownr/88x2bu-20210702.git
cd 88x2bu-20210702/
sudo ./install-driver.sh
```

#### TP-Link Archer T3U driver

TP-Link Archer T3U系の場合は、下記のリポジトリを使います。

Clone the repository

```bash
sudo apt install git dkms rsync build-essential bc
git clone https://github.com/cilynx/rtl88x2bu.git
cd rtl88x2bu
```

Install

```bash
VER=$(sed -n 's/\PACKAGE_VERSION="\(.*\)"/\1/p' dkms.conf)
sudo rsync -rvhP ./ /usr/src/rtl88x2bu-${VER}
sudo dkms add -m rtl88x2bu -v ${VER}
sudo dkms build -m rtl88x2bu -v ${VER}
sudo dkms install -m rtl88x2bu -v ${VER}
sudo modprobe 88x2bu
```

### 入力ソース

Ubuntuはデフォルト英語入力しかはいっていないので、日本語と中国語の入力ソースを追加します。

#### 日本語入力

Setting -> Region & Language -> Manage Installed Languages -> The language support is not installed completely” と表示さて -> Install

```bash
sudo apt install ibus-mozc 
ibus restart 
gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'mozc-jp')]"
```

USキーボードを利用している方はmozc入力モードの切り替えを設定しておくと便利でしょう。

Mozc Setting -> Keymap style -> Customize
- パッティングを避けるために、「Ctrl Space」になっているコマンドを適当なものに変更
-「key」が「Hankaku/Zenkaku」になっている4箇所を「Ctrl Space」に変更

詳細はこちらの記事 [ubuntu mozc 入力モード 切り替え](https://johnyuan2000.hatenablog.com/entry/2020/07/06/182537)にご参照ください。

PCを再起動すると日本語入力が使えるようになりました。

#### 中国語入力

Add an Input Source -> Chinese (Intelligent Pinyin)

### メディア

```
sudo apt install ubuntu-restricted-extras
```

## 開発環境

- fish shell
- Visual Studio Code
- Docker
- GitHub
- Python
  - pyenv
  - pyenv-virtualenv
- Node
  - nvm

### fish shell

user-friendlyなシェルfishをインストールします。

https://fishshell.com/

```bash
sudo apt install fish
chsh -s $(which fish)
```

これでfishがデフォルトのshellとして設定されました。
一回再起動すると確認できます。

fishのプラグインを管理ツール`fisher`をインストールしますで。

```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

### Visual Studio Code

https://code.visualstudio.com/docs/setup/linux

`.deb package`をダウンロードし、インストールする

```bash
sudo apt install ~/Downloads/{YOUR_VERSION}.deb
```


### GitHub

#### 認証

2021年までにtokenを発行してローカルにダウンロードする必要がありましたが、認証用のCLI `gh`のおかげで、AWSやGCPなどと同じくブラウザ経由で認証できるようになりました。

まずは`gh`をインストールします。
https://github.com/cli/cli/blob/trunk/docs/install_linux.md


https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git


`gh auth login`を実行すると認証が完了するので、tokenをローカルに保存しなくても良いです。だいぶ便利になりましたね。

### Docker
公式によると、リポジトリ、パッケージ、スクリプトの3種類のインストールする方法がありますが、スクリプトはOSバージョンやCPUアーキテクチャを自動的に識別してくれるので、便利です。

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo docker run hello-world
```

UbuntuはDebian basedのLinuxなので、`systemctl`や`service`コマンドを実行しなくても、dockerは自動的に立ち上がります。また、rootlessでも使いたい場合は追加の設定が必要です。

https://docs.docker.com/engine/security/rootless/

### Python 

pyenvはシンプルで複数のPythonバージョン切り替えやすいため、今回は採用しました。

#### pyenv

https://github.com/pyenv/pyenv#automatic-installer

```bash
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
```

`~/.config/fish/config.fish`に環境変数の設定を追加します。
```
set -Ux PYENV_ROOT $HOME/.pyenv
set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
```

#### pyenvのビルド環境

https://github.com/pyenv/pyenv/wiki#suggested-build-environment

```bash
sudo apt install make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

#### pyenv-virtualenv

インストール
```bash
git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
```

初期化
```bash
pyenv init - | source
pyenv virtualenv-init - | source
```

実際にPython 3.12.3を入れてみましょう
```
pyenv install 3.12.3
pyenv virtualenv 3.12.3 {YOUR_NAME}
pyenv local {YOUR_NAME}
```

### Node

Pythonと同じく、そのまま`node`をインストールしてしまうと、バージョンを特定したい場合やdependencyを管理するのがめんどくさくなるので、`nvm`という`node`のバージョンマネージャーを導入します。

#### nvm
先ほど、fishのプラグインを管理ツール`fisher`をインストールしたので、`fisher install jorgebucaran/nvm.fish`で一発インストールできます。

```bash
fisher install jorgebucaran/nvm.fish
nvm ls-remote
nvm install 18.4.0
```

他のシェルを利用している場合は、公式のリポジトリにご参照ください。
https://github.com/nvm-sh/nvm#installing-and-updating


## Start Your Voyage

8万円未満でそこそこ良いGPU付きのPCを自作し、開発環境を構築しました。
以上
