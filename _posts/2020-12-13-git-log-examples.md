---
layout: post-minimal
title: 'git log examples'
date: 2020-02-12 00:00:00 +0900
categories:
- learn-and-think
tags:
- Git
- 개발자
---

<script id="asciicast-378873" src="https://asciinema.org/a/378873.js" async></script>

## 뷰
```bash
# -p: 각 커밋별 diff
git log -p
```
```bash
# -2: 최근 2개 커밋
git log -p -2
```
```bash
# --stat: 각 커밋별 통계
git log --stat
```
```bash
# --pretty: oneline, short, full, fuller
git log --pretty=oneline
git log --pretty=short
git log --pretty=full
git log --pretty=fuller
```
```bash
# --graph
git log --graph
```
```bash
# --name-only: 각 커밋별 파일 목록
git log --name-only
```

## 필터링
```bash
# commitId..commitId: 커밋ID로 필터
git log git log b315c55..HEAD
```
```bash
# --since; --after: 기간으로 필터
git log --since=1.weeks
```
```bash
# --until; --before: 기간으로 필터
git log --until=3.days
```
```bash
# --author: 커미터로 필터
git log --author=appkr
```
```bash
# -S: 파일, 함수로 필터
git log -S PersistentEventPublisher
```

## 알림
터미널에서 `git log`했을 때 저랑 다르게 나오는데요. 예, 로그 기본 출력 형식은 전역 `.gitconfig`에 미리 정의해뒀기때문입니다 
```bash
# ~/.gitconfig
[format]
	pretty = oneline
	pretty = format: %C(auto)%h%Creset %C(auto)%ad%Creset %C(auto,green)%aN%Creset %C(auto)%s%Creset
```
