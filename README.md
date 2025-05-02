# mypaceshun の技術メモ

https://mypaceshun.github.io/blog/

# Author

* mypaceshun <https://github.com/mypaceshun>

# 自分用メモ

## ブログページの作成

```
hugo new posts/ファイル名.md
```

## ブログページのビルド

```
hugo
```

## テストサーバーの起動

```
hugo server
```
# dockerを利用した開発方法

hugoを直接インストールせずdockerでも実行できるようにしました
dockerはrootlessモードでインストールすることを前提としています。


## dockerでブログページの作成

```
make new NEW_FILENAME=ファイル名
```

## dockerでブログページのビルド

```
make build
```

## dockerでテストサーバーの起動

```
make run
```
