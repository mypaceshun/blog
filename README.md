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

## dockerでブログページのビルド

```
docker run --rm -it -v $(pwd):/src klakegg/hugo
```

## dockerでテストサーバーの起動

```
docker run --rm -it -v $(pwd):/src -p 1313:1313 klakegg/hugo server
```
