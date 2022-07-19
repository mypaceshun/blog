---
title: Pythonで開発する時のディレクトリ構成を晒します
date: 2022-07-19T22:42:13+09:00
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
個人的には後述する `pyproject.toml` 内で `src/` と指定することで、別プロジェクトでも使い回しが出来るようになったことが気に入ってますw

また、特に重要となる `pyproject.toml` の内容もまとめて紹介します。

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
現状は非常に助かっているので私のなかでは欠かせないライブラリになりました。

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

E302エラーは修正されていますね！
F841エラーはそのままです。 `autoflake`で述べたようにこれの修正は難しいのだと思ってます。
また注目すべき点としては `'no use'` が `"no use"` になってます。
Pythonのコードではシングルクオートでもダブルクオートでもエラーになりません。
[pep8](https://pep8-ja.readthedocs.io/ja/latest/#section-11)では、
「どちらでもいいけど統一しよう」ということらしいです。

`black`では全てダブルクオートで統一するように修正してくれます。
勝手に統一してくれるという点で非常に気に入ってます。
シングルクオート派の人がいたら鬱陶しい機能でしょうが、私は特にこだわりりがないので問題になっていません。

## タスクランナーの導入

タスクランナーとはよく実行するコマンドを登録しておけるものです。
例えば `autoflake` を実行する場合 `autoflake -ir --remove-all-unused-impoprts --ignore-init-module-imports src/` というコマンドを実行します。
これを毎回入力して実行するのはあまりにも大変です。
そこで活躍するのが `poethepoet` というライブラリです。

前述した `pyproject.toml` 内の `tool.poe` で始まるセクションはすべて `poethepoet` の設定になります。

```
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
```

このようによく使うコマンドを設定に書いておくことで簡単に呼び出せるようになります。
例えば `[tool.poe.tasks.lint]` に記載されているコマンドは、以下のコマンドで呼び出せます。

```
poetry run poe lint
```

`tool.poe.tasks` のあとは任意の文字列を設定でき、呼び出す際にはその文字列を利用します。
`tool.poe.tasks.format` だとしたら呼び出す際のコマンドは `poetry run poe format` となるわけです。

上記の設定では `poetry run poe lint` でリンターの実行。
`poetry run poe format` でフォーマッターの実行が可能になります。

これで長いオプションを入力する必要もなくなり、`autoflake`や`isort`や`black`もコマンド一発で全て実行出来るようになります。
`poethepoet` が無かったらここまで `poetry` をガッツリ使うようになることも無かったかもしれません。
それくらい助かってます。

## `pre-commit`の導入

`pre-commit` というのはもともと `git` の `hook` のひとつです。[参考](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA-Git-%E3%83%95%E3%83%83%E3%82%AF)
`git commit` する際に自動で実行されるスクリプトを設定しやすくしたライブラリが `pre-commit` です。

`pre-commit` の設定は `.pre-commit-config.yaml` に記述します。
例として私が使っている設定を晒します。

```
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks
repos:
- repo: https://github.com/psf/black
  rev: 22.6.0
  hooks:
  - id: black
    language_version: python3

- repo: https://github.com/pycqa/isort
  rev: 5.10.1
  hooks:
    - id: isort
      args: ["--profile", "black"]

- repo: https://github.com/myint/autoflake.git
  rev: v1.4
  hooks:
  - id: autoflake
    args:
      - "-i"
      - "--remove-all-unused-imports"
      - "--ignore-init-module-imports"

- repo: https://gitlab.com/pycqa/flake8
  rev: 3.9.2
  hooks:
  - id: flake8
    # max-line-length setting is the same as black
    # commit cannot be done when cyclomatic complexity is more than 10.
    args: [--max-line-length, "88"]
```

コミット時に含まれてるファイルをチェックし、設定に記述されているコマンドを実行していきます。
他にも設定ファイルをフォーマットしたり、rstファイルをスタイルチェックしてくれたりするのですが、
正直うまく使いこなせていません。

というのも、それぞれのコマンドの設定が `.pre-commit-config-yaml` と `pyproject.toml` に分かれてしまっているのが一番納得のいっていないポイントです。
あまり変更しない箇所なのでいいっちゃいいのですが、たまーに変更したくなったときに両者のファイルを修正しなければならないのがうまくありません。

これに関してはよりよい構成を探している最中です、アドバイス等いただけると飛んで喜びます...

`pre-commit` のフックはインストールする必要があります。
インストールというのも `.git/hooks/` にスクリプトを配置する必要があるのですが、
もちろん手動で配置する必要はありません。
以下のコマンドでフックのインストールが完了します。

```
poetry run pre-commit install
```

これでコミットするたびに `flake8` 等が実行されるようになりました。
私は基本的にコード書きながら `poetry run poe format` するので必要無いと言えば無いのですが、
忘れてコミットしようとすることもあるので、その時は `pre-commit` がエラーになり、
フォーマット前のコードをコミットすることを防いでくれます。


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

雑に書く時の構成から変更されたポイントとしては `tests/` ディレクトリや、`.github/` ディレクトリが増えた点でしょうか。
このくらいからはテストコードもしっかり書こうとします。作業が増えるのであまり好きではないですが(小声)
他人に見られることを考えるなら最低限のテストコードは書きます。
また `GitHub Actions` の設定も追加します。`GitHub Actions`を使うようになったのは最近ですが(さらに小声)
自動でテストしてくれるので使わない理由はありません。
テストコードをしっかり書き、`GitHub Actions`でテストを実行することでプログラムの動作が保証されます。
`GitHub Actions` を使うためにもテストコードを書く必要が出てきます。

`CHANGELOG.rst` が増えていますがこれには改定履歴をせっせと書きます。
「`changelog`あるとそれっぽいよな〜」くらいの軽い気持ちで追加してます。
実際機能追加した時期などわかると後々便利なのでしょうが、
あとから `changelog` を確認しなければならないほど長いことこの構成を使っていないので、
あまり恩恵は受けていませんw

また他人に利用してもらうことを想定するので利用手順やインストール手順をちゃんと書きます。
これは `README.rst` にせっせと書きます。
`README.md` ではなく `README.rst` なのは後述する `Sphinx` でインポートすることを想定しているためです。
そこまでするつもりのない場合は `README.md` で書いたりします。正直どっちでもいいです。

またこの構成での `pyproject.toml` の内容も晒します。

```
[tool.poetry]
name = "sample-project"
version = "0.9.0"
description = "sample project"
authors = ["KAWAI Shun <mypaceshun@gmail.com>"]
packages = [
  { from = "src/", include = "sample_project" }
]
include = [
  "CHANGELOG.rst"
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
pytest = "^7.1.1"
pytest-cov = "^3.0.0"
mypy = "^0.942"
types-setuptools = "^57.4.12"

[tool.poetry.scripts]
command = "sample_project.command:cli"

[tool.poetry-dynamic-versioning]
enable = true
vcs = "git"

[tool.poe.tasks.lint]
sequence = [
  { cmd = "pflake8 src/ tests/" },
  { cmd = "mypy src/ tests/" }
]
help = "check syntax"
ignore_fail = "return_non_zero"

[tool.poe.tasks.format]
sequence = [
  { cmd = "autoflake -ir --remove-all-unused-imports --ignore-init-module-imports src/ tests/" },
  { cmd = "isort src/ tests/" },
  { cmd = "black src/ tests/" },
  "lint"
]
help = "format code style"

[tool.poe.tasks.test]
cmd = "pytest -v --cov=src/ --cov-report=html --cov-report=xml --cov-report=term tests/"
help = "run test"

[tool.isort]
profile = "black"

[tool.flake8]
max-line-length = 88

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

雑に書く時の構成に追加して `poetry add -D pytest pytest-cov mypy types-setuptools` としています。
ポイントとしては以下です。

* mypyの導入
* テストコードの導入(`pytest`、`pytest-cov`)
* poetry-dynamic-versioningの導入
* GitHub Actionsの導入

## mypyの導入

Pythonの[型ヒント](https://docs.python.org/ja/3/library/typing.html)というやつですね。最近少しづつ付けられるようになりました。
`mypy`は型ヒントを見てチェックをしてくれます。[公式](https://mypy.readthedocs.io/en/stable/)曰く「static type checker」です。

もともとPythonは動的に型を判断する動的型付け言語です。
プログラム内で変数の中に入る型はプログラム実行中に決まります。

```
>>> def printType(var):
...   print(type(var))
...
>>> printType(123)
<class 'int'>
>>> printType("abc")
<class 'str'>
```

静的型付け言語や動的型付け言語などしらべるとたくさん情報が出てくると思います。

Python3.5から `typing` というモジュールが追加され、Pythonでも静的型付けが出来るようになってきました。
先程の関数の引数 `var` を `str` 型を受け付けるように型ヒントを付けると以下のようになります。

```
def printType(var: str):
  print(type(var))
```

ただPythonは「型ヒント」というように、型の情報はあくまでヒントにすぎず、これに沿わなくてもプログラムは動作します。

```
>>> def printType(var: str):
...   print(type(var))
...
>>> printType(123)
<class 'int'>
>>> printType("abc")
<class 'str'>
```

そしてこの型ヒントを見てコードのチェックをしてくれる賢いやつが `mypy` というツールになります。
`mypy` は型ヒントを見てコード実行前に不正な代入が行われていないかチェックしてくれます。
先程のコードを `mypy` を使ってチェックすると以下のようなエラーになります。

```
error: Argument 1 to "printType" has incompatible type "int"; expected "str"
```

`printType`には`str`が渡されるはずなのに`int`が渡されていると言われてますね。
リンター同様に未来のバグを発見することが出来ます。
例えば以下のようなコードがあるとします。

```
from typing import Union

def func(var: Union[str, int]) -> int:
    return len(var)

length = func("abc")
print(length)
```

`Union` というのは `typing` モジュールに含まれるもので、
`Union[str, int]` というのは「`str`か`int`のどちらか」という意味になります。

`def func(var: Union[str, int]) -> int:` というのは、
「`var`という引数は`str`か`int`の型を受け取り、この関数の返り値は `int` になる」という意味です。

このプログラムはエラーなく動作します。

```
$ python3 test.py
3
```

ですが`mypy`を実行するとエラーになります。

```
$ mypy test.py
test.py:4: error: Argument 1 to "len" has incompatible type "Union[str, int]"; expected "Sized"
Found 1 error in 1 file (checked 1 source file)
```

`var` は `int` と `str` を許容するはずですが、関数内で利用されている `len(var)` は `int` では動作しないためです。
将来的に `int` 型の値を入れていたらエラーになっていたことでしょう。
こういった将来的にバグをうむ可能性がある箇所を事前にチェックしてくれるのでとても気に入っています。
先程のプログラムは以下の用に修正すると `mypy` のチェックに通るようになります。

```
from typing import Union

def func(var: Union[str, int]) -> int:
    if isinstance(var, int):
        return var
    return len(var)

length = func("abc")
print(length)
```

(そもそもどういう意図のコードなのかは置いておいてください私もわかりません)

最近ようやく慣れてきましたがまだ直し方のわからないエラーに遭遇することがあります...

また`poetry run poe lint` で `mypy` の実行も出来るように`[tool.poe.tasks.lint]` の設定も追加されています。


## テストコードの導入

コードの動作を保証するためにテストコードも導入します。
テストコードは実際に動作するコードとは別に、それの動作をテストするためのコードです。
Pythonのテストコードを導入するライブラリとしては `pytest` がメジャーだと思います(自分調べ)
私はそれに加え `pytest-cov` というライブラリも合わせて導入しています。

私の構成ではテストコードは `tests/` ディレクトリ配下にまとめます。
`pytest` は指定したディレクトリ内の `test_*.py` というファイルか `*_test.py` というファイルをテストコードと認識し、
テストを実行していきます。
詳しくは [公式](https://docs.pytest.org/en/7.1.x/explanation/goodpractices.html#test-discovery)に記載されています。

例えば先程のコード

```
from typing import Union

def func(var: Union[str, int]) -> int:
    if isinstance(var, int):
        return var
    return len(var)

length = func("abc")
print(length)
```

これのテストコードの例としては以下のようになります。

```
from sample_project.main import func


def test_func_success_str():
    assert func("test") == 4
```

`from sample_project.main import func` は先程のコードが `src/sample_project/main.py` に記載されていることを想定しています。
今回テストする `func` 関数をインポートしています。

このテストを実行するには `pytest tests/` と実行してください。

```
$ poetry run pytest tests/
=========================================================== test session starts ============================================================
platform linux -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0
rootdir: /tmp/sample-project
plugins: cov-3.0.0
collected 1 items                                                                                                                          

tests/test_func.py  .                                                                                                                [100%]

============================================================ 1 passed in 0.01s =============================================================

```

よい感じに出力してくれます。

テストの書き方は様々な考え方があるのでこう書くべき！みたいなのはここでは言及しませんが、
関数ごとに最低限の機能を満たしているか確認するようなテストコードはあると将来の自分が助かります。

少し時間をあけた後にプログラムの改修をした際などに、既存の機能が破壊されていないことを手軽に確認出来ますし、
手作業で確認するのと違って確認漏れなどが発生しづらいので、将来の自分が安心して手を加えられるようにもテストコードはあるに越したことはないと思っています。

### カバレッジ

テストにはカバレッジ(coverage)というもの(?)があります。
テストカバー率と言えばまだわかりやすいかもしれません。
簡単に言うと「コード全体の内テストコードでカバー出来た部分の割合」でしょうか。

`pytest` では `pytest-cov` というプラグインを使うことで簡単に計測できます。
`pytest-cov` がインストールされている環境では `pytest` に新しいオプションが追加されます。
それが `--cov` や `--cov-report` です。

先程のテストコードをもとに実行するコマンドを `pytest --cov=src/ tests/` としてみましょう。

```
$ poetry run pytest --cov=src/ tests/                       
=========================================================== test session starts ============================================================
platform linux -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0
rootdir: /home/shun/document/tmp/sample-project
plugins: cov-3.0.0
collected 1 item                                                                                                                           

tests/test_func.py .                                                                                                                 [100%]

---------- coverage: platform linux, python 3.10.4-final-0 -----------
Name                         Stmts   Miss  Cover
------------------------------------------------
src/sample_project/main.py       7      1    86%
------------------------------------------------
TOTAL                            7      1    86%


============================================================ 1 passed in 0.02s =============================================================
```

86%となっていますね。これはテストコード実行時に `src/sample_project/main.py` の86%の行が実行されたことを示します。

さらに `--cov-report` オプションを追加してみましょう。
これは計測結果の出力形式を指定できます。
私のお気に入りは `--cov-report=html` です。

```
$ poetry run pytest --cov=src/ --cov-report=html tests/
=========================================================== test session starts ============================================================
platform linux -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0
rootdir: /home/shun/document/tmp/sample-project
plugins: cov-3.0.0
collected 1 item                                                                                                                           

tests/test_func.py .                                                                                                                 [100%]

---------- coverage: platform linux, python 3.10.4-final-0 -----------
Coverage HTML written to dir htmlcov


============================================================ 1 passed in 0.03s =============================================================
```

`Coverage HTML written to dir htmlcov` と書かれているように、計測結果がHTMLファイルで`htmlcov`配下に出力されます。
お好きなWebブラウザで `htmlcov/index.html` を表示すると計測結果がとても見やすく表示されます。

{{< figure src="/images/20220719/coverage_report_top.png" >}}

また、コードを直接表示し、テストで実行された行と実行されなかった行を見やすく表示してくれます。

{{< figure src="/images/20220719/coverage_report_main_86.png" >}}

今回は6行目 `return var` の行が実行されていませんでした。
つまり `var` が `int` だった場合のテストが無かったわけです。
これを解消するにはテストを増やしましょう。

```
from sample_project.main import func


def test_func_success_str():
    assert func("test") == 4

def test_func_success_int():
    assert func(10) == 10
```

{{< figure src="/images/20220719/coverage_report_main_100.png" >}}

全てのコードがテストで実行され、カバレッジが100%になりました。

今回のように「テストコードの作成漏れ」を探すのにとても助かります。
ただ「カバレッジが100%のコードがいいコード」とは限りません。
カバレッジを100%にしたいがために追加したテストコードは、
必ずしも適切なテストコードになるとは限らないからです。

ただカバレッジが100%になったときは達成感があるので、100%に出来るならしてしまいます。(小声)

カバレッジをどこまで求めるかは人によって意見の分かれそうなところですね。

## poetry-dynamic-versioningの導入

[`poetry-dynamic-versiong`](https://github.com/mtkennerly/poetry-dynamic-versioning)というライブラリを導入します。
導入するといってもこれは今までのライブとは少しテイストが違います。

というのも、`Poetry` 自体の拡張ライブラリになります。
`Poetry` が導入されている環境にインストールする必要があるので `pyproject.toml` には記載しません。
例えば `Poetry` を `python3 -m pip install --user poetry` としてインストールした場合は `python3 -m pip install --user poetry-dynamic-versioning` とします。

結局 `poetry-dynamic-versioning` とは何かと言うと、パッケージのバージョンを外部から取得出来るようにするツールです。

というのも `Poetry` ではパッケージのバージョンは `pyproject.toml` に記述するしか方法がありません。
`setup.cfg` の頃は[コード内の変数から取得出来たり](https://setuptools.pypa.io/en/latest/userguide/declarative_config.html#specifying-values)、
[`setuptools-scm`](https://github.com/pypa/setuptools_scm/) というライブラリを利用して、gitのタグをそのままバージョンとする方法がありました。

`poetry-dynamic-versioning`はまさにそれらと同等のことを `Poetry` で実現するためのライブラリです。

`poetry-dynamic-versioning` の設定は`pyproject.toml`の`[tool.poetry-dynamic-versioning]`に記述します。
私が使っている設定は以下になります。

```
[tool.poetry-dynamic-versioning]
enable = true
vcs = "git"
```

ほぼデフォルトのままですね。さらに言えば `vcs = "git"` は明示的に書かなくても動作するので実際は `enable = true` の1行で動作します。

これを設定し、`v0.0.0`の形式でgitのタグを設定すると、タグの値をバージョンとして認識してくれます。

```
$ git tag v0.9.1

$ poetry version
sample-project 0.9.1
```

設定をすることでタグから追加のコミットがあった場合、バージョン名に開発版を示すタグをつけたり出来ます。
私はそこまでは必要としていないので使っていません。興味がある方は公式のドキュメントを読んでみてください。
結構いろんなことが出来ます。

### `__version__`

ライブラリには `__version__` という変数を設定しているものをよく見ます。
~~正直必要性はよくわかっていませんが~~ せっかくなら定義しておきたいですね。

私がよく書く `__init__.py` はこちらです。

```
__name__ = "sample-project"
import pkg_resources

__version__ = pkg_resources.get_distribution(__name__).version
```

`pkg_resources` を使ってインストールされているライブラリのメタデータを参照する形になります。
こうすることで `pyproject.toml` と別に直接バージョンを書く必要がなくなります。

PoetryのどこかしらのIssueで見てから参考にさせてもらってます。

実はこの書き方、このまま `mypy` を通すとエラーになります。

```
$ poetry run poe lint
Poe => pflake8 src/ tests/
Poe => mypy src/
src/sample_project/__init__.py:2: error: Library stubs not installed for "pkg_resources" (or incompatible with Python 3.10)
src/sample_project/__init__.py:2: note: Hint: "python3 -m pip install types-setuptools"
src/sample_project/__init__.py:2: note: (or run "mypy --install-types" to install all missing stub packages)
src/sample_project/__init__.py:2: note: See https://mypy.readthedocs.io/en/stable/running_mypy.html#missing-imports
Found 1 error in 1 file (checked 2 source files)
Error: Subtasks lint[1] returned non-zero exit status
```

`pkg_resources` の型情報を追加でインストールする必要があるのですね。
そのために `types-setuptools` をあわせてインストールしています。

```
$ poetry add -D types-setuptools 
Using version ^63.2.0 for types-setuptools

Updating dependencies
Resolving dependencies... (0.2s)

Writing lock file

Package operations: 1 install, 0 updates, 0 removals

  - Installing types-setuptools (63.2.0)

$ poetry run poe lint
Poe => pflake8 src/ tests/
Poe => mypy src/
Success: no issues found in 2 source files

```


## GitHub Actionsの導入

GitHub ActionsはGitHubが提供しているCIツールです。
CIとは継続的インテグレーションというもので、継続的インテグレーションが何かと言うと...なんでしょう()

テストコードの実行やカバレッジ計測、パッケージのリリースなどの自動化が出来ます。

[`Travis CI`](https://www.travis-ci.com/)や[`Circle CI`](https://circleci.com/ja/)などのサービスもありますが、
私はGitHubのリポジトリであればそのまま利用出来る`GitHub Actions`に落ち着きました。

`Github Actions`の設定は、`.github/workflows/`内にYAMLファイルで記述します。
これも一度作ったものをコピペし続けてる秘伝のタレになってますw
そんな私の `GitHub Actions`の設定はこちらになります。

```
name: Test
on:
  workflow_dispatch:
  push:
    branches:
      - '*'
    tags:
      - 'v*.*.*'

jobs:
  lint:
    name: ${{ matrix.name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - {name: '3.10', python: '3.10', os: ubuntu-latest}
          - {name: '3.9', python: '3.9', os: ubuntu-latest}
          - {name: '3.8', python: '3.8', os: ubuntu-latest}
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: ${{ matrix.python }}
      - name: update pip
        run: pip install -U pip setuptools wheel
      - name: install poetry
        run: pip install poetry poetry-dynamic-versioning
      - name: install libraries
        run: poetry install
      - name: run lint
        run: poetry run poe lint
  test:
    needs: lint
    name: ${{ matrix.name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - {name: '3.10', python: '3.10', os: ubuntu-latest}
          - {name: '3.9', python: '3.9', os: ubuntu-latest}
          - {name: '3.8', python: '3.8', os: ubuntu-latest}
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: ${{ matrix.python }}
      - name: update pip
        run: pip install -U pip setuptools wheel
      - name: install poetry
        run: pip install poetry poetry-dynamic-versioning
      - name: install libraries
        run: poetry install
      - name: run test
        run: poetry run poe test
      - name: upload codecov
        uses: codecov/codecov-action@v2
        with:
          fail_ci_if_error: true
          token: ${{ secrets.CODECOV_TOKEN }}
  release:
    needs: test
    name: Release
    runs-on: ubuntu-latest
    steps:
      - if: startsWith(github.ref, 'refs/tags/v')
        env:
          REF: ${{ github.ref }}
        run: echo "${REF##*/}"
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Update pip
        run: pip install -U pip setuptools wheel
      - name: Install poetry
        run: pip install poetry poetry-dynamic-versioning
      - name: Install dependent libraries
        run: poetry install
      - name: Build package
        run: poetry build
      - name: Upload artifact
        uses: actions/upload-artifact@v1
        with:
          name: 'dist'
          path: 'dist'
      - name: Create Release
        if: startsWith(github.ref, 'refs/tags/v')
        uses: ncipollo/release-action@v1
        with:
          artifacts: 'dist/*'
          token: ${{ secrets.GITHUB_TOKEN }}
          draft: false
      #- name: Publish to PyPI
      #  if: startsWith(github.ref, 'refs/tags/v')
      #  env:
      #    POETRY_PYPI_TOKEN_PYPI: ${{ secrets.PYPI_TOKEN }}
      #  run: poetry publish
```

軽く説明すると、`on` でこのワークフローを動かすタイミングを定義しており、
`jobs` でこのワークフローのジョブを定義しています。

`job` には `lint`、`test`、`release`の3つのジョブが定義されています。

`lint`ジョブでは `Python3.8`、`Python3.9`、`Python3.10`の3つのバージョンで `poetry run poe lint` を実行しています。

`lint`ジョブに成功した場合は`test`ジョブが実行されます。
`test`ジョブでは `Python3.8`、`Python3.9`、`Python3.10`のバージョンで`poetry run poe test`を実行しています。
また、[Codecov](https://about.codecov.io/)というサービスを使ってカバレッジの記録をしています。
そのため事前に`CODECOV_TOKEN`という変数に`Codecove`のアクセストークンを設定しておく必要があります。
`GitHub Actions`ではアクセストークンなど、リポジトリには入れずに利用したい変数をリポジトリの`Settings->Security->Secrets->Actions->New repository secret`で設定することが出来ます。

`test`ジョブに成功した場合は`release`ジョブが実行されます。
`release`ジョブでは`poetry build`を実行しGitHubのリリースページを作成しています。
`Create Release`ステップでは `if: startsWith(github.ref, 'refs/tags/v')`としています。
こうすることでgitのタグをプッシュした時のみ動作するようになります。

まとめると、コミット時に`lint -> test -> release(poetry build のみ)`の順にジョブが動作し、タグをプッシュした時に `lint -> test -> release(Releaseの作成も込み)`という順でジョブが実行されます。

開発中は特に気にせずコミットし続けるだけでテストやカバレッジの計測をしてくれる上、
タグをプッシュした際はパッケージを作成しReleaseの作成まで自動でしてくれます。

上の設定はどのプロジェクトでもほぼコピペで動作するのでとても重宝しています。


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

少し真面目に書く時の構成から変更されたポイントとしてはやはり `docs/` ディレクトリでしょうか。
自分以外にプログラムを利用してもらおうと思った時一番大事になる部分がドキュメントだと最近思うようになりました。
そのためPyPIに公開するようなプログラムは `Sphinx` でちゃんとドキュメントを整備すべきだと思い、
この構成に落ち着きました。
実際に他人がドキュメントを見るかどうかはわかりませんが、
ここで言う「自分以外」には「未来の自分」も含まれます。
と言うか多分一番助かってるのが未来の自分だと思いますw

`LINCENSE`ファイルなども増えていますが、これは`GitHub`でリポジトリ作成時に自動生成されるものを利用しています。

また、この構成での `pyproject.toml` を晒します。

```
[tool.poetry]
name = "sample-project"
version = "0.9.0"
description = "sample project"
authors = ["KAWAI Shun <mypaceshun@gmail.com>"]
packages = [
  { from = "src/", include = "sample_project" }
]
include = [
  "CHANGELOG.rst"
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
pytest = "^7.1.1"
pytest-cov = "^3.0.0"
mypy = "^0.942"
types-setuptools = "^57.4.12"
Sphinx = "^5.0.2"

[tool.poetry.scripts]
command = "sample_project.command:cli"

[tool.poetry-dynamic-versioning]
enable = true
vcs = "git"

[tool.poe.tasks.lint]
sequence = [
  { cmd = "pflake8 src/ tests/" },
  { cmd = "mypy src/ tests/" }
]
help = "check syntax"
ignore_fail = "return_non_zero"

[tool.poe.tasks.format]
sequence = [
  { cmd = "autoflake -ir --remove-all-unused-imports --ignore-init-module-imports src/ tests/" },
  { cmd = "isort src/ tests/" },
  { cmd = "black src/ tests/" },
  "lint"
]
help = "format code style"

[tool.poe.tasks.test]
cmd = "pytest -v --cov=src/ --cov-report=html --cov-report=xml --cov-report=term tests/"
help = "run test"

[tool.poe.tasks.doc]
sequence = [ 
  { cmd = "sphinx-apidoc -f -e -o pre-docs/ src/"},
]
help = "build document"

[tool.isort]
profile = "black"

[tool.flake8]
max-line-length = 88

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

少し真面目に書く時の構成に追加して `poetry add -D Sphinx` としています。
また `Sphinx` の初期設定のため `sphinx-quickstart` を実行します。
`sphinx-quickstart`を実行すると対話的に設定を入力し、
`source/index.rst`と`source/conf.py`を生成してくれます。

```
$ poetry run sphinx-quickstart --sep -l ja --ext-autodoc --no-makefile --no-batchfile --extensions sphinx.ext.napoleon
Sphinx 5.0.2 クイックスタートユーティリティへようこそ。

以下の設定値を入力してください（Enter キーのみ押した場合、
かっこで囲まれた値をデフォルト値として受け入れます）。

選択されたルートパス: .

プロジェクト名は、ビルドされたドキュメントのいくつかの場所にあります。
> プロジェクト名: sample-project
> 著者名（複数可）: KAWAI Shun <mypaceshun@gmail.com>
> プロジェクトのリリース []: 0.9.0

ファイル /tmp/sample-project/source/conf.py を作成しています。
ファイル /tmp/sample-project/source/index.rst を作成しています。

終了：初期ディレクトリ構造が作成されました。

マスターファイル /tmp/sample-project/source/index.rst を作成して
他のドキュメントソースファイルを作成します。次のように、ドキュメントを構築するには sphinx-build コマンドを使用してください。
 sphinx-build -b builder /tmp/sample-project/source /tmp/sample-project/build
"builder" はサポートされているビルダーの 1 つです。 例: html, latex, または linkcheck
```

また `source`ディレクトリだと `src`と被ってしまうので、`mv source/ docs/` としディレクトリ名をリネームします。
ここまでやってこの構成は完成です。

それではこの構成のポイントをまとめます。

* Sphinxの導入
* `.readthedocs.yaml` の導入
* PyPIへの公開

## Sphinxの導入

## Read the Docsの導入

## PyPIへの公開
