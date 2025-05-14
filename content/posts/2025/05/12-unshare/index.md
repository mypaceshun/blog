---
title: "unshareコマンドで遊んでみた"
date: 2025-05-12T06:56:50+09:00
description: "unshareコマンドを使って色々遊んでみました。"
draft: false

tags:
  - tech
  - Linux
  - unshare
---

DockerのRootlessモードを調べている中で、`unshare` というコマンドを見つけました。
Linuxカーネルの機能である名前空間の分離が出来るコマンドです。
`unshare` コマンドを使ってユーザー名前空間の分離を試してみました。

<!--more-->

# はじめに {#introduction}

以前、DockerのRootlessモードを調べている中で、`unshare` というコマンドを見つけました。
`unshare` を使ってユーザー名前空間の分離を試してみようと思ったところ、
結構苦戦したけれどなんとか動かせたので、
メモがてらまとめておこうと思います。

# 検証環境 {#environment}

本文章執筆時の検証環境の情報は以下のとおりです。

* OS: AlmaLinux 9.5
* Kernel: `5.14.0-503.38.1.el9_5.x86_64`
* unshare:

    ```console
    unshare --version
    unshare from util-linux 2.37.4
    ```

# `unshare` コマンドとは {#unshare}

`unshare` コマンドは、Linuxカーネルの機能である名前空間を作成し、新しい名前空間で任意のコマンドを実行するためのコマンドです。
引数が指定されない場合はデフォルトで `/bin/sh` が実行されます。
また、 `$SHELL` の環境変数が定義されている場合は、 `$SHELL` の値が実行されます。
オプションを指定することで様々な名前空間を分離することが出来ます。

```console
$ unshare --help

Usage:
 unshare [options] [<program> [<argument>...]]

Run a program with some namespaces unshared from the parent.

Options:
 -m, --mount[=<file>]      unshare mounts namespace
 -u, --uts[=<file>]        unshare UTS namespace (hostname etc)
 -i, --ipc[=<file>]        unshare System V IPC namespace
 -n, --net[=<file>]        unshare network namespace
 -p, --pid[=<file>]        unshare pid namespace
 -U, --user[=<file>]       unshare user namespace
 -C, --cgroup[=<file>]     unshare cgroup namespace
 -T, --time[=<file>]       unshare time namespace
```

勉強がてらユーザー名前空間の分離を試してみました。
その他の名前空間の分離に関しては本記事では触れていません。

# ユーザー名前空間の分離 {#user-namespace}

ユーザー名前空間の分離を試してみます。

新しいユーザー名前空間でコマンドを実行するには `--user` オプションを指定します。

```console
$ id
uid=1001(shun) gid=1001(shun) groups=1001(shun)
$ unshare --user /bin/bash
$ id
uid=65534(nobody) gid=65534(nobody) groups=65534(nobody)
```

UID/GIDはそのままだと `65534(nobody)` になってしまいます。
ここから `newuidmap` `newgidmap` コマンドを使って、UID/GIDのマッピングを行います。
マッピング設定は `unshare` で作成した名前空間内では行えないので、
別の端末を開いて実行します。

## ユーザー名前空間の設定 {#userns-setup}

UID/GIDマッピングは `/etc/subuid` `/etc/subgid` に記載されている範囲でのみ設定可能です。
現在の設定は `getsubids` コマンドで確認出来ます。
詳しくは [以前の記事]({{% ref "/posts/2025/05/02-user-namespace#userns-uid-gid" %}})を参照してください。

今回はUID1001番のユーザーに `300000-365535` の範囲を、ユーザー名前空間で利用なUID/GIDとして割り当てます。

```console
$ sudo usermod --add-subuids 300000-365535 --add-subgids 300000-365535 $USER
$ getsubids $USER; getsubids -g $USER
0: shun 300000 65536
0: shun 300000 65536
```

再度 `unshare` コマンドで新しい名前空間を作成します。

```console
$ unshare --user
$ id
uid=65534(nobody) gid=65534(nobody) groups=65534(nobody)
```

プロセスごとに設定されているUID/GIDのマッピングは
`/proc/<pid>/uid_map` `/proc/<pid>/gid_map` で確認出来ます。
`unshare --user` で作成した名前空間はまだ何も設定がいないので、
`/proc/self/uid_map` `/proc/self/gid_map` は空です。

```console
$ cat /proc/self/uid_map
$ cat /proc/self/gid_map
```

次に `newuidmap` `newgidmap` コマンドを使って、UID/GIDのマッピングを行います。
`newuidmap <PID> <名前空間内でのUID> <ホスト側でのUID> <マッピング数>` の形式で指定します。
`unshare` で実行しているプロセスのPIDは `$$` という変数で確認出来ます。

```console
$ echo $$
37180
```

試しに名前空間内のrootユーザー(UID=0,GID=0)をホスト側の一般ユーザー(UID=1001,GID=1001)にマッピングしてみます。
`unshare` を実行している端末とは別の端末を開いて実行してください。

```console
$ newuidmap 37180 0 1001 1
$ newgidmap 37180 0 1001 1
```

`unshare` で実行している端末に戻ると、実行ユーザーがrootユーザー(UID=0,GID=0)に変わっていることが確認出来ます。

```console
$ id
uid=0(root) gid=0(root) groups=0(root),65534(nobody)
```

`/proc/self/uid_map` `/proc/self/gid_map` を確認すると、マッピングが設定されていることが確認出来ます。

```console
$ cat /proc/self/{u,g}id_map
     0       1001          1
     0       1001          1
```

ホスト側での一般ユーザー(UID=1001,GID=1001)で作成したファイルは、
`unshare` で作成した名前空間内でrootユーザー(UID=0,GID=0)がオーナーのファイルとして確認出来ます。

```console
# ホスト側
$ date > test1.txt
$ ls -aln
total 4
drwxr-xr-x 2 1001 1001 23 May 13 16:19 .
drwxr-xr-x 3 1001 1001 26 May 13 11:36 ..
-rw-r--r-- 1 1001 1001 32 May 13 16:19 test1.txt
```

```console
# unshareで作成した名前空間内
$ ls -aln
total 4
drwxr-xr-x 2 0 0 23 May 13 16:19 .
drwxr-xr-x 3 0 0 26 May 13 11:36 ..
-rw-r--r-- 1 0 0 32 May 13 16:19 test1.txt
```

以前の記事で紹介した [RootlessなDocker環境でコンテナ内プロセスをコンテナ内rootユーザーで動かす場合]({{% ref "/posts/2025/05/02-user-namespace#rootless-docker-root" %}}) と似たようなマッピングになりましたね。
ただこのままでは名前空間内のrootユーザー(UID=0)がホスト側の一般ユーザー(UID=1001)にマッピングしただけで、
先の記事のようにコンテナ内の一般ユーザー(UID=1000)がホスト側の一般ユーザー(UID=300999)にマッピングされることはありません。
そのためには `newuidmap` `newgidmap` コマンドでマッピングを設定する際に、追加の設定を行う必要があります。

## ユーザー名前空間の複数マッピング {#userns-multi-mapping}

RootlessモードのDocker環境にならって、名前空間内のrootユーザー(UID=0)をホスト側の一般ユーザー(UID=1001)にマッピングし、
名前空間内の一般ユーザー(UID=1)以降のユーザーをホスト側の一般ユーザー(UID=300000)以降にマッピングしてみます。

`unshare` コマンドで新しく名前空間を作成します。

```console
$ unshare --user
$ id
uid=65534(nobody) gid=65534(nobody) groups=65534(nobody)
$ echo $$
37820
```

別端末からUID/GIDマッピングを設定します。

```console
$ newuidmap 37820 0 1001 1 1 300000 5000
$ newgidmap 37820 0 1001 1 1 300000 5000
```

名前空間内に戻ってみます。

```console
$ id
uid=0(root) gid=0(root) groups=0(root),65534(nobody)
$ ls -aln
total 4
drwxr-xr-x 2 0 0 23 May 13 16:19 .
drwxr-xr-x 3 0 0 26 May 13 11:36 ..
-rw-r--r-- 1 0 0 32 May 13 16:19 test1.txt
```

先程と同様名前空間内のrootユーザー(UID=0)がホスト側の一般ユーザー(UID=1001)にマッピングされていることが確認出来ます。

ここで名前空間内の一般ユーザーがオーナーのファイルをいくつか作成してみます。

```console
$ date > tmp
$ for f in $(seq 3); do echo "[UID=$f]" && install -v -o $f -g $f -m 644 tmp namespace-$f.txt; done
[UID=1]
removed 'namespace-1.txt'
'tmp' -> 'namespace-1.txt'
[UID=2]
removed 'namespace-2.txt'
'tmp' -> 'namespace-2.txt'
[UID=3]
removed 'namespace-3.txt'
'tmp' -> 'namespace-3.txt'
$ for f in $(seq 1000 1003); do echo "[UID=$f]" && install -v -o $f -g $f -m 644 tmp namespace-$f.txt; done
[UID=1000]
'tmp' -> 'namespace-1000.txt'
[UID=1001]
'tmp' -> 'namespace-1001.txt'
[UID=1002]
'tmp' -> 'namespace-1002.txt'
[UID=1003]
'tmp' -> 'namespace-1003.txt'
$ mv -v tmp namespace-0.txt
renamed 'tmp' -> 'namespace-0.txt'
$ ls -aln
total 40
drwxr-xr-x 2    0    0 4096 May 14 10:57 .
drwxr-xr-x 3    0    0   26 May 13 11:36 ..
-rw-r--r-- 1    0    0   32 May 14 10:52 namespace-0.txt
-rw-r--r-- 1 1000 1000   32 May 14 10:56 namespace-1000.txt
-rw-r--r-- 1 1001 1001   32 May 14 10:56 namespace-1001.txt
-rw-r--r-- 1 1002 1002   32 May 14 10:56 namespace-1002.txt
-rw-r--r-- 1 1003 1003   32 May 14 10:56 namespace-1003.txt
-rw-r--r-- 1    1    1   32 May 14 10:56 namespace-1.txt
-rw-r--r-- 1    2    2   32 May 14 10:56 namespace-2.txt
-rw-r--r-- 1    3    3   32 May 14 10:56 namespace-3.txt
-rw-r--r-- 1    0    0   32 May 13 16:19 test1.txt
```

ではホスト側から確認してみましょう。

```console
$ ls -aln
total 40
drwxr-xr-x 2   1001   1001 4096 May 14 10:57 .
drwxr-xr-x 3   1001   1001   26 May 13 11:36 ..
-rw-r--r-- 1   1001   1001   32 May 14 10:52 namespace-0.txt
-rw-r--r-- 1 300999 300999   32 May 14 10:56 namespace-1000.txt
-rw-r--r-- 1 301000 301000   32 May 14 10:56 namespace-1001.txt
-rw-r--r-- 1 301001 301001   32 May 14 10:56 namespace-1002.txt
-rw-r--r-- 1 301002 301002   32 May 14 10:56 namespace-1003.txt
-rw-r--r-- 1 300000 300000   32 May 14 10:56 namespace-1.txt
-rw-r--r-- 1 300001 300001   32 May 14 10:56 namespace-2.txt
-rw-r--r-- 1 300002 300002   32 May 14 10:56 namespace-3.txt
-rw-r--r-- 1   1001   1001   32 May 13 16:19 test1.txt
```

いい感じにマッピング出来ていますね。
名前空間内のrootユーザー(UID=0)のみホスト側の一般ユーザー(UID=1001)にマッピングされていて、
名前空間内の一般ユーザー(UID=1)以降はホスト側の一般ユーザー(UID=300000)以降にマッピングされています。

RootlessなDocker環境でのホストOとコンテナ間のUID/GIDマッピングと同じような形になりました。
`/etc/subuid` `/etc/subgid` の設定範囲内であれば結構自由にマッピング設定が出来そうですね。

## `unshare` コマンドのオプションで設定 {#userns-unshare-option}

一部のマッピング設定は `unshare` のオプションを指定することでも。

`--map-user` `--map-group` オプションを指定すると、名前空間内の実行ユーザーのUID/GID指定でき、指定されたユーザーはホスト側の実行ユーザー(UID=1001,GID=1001)にマッピングされます。

```console
$ unshare --user --map-user=1000 --map-group=1000
$ id
uid=1000(testuser) gid=1000(testuser) groups=1000(testuser),65534(nobody)
$ cat /proc/$$/{u,g}id_map
      1000       1001          1
      1000       1001          1
```

名前空間内のUID=1000,GID=1000のユーザーがホスト側のUID=1001,GID=1001のユーザーにマッピングされていることが確認出来ます。

`--map-root` オプションを指定すると、名前空間内の実行ユーザーがroot(UID=0)のユーザーになり、名前空間内のrootユーザー(UID=0)をホスト側の一般ユーザー(UID=1001)にマッピングしてくれます。

`--map-user=0` `--map-group=0` と同じような動作ですね。

```console
$ unshare --user --map-root
$ id
uid=0(root) gid=0(root) groups=0(root),65534(nobody)
$ cat /proc/$$/{u,g}id_map 
         0       1001          1
         0       1001          1
```

また、 `--map-current-user` オプションを指定すると、名前空間内の実行ユーザーが現在のユーザー(UID=1001)になり、名前空間内の一般ユーザー(UID=1001)をホスト側の一般ユーザー(UID=1001)にマッピングしてくれます。

こちらは `--map-user=1001` `--map-group=1001` と同じような動作になります。

```console
$ unshare --user --map-current-user
$ id
uid=1001(shun) gid=1001(shun) groups=1001(shun),65534(nobody)
$ cat /proc/$$/{u,g}id_map
      1001       1001          1
      1001       1001          1
```

他にも `util-linux` のバージョンが `2.39` 以降くらいから、
`--map-users` `--map-groups` というオプションが追加されているようで、
さらに複雑な設定が `unshare` のオプションで出来るようになっているようです。
詳しくは [`unshare(1)`](https://man7.org/linux/man-pages/man1/unshare.1.html) を参照してください。

# まとめ {#summary}

今回は `unshare` コマンドを使ってユーザー名前空間の分離を試してみました。
`newuidmap` `newgidmap` コマンドの使い方や、
名前空間内でのUID/GIDマッピングについての理解が深まった気がします。

お手軽にユーザー名前空間のマッピング設定が試せたのでだいぶ面白いです。
他の名前空間の分離も試してみたいですね。
