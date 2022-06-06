---
title: "Poetryがとてもいいという話"
date: 2022-06-06T22:58:56+09:00
description: Poetryがとてもいいというお話

tags:
  - tech
  - Python
  - Poetry
---

Poetryの使用感がとてもよく、Pythonでコードを書く際はPoetryが必須の体になってしまいました。
そこでPoetryはいいぞ！という話と、Poetryの簡単な利用方法をまとめたいと思い本記事を書き始めました。

<!--more-->

# Poetryに出会うまでのライブラリ管理

私は4年くらい前からPythonのコードを書くようになりました。
いろいろ試行錯誤した結果Poetryに行き着きましたが、それまでの経緯を軽くまとめます。

## pip + requirements.txt

`requirements.txt` は例として以下のような内容を記述したテキストファイルになります。
ファイル名は特に指定はありませんが `requirements.txt` としているプロジェクトをよく見ます。

```
# requirements.txt 
click==8.0.3
requests==2.27.1
```

使い方としては通常の `pip install` に `-r` オプションでファイルを指定します。
以下の例では `testenv` というvenv環境に上記の `requirements.txt` を利用してライブラリをインストールしています。

```
$ python3 -m venv testenv
$ ./testenv/bin/python -m pip install -r requirements.txt 
Collecting click==8.0.3
  Using cached click-8.0.3-py3-none-any.whl (97 kB)
Collecting requests==2.27.1
  Using cached requests-2.27.1-py2.py3-none-any.whl (63 kB)
Collecting charset-normalizer~=2.0.0
  Using cached charset_normalizer-2.0.12-py3-none-any.whl (39 kB)
Collecting certifi>=2017.4.17
  Using cached certifi-2022.5.18.1-py3-none-any.whl (155 kB)
Collecting idna<4,>=2.5
  Using cached idna-3.3-py3-none-any.whl (61 kB)
Collecting urllib3<1.27,>=1.21.1
  Using cached urllib3-1.26.9-py2.py3-none-any.whl (138 kB)
Installing collected packages: urllib3, idna, click, charset-normalizer, certifi, requests
Successfully installed certifi-2022.5.18.1 charset-normalizer-2.0.12 click-8.0.3 idna-3.3 requests-2.27.1 urllib3-1.26.9
```

`requirements.txt` で記述された `requests` と `click` がインストールされていますね。
`==2.27.1` というように指定したバージョンも問題なさそうです。
`certifi`、`charset-normalizer`、`idna`、`urllib3`というライブラリもまとめてインストールされています。
これは `requests` の依存ライブラリなので、`pip` が依存関係を解決し、一緒にインストールしてくれています。
`pip`がいい感じですね。

これでも十分な気がしますが、この構成では依存ライブラリのバージョンが管理されず、
依存ライブラリのバージョン違いで環境によっては動作しないという悲しい事件も何回か遭遇しました。

## Pipenv

その次にPipenvに出会いました。

* https://pipenv-ja.readthedocs.io/ja/translate-ja/

Pipenvは`Pipfile`と`Pipfile.lock`という２つのファイルを用いてライブラリのバージョン管理します。
例として `pipenv install click requests` とした際の `Pipfile` と `Pipfile.lock` の内容は以下になります。

`Pipfile`

```
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
click = "*"
requests = "*"

[dev-packages]

[requires]
python_version = "3.10"
```

`Pipfile.lock`

```
{
    "_meta": {
        "hash": {
            "sha256": "faefa386028d771dd494e1aadbbaec027f04d2ca7270ffe5de45e94cd8e41326"
        },
        "pipfile-spec": 6,
        "requires": {
            "python_version": "3.10"
        },
        "sources": [
            {
                "name": "pypi",
                "url": "https://pypi.org/simple",
                "verify_ssl": true
            }
        ]
    },
    "default": {
        "certifi": {
            "hashes": [
                "sha256:9c5705e395cd70084351dd8ad5c41e65655e08ce46f2ec9cf6c2c08390f71eb7",
                "sha256:f1d53542ee8cbedbe2118b5686372fb33c297fcd6379b050cca0ef13a597382a"
            ],
            "markers": "python_version >= '3.6'",
            "version": "==2022.5.18.1"
        },
        "charset-normalizer": {
            "hashes": [
                "sha256:2857e29ff0d34db842cd7ca3230549d1a697f96ee6d3fb071cfa6c7393832597",
                "sha256:6881edbebdb17b39b4eaaa821b438bf6eddffb4468cf344f09f89def34a8b1df"
            ],
            "markers": "python_version >= '3'",
            "version": "==2.0.12"
        },
        "click": {
            "hashes": [
                "sha256:7682dc8afb30297001674575ea00d1814d808d6a36af415a82bd481d37ba7b8e",
                "sha256:bb4d8133cb15a609f44e8213d9b391b0809795062913b383c62be0ee95b1db48"
            ],
            "index": "pypi",
            "version": "==8.1.3"
        },
        "idna": {
            "hashes": [
                "sha256:84d9dd047ffa80596e0f246e2eab0b391788b0503584e8945f2368256d2735ff",
                "sha256:9d643ff0a55b762d5cdb124b8eaa99c66322e2157b69160bc32796e824360e6d"
            ],
            "markers": "python_version >= '3'",
            "version": "==3.3"
        },
        "requests": {
            "hashes": [
                "sha256:68d7c56fd5a8999887728ef304a6d12edc7be74f1cfa47714fc8b414525c9a61",
                "sha256:f22fa1e554c9ddfd16e6e41ac79759e17be9e492b3587efa038054674760e72d"
            ],
            "index": "pypi",
            "version": "==2.27.1"
        },
        "urllib3": {
            "hashes": [
                "sha256:44ece4d53fb1706f667c9bd1c648f5469a2ec925fcf3a776667042d645472c14",
                "sha256:aabaf16477806a5e1dd19aa41f8c2b7950dd3c746362d7e3223dbe6de6ac448e"
            ],
            "markers": "python_version >= '2.7' and python_version not in '3.0, 3.1, 3.2, 3.3, 3.4' and python_version < '4'",
            "version": "==1.26.9"
        }
    },
    "develop": {}
}

```

`Pipfile`に利用するライブラリを記述し、`Pipfile.lock` に依存ライブラリを含めた情報が記述されています。
一見してわかるように`Pipfile.lock`はとても人の見れたファイルではありません。`Pipfile`に記載されているライブラリ情報をみてPipenvが自動で生成してくれます。

`Pipfile.lock` も含めて管理することで、`pipenv sync` とするだけで依存ライブラリも含めて同じ環境を再現することができます。

ちなみにPipenvは他にもいろんな機能があり、自動でvenv環境を作成してくれるところや`.env`ファイルを自動で読み込んでくれるところ、`[scripts]`という設定でタスクランナーのような使い方が出来る所も気に入ってました。

特に不満もなく使えていたのですが、Poetryを知ってしまった今はもうPipenvに戻れません...

# そしてPoetryへたどり着く

Pipenvで満足していたのですが、Poetryというものを知って軽い気持ちで使ってみました。

* https://python-poetry.org/

Poetryは `pyproject.toml`と`poetry.lock`というファイルでライブラリのバージョンを管理します。
これらのファイルは `Pipfile` `Pipfile.lock` と機能としてはほぼ同等です。
使い始めた当初としては「Pipenvと同じようなことが出来るな〜」くらいの認識で、なんなら先述した`[scripts]`を利用したタスクランナーの機能がなかったりして「これならPipenvでよくないか？」とまで思っていました。あることを知るまでは...

# pyproject.toml

この `pyproject.toml` というファイルですが、なんと`setup.py`の代替になります。
`v19.0`以降のpipコマンドは`pyproject.toml`を見てくれるのです。これがでかい。

一度Pythonのライブラリを書いたことがある人はわかると思いますが、
自分のライブラリを`whl`ファイルにビルドしたり、`PyPI`に登録して`pip install`出来るようにしたり、
pipで扱えるライブラリにするには`setup.py`が必須でした。

これが非常に書きにくくて私は苦手でした。
Pipenvを使ってもこればっかりは自分で作成する必要があり、
過去のコードやネットの情報を見つつせっせと作っていました。

参考に私が作ったライブラリを紹介します。

* https://github.com/mypaceshun/qiitacli

ここでは`setup.cfg`という`setup.py`の設定ファイルを使ってます。

`setup.py`を書くのが面倒で`pip install`出来る形にしなかったコードもたくさんありました...

ですがどうでしょう。Poetryを使うとPipenvのようにライブラリのバージョン管理をしているだけで、
そのプロジェクトをそのまま`pip install`したり`whl`ファイルにビルドしたり出来るのです。
これが本当に便利すぎて私はすっかりPipenvからPoetryに乗り換えました。

機能的にはPipenvもPoetryもほぼ同等だと思っており、あっちがいいこっちが悪いという話はするつもりは無いですが、

**Poetryで開発したプロジェクトは`setup.py`を書かなくても`pip install`することが可能になる。**

この一点で完全にPoetryを利用することを決めました。(どんだけ`setup.py`書きたくなかったんだw)

# Poetryの使い方

ここからはPoetryの利用方法を簡単に紹介しようと思います。

## Poetryのインストール

PoetryもPythonのライブラリなのでpipでインストールすることができます。
私はLinux環境を触ることが多いので以下のコマンドでインストールすることが多いです。

```
$ python3 -m pip install --user poetry
```

`--user`をつけるとグローバル環境を汚さず`~/.local/`配下にインストールしてくれるんですよね〜便利。
あとは`.bashrc`なり`.zshrc`なりに `export PATH=$PATH:~/.local/bin` と追記してパスを通せばpoetryコマンドが利用可能になります。

私は基本的にこの手順でインストールします。

最近だと`get-poetry.py`を実行したほうがスマートなのか？詳細は公式ドキュメントを確認してみてください。

* https://python-poetry.org/docs/#installation

## Poetryプロジェクトの作成

`pyproject.toml`も1から書こうと思うと大変ですが、もちろんそんなことはしなくて大丈夫です。
`poetry init` というコマンドが用意されており、対話的に情報を入れていくだけで`pyproject.toml`ファイルを生成してくれます。

```
$ poetry init

This command will guide you through creating your pyproject.toml config.

Package name [poetry-blog]:  
Version [0.1.0]:  0.9.0
Description []:  Poetry ha iizo
Author [KAWAI Shun <your@mail.example.com>, n to skip]:  
License []:  MIT
Compatible Python versions [^3.10]:  ^3.8

Would you like to define your main dependencies interactively? (yes/no) [yes] 
You can specify a package in the following forms:
  - A single name (requests)
  - A name and a constraint (requests@^2.23.0)
  - A git url (git+https://github.com/python-poetry/poetry.git)
  - A git url with a revision (git+https://github.com/python-poetry/poetry.git#develop)
  - A file path (../my-package/my-package.whl)
  - A directory (../my-package/)
  - A url (https://example.com/packages/my-package-0.1.0.tar.gz)

Search for package to add (or leave blank to continue): 

Would you like to define your development dependencies interactively? (yes/no) [yes] 
Search for package to add (or leave blank to continue): 

Generated file

[tool.poetry]
name = "poetry-blog"
version = "0.9.0"
description = "Poetry ha iizo"
authors = ["KAWAI Shun <your@mail.example.com>"]
license = "MIT"

[tool.poetry.dependencies]
python = "^3.8"

[tool.poetry.dev-dependencies]

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"


Do you confirm generation? (yes/no) [yes]
```

質問文後半の`[]`内の値がデフォルト値になります。そのままで良ければ`Enter`で変更する場合は値を入れて`Enter`です。
私は`version`を`0.9.0`として`license`を`MIT`とするようにしてます。あまり深い意味はありません。

`Compatible Python versions`はデフォルトで`^3.10`となっていますが、これだとPython3.10以降でしかインストール出来ないライブラリになるので少し使い勝手が悪い気がします。
個人利用するだけなら問題ないですが、特にPython3.10やPython3.9でしか利用出来ない構文を利用する予定がなければ、`^3.8`くらいに落としておいた方がいいと思います。

またこれ以降で依存ライブラリの設定なども出来ますが、これは後からでも出来るので私は`Enter`連打して終わらせてしまいますw

これで`pyproject.toml`の完成です！

この時点ですでに`pip install`することが可能です。`pip install <ファイルパス>`でローカルディレクトリを直接指定してインストールしたり、
`pip install git+https://github.com/mypaceshun/poetry-blog`とすることでGitHub経由でインストールすることも可能です。

## 依存ライブラリの追加

これだと依存ライブラリの設定が出来ないので以前の例同様に`click`と`requests`を依存ライブラリとしてインストールしてみましょう。
依存ライブラリの追加は`poetry add`コマンドを利用します。今回の場合は`poetry add click requests`とします。

```
poetry add click requests
Creating virtualenv poetry-blog in /home/shun/poetry-blog/.venv
Using version ^8.1.3 for click
Using version ^2.27.1 for requests

Updating dependencies
Resolving dependencies... (0.5s)

Writing lock file

Package operations: 6 installs, 0 updates, 0 removals

  - Installing certifi (2022.5.18.1)
  - Installing charset-normalizer (2.0.12)
  - Installing idna (3.3)
  - Installing urllib3 (1.26.9)
  - Installing click (8.1.3)
  - Installing requests (2.27.1)
```

この中でいくつかのことをまとめてやってくれています。

* venv環境の作成

  venv環境がなければ適切な場所にvenv環境を作成します。
  私の場合は`virtualenvs.in-project`をtrueにしているので([参考](https://python-poetry.org/docs/configuration/#virtualenvsin-project))、`pyproject.toml`と同ディレクトリに`.venv`という名前のvenv環境が出来ました。

* 依存関係の解決とインストール

  依存関係を解決し、必要なライブラリをまとめてインストールしてくれます。

* `Poetry.lock`ファイルのアップデート

  依存ライブラリを含めたすべてのライブラリのバージョン情報を `poetry.lock` に書き出しています。

ほかにも`poetry remove`で依存ライブラリを削除したり、`poetry update`で依存ライブラリのアップデートが可能です。

## 別環境へのインストール

`pyproject.toml`や`poetry.lock`を利用してライブラリをインストールする際は`poetry install`を利用します。

```
$ poetry install
Creating virtualenv poetry-blog in /home/shun/poetry-blog/.venv
Installing dependencies from lock file

Package operations: 6 installs, 0 updates, 0 removals

  - Installing certifi (2022.5.18.1)
  - Installing charset-normalizer (2.0.12)
  - Installing idna (3.3)
  - Installing urllib3 (1.26.9)
  - Installing click (8.1.3)
  - Installing requests (2.27.1)
```

ここでも必要に応じてvenv環境を作成し、依存ライブラリをインストールしています。

また`poetry install`は、「`poetry.lock`が存在する場合はそちらを参照し、ない場合は`pyproject.toml`を参照し`poetry.lock`を生成する」という動作になります。
`poetry.lock`も含めて管理していればこちらを参照してくれるので、依存ライブラリを含めて全く同じ環境がすぐに再現できます。

# whlファイルの作成

ビルド手順を説明する前にコードを追加します。
コード1行も無いともちろんビルドに失敗します。
ディレクトリ構成としては以下のようになります。

```
poetry-blog
├── pyproject.toml
├── README.rst
└── poetry_blog
   └── __init__.py
```

Poetryはデフォルトで`pyproject.toml`と同ディレクトリで、ライブラリと同名のディレクトリをパッケージ本体として認識してくれます。
なお、ハイフン(`-`)はPythonのライブラリ名として利用出来ないので、アンダーバー(`_`)に読み替えられます。
`poetry_blog`ディレクトリに自身のコードをせっせと書いていくわけですが、今回はひとまず空っぽのまま`__init__.py`だけ置いておきます。

whlファイルのビルドには`poetry build`を利用します。

```
$ poetry build
Building poetry-blog (0.9.0)
  - Building sdist
  - Built poetry-blog-0.9.0.tar.gz
  - Building wheel
  - Built poetry_blog-0.9.0-py3-none-any.whl
```

これで`pyproject.toml`と同ディレクトリに`dist`というディレクトリが作成され、ビルド成果物が保存されています。

```
$ ls dist 
poetry-blog-0.9.0.tar.gz  poetry_blog-0.9.0-py3-none-any.whl
```

ここまでくれば後は `poetry publish`とするだけで`PyPI`にアップロードすることも可能です。
今回は空っぽのライブラリなのでさすがにアップロードまではしませんが、
自分の書いたライブラリが`PyPI`に登録されるのは便利ですし、`pip install`出来た時は結構嬉しいですw

# おわり

ここで紹介した機能はほんの一部ですので、興味のある方はPoetryのドキュメントを眺めて見ると面白いと思います。

* https://python-poetry.org/docs/

サンプルコードが多く、英語能力壊滅している私でもかなり理解しやすい内容になってましたw

もとはといえば「Poetryで開発する時に❍❍するといい感じでさ〜」という話を友人にしてた時に、
「Poetryよくわかってないんだよね〜」と言われたことをきっかけに、
Poetryを利用するとっかかりになればいいなと思って書き始めました。

どこかの誰かのPoetryを使うとっかかりになれば幸いです。
