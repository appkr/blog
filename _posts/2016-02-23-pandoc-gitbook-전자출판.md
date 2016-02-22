---
layout: post
title: Gitbook 과 Pandoc 을 이용한 전자 출판
date: 2016-02-23 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
---

[Gitbook](https://github.com/GitbookIO/gitbook) 은 이미 알고 있었지만, [Pandoc](http://pandoc.org/) 은 오늘 알게 되었다. 요거 요거 물건이다. Gitbook 과 Pandoc 을 이용해서 전자책을 만드는 방법을 정리해 놓는다.

-   Gitbook

    GitBook is a command line tool (and Node.js library) for building beautiful books using GitHub/Git and Markdown
    
-   Pandoc

    If you need to convert files from one markup format into another, pandoc is your swiss-army knife.

<!--more-->

<div class="spacer">• • •</div>

## Install Gitbook

```bash
$ npm install gitbook-cli -g
$ gitbook --version # 1.0.1
```

`.epub`, `.mobi`, `.pdf` 출판을 위한 Calibre 확장 설치

```bash
$ brew install Caskroom/cask/calibre
```

## Install Pandoc

```bash
$ brew install pandoc
$ pandoc --version # pandoc 1.16.0.2
```

## Create Project

```bash
$ mkdir my-book && cd my-book
```

Markdown 으로 책 본문을 쓰자.

```markdown
<!--chapter1.md-->

# An exhibit of Markdown

This note demonstrates some of what [Markdown][1] is capable of doing.

*Note: Feel free to play with this page. Unlike regular notes, this doesn't automatically save itself.*

[1]: http://daringfireball.net/projects/markdown/
```

```markdown
<!--chapter2.md-->

# An exhibit of Markdown

## Unordered list

- An item
- Another item
- Yet another item
- And there's more...
```

`README.md` 와 `SUMMARY.md` 는 Gitbook Mandatory 이므로 꼭 만들어 주어야 한다.

```markdown
<!--README.md-->

# My Book

by appkr
```

## Build Script

`_build` 디렉토리에 빌드 결과물을 저장하였다.

```bash
# build.sh

#!/usr/bin/env bash

[ ! -d _build ] && mkdir _build

# Build pandoc
pandoc -S -o _build/my-book.docx \
  chapter1.md \
  chapter2.md

# Build gitbook
gitbook pdf ./ _build/my-book.pdf
gitbook epub ./ _build/my-book.epub
gitbook mobi ./ _build/my-book.mobi
gitbook build
```

## Build

```bash
$ bash build.sh
```

```
.
├── README.md
├── SUMMARY.md
├── _book
├── _build
│   ├── my-book.docx
│   ├── my-book.epub
│   ├── my-book.mobi
│   └── my-book.pdf
├── build.sh
├── chapter1.md
├── chapter2.md
└── title.txt
```

[![Pages 에서 오픈한 my-book.docx](/images/2016-02-23-img-01.png)](/images/2016-02-23-img-01.png)

## Conclusion

Gitbook 은 웹 서버에 바로 올릴 수 있는 Static HTML 페이지를 생성해 준다. 책 전체 색인, 좌우 스크롤/화살표 네비게이션 뿐 아니라, 검색, 배경색 변경, 글꼴 크기, SNS 공유 등의 부가 기능도 제공하는 꽤 쓸만한 웹 페이지 이다.

Pandoc 은 MS Word 형식으로 변환해 준다. 출판 업계가 교정 및 편집을 위해 MS Word 를 표준으로 사용하고 있다는 점 때문에, Pandoc 의 가치는 더 빛난다. 공식 문서를 방문해 보고 변환이 안되는 문서가 거의 없다는 점에 놀랐다.

어쨌든 3시간 남짓의 실험으로 Markdown 형식으로 쓴 책을 `.epub`, `.mobi`, `.pdf`, `.docx` 뿐 아니라, 웹으로도 출판할 수 있는 도구를 얻었다.

[![Gitbook 이 생성한 Static 웹 페이지](/images/2016-02-23-img-02.png)](/images/2016-02-23-img-02.png)
