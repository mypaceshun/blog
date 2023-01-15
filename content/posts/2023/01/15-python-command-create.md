---
title: Pythonで自作コマンドをサクっと作る
date: 2023-01-15T20:37:41+09:00
description: Pythonで簡単なコマンドを作成し、インストールする手順を紹介します。
draft: false

tags:
  - tech
  - Python
  - Poetry
  - CLI
---

仕事や趣味でPCを操作している時、簡単な処理をコマンドにしてしまいたいことがあります。
何度もする操作や処理はひとつのコマンドで処理出来るようになると、非常に気持ちよくなれます。
コマンドの内容はさておき、作成する手順やpipを使ってインストールするまでの手順を紹介します。

<!--more-->

# 概要

最近仕事で簡単なコマンドをPythonで作成する機会が多くあったので、
私がコマンドを作成するまでの手順と、それを `pip` でインストールするまでの手順を紹介します。
私が `Poetry` 人間なので開発には `Poetry` を使います。
`Poetry` のインストール手順は公式を参照してください。

* https://python-poetry.org/docs/#installation

# コマンドを作る

`Poetry` を使って初期設定をして行きます。
詳細については[以前書いた記事](https://mypaceshun.github.io/blog/2022/07/19-my-python-style/)をご覧ください。

## 初期設定

初期設定は `poetry init` コマンドでほぼ完了します。

```
$ poetry init

This command will guide you through creating your pyproject.toml config.

Package name [omikuji]:
Version [0.1.0]:  0.9.0
Description []:  Simple omikuji application
Author [KAWAI Shun <your@mail.example.com>, n to skip]:
License []:  MIT
Compatible Python versions [^3.10]:  

Would you like to define your main dependencies interactively? (yes/no) [yes] no
Would you like to define your development dependencies interactively? (yes/no) [yes] no
```

これで以下のような `pyproject.toml` ファイルが生成されます。

```
[tool.poetry]
name = "omikuji"
version = "0.9.0"
description = "Simple omikuji application"
authors = ["KAWAI Shun <your@mail.example.com>"]
license = "MIT"
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.10"


[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

## プログラム作成

`src/` ディレクトリを作成し、その中にプログラムの実体を作成します。

```
omikuji
├── README.md
├── poetry.lock
├── pyproject.toml
└── src
    └── omikuji
        ├── __init__.py <- 空ファイル
        └── command.py  <- プログラムの実体
```

`command.py` に実際のコードを書きます。 `__init__.py` は私はいつも作りますが無くても動作します。
実際にコマンドとして動作させたい内容は関数にしておくのが必須です。

```
import random
RESULTS = ["大吉", "吉", "凶", "大凶"]

def cmd():
    result = random.choice(RESULTS)
    print(f"本日の運勢は... {result}")
```

かんたんなおみくじコマンドにしてみました。
これは `omikuji`パッケージの中にある、`command`モジュールの中の、`cmd`という関数が実体になります。
これをコマンドにするには `pyproject.toml`の設定を編集します。

## `pyproject.toml` の設定変更

```
[tool.poetry]
name = "omikuji"
version = "0.9.0"
description = "Simple omikuji application"
authors = ["KAWAI Shun <your@mail.example.com>"]
license = "MIT"
readme = "README.md"
package = [
  { include="omikuji", from="src" }
]  <- src/omikujiディレクトリをパッケージを追加します

[tool.poetry.dependencies]
python = "^3.10"

[tool.poetry.scripts]
omikuji = "omikuji.command:cmd"  <- cmd関数をomikujiコマンドとして追加します

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

`package`の設定をすることで `src/omikuji` ディレクトリが `import omikuji` としてインポート可能になります。
また `[tool.poetry.scripts]` には指定した関数を任意の名前のコマンドとして登録出来ます。
これだけで `Poetry` コマンドで呼び出し可能なコマンドになります。呼び出す際は `poetry run` コマンドを利用します。

```
$ poetry run omikuji
本日の運勢は... 大凶
```

残念です...

これでインストール可能なコマンドの作成は完了です。

# コマンドをインストールする

作成したコマンドは `pip` を使ってインストール可能です。
適宜 `venv` などを作って仮想環境にインストールするのがおすすめです。
また何通りかインストール方法がありますが、今回は GitHub 経由でインストールする方法と、wheelファイルからインストールする方法を紹介します。

## GitHub からインストールする方法

`git clone` でダウンロードしてインストールする方法です。GitHubを例に上げていますがもちろん他のリモートリポジトリでも問題ありません。
インストールするコマンドは以下になります。

```
$ python -m pip install git+<GitHubのURL>
```

例として本記事用に作成した[リポジトリ](https://github.com/mypaceshun/omikuji)を利用すると次のようになります。

```
$ python3 -m pip install git+https://github.com/mypaceshun/omikuji.git
```

内部的に `git clone` をしているので `git` コマンドが必要です。
またこれは `pip` の機能を利用しているので、書き方によってはブランチを指定したり、タグやコミットを指定することも可能です。
詳しくは `pip` のドキュメントを参照してください。

* https://pip.pypa.io/en/stable/cli/pip_install/

インストールが完了すると `bin` ディレクトリに `omikuji` コマンドが追加されています。
`venv` を利用していた場合は `venv/bin/omikuji` になります。

```
$ python3 -m venv venv
$ ./venv/bin/python -m pip install git+https://github.com/mypaceshun/omikuji.git
Collecting git+https://github.com/mypaceshun/omikuji.git
  Cloning https://github.com/mypaceshun/omikuji.git to /tmp/pip-req-build-9i0wo4_d
  Running command git clone --filter=blob:none --quiet https://github.com/mypaceshun/omikuji.git /tmp/pip-req-build-9i0wo4_d
  Resolved https://github.com/mypaceshun/omikuji.git to commit c491805c9d65a2e276c100fd70857a9542e2627a
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Building wheels for collected packages: omikuji
  Building wheel for omikuji (pyproject.toml) ... done
  Created wheel for omikuji: filename=omikuji-0.9.0-py3-none-any.whl size=1710 sha256=1fa4a2e92ef3b288bb8f1125fa569508569af369b66362ae7a27a1f931071069
  Stored in directory: /tmp/pip-ephem-wheel-cache-45usddqu/wheels/ae/e5/6b/fe6fc68d0f87aeb0e7569ccbd854aef5385c3205cab733c4e7
Successfully built omikuji
Installing collected packages: omikuji
Successfully installed omikuji-0.9.0

$ ./venv/bin/omikuji 
本日の運勢は... 大凶
```

しょんなぁ...

これにて GitHubからのインストールは完了です。

## wheelファイルからインストールする方法

GitHubに常にアップロード出来るわけでもないですし、GitHubから常にクローン出来るわけでもありません。
その場合はwheelファイルを使ってインストールすることが出来ます。
まず wheelファイルを作りましょう。`poetry build` コマンドを使って簡単に作成することが出来ます。

```
$ poetry build
Building omikuji (0.9.0)
  - Building sdist
  - Built omikuji-0.9.0.tar.gz
  - Building wheel
  - Built omikuji-0.9.0-py3-none-any.whl
```

`dist` ディレクトリ内に `omikuji-0.9.0-py3-none-any.whl` が出来ています。これがwheelファイルです。
拡張子は `whl` になります。インストールしたい環境に持っていきましょう。

インストールする際は `pip install` にwheelファイルを指定するだけでOKです。

```
$ python3 -m pip install <wheelファイル>
```

`omikuji-0.9.0-py3-none-any.whl` をインストールすると以下のようになります。

```
$ python3 -m venv venv
$ ./venv/bin/python -m pip install ./omikuji-0.9.0-py3-none-any.whl 
Processing ./omikuji-0.9.0-py3-none-any.whl
Installing collected packages: omikuji
Successfully installed omikuji-0.9.0

$ ./venv/bin/omikuji
本日の運勢は... 大吉
```

やったー！

# まとめ

今回はおみくじくをしただけでしたが、
何度も行う作業などをコマンドにすることで効率化出来るようになります。

今回紹介したコードはGitHubに上げているので参考になれば幸いです。

* https://github.com/mypaceshun/omikuji

慣れると簡単に作れるのでぜひお試しあれ
