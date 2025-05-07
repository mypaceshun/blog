---
title: ユーザー名前空間について調べたことをまとめたい
date: 2025-05-02T06:56:50+09:00
description: Dockerのrootlessモードを触る際に、ユーザー名前空間について色々調べる機会があったので、その内容をまとめておきたいと思います。
draft: true

tags:
  - tech
  - Linux
  - Docker
  - Podman
---

DockerのRootlessモード使ってますか？
RootlessモードではDockerデーモンをroot以外のユーザーで動作させることができるので、セキュリティ的によいとされています。
Rootlessな環境でコンテナを動かすと、Linuxカーネルのユーザー名前空間という機能を利用して、コンテナ内のUID/GIDをいい感じに変換します。
このユーザー名前空間の仕組みについて調べたことをまとめておきたいと思います。

<!--more-->

# はじめに

仕事の中でDockerを使うことはちょこちょこあったんですが、最近はRootlessモードで使ったほうがいいと言われ、
Rootlessモードでコンテナを動かす機会が多くなりました。
その際volumesマウントしたファイルが、コンテナ内で読み書き出来なかったり、
逆にコンテナ内で作成したファイルがホストOSで読み書きできなかったりといったことがありました。
そういった悲しみから解放されたい一新で、ホストOSとコンテナ内のUID/GIDの関係について調べてみました。
また、PodmanもデフォルトでDockerのRootlessモードと同じような動きをすると聞いたので、
Podmanでも同様の検証をしてみようと思います。

# バージョン情報

本文章執筆時の検証環境は以下のとおりです。
基本的にはDockerで検証していますが、Podmanでも軽く動作確認してみます。
Dockerはよく使いますがPodmanはまだまだ勉強中です。

* OS: AlmaLinux 9.5
* Kernel: `5.14.0-503.38.1.el9_5.x86_64`
* Docker:

    ```
    $ rpm -qa | grep docker
    docker-buildx-plugin-0.23.0-1.el9.x86_64
    docker-compose-plugin-2.35.1-1.el9.x86_64
    docker-ce-cli-28.1.1-1.el9.x86_64
    docker-ce-rootless-extras-28.1.1-1.el9.x86_64
    docker-ce-28.1.1-1.el9.x86_64
    ```

* Podman:

    ```
    $ rpm -qa | grep podman
    podman-5.2.2-15.el9_5.x86_64
    ```

# Docker・Podman周りのUID/GID事情

volumesマウントしたファイルのUID/GIDに関する悲しみは以下の2つの要因が関連しています。

* 起動しているデーモンがrootユーザーで動作しているかどうか(rootful/rootless)
* コンテナ内のプロセスがコンテナ内rootユーザーで動作しているかどうか

Dockerはインストール後そのまま起動すると、rootユーザーでDockerデーモンが起動します。
Dockerインストール後、 `dockerd-rootless-setuptools.sh` というスクリプトを実行することで、
root以外のユーザーでDockerデーモンが起動できる、rootlessモードという環境が構築できます(
[参考](https://docs.docker.com/engine/security/rootless/#install))。
PodmanはデフォルトでDockerのrootlessモードと同じような動きをします。

また、コンテナ内のプロセスを動作させるユーザーもコンテナごとに指定できます。
Dockerfileの `USER` や `docker run` コマンドの `--user` オプションである程度自由に指定できます。
`docker run` コマンドを使った場合、以下のようになります。

```
$ docker run alpine id
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)

$ docker run --user 1000:1000 alpine id
uid=1000 gid=1000 groups=1000
```

`--user` オプションで指定したUID/GIDのユーザーで動作していることが確認できます。

このように、ホストOS上のUID/GIDとコンテナ内のUID/GIDは別々に考える必要があります。

{{< figure
    src="../images/test.png"
    alt="ホストOSとコンテナ内でのUID"
>}}

# rootfulなDocker環境でのUID/GID

rootfulなDocker環境ではホストOSのUID/GIDとコンテナ内のUID/GIDは同じになります。

# ユーザー名前空間の仕組み

# DockerやPodmanでのユーザー名前空間の使い方

# 個人的な結論

# 参考文献
