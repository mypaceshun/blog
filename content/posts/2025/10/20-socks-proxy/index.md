---
title: "SOCKSプロキシ"
date: 2025-10-20T07:44:27Z
description: this is description
draft: false

tags:
  - tech
  - ssh
  - SOCKS
---

私はWebアプリを開発することがあり、Webアプリの動作確認のためにsshポート転送をよく使います。
様々な試行錯誤を経て、SOCKSプロキシが一番使いやすいと感じました。

<!--more-->

# はじめに {#introduction}

sshポート転送使いますか？ssh先のリモートサーバーのポートをローカルに転送したり、またその逆も出来ます。
私はリモートサーバー上で開発することが多く、特に開発中のWebアプリの動作確認なんかはsshポート転送を駆使して行います。
単純にポート転送するだけで大体の場合は事足りますが、利用している中で苦労することがちょこちょこあり、試行錯誤していく中でSOCKSプロキシが一番使いやすいと感じました。
その結論に至るまでの経緯と、SOCKSプロキシの使い方についてまとめます。

# 前提条件 {#precondition}

今回想定している環境イメージは以下のようになります。

{{< figure
    src="images/ssh-to-localnet.png"
    alt="今回想定する環境イメージ"
>}}

と言っても実際に私が開発している環境がこのような構成になっています。

* リモートサーバーへはsshでのみアクセス可能
* リモートサーバー同士の通信は可能
* リモート環境にはDNSサーバーもあり、リモート環境内で名前解決可能なFQDNが存在する（例: `server1.localnet.example.com` ）
* リモートサーバーも接続端末もLinuxマシン
  * リモートサーバー
    * OS: AlmaLinuxを想定
    * 例としてFQDNは `server1.localnet.example.com` とします
  * 接続端末
    * OS: Ubuntuを想定

使ってるOSのディストリビューションまではあまり関係ないと思いますが念の為。

`ssh server1.localnet.example.com` は通るが、 `curl https://server1.localnet.example.com` は通らない環境を想定します。

# 単純なsshポート転送 {#ssh-port-forward}

さて、リモートサーバーでWebアプリを開発しているとします。
接続端末上のブラウザから画面を確認したい場合、sshポート転送の出番ですね。

以下のコマンドでリモートサーバーの443ポートをローカルの10443ポートに転送出来ます。

```console
ssh -L 10443:localhost:443 server1.localnet.example.com
```

このまま実行すると `server1.localnet.example.com` にsshログインし、リモートサーバーのシェルが立ち上がってしまうので、
私が実際に実行する際は `-f -N` オプションを合わせてつけて以下のようにします。

```console
ssh -f -N -L 10443:localhost:443 server1.localnet.example.com
```

これによりリモートサーバーのシェルを起動することなく、バックグラウンドでポート転送だけが行われます。

{{< figure
    src="images/ssh-port-forward-10443.png"
    alt="単純なsshポート転送"
>}}

この状態で接続端末上のブラウザから `https://localhost:10443` にアクセスすると、リモートサーバー上のWebアプリにアクセス出来ます。
今回はWebサーバーなので443ポートを転送しましたが、他のポートでも同様に転送できるのでWebサーバー以外でも利用可能です。

Linuxマシンではデフォルトで 1024未満のポートは一般ユーザーが利用できません。
そのため443ポートを直接利用せず、10443など1024番以上のポートを利用しています。

# Originが異なってしまう問題 {#origin-check}

単純なWebアプリをポート転送する場合は上記の方法で十分ですが、最近のWebアプリではバックエンドのAPIサーバーと通信する際など、セキュリティ対策にOriginのチェックが行われることがあります。
具体的にはアクセス時のFQDNやポート番号がチェックされ、許可されたFQDN以外での通信が拒否されます。
上記のポート転送をした場合、ブラウザからは `https://localhost:10443` にアクセスしていることになるため、Originチェックに引っかかってしまいます。

解決策としてLinuxマシンでは `/etc/hosts` ファイルを編集し、 `server1.localnet.example.com` が `127.0.0.1` に解決されるようにします。

```plain
127.0.0.1    localhost

127.0.0.1    server1.localnet.example.com
```

このとき `ssh server1.localnet.example.com` も `127.0.0.1` に解決されてしまうので、 `~/.ssh/config` ファイルに直接IPアドレスを指定するようにしてください。

```plain
Host server1.localnet.example.com
    HostName <リモートサーバーの実IPアドレス>
```

これで `https://server1.localnet.example.com:10443` にアクセスして、リモートサーバー上のWebアプリにアクセス出来ます。
ただ、まだポート番号が10443のままなので、Originチェックに引っかかる可能性があります。

その場合は以下のコマンドを実行してください。

```console
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=443
```

利用可能なポートを1024番以上から443番以上に変更します。
443番以上のすべてのポートが一般ユーザーに利用可能になるので、変更は慎重に行ってください。

これで443ポートでポート転送が利用可能になりました。
以下のコマンドを実行することでリモートサーバーの443ポートをローカルの443ポートに転送出来ます。

```console
ssh -f -N -L 443:localhost:443 server1.localnet.example.com
```

これで接続端末上のブラウザからは、 `https://server1.localnet.example.com` でリモートサーバー上のWebアプリにアクセス出来るようになりました。

{{< figure
    src="images/ssh-port-forward-443.png"
    alt="443ポートを直接sshポート転送"
>}}

Webサーバー側でOriginの設定をわざわざ変更せずに済むので楽になりましたね。

# サーバーが複数台ある場合 {#multiple-servers}

これでめでたしめでたし、と行きたいところでしたが新たな問題が出てきました。

**他のWebサーバーにもアクセスしたい！**

リモート環境に `server1.localnet.example.com` の他にも、`server2.localnet.example.com` や `server3.localnet.example.com` といった複数のWebサーバーが存在していました。
これらを閲覧したいとなった時に、以下の手順が必要になります

1. 既存のsshポート転送を停止する
2. 他のサーバー(`server2.localnet.example.com`など)に対して、sshポート転送を設定する
3. `/etc/hosts` を書き換える

なんと面倒な。 `server1` を見て → `server2` を見て... と繰り返すととんでもない手間が発生します。

# 僕が考えた最強の複数サーバー対応sshポート転送方法 {#ssh-port-forward-multi}

そこで私が思いついたのが、`127.0.0.1` 以外のアドレスを利用する方法です。
ループバックアドレスは `127.0.0.1/8` が利用できるので、 `127.0.0.2` や `127.0.1.1` でも問題なく利用できます。

`/etc/hosts` を以下のように編集します。

```plain
127.0.0.1   localhost

127.0.1.1   server1.localnet.example.com
127.0.1.2   server2.localnet.example.com
127.0.1.3   server3.localnet.example.com
```

前回同様 `ssh server1.localnet.example.com` も `127.0.1.1` に解決されてしまうので、 `~/.ssh/config` ファイルに直接IPアドレスを指定するようにしてください。

```plain
Host server1.localnet.example.com
    HostName <server1.localnet.example.comの実IPアドレス>
Host server2.localnet.example.com
    HostName <server2.localnet.example.comの実IPアドレス>
Host server3.localnet.example.com
    HostName <server3.localnet.example.comの実IPアドレス>
```

この状態でsshのポート転送を実行します。

```console
ssh -f -N -L server1.localnet.example.com:443:localhost:443 server1.localnet.example.com
ssh -f -N -L server2.localnet.example.com:443:localhost:443 server2.localnet.example.com
ssh -f -N -L server3.localnet.example.com:443:localhost:443 server3.localnet.example.com
```

これは `server1.localnet.example.com` の443ポートをローカルの `server1.localnet.example.com(127.0.1.1)` の443ポートに転送しています。 `127.0.1.1` のアドレスにバインドすると、 `localhost(127.0.0.1)` ではなく、 `server1.localnet.example.com(127.0.1.1)` にアクセスする必要がある点がポイントです。

これでブラウザからは `https://server1.localnet.example.com` 、 `https://server2.localnet.example.com` 、 `https://server3.localnet.example.com` とアクセスすることで、複数のWebサーバーに同時にアクセス出来るようになります。

{{< figure
    src="images/ssh-port-forward-multi.png"
    alt="複数サーバーのsshポート転送"
>}}

ついに複数サーバーでも問題なくアクセス出来て、
Originの問題にも当たらない理想郷が完成しました。

ウキウキで社内に共有したところ先輩から一言。

> SOCKSプロクシーの方が簡単ではないだろうか。

SOCKS...??

# SOCKSプロキシ {#socks-proxy}

はい、ここからが本題です。
私が知らなかった(忘れていた)だけで、今までの要件をすべてスッキリ解決出来るのがSOCKSプロキシです。

OpenSSHでは `-D` オプションを利用することでSOCKSプロキシを簡単に立ち上げることが出来ます。
SOCKSプロキシを経由することで、リモート環境内への通信が可能になります。
クライアントもSOCKSプロキシに対応している必要がありますが、私がよく使う FireFox、Google Chrome、curl などは対応していたので特に困ることはありませんでした。

また設定によっては名前解決もプロキシ先で行えるので、今までやっていた `/etc/hosts` の編集もすべて不要になります。

{{< figure
    src="images/socks-proxy.png"
    alt="SOCKSプロキシのイメージ"
>}}

以下のコマンドでSOCKSプロキシを立ち上げます。

```console
ssh -f -N -D 1080 server1.localnet.example.com
```

これで `localhost:1080` がSOCKSプロキシの受け口となります。

これを利用する方法をいくつか紹介します。

## `curl` でSOCKSプロキシ {#curl-socks}

`curl` をSOCKSプロキシ経由で実行する場合は以下のようになります。

```console
curl --proxy socks5h://localhost:1080 https://server1.localnet.example.com
```

`socks5h` とすることで名前解決もSOCKSプロキシ先で行われるため、
接続端末で `/etc/hosts` を編集することなく、
そのままリモート環境のWebサーバーにアクセス出来ます。

## Google Chrome でSOCKSプロキシ {#chrome-socks}

Google Chrome は起動時のオプションでSOCKSプロキシを指定出来ます。

```console
google-chrome --proxy-server="socks5://localhost:1080"
```

これで起動したGoogle Chromeで、 `https://server1.localnet.example.com` にアクセスすることで、
問題なくリモート環境のWebサーバーにアクセス出来ます。

## FireFox でSOCKSプロキシ {#firefox-socks}

FireFox は設定画面からSOCKSプロキシを指定出来ます。

設定画面内、ネットワーク設定から接続設定をクリック。

{{< figure
    src="images/firefox-socks-1.png"
    alt="FireFoxの接続設定画面"
>}}

手動でプロキシーを設定するを選択し、SOCKSホストに `localhost` 、ポートに `1080` を指定します。
このとき `SOCKS v5` を選択し、 SOCKS v5 を使用するときはDNSもプロキシーを使用する にチェックを入れてください。

{{< figure
    src="images/firefox-socks-2.png"
    alt="FireFoxのプロキシ設定画面"
>}}

これで `https://server1.localnet.example.com` にアクセスすることで、
問題なくリモート環境のWebサーバーにアクセス出来ます。

# まとめ {#summary}

長々と書きましたが結局は SOCKSプロキシ便利で最高だった！ という事が言いたいだけでした。
私自身2年くらい前に一度SOCKSプロキシを使っていたんですが、綺麗サッパリ忘れて様々なsshポート転送の試行錯誤をしてしまいました。
この記事を書いたことで2年後の私もSOCKSプロキシを利用して快適な開発ライフを送っていることを願っています。
