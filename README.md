# shellcgi - Shell framework for CGI programming

Copyright (C) 2009 Masahiko Ito

These programs is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

These programs is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with these programs; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Mail suggestions and bug reports for these programs to
"Masahiko Ito" \<m-ito@myh.no-ip.org\>

## 目的
一般的にCGIプログラムを作成する際には、ruby,perl,python,php等
々のスクリプト言語を 利用することが多いかと思いますが、shellcgi
はshell(bash)スクリプトでCGIプログラムを 構築することを容易に
するフレームワークです。shellcgiはメインフレームコンピュータ
(Z/OS、VOS3、ACOS-4 etc)での会話処理プログラムの構造に近い形
でCGIプログラムを実現します。 たとえば、1本のプログラムは1つ
の画面の作成及び処理を行います。画面遷移(プログラム遷移)はト
ランザクションコードで指定し、トランザクションコードに紐づけ
られたプログラムが順次 実行されます。各プログラム間で受け渡す
必要のあるデータは、SPA(Scratch Pad Area)を介して 連携します。
このような構造でプログラミングが可能なことで、従来COBOL等でシ
ステム開発 をしてきたエンジニアでもCGIを利用したWebアプリケー
ションを作成しやすくなります。

## インストール方法(例)
```
tar xvf shellcgi.tar.gz
cp -r shellcgi/public_html/shellcgi ~/public_html/
cp -r shellcgi/.shellcgi ~/
```

## 環境設定
~/public_html/shellcgi/cgi-bin/shellcgi.sh内の環境変数を適切に設定します。
最低限、**CGICTRL_HOMEDIR** の **_USERNAME_** 部分は自己環境に合わせて修正が必要です。
```
CGICTRL_HOMEDIR=/home/_USERNAME_/.shellcgi; export CGICTRL_HOMEDIR
CGICTRL_TMPDIR=/tmp/.shellcgi; export CGICTRL_TMPDIR
CGICTRL_LOGGING=YES; export CGICTRL_LOGGING
CGICTRL_NOAUTHENTICATEDUSER=anonymous; export CGICTRL_NOAUTHENTICATEDUSER
CGICTRL_MAXLOCKRETRY=180; export CGICTRL_MAXLOCKRETRY
CGICTRL_SWEEPDAY=2; export CGICTRL_SWEEPDAY
```

## 開発の手順(例)

### 実装する機能
今回はサンプルとして、

* 文字列を入力させる
* /etc/shellsから入力させた文字列を含む行を検索する
* 検索された行を表示する
* 空文字列が入力された場合はエラーメッセージを表示する

というのを基本的な機能とします。画面構成は文字列を入力させる画面と、
検索結果を表示する画面の2画面構成とします。

### 画面を設計する
~/.shellcgi/html/の下にhtmlファイル形式で画面を作成します。

#### 入力画面(sample1.html)
```
 1: Content-Type: text/html
 2: 
 3: <html>
 4: <head>
 5:     <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
 6:     <title>検索文字列を入力してください</title>
 7: </head>
 8: <body>
 9:     [sample1]
10:     <h1>検索文字列を入力してください</h1>
11: 
12:     <form action="./shellcgi.cgi" method="POST" enctype="multipart/form-data">
13:     <input type="hidden" value="@{CGICTRL_SESSIONID}@" name="CGICTRL_SESSIONID">
14:     <input type="text" size="80" value="@{search}@" maxlength="80" name="search"><br>
15:     <input type="submit" value="検索開始" name="submit">
16:     </form>
17:     <pre style="color:@{msgcolor=black}@">
18: @{message=}@
19:     </pre>
20: </body>
21: </html>
```
行番号は説明の便宜上付番しているものなので、実際に記述してはいけません。
では上から順に説明します。
* 1: Content-typeを指定します。通常はサンプルの通りで良いでしょう。
* 2: 必ず改行させます。
* 3: この行以降に基本的にはhtml文法に従って定義していきます。
* 12: formタグのactionには必ず **shellcgi.cgi** を呼び出すように指定します。
* 13: formタグには必ずこのhiddenタイプのinputタグを記述します。通常はサンプルの通りで良いでしょう。
* 14: **@{search}@** 部分はCGIプログラムから置き換えます。
* 17: **@{msgcolor=black}@** 部分はCGIプログラムから置き換えます。CGIプログラムから置き換えなかった場合は **black** が規定値となります。
* 18: **@{message=}@** 部分はCGIプログラムから置き換えます。規定値として空文字が指定されています。

#### 検索結果画面(sample2.html)
```
 1: #
 2: # START=@:
 3: # END=:@
 4: #
 5: Content-Type: text/html
 6: 
 7: <html>
 8: <head>
 9:     <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
10:     <title>検索結果</title>
11: </head>
12: <body>
13:     [sample2]
14:     <h1>検索結果</h1>
15: 
16:     <form action="./shellcgi.cgi" method="POST" enctype="multipart/form-data">
17:     <input type="hidden" value="@:CGICTRL_SESSIONID:@" name="CGICTRL_SESSIONID">
18:     <input type="submit" value="戻る" name="submit">
19:     </form>
20:     <h2>検索文字列</h2>
21:     <pre>
22: @:search:@
23:     </pre>
24:     <h2>検索結果</h2>
25:     <pre>
26: @:result:@
27:     </pre>
28:     <pre>
29: @:message=:@
30:     </pre>
31: </body>
32: </html>
```
行番号は説明の便宜上付番しているものなので、実際に記述してはいけません。
では上から順に説明します。
* 1: 「#」で始まる行はコメント行として扱われます。
* 2: コメント行に、 **START=** を記述した場合は、 **=** の右辺値で置換対象文字列の開始を表す **@{** を変更します。
* 3: コメント行に、 **END=** を記述した場合は、 **=** の右辺値で置換対象文字列の終了を表す **}@** を変更します。
* 5: Content-typeを指定します。通常はサンプルの通りで良いでしょう。
* 6: 必ず改行させます。
* 7: この行以降に基本的にはhtml文法に従って定義していきます。
* 16: formタグのactionには必ず **shellcgi.cgi** を呼び出すように指定します。
* 17: formタグには必ずこのhiddenタイプのinputタグを記述します。通常はサンプルの通りで良いでしょう。
* 14: **@:search:@** 部分はCGIプログラムから置き換えます。
* 26: **@:result:@** 部分はCGIプログラムから置き換えます。
* 29: **@:message=:@** 部分はCGIプログラムから置き換えます。規定値として空文字が指定されています。

### リソースを定義する
CGIプログラムで排他制御の対象とするリソースを定義します。
~/.shellcgi/resource/の下にリソースを示す文字列(リソースID)と同名のファイルを作成し、その中に
リソースの実体を示す文字列(ファイルであればフルパス等)を記述します。
```
echo "/etc/shells" >~/.shellcgi/resource/ETC_SHELLS
```

### トランザクションとCGIプログラムを定義する
~/.shellcgi/tranpgm/の下にトランザクションを示す文字列(トランザクションID)と同名のファイルを作成し、その中に
トランザクションに紐づくCGIプログラムを記述します。
```
echo "${HOME}/public_html/shellcgi/cgi-bin/sample1.cgi" >~/.shellcgi/tranpgm/SAMPLE1
echo "${HOME}/public_html/shellcgi/cgi-bin/sample2.cgi" >~/.shellcgi/tranpgm/SAMPLE2
```

### トランザクションとリソースを定義する
\~/.shellcgi/tranres/の下にトランザクションを示す文字列(トランザクションID)と同名のファイルを作成し、その中に
トランザクションで排他的に使用するリソースのリソースIDを記述します。リソースIDは\~/.shellcgi/resource/の下に定義
されている必要があります。
```
echo "ETC_SHELLS" >~/.shellcgi/tranres/SAMPLE1
echo "ETC_SHELLS" >~/.shellcgi/tranres/SAMPLE2
```

### ユーザに許可するトランザクションを定義する
~/.shellcgi/usertran/の下にBASIC認証またはDIGEST認証するユーザ名と同名のファイルを作成し、その中に
そのユーザに許可するトランザクションIDを記述します(正規表現可能)。
認証機構を使用しない場合は全てのユーザが仮想的にユーザ **anonymous** でアクセスしていることになるので、
**anonymous** に許可するトランザクションIDを記述する必要があります。
```
echo "^SAMPLE[01]$" >~/.shellcgi/usertran/anonymous
```

### sample1.cgi(入力画面処理CGI)
```
 1: #! /bin/sh
 2: . ./shellcgi.sh
 3: #-- USER CODING START(1)
 4: #-- USER CODING END(1)
 5: if [ `isinputmode` ]
 6: then
 7: #
 8: # This block processes input data from FORM or SPA and determine next transaction which create screen.
 9: #
10: #-- USER CODING START(2)
11:     search=`getvalue search`
12:     if [ "X${search}" = "X" ]
13:     then
14:         setspa search "${search}"
15:         setspa message "検索文字列が指定されていません"
16:         setspa msgcolor "red"
17:         settran "SAMPLE1"
18:     else
19:         user=`getuser`
20:         if [ `ispermittedwith "${user}" SAMPLE2` ]
21:         then
22:             setspa search "${search}"
23:             setspa message ""
24:             setspa msgcolor "black"
25:             settran "SAMPLE2"
26:         else
27:             setspa search "${search}"
28:             setspa message "${user}は結果の表示を許可されていません"
29:             setspa msgcolor "red"
30:             settran "SAMPLE1"
31:         fi
32:     fi
33: #-- USER CODING END(2)
34: else
35: #
36: # This block edit screen from SPA and output it.
37: # Next transaction must be a transaction for this program.
38: #
39: #-- USER CODING START(3)
40:     thistran=`gettran`
41:     search=`getspa search`
42:     message=`getspa message`
43:     msgcolor=`getspa msgcolor`
44:     outhtml ${thistran}.html \
45:         "search=${search}" \
46:         "message=${message}" \
47:         "msgcolor=${msgcolor}"
48:     settran "${thistran}"
49: #-- USER CODING END(3)
50: fi
51: exit 0
```
* 原則、**#-- USER CODING START(x)〜#-- USER CODING END(x)** の間にコーディングを行います。
* **USER CODING START(1)** のブロック内は任意のコーディングを行います。
* **USER CODING START(2)** のブロック内は **form** から入力されたデータを処理し、
次に展開するトランザクションを決定( **settran** )し、そのトランザクションに引き継ぐデータをSPA(Scratch Pad Area)に格納( **setspa** )します。
* **USER CODING START(3)** のブロック内は **SPA** 等からのデータを利用して画面を編集し出力( **outhtml** )します。

### sample2.cgi(検索結果画面処理CGI)
```
 1: #! /bin/sh
 2: . ./shellcgi.sh
 3: #-- USER CODING START(1)
 4: #-- USER CODING END(1)
 5: if [ `isinputmode` ]
 6: then
 7: #
 8: # This block processes input data from FORM or SPA and determine next transaction which create screen.
 9: #
10: #-- USER CODING START(2)
11:     settran "SAMPLE1"
12: #-- USER CODING END(2)
13: else
14: #
15: # This block edit screen from SPA and output it.
16: # Next transaction must be a transaction for this program.
17: #
18: #-- USER CODING START(3)
19:     thistran=`gettran`
20:     search=`getspa search`
21:     inputfile=`getrealres "ETC_SHELLS"`
22:     result=`cat ${inputfile} | egrep "${search}"`
23:     setspa search "${search}"
24:     outhtml ${thistran}.html \
25:         "search=${search}" \
26:         "result=${result}"
27:         "message=" \
28:     settran "${thistran}"
29: #-- USER CODING END(3)
30: fi
31: exit 0
```

### 起動の仕方
会話処理の一番最初はGETメソッドを使い、パラメータ「inittran」に
初期トランザクションを指定して、「shellcgi.cgi」を呼び出します。
```
 1: <html>
 2: <head>
 3:     <META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=UTF-8">
 4:     <title>shellcgi sample page</title>
 5: </head>
 6: <body>
 7:     <h1>shellcgi sample page</h1>
 8:     <ul>
 9:         <li><a href="./cgi-bin/shellcgi.cgi?inittran=SAMPLE1">shellcgi sample</a>
10:     </ul>
11: </body>
12: </html>
```

## デモ
[shellcgi sample page](http://myh.no-ip.org/~m-ito/shellcgi/)
