---
layout: post
title: Gitbook 과 Pandoc 을 이용한 전자 출판
date: 2016-02-23 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
image: /images/2016-02-23-img-02.png
---

Gitbook 은 이미 알고 있었지만, Pandoc 은 오늘 알게 되었다. 요거 요거 물건이다. Gitbook 과 Pandoc 을 이용해서 전자책을 만드는 방법을 정리해 놓는다.

-   [Gitbook](https://github.com/GitbookIO/gitbook)

    GitBook is a command line tool (and Node.js library) for building beautiful books using GitHub/Git and Markdown
    
-   [Pandoc](http://pandoc.org/)

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

<div class="spacer">• • •</div>

필요한 도구가 모두 준비되었으니, 이제 새로운 전자출판 프로젝트를 만들고 책을 집필하자.

## Create Project

책 본문은 `_draft` 디렉터리에 담는다.

```bash
# -p 옵션을 주면 만드려는 디렉터리의 부모 디렉터리가 없을 때 만든다.
$ mkdir -p my-book/_draft && cd my-book
```

## Write Contents

Markdown 문법으로 책 본문을 쓰자. 실험 집필에서는 `_draft/chapter1.md`, `_draft/chapter2.md` 2개의 Markdown 파일을 만들었다. 책에 쓰이는 이미지 파일들은 `_draft/images` 에 넣었다.

```markdown
<!--_draft/chapter1.md-->

# An exhibit of Markdown

This note demonstrates some of what [Markdown][1] is capable of doing.

*Note: Feel free to play with this page. Unlike regular notes, this doesn't automatically save itself.*

![](images/markdown_editor.png)

[1]: http://daringfireball.net/projects/markdown/
```

```markdown
<!--_draft/chapter2.md-->

# An exhibit of Markdown

## Unordered list

- An item
- Another item[^1]
- Yet another item
- And there's more...

[^1]: Another Item_ http://blog.appkr.kr 
```

`README.md` 와 `SUMMARY.md` 2개의 파일은 Gitbook Mandatory 이므로 꼭 만들어 주어야 한다. (프로젝트 루트에 만든다.)

```markdown
<!--README.md-->

# My Book

by appkr
```

```markdown
<!--SUMMARY.md-->

# Table of Contents

- [Chapter 1](_draft/chapter1.md)
- [Chapter 2](_draft/chapter2.md)
```

## Gitbook Serve

속도가 빠르지는 않지만, Gitbook 을 이용하면 집필 중에 Markdown 컴파일 결과를 미리 확인할 수 있다.

```bash
$ gitbook serve
```

[![Gitbook 이 생성한 정적 웹 페이지](/images/2016-02-23-img-02.png)](/images/2016-02-23-img-02.png)

<div class="spacer">• • •</div>

이제 시험 집필이 끝났으니, 전자책으로 빌드(출판)한다. 빌드 결과는 `_build` 디렉터리에 저장하는 것으로 하자.

```bash
$ mkdir _build
```

## Gitbook Build

Gitbook 으로 `my-book.pdf`, `my-book.epub`, `my-book.mobi` 전자책을 빌드한다. Gitbook 은 `README.md` 및 `SUMMARY.md` 파일을 기준으로 동작한다. 따라서 이 파일들이 위치한 디렉터리에서 아래 명령들을 실행해야 한다.

```bash
# gitbook {format} {source_path} {output_path}

$ gitbook pdf ./ _build/my-book.pdf
$ gitbook epub ./ _build/my-book.epub
$ gitbook mobi ./ _build/my-book.mobi
```

`$ gitbook build` 명령을 이용하면 정적 웹페이지를 빌드할 수 있다. 빌드된 웹페이지는 `_book` 디렉터리에 저장되는데, 웹 서버에 올리면 바로 온라인 책이 된다. 프로젝트 루트에 `.bookignore` 파일을 만들고, 정적 웹페이지 빌드에 제외할 파일과 디렉터리를 지정할 수 있다.

## Pandoc Build

Pandoc 으로도 Gitbook 으로 빌드한 형식의 파일들을 빌드할 수 있다. 그런데, 내가 Pandoc 을 이용하는 이유는 MS워드 형식(`.docx`) 때문이다. **Gitbook 과 달리 Pandoc 은 빌드할 Markdown 파일이 위치한 경로를 기준으로 동작한다.** 프로젝트 루트에서 Pandoc 빌드를 실행하면, 마크다운 안에 위치한 상대경로(e.g. 그림 파일)들이 모두 망가지기 때문에 주의해야 한다. 

```bash
# Change working directory
$ cd _draft

# pandoc {options} {source_files}
$ pandoc --smart --output=../_build/my-book.docx \
          ../README.md \
          ../SUMMARY.md \
          chapter1.md \
          chapter2.md
```

오오~ 멋지다.

[![Pages 에서 오픈한 my-book.docx](/images/2016-02-23-img-01.png)](/images/2016-02-23-img-01.png)

<div class="spacer">• • •</div>

현재까지 작업한 프로젝트의 디렉터리 구조이다.

```bash
.
├── .bookignore
├── .gitignore
├── README.md
├── SUMMARY.md
├── _book
├── _build
│   ├── my-book.docx
│   ├── my-book.epub
│   ├── my-book.mobi
│   └── my-book.pdf
└── _draft
    ├── chapter1.md
    ├── chapter2.md
    └── images
```

## Conclusion

Gitbook 은 웹 서버에 바로 올릴 수 있는 정적 HTML 페이지를 생성해 준다. 책 전체 색인, 좌우 스크롤/화살표 네비게이션 뿐 아니라, 검색, 배경색 변경, 글꼴 크기, SNS 공유 등의 부가 기능도 제공하는 꽤 쓸만한 웹 페이지 이다. 그리고, Gitbook 으로 빌드한 전자책의 짜임새가 Pandoc 보다 조금 더 낫다.

Pandoc 은 Markdown 으로 집필한 책을 MS워드 형식으로 변환해 준다. (Pandoc 은 훨씬 더 많은 일을 할 수 있지만, 나는 이 목적으로만 쓴다.) 출판 업계가 교정 및 편집을 위해 MS워드를 표준으로 사용하고 있다는 점 때문에, Pandoc 의 가치는 더 빛난다. 

어쨌든 3시간 남짓의 실험으로 Markdown 형식으로 쓴 책을 `.epub`, `.mobi`, `.pdf`, `.docx` 뿐 아니라, 웹으로도 출판할 수 있는 도구를 얻었다. 예제 프로젝트는 이 [Github Repo](https://github.com/appkr/book-writing-kit) 에서 받을 수 있다.
