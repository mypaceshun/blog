---
title: Pythonで開発する時のディレクトリ構成を晒します
date: 2022-07-09T22:42:13+09:00
description: 私がPythonで開発をするときのディレクトリ構成を紹介します。
draft: false

tags:
  - tech
  - Python
  - Poetry
---

Pythonでコードを書き始めて気づけば5年くらい経ってました...
時の流れが早すぎる...
Pythonで開発をする際の構成がおおよそ落ち着いてきたので、まとめる意味も含めここで紹介しようと思います。

<!--more-->

# 概要

一概にPythonを書く時といってもPyPIに公開することを見据えて書く時と、
自分だけが使う予定のコードを書く時ではさすがに真剣度(とは)が違います。
そこで今回は雑に書く時、少し真面目に書く時、真剣に書く時の3種類に分けて紹介しようと思います。
全体を通して `Poetry` を使った開発、`git`でバージョン管理し`GitHub`をリモートリポジトリとすることを前提としています。
私の開発環境はUbuntuですが、今回の内容ではあまり関係ないと思います。

# 雑に書く時の構成

「雑に書く」の基準としては、自分以外に見せる予定が無い、自分も将来使いまわす予定がない、をイメージしています。
逆に言うならどんなコードを書くときも絶対にしている基本の部分です。
まず最初にディレクトリ構成がこちらです。

```
sample-project
├── .gitignore
├── .pre-commit-config.yaml
├── README.rst
├── poetry.lock
├── pyproject.toml
└── src
    └── sample_project
        ├── __init__.py
        ├── main.py
        └── command.py
```

ディレクトリ構成としては `src/` 配下にコードをまとめているのがポイントですかね。
最初はpyptoject.tomlと同レベルに `sample_project` ディレクトリを作成する構成をとっていました。
これの利点としては `Poetry` がプロジェクト名と同名のディレクトリを自動でインポートしてくれるので、
特に設定をしなくてもそのまま利用出来たところです。
ただ、[pytestのベストプラクティス](https://docs.pytest.org/en/7.1.x/explanation/goodpractices.html#choosing-a-test-layout-import-rules)を眺めていた時にこの構成を見つけ、
なにやら[非常におすすめらしい](https://blog.ionelmc.ro/2014/05/25/python-packaging/#the-structure)ので(よくわかってない)この構成を使ってみました。
個人的には後述する `pyproject.toml` 内で `src/` と指定することで、別プロジェクトでも追加回しが出来るようになったことが気に入ってますw

また、特に重要となる `pyproject.toml` ファイルの内容もまとめて紹介します。

```
[tool.poetry]
name = "sample-project"
version = "0.9.0"
description = "sample project"
authors = ["KAWAI Shun <mypaceshun@gmail.com>"]
packages = [
  { from = "src/", include = "sample_project" }
]

[tool.poetry.dependencies]
python = "^3.10"
click = "^8.1.3"

[tool.poetry.dev-dependencies]
flake8 = "^4.0.1"
pyproject-flake8 = "^0.0.1-alpha.4"
isort = "^5.10.1"
autoflake = "^1.4"
black = "^22.6.0"
poethepoet = "^0.15.0"
pre-commit = "^2.19.0"

[tool.poetry.scripts]
command = "sample_project.command:cli"

[tool.poe.tasks.lint]
sequence = [
  { cmd = "pflake8 src/" },
]
help = "check syntax"
ignore_fail = "return_non_zero"

[tool.poe.tasks.format]
sequence = [ 
  { cmd = "autoflake -ir --remove-all-unused-imports --ignore-init-module-imports src/" },
  { cmd = "isort src/" },
  { cmd = "black src/" },
  "lint"
]
help = "format code style"

[tool.isort]
profile = "black"

[tool.flake8]
max-line-length = 88

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

`[build-system]` は `poetry init`で自動生成されたままのものなので割愛します。
`poetry init` した後、`poetry add -D flake8 pyproject-flake8 autoflake isort black poethepoet pre-commit`としています。
ポイントとしては以下です。

* リンターの導入(`flake8`、`pyproject-flake8`)
* フォーマッターの導入(`autoflake`、`isort`、`black`)
* タスクランナーの導入(`poethepoet`)
* `pre-commit`の導入

## リンターの導入

リンターとはコードのスタイルチェックをしてくれるツールです。
コードとしてはエラーにならないが、コード記述のルールに沿わないものをチェックしてくれます。
例として以下のコードに`flake8`を実行するとエラーになります。

```
import click

@click.command()
def cli():
    no_use_var = 'no use'
    click.echo("Sample Project")
```

こんな感じで怒られます。

```
src/sample_project/command.py:3:1: E302 expected 2 blank lines, found 1
src/sample_project/command.py:5:5: F841 local variable 'no_use_var' is assigned to but never used
```

`E302 expected 2 blank lines, found 1` [E302エラー](https://www.flake8rules.com/rules/E302.html)は簡単に言うと、
関数間の改行は2行開けようねということです。
これくらいだと別にいいだろ！となりますねw

`F841 local variable 'no_use_var' is assigned to but never used` [F841エラー](https://www.flake8rules.com/rules/F841.html)は見ての通り、
`no_use_var`という変数は使われていないよと教えてくれてます。
こういう「動作上問題無いが、書き方として望ましくない箇所」をエラーにして教えてくれます。
これらは将来的にバグを生む可能性があるので全て潰しておくのが吉です。

ただ、ひたすらコード書いた後にこのエラーが100個とか出てきて白目を剥くことが多々あるのですが、
それの対処法は後述するフォーマッターがうまいことしてくれます。

`pyproject-flake8`は最近見つけたライブラリで痒いところに手が届くやつです。
というのも、`flake8`の設定は `setup.cfg`、`tox.ini`、`.flake8`のいずれかに書く必要があります。
私の構成では`max-line-length = 88`を設定する必要があったのですが(後述)このためだけにファイルが一つ増えるのは億劫でした。
そこで見つけたのが`pyproject-flake8`で読んで字のごとく`pyproject.toml`に`flake8`の設定を記述出来るようになります。

もちろん将来的に`flake8`が`pyproject.toml`を設定ファイルとして参照してくれるようになったらお役御免なのですが、
現状は非常に助かっているので私のなかで欠かせないライブラリになりました。

注意点として `flake8` を実行するときのコマンドは `flake8` ですが、 `pyproject-flake8` を利用して実行する際のコマンドは `pflake8` になります。

## フォーマッターの導入

フォーマッターとはコードのスタイル整形をしてくれるツールです。
リンターがエラーとする箇所を出来る限り自動で直してくれます。
現状私が使っているフォーマッターは`autoflake`、`isort`、`black`の3つです。

それぞれ、順番に解説していきます。

### autoflake

`autoflake` は使っていない変数や使っていないインポートを削除してくれます。
特に使っていないインポートを削除してくれる機能が嬉しく、そのためだけに導入していると言っても過言ではありません。

逆に使っていない変数を削除してくれる機能は最近は使わなくなってきました。

```
var = 1 + 2
```

というコードの`var`という変数が利用されていない場合、`autoflake`を実行すると以下のようになります。

```
1 + 2
```

いやそこは残るのか！

確かに右辺で大事な関数の呼び出しなどしている可能性もあるので、迂闊に削除出来ないのでしょう。
ただこうなってしまうとコード上問題は無いので、リンターにもかからず永遠に意味のないコードが埋もれてしまう可能性があります。
そのため利用されていない変数はリンターにエラーとして出してもらい自分で対処するのが一番良さそうです。

### isort

`isort` はインポート文をいい感じに並び替えてくれます。

例として以下のコードを並び替えてもらうと、

```
import sys 
from pathlib import Path
import click
import os
```

こうなります。

```
import os
import sys 
from pathlib import Path

import click
```

インポート文をアルファベット順で並べ替えるのがメインの機能ですが、標準ライブラリとそうでないライブラリを分けてくれる機能もあります。
また `import` 形式と `from` 形式も区別してくれてますね。
この後紹介する `black` と足並みを揃えてもらうために `profile = "black"` の設定が必須です。

### black

これも最近知ったフォーマッターですがかなり気に入ってます。
`black`に関しては先に紹介した`autoflake`、`isort`以外のフォーマットを全てしてくれます。
最強便利マンだと思ってます。
先述した `flake8` に怒られるコードを例に紹介します。

```
import click

@click.command()
def cli():
    no_use_var = 'no use'
    click.echo("Sample Project")
```

これに対し `black` を実行すると以下のようになります。

```
import click


@click.command()
def cli():
    no_use_var = "no use"
    click.echo("Sample Project")
```

E30エラーは修正されていますね！
F841エラーはそのままです。 `autoflake`で述べたようにこれの修正は難しいのだと思ってます。
また注目すべき点としては `'no use'` が `"no use"` になってます。
Pythonのコードではシングルクオートでもダブルクオートでもエラーになりません。
[pep8](https://pep8-ja.readthedocs.io/ja/latest/#section-11)では、
「どちらでもいいけど統一しよう」ということらしいです。

`black`では全てダブルクオートで統一するように修正してくれます。
勝手に統一してくれるという点で非常に気に入ってます。
シングルクオート派の人がいたら鬱陶しい機能でしょうが、私は特にこだわりりがないので問題になっていません。

## タスクランナーの導入

## `pre-commit`の導入

# 少し真面目に書く時の構成

「少し真面目に書く」の基準としては、知人や職場の人も見る予定がある、自分でも今後複数回使う予定がある、をイメージしています。
ある程度他人に見られる想定をしてコードを書きますが、最終的には直接説明したりすればいいかなという温度感です。
あと自分以外に利用してもらうことを想定するので、コードの完成度も少し考えるようになります。

ディレクトリ構成はこちらです。

```
sample-project
├── .gitignore
├── .pre-commit-config.yaml
├── README.rst
├── CHANGELOG.rst
├── poetry.lock
├── pyproject.toml
├── .github
│   └── workflows
│       └── main.yml
├── src
│   └── sample_project
│       ├── __init__.py
│       ├── main.py
│       └── command.py
└── tests
    └── test_command.py

```

* mypyの導入
* テストコードの導入(`pytest`、`pytest-cov`)
* poetry-dynamic-versioningの導入
* GitHub Actionsの導入


# 真剣に書くときの構成

「真剣に書く」の基準としては、PyPIに公開する予定がある、をイメージしています。
赤の他人が見て利用出来ることを想定するので、ドキュメントをしっかり書きます。
逆にここまでしっかり作り込まない時は`README`につらつら書いて済ませてしまいます。

ディレクトリ構成はこちらです。


```
sample-project
├── .gitignore
├── .pre-commit-config.yaml
├── .readthedocs.yaml
├── README.rst
├── CHANGELOG.rst
├── LICENSE
├── poetry.lock
├── pyproject.toml
├── .github
│   └── workflows
│       └── main.yml
├── docs
│   ├── conf.py
│   ├── index.rst
│   └── changelog.rst
├── src
│   └── sample_project
│       ├── __init__.py
│       ├── main.py
│       └── command.py
└── tests
    └── test_command.py

```

* Sphinxの導入
* `.readthedocs.yaml` の導入
