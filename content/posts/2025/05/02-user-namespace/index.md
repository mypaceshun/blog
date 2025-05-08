---
title: ユーザー名前空間について調べたことをまとめたい
date: 2025-05-02T06:56:50+09:00
description: DockerのRootlessモードを触る際に、ユーザー名前空間について色々調べる機会があったので、その内容をまとめておきたいと思います。
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
    docker-ce-Rootless-extras-28.1.1-1.el9.x86_64
    docker-ce-28.1.1-1.el9.x86_64
    ```

* Podman:

    ```
    $ rpm -qa | grep podman
    podman-5.2.2-15.el9_5.x86_64
    ```

# Docker・Podman周りのUID/GID事情

volumesマウントしたファイルのUID/GIDに関する悲しみは以下の2つの要因が関連しています。

* 起動しているデーモンがrootユーザーで動作しているかどうか(Rootful/Rootless)
* コンテナ内のプロセスがコンテナ内rootユーザーで動作しているかどうか

Dockerはインストール後そのまま起動すると、rootユーザーでDockerデーモンが起動します。
Dockerインストール後、 `dockerd-Rootless-setuptools.sh` というスクリプトを実行することで、
root以外のユーザーでDockerデーモンが起動できる、Rootlessモードという環境が構築できます(
[参考](https://docs.docker.com/engine/security/Rootless/#install))。
PodmanはデフォルトでDockerのRootlessモードと同じような動きをします。

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
    src="images/01_ホストOSとコンテナ内でのUID.png"
    alt="ホストOSとコンテナ内でのUID"
>}}

混同を避けるため本記事では、 **ホストOS上のxxxユーザー** と **コンテナ内のxxxユーザー** と区別して表記します。

# RootfulなDocker環境でのUID/GID

RootfulなDocker環境ではホストOS上のUID/GIDとコンテナ内のUID/GIDは同じになります。
特にUIDやGIDの変換は行われません。

{{< figure
    src="images/02_Rootful環境でのUIDマッピング.png"
    alt="Rootful環境でのUIDマッピング"
>}}

コンテナ内のプロセスをコンテナ内のrootユーザー(UID=0)で動かす場合と、
コンテナ内の一般ユーザー(UID=1000)で動かす場合の2パターンを試してみます。

## コンテナ内のプロセスをコンテナ内のrootユーザーで動かす場合

コンテナ内のrootユーザー(UID=0)で作成したファイルは、
ホストOS上でもホストOS上のrootユーザー(UID=0)がオーナーのファイルとして扱われます。

実際に実験してみます。

RootfulなDocker環境での実行です。
一般ユーザー(UID=1001)をdockerグループに追加することで、dockerコマンドを実行できるようにしています。
コンテナ内プロセスはコンテナ内のrootユーザー(UID=0)として動作させます。

```
$ id
uid=1001(shun) gid=1001(shun) groups=1001(shun),989(docker)
```

ホストOS上の一般ユーザーでファイルを作成します。

```
$ date > test1.txt
```

コンテナ内では、コンテナ内の一般ユーザー(UID=1001)がオーナーのファイルとして確認出来ます。

```
$ docker run -v "$(pwd):/tmp" alpine ls -anl /tmp
total 8
drwxr-xr-x    2 1001     1001          4096 May  7 07:23 .
drwxr-xr-x    1 0        0                6 May  7 07:25 ..
-rw-r--r--    1 1001     1001            32 May  7 07:23 test1
```

コンテナ内でファイルを作成します。

```
$ docker run -v "$(pwd):/tmp" alpine sh -c "date > /tmp/test2"
$ docker run -v "$(pwd):/tmp" alpine ls -anl /tmp
total 12
drwxr-xr-x    2 1001     1001          4096 May  7 07:28 .
drwxr-xr-x    1 0        0                6 May  7 07:31 ..
-rw-r--r--    1 1001     1001            32 May  7 07:23 test1
-rw-r--r--    1 0        0               29 May  7 07:28 test2
```

ホストOS上でもホストOS上のrootユーザー(UID=0)がオーナーのファイルとして確認出来ます。

```
$ ls -aln
total 16
drwxr-xr-x. 2 1001 1001 4096 May  7 16:28 .
drwxr-xr-x. 6 1001 1001 4096 May  7 16:20 ..
-rw-r--r--. 1 1001 1001   32 May  7 16:23 test1
-rw-r--r--. 1    0    0   29 May  7 16:28 test2
```

ホストOS上の一般ユーザー(UID=1001)では権限不足でファイルの編集が出来なくなります。
不便ですね。

```
$ date > test2
zsh: permission denied: test2
```

不便なだけでなく、ホストOS上のrootユーザー(UID=0)としてファイルが作成・編集出来てしまうのは、
セキュリティ的にもよろしくありませんね。
これはあまりいい方法では無さそうです。

## コンテナ内のプロセスをコンテナ内の一般ユーザーで動かす場合

コンテナ内の一般ユーザー(UID=1000)で作成したファイルは、
ホストOS上でもホストOS上の一般ユーザー(UID=1000)がオーナーのファイルとして扱われます。

実際に実験してみます。

RootfulなDocker環境での実行です。
一般ユーザー(UID=1001)をdockerグループに追加することで、dockerコマンドを実行できるようにしています。
コンテナ内プログラムはコンテナ内の一般ユーザー(UID=1000)として動作させます。

```
$ id
uid=1001(shun) gid=1001(shun) groups=1001(shun),989(docker)
```

ホストOS上の一般ユーザーでファイルを作成します。

```
$ date > test1.txt
```

コンテナ内では、コンテナ内の一般ユーザー(UID=1001)がオーナーのファイルとして確認出来ます。

```
$ docker run -v "$(pwd):/tmp" --user 1000:1000 alpine ls -aln /tmp             
total 4
drwxr-xr-x    2 1001     1001            19 May  7 07:56 .
drwxr-xr-x    1 0        0                6 May  7 07:56 ..
-rw-rw-r--    1 1001     1001            32 May  7 07:56 test1
```

コンテナ内でファイルを作成します。

```
$ docker run -v "$(pwd):/tmp" --user 1000:1000 alpine sh -c "date > /tmp/test2"
sh: can't create /tmp/test2: Permission denied
```

権限エラーでファイルが作成出来ませんでした。
アクセスしたディレクトリがコンテナ内の一般ユーザー(UID=1001)がオーナーのディレクトリのため、
コンテナ内の一般ユーザー(UID=1000)では書き込み権限がありません。

一時的にマウントディレクトリの権限を 777 に変更して、誰でも書き込みが出来るようにして実行します。

```
$ chmod 777 .
$ docker run -v "$(pwd):/tmp" --user 1000:1000 alpine sh -c "date > /tmp/test2"
$ chmod 755 .
$ docker run -v "$(pwd):/tmp" --user 1000:1000 alpine ls -aln /tmp
total 8
drwxr-xr-x    2 1001     1001            32 May  7 08:01 .
drwxr-xr-x    1 0        0                6 May  7 08:03 ..
-rw-rw-r--    1 1001     1001            32 May  7 07:56 test1
-rw-r--r--    1 1000     1000            29 May  7 08:01 test2
```

ホストOS上でもホストOS上の一般ユーザー(UID=1000)がオーナーのファイルとして確認出来ます。

```
$ ls -aln
total 8
drwxr-xr-x. 2 1001 1001 32 May  7 17:01 .
drwxr-xr-x. 3 1001 1001 24 May  7 16:55 ..
-rw-rw-r--. 1 1001 1001 32 May  7 16:56 test1
-rw-r--r--. 1 1000 1000 29 May  7 17:01 test2
```

今回はあえてコンテナ内のプロセスをホストOS上の一般ユーザー(UID=1001)とは異なるUIDを指定した、コンテナ内の一般ユーザー(UID=1000)で動作させました。
UIDが一致しないため、コンテナ内で作成したファイル・ディレクトリはホストOS上で読み書き出来ませんし、
ホストOS上で作成したファイル・ディレクトリもコンテナ内で読み書き出来ません。

UIDを一致させればこのような不便は発生しません。
Rootlessな環境を作成する以前は、
コンテナ内のプロセスをホストOS上の一般ユーザー(UID=1001)と一致するUIDのコンテナ内の一般ユーザー(UID=1001)で動作させることで、
作成したファイルが読み書き出来ない問題を回避していました。

しかし、そもそも違うUIDのユーザーがオーナーのファイルを編集・作成出来てしまうのはセキュリティ的によろしくありません。

また、そもそもコンテナ内プロセスがコンテナ内のrootユーザーでないと動作しないようなDockerイメージはそこそこある印象です。
最近ではnon-rootでも動作するようなDockerイメージも見ますが、全部が全部ではありません。
実際に私も `--user` オプションを付けて起動したらコンテナ内部で権限エラーになってしまい、
そもそも起動出来なくなってしまったという経験をしたことがあります。

これもあまりいい構成とは言えなさそうですね。

# RootlessモードのDockerやPodmanでのUIDの仕組み

RootlessモードのDockerやPodmanでは、ホストOS上の一般ユーザーの権限でデーモンプロセスが起動します。
コンテナ内の環境はLinuxカーネルの機能で分離されてはいますが、ベースはホストOS上のカーネルを利用しています。
そのためコンテナ内のプロセスで参照するファイルも、実際にはホストOS上のファイルシステムを参照します。
当然ホストOS上の一般ユーザーで動作しているデーモンが、ホストOS上のrootユーザー権限のファイルを作成・編集することは出来ません。

そのため、コンテナ内のプロセスはLinuxカーネルのユーザー名前空間という機能を利用して、
ホストOS上のUID/GIDテーブルとコンテナ内のUID/GIDテーブルをマッピングします。

## ユーザー名前空間内で利用可能なUID/GIDの範囲

Linuxユーザーには自身のUIDの他に利用可能なUID/GIDの範囲を持っています。
これは `getsubids` というコマンドで確認出来ます。
利用可能なUIDの範囲を開始値と範囲の長さで確認出来ます。
以下の `100000 65536` というのは、100000から165535までのUIDを利用可能という意味です。

```
$ rpm -qf /bin/getsubids
shadow-utils-subid-4.9-10.el9_5.x86_64
$ getsubids testuser
0: testuser 100000 65536
$ getsubids -g testuser
0: testuser 100000 65536
```

以下のようなイメージになります。

{{< figure
    src="images/03_ユーザー名前空間設定イメージ.png"
    alt="ユーザー名前空間設定イメージ"
>}}

ユーザー名前空間の設定が存在しない場合は以下のように出力されます。

```
$ getsubids shun
Error fetching ranges
```

ちなみに存在しないユーザーを指定しても同じ出力でした。
混乱しそう...

```
$ getsubids damedame
Error fetching ranges
```

ユーザー名前空間の設定は `usermod` コマンドの `--add-subuids` オプションと `--add-subgids` オプションで設定出来ます。
こちらは利用可能なUID/GIDの範囲を`開始値-終了値` で指定します。
`getsubids` の表記と違うので少し混乱しますね。

```
$ sudo usermod --add-subuids 300000-365535 --add-subgids 300000-365535 shun
$ getsubids shun
0: shun 300000 65536

$ getsubids -g shun
0: shun 300000 65536
```

## ユーザー名前空間のUID/GIDマッピング

RootlessモードのDockerやPodmanでコンテナを起動すると、
ユーザー名前空間のUID/GIDマッピングが行われます。
先述した利用可能な範囲でUID/GIDのマッピングが行われます。

例として、UID100000番から165535番までのユーザー名前空間の範囲を持つホストOS上の一般ユーザー(UID=1000)でコンテナを起動した場合、
コンテナ内のUID/GIDマッピングは以下のようになります。

* コンテナ内のrootユーザー(UID=0)はホストOS上の一般ユーザー(UID=1000)にマッピングされます。
* コンテナ内のUID/GIDは1番から順に、ホストOS上の一般ユーザーが利用可能なユーザー名前空間の範囲(100000-165535)にマッピングされます。

イメージとしては以下のようになります。
コンテナ内rootユーザーがホストOS上の一般ユーザー(UID=1000)にマッピングされるのがポイントです。

{{< figure
    src="images/04_ユーザー名前空間マッピングイメージ.png"
    alt="ユーザー名前空間マッピングイメージ"
>}}

# RootlessなDocker環境やPodman環境でのUID/GID

RootlessなDocker環境やPodman環境ではUID/GIDのマッピングが行われます。
実際にコンテナ内の実行ユーザーがコンテナ内のrootユーザーの場合とコンテナ内の一般ユーザーの場合で、それぞれ動作を見てみましょう。

## コンテナ内プロセスをコンテナ内のrootユーザーで動かす場合

コンテナ内のrootユーザー(UID=0)はホストOS上のデーモンを実行している一般ユーザーにマッピングされます。
今回はUID1003番の一般ユーザーでDockerデーモンを実行するので、コンテナ内のrootユーザー(UID=0)はホストOS上の一般ユーザー(UID=1003)にマッピングされます。

実際に実験してみます。

RootlessなDocker環境での実行です。
一般ユーザー(UID=1003)の権限でDockerデーモンが起動しています。
Rootlessモードを動作させる都合上ユーザー名前空間の設定がされていますが、
今回の実験では特に関係ありません。

```
$ id
uid=1003(shun) gid=1003(shun) groups=1003(shun)
$ getsubids shun
0: shun 200000 65536
$ getsubids -g shun
0: shun 200000 65536
```

ホストOS上の一般ユーザー(UID=1003)でファイルを作成します。

```
$ date > test1.txt
$ ls -aln
total 4
drwxr-xr-x  2 1003 1003 23 May  8 10:47 .
drwxr-xr-x. 3 1003 1003 57 May  8 10:42 ..
-rw-r--r--  1 1003 1003 32 May  8 10:47 test1.txt
```

コンテナ内では、コンテナ内のrootユーザー(UID=0)がオーナーのファイルとして確認出来ます。

```
$ docker run -v "${PWD}:/tmp" alpine ls -aln /tmp
total 4
drwxr-xr-x    2 0        0               23 May  8 01:47 .
drwxr-xr-x   19 0        0                6 May  8 01:48 ..
-rw-r--r--    1 0        0               32 May  8 01:47 test1.txt
```

コンテナ内でファイルを作成します。

```
$ docker run -v "${PWD}:/tmp" alpine sh -c "date > /tmp/test2.txt"
$ docker run -v "${PWD}:/tmp" alpine ls -aln /tmp
total 8
drwxr-xr-x    2 0        0               40 May  8 01:49 .
drwxr-xr-x   19 0        0                6 May  8 01:49 ..
-rw-r--r--    1 0        0               32 May  8 01:47 test1.txt
-rw-r--r--    1 0        0               29 May  8 01:49 test2.txt
```

ホストOS上ではホストOS上の一般ユーザー(UID=1003)がオーナーのファイルとして確認出来ます。

```
$ ls -aln
total 8
drwxr-xr-x  2 1003 1003 40 May  8 10:49 .
drwxr-xr-x. 3 1003 1003 57 May  8 10:42 ..
-rw-r--r--  1 1003 1003 32 May  8 10:47 test1.txt
-rw-r--r--  1 1003 1003 29 May  8 10:49 test2.txt
```

これは便利です。
コンテナ内で作成したファイルもホストOS上で作成したファイルも、
相互に編集が可能です。

個人的にこれのありがたい点は、
Dockerデーモンの実行ユーザーのUID/GIDに適宜マッピングしてくれる点です。
以前はRootfulモードで作業用ユーザーのUID/GIDをコンテナ内プロセスを実行するユーザーにわざわざ合わせたりしていましたが、
この手間が一切不要になりました。

また、コンテナ内プロセスがコンテナ内のrootユーザーで実行されるので、パッケージの追加インストールなど、root権限が必要な操作も行えるので、
開発中に気軽にパッケージをインストールしたり出来るので便利です。
ただし、root権限で動作している以上、潜在的にセキュリティリスクはあります。

仮にコンテナを乗っ取られたとしても、ホストOS上では一般ユーザー(UID=1003)の権限でしか動作しないので、
Rootfulな環境よりは安全と言えるでしょう。

先の実験内容をPodmanでも実施してみます。

Podman環境での実行です。
Docker環境同様ユーザー名前空間の設定がされていますが、今回の実験では特に関係ありません。

```
$ id
uid=1003(shun) gid=1003(shun) groups=1003(shun)
$ getsubids shun
0: shun 200000 65536
$ getsubids -g shun
0: shun 200000 65536
```

ホストOS上の一般ユーザー(UID=1003)でファイルを作成します。

```
$ date > test1.txt
$ ls -aln
total 4
drwxr-xr-x  2 1003 1003 23 May  8 11:09 .
drwxr-xr-x. 3 1003 1003 41 May  8 11:08 ..
-rw-r--r--  1 1003 1003 32 May  8 11:09 test1.txt
```

コンテナ内では、コンテナ内のrootユーザー(UID=0)がオーナーのファイルとして確認出来ます。

```
$ podman run -v "${PWD}:/tmp" alpine ls -aln /tmp
total 4
drwxr-xr-x    2 0        0               23 May  8 02:09 .
dr-xr-xr-x    1 0        0               28 May  8 02:12 ..
-rw-r--r--    1 0        0               32 May  8 02:09 test1.txt
```

コンテナ内でファイルを作成します。

```
$ podman run -v "${PWD}:/tmp" alpine sh -c "date > /tmp/test2.txt"
$ podman run -v "${PWD}:/tmp" alpine ls -aln /tmp
total 8
drwxr-xr-x    2 0        0               40 May  8 02:13 .
dr-xr-xr-x    1 0        0               28 May  8 02:13 ..
-rw-r--r--    1 0        0               32 May  8 02:09 test1.txt
-rw-r--r--    1 0        0               29 May  8 02:13 test2.txt
```

ホストOS上ではホストOS上の一般ユーザー(UID=1003)がオーナーのファイルとして確認出来ます。

```
$ ls -aln
total 8
drwxr-xr-x  2 1003 1003 40 May  8 11:13 .
drwxr-xr-x. 3 1003 1003 41 May  8 11:08 ..
-rw-r--r--  1 1003 1003 32 May  8 11:09 test1.txt
-rw-r--r--  1 1003 1003 29 May  8 11:13 test2.txt
```

RootlessなDocker環境と同様の挙動になりましたね。
コマンドもオプションも全く同じだったので違和感なく実行できました。Podmanいいな。

## コンテナ内プロセスをコンテナ内の一般ユーザーで動かす場合

コンテナ内の一般ユーザー(UID=1000)はホストOS上の一般ユーザー(UID=1003)が利用可能なユーザー名前空間の範囲にマッピングされます。
今回実行した環境では200000番から265535番までの範囲が利用可能なため、コンテナ内の一般ユーザー(UID=1000)はホストOS上ではUID200999番のユーザーとしてマッピングされます。

実際に実験してみます。

RootlessなDocker環境での実行です。
一般ユーザー(UID=1003)の権限でDockerデーモンが起動しています。
ユーザー名前空間は200000-265535の範囲が設定されています。

```
$ id
uid=1003(shun) gid=1003(shun) groups=1003(shun)
$ getsubids shun
0: shun 200000 65536
$ getsubids -g shun
0: shun 200000 65536
```

ホストOS上の一般ユーザー(UID=1003)でファイルを作成します。

```
$ date > test1.txt
$ ls -aln
total 4
drwxr-xr-x  2 1003 1003 23 May  8 11:24 .
drwxr-xr-x. 3 1003 1003 57 May  8 10:42 ..
-rw-r--r--  1 1003 1003 32 May  8 11:24 test1.txt
```

コンテナ内では、コンテナ内の一般ユーザー(UID=1000)がオーナーのファイルとして確認出来ます。

```
$ docker run --rm -v "${PWD}:/tmp" --user "1000:1000" alpine ls -aln /tmp
total 4
drwxr-xr-x    2 0        0               23 May  8 02:24 .
drwxr-xr-x   19 0        0                6 May  8 02:25 ..
-rw-r--r--    1 0        0               32 May  8 02:24 test1.txt
```

コンテナ内でファイルを作成します。

```
$ docker run --rm -v "${PWD}:/tmp" --user "1000:1000" alpine sh -c "date > /tmp/test2.txt"
sh: can't create /tmp/test2.txt: Permission denied
```

権限エラーでファイルが作成出来ませんでした。
アクセスしたディレクトリがコンテナ内のrootユーザー(UID=0)がオーナーのディレクトリのため、
コンテナ内の一般ユーザー(UID=1000)では書き込み権限がありません。

一時的にマウントディレクトリの権限を 777 に変更して、誰でも書き込みが出来るようにして実行します。

```
$ chmod 777 .
$ chmod 755 .
$ docker run -v "${PWD}:/tmp" --user "1000:1000" alpine ls -aln /tmp
total 8
drwxr-xr-x    2 0        0               40 May  8 02:33 .
drwxr-xr-x   19 0        0                6 May  8 02:33 ..
-rw-r--r--    1 0        0               32 May  8 02:24 test1.txt
-rw-r--r--    1 1000     1000            29 May  8 02:32 test2.txt
```

ホストOS上ではホストOS上の一般ユーザー(UID=1003)が利用可能なユーザー名前空間の範囲でマッピングされた、UID200999番/GID200999番のユーザーがオーナーのファイルとして確認出来ます。

```
$ ls -aln
total 8
drwxr-xr-x  2   1003   1003 40 May  8 11:33 .
drwxr-xr-x. 3   1003   1003 57 May  8 10:42 ..
-rw-r--r--  1   1003   1003 32 May  8 11:24 test1.txt
-rw-r--r--  1 200999 200999 29 May  8 11:32 test2.txt
```

あまり見慣れないUID/GIDになりましたね。
初見では巨大なUID/GIDになっていてびっくりしますが、
先のマッピングの話を踏まえると意図通りのUID/GIDになっていることがわかると思います。

ただこのままではホストOS上の一般ユーザー(UID=1003)ではファイルの編集が出来ません。

```
$ date >> test2.txt
zsh: permission denied: test2.txt
```

そんなときに使えるとても便利なコマンドを紹介します。

### rootlesskit

DockerをRootlessモードでインストールした際にあわせてインストールされる `rootlesskit` というコマンドがあります。
これはユーザー名前空間を利用して、コンテナ内のrootユーザー(UID=0)としてコマンドを実行してくれるツールです。
試しに使ってみましょう。

先程RootlessなDocker環境でコンテナ内の一般ユーザー(UID=1000)でファイルを作成したら、
ホストOS上の一般ユーザー(UID=1003)では編集出来なくなってしまいました。

```
$ ls -aln
total 8
drwxr-xr-x  2   1003   1003 40 May  8 11:33 .
drwxr-xr-x. 3   1003   1003 57 May  8 10:42 ..
-rw-r--r--  1   1003   1003 32 May  8 11:24 test1.txt
-rw-r--r--  1 200999 200999 29 May  8 11:32 test2.txt
```

`rootlesskit` を介すとコンテナ内のrootユーザー(UID=0)としてコマンドを実行してくれます。

```
$ rootlesskit ls -aln
total 8
drwxr-xr-x  2    0    0 40 May  8 11:33 .
drwxr-xr-x. 3    0    0 57 May  8 10:42 ..
-rw-r--r--  1    0    0 32 May  8 11:24 test1.txt
-rw-r--r--  1 1000 1000 29 May  8 11:32 test2.txt
```

`docker run` でコンテナ内で実行した場合と同様の出力になりました。
ユーザー名前空間のマッピングを利用しているだけなので、
実際にコンテナが起動しているわけではありません。

`rootlesskit` を使ってファイルを編集出来ました。

```
$ rootlesskit sh -c "date >> test2.txt"
$ ls -aln
total 8
drwxr-xr-x  2   1003   1003 40 May  8 11:33 .
drwxr-xr-x. 3   1003   1003 57 May  8 10:42 ..
-rw-r--r--  1   1003   1003 32 May  8 11:24 test1.txt
-rw-r--r--  1 200999 200999 61 May  8 11:45 test2.txt
$ cat test2.txt
Thu May  8 02:32:43 UTC 2025
Thu May  8 11:45:54 AM JST 2025
```

これはいいですねぇ。

コンテナ内のプロセスが一般ユーザー権限で動作しているため、
今まで紹介した中では最も安全と言えるでしょう。

また、UID/GIDのマッピングで発生するズレも、
`rootlesskit` を使うことでおおよそ解決できます。
安全かつ便利な構成でとてもいいですね。

ただし、`rootlesskit` は実行しているホストOS上の一般ユーザーと、その利用可能なユーザー名前空間の範囲でしか実行できません。
すべてがすべて `rootlesskit` で解決するかとまでは言い切れないです。

### Podmanの場合

Podmanでも同様の実験をしてみます。

Podman環境での実行です。
一般ユーザー(UID=1003)で実行し、
ユーザー名前空間は200000-265535の範囲が設定されています。

```
$ id
uid=1003(shun) gid=1003(shun) groups=1003(shun)
$ getsubids shun
0: shun 200000 65536
$ getsubids -g shun
0: shun 200000 65536
```

ホストOS上の一般ユーザー(UID=1003)でファイルを作成します。

```
$ date > test1.txt
$ ls -aln
total 4
drwxr-xr-x  2 1003 1003 23 May  8 11:58 .
drwxr-xr-x. 3 1003 1003 41 May  8 11:08 ..
-rw-r--r--  1 1003 1003 32 May  8 11:58 test1.txt
```

コンテナ内では、コンテナ内のrootユーザー(UID=0)がオーナーのファイルとして確認出来ます。

```
$ podman run -v "${PWD}:/tmp" --user "1000:1000" alpine ls -aln /tmp
total 4
drwxr-xr-x    2 0        0               23 May  8 02:58 .
dr-xr-xr-x    1 0        0               28 May  8 02:59 ..
-rw-r--r--    1 0        0               32 May  8 02:58 test1.txt
```

コンテナ内でファイルを作成します。

```
$ podman run -v "${PWD}:/tmp" --user "1000:1000" alpine sh -c "date > /tmp/test2.txt"
sh: can't create /tmp/test2.txt: Permission denied
```

権限エラーでファイルが作成出来ませんでした。
アクセスしたディレクトリがコンテナ内のrootユーザー(UID=0)がオーナーのディレクトリのため、
コンテナ内の一般ユーザー(UID=1000)では書き込み権限がありません。

一時的にマウントディレクトリの権限を 777 に変更して、誰でも書き込みが出来るようにして実行します。

```
$ chmod 777 .
$ podman run -v "${PWD}:/tmp" --user "1000:1000" alpine sh -c "date > /tmp/test2.txt"
$ chmod 755 .
$ podman run -v "${PWD}:/tmp" --user "1000:1000" alpine ls -aln /tmp
$ podman run -v "${PWD}:/tmp" --user "1000:1000" alpine ls -aln /tmp
total 8
drwxr-xr-x    2 0        0               40 May  8 03:00 .
dr-xr-xr-x    1 0        0               28 May  8 03:01 ..
-rw-r--r--    1 0        0               32 May  8 02:58 test1.txt
-rw-r--r--    1 1000     1000            29 May  8 03:00 test2.txt
```

ホストOS上ではホストOS上の一般ユーザー(UID=1003)が利用可能なユーザー名前空間の範囲でマッピングされた、UID200999番/GID200999番のユーザーがオーナーのファイルとして確認出来ます。

```
$ ls -aln
total 8
drwxr-xr-x  2   1003   1003 40 May  8 12:00 .
drwxr-xr-x. 3   1003   1003 41 May  8 11:08 ..
-rw-r--r--  1   1003   1003 32 May  8 11:58 test1.txt
-rw-r--r--  1 200999 200999 29 May  8 12:00 test2.txt
```

RootlessなDocker環境と同様の挙動になりましたね。

ホストOS上の一般ユーザー(UID=1003)でファイルの編集が出来ない問題も同様に発生します。
Docker環境では `rootlesskit` というコマンドを使いましたが、
Podman環境では `podman unshare` というコマンドを使います。

### podman unshare

Podman環境では `podman unshare` というコマンドを使うと、ユーザー名前空間を、コンテナ内のrootユーザー(UID=0)としてコマンドを実行してくれます。
試しに使ってみましょう。

先程Podman環境でコンテナ内の一般ユーザー(UID=1000)でファイルを作成したら、
ホストOS上の一般ユーザー(UID=1003)では編集出来なくなってしまいました。

```
$ ls -aln
total 8
drwxr-xr-x  2   1003   1003 40 May  8 12:00 .
drwxr-xr-x. 3   1003   1003 41 May  8 11:08 ..
-rw-r--r--  1   1003   1003 32 May  8 11:58 test1.txt
-rw-r--r--  1 200999 200999 29 May  8 12:00 test2.txt
```

`podman unshare` を介すとコンテナ内のrootユーザー(UID=0)としてコマンドを実行してくれます。

```
$ podman unshare ls -aln
total 8
drwxr-xr-x  2    0    0 40 May  8 12:00 .
drwxr-xr-x. 3    0    0 41 May  8 11:08 ..
-rw-r--r--  1    0    0 32 May  8 11:58 test1.txt
-rw-r--r--  1 1000 1000 29 May  8 12:00 test2.txt
```

`rootlesskit` と同様ですね。
`podman unshare` を使ってファイルの編集も出来ました。

```
$ podman unshare sh -c "date >> test2.txt"
$ ls -aln
total 8
drwxr-xr-x  2   1003   1003 40 May  8 12:00 .
drwxr-xr-x. 3   1003   1003 41 May  8 11:08 ..
-rw-r--r--  1   1003   1003 32 May  8 11:58 test1.txt
-rw-r--r--  1 200999 200999 61 May  8 12:05 test2.txt
$ cat test2.txt
Thu May  8 03:00:57 UTC 2025
Thu May  8 12:05:06 PM JST 2025
```

RootlessなDocker環境と同様の挙動になりましたね。
こちらも `podman unshare` を使うことで、
安全かつ便利な構成になるのでとてもいいです。

# 個人的な結論

個人的な結論としては、
特に制約がなければ、RootlessなDocker環境やPodman環境を利用するのが良いと思います。
また、 コンテナ内プロセスの実行ユーザーは基本的にコンテナ内の一般ユーザー(UID=1000など)で実行し、
必要に応じてコンテナ内のrootユーザー(UID=0)で実行するようにします。

この必要に応じてというところですが、
作成したファイルをまた別のサービスやプログラムで利用する場合、
やはり `200999:200999` のようなUID/GIDになっているファイルは扱いづらい場合があります。

コンテナをコマンド的に利用してなにかファイルを生成する場合や、
コンテナ内でパッケージビルドする場合などは、
コンテナ内のrootユーザー(UID=0)で実行すると、
ホストOS上の実行ユーザーの権限でファイルを作成してくれるので何かと都合がいいです。

逆に運用環境などファイル生成・出力がない状況だったり、
出力したファイルを扱うにしても `rootlesskit` や `podman unshare` を使える環境であれば、
コンテナ内の一般ユーザー(UID=1000など)で実行するのがより安全で良いでしょう。
