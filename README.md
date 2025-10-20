# mypaceshun の技術メモ

https://mypaceshun.github.io/blog/

# Author

* mypaceshun <https://github.com/mypaceshun>

# 自分用メモ

## ブログページの作成

``` console
hugo new posts/ファイル名.md
```

## ブログページのビルド

``` console
hugo
```

## テストサーバーの起動

``` console
hugo server
```
# dockerを利用した開発方法

hugoを直接インストールせずdockerでも実行できるようにしました
dockerはrootlessモードでインストールすることを前提としています。


## dockerでブログページの作成

``` console
make new NEW_FILENAME=ファイル名
```

現在の日付からパスはいい感じに生成してくれます。

```console
$ make new NEW_FILENAME=socks-proxy
posts/2025/10/20-socks-proxy/index.md
docker run -it --rm \
	-v /home/shun/document/github/mypaceshun/blog:/src \
	"hugomods/hugo:0.145.0" \
	hugo new "posts/2025/10/20-socks-proxy/index.md"
Content "/src/content/posts/2025/10/20-socks-proxy/index.md" created
```

## dockerでブログページのビルド

``` console
make build
```

## dockerでテストサーバーの起動

``` console
make run
```
