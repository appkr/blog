---
layout: post
title: 'GIT REBASE, 커밋 이력을 유지하면서 과거 커밋의 내용 수정하기' 
date: 2016-04-25 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- git
---

깃(git)을 꽤 오랫동안 썼지만 잘 모르는 기능 중에 하나가 리베이스(rebase)다. 사실 리베이스를 할 줄 알고 모름에 따라, 초급과 중급으로 구분된다고 해도 과언이 아니다. 리베이스를 꽤 오랫동안 썼지만, 주로 하는 것은 커밋 합치기(fixup, or squash)와 커밋 메시지 바꾸기(reword) 정도였다. 

이번에 예전에 커밋한 내용을 수정할 일이 있어서 수정(edit) 기능을 처음 써봤다. 최종 목표는 이렇다.

1.  이전에 커밋한 내용을 수정하고, 그 뒤에 연속되는 커밋에 변경 내용을 모두 반영한다.
2.  리베이스하기 전의 전체 커밋 로그를 리베이스 후에도 그대로 유지한다. 

말로는 쉬워보이지만, 2번이 정말 어려웠다. 

예를 들어, `foo` -> `bar` -> `baz` 커밋 로그가 있다고 하자. 리베이스로 `foo` 커밋의 내용을 수정했는데 `bar`에서 충돌이 발생했다. `bar` 커밋에서 발생한 충돌을 해결하고 나면, `bar` 커밋은 `foo` 커밋으로 합쳐지고, `bar` 커밋 로그는 남지 않는다.

'최종 커밋만 있으면 되지~', '중간 커밋을 살리는 것이 무슨 의미가...?'라는 의문이 생길 수 있다. 맞다. 최종 커밋만 있으면 된다. 그런데, 나는 이번에 나올 책에서 챕터별로 예제 코드를 커밋했고, 커밋 로그 하나가 사라지면 챕터에 해당하는 소스코드의 이력이 사라지기 때문에 이 문제를 꼭 해결해야만 했다. 

이 고생을 한 이유는 책을 쓰는 도중 라라벨 프레임워크의 수버전이(유의적 버전은 주.부.수로 쓴다) 변경되었고, 이번 버전 업에서는 라우트 사용법이 변경되었기 때문이다. 라우트는 웹 서버와 라라벨의 경계에 해당하는 부분이라 아주 아주 아주 중요할뿐더러, 책의 가장 첫 부분이기도 하다. 독자들은 새 버전의 프레임워크로 프로젝트를 시작할테고, 바뀐 사용법을 적용하지 않으면 책의 시작부터 작동하지 않는 소스코드를 만나게 되는 셈이다.  

어쨌든... 이 포스트는 이 문제점을 해결한 이력이다.

<!--more-->
<div class="spacer">• • •</div>

**문제 해결의 핵심은 리베이스를 두 번 하는 것이다.** 

- 첫번째는 수정을 위한 리베이스
- 두번째는 커밋 이름을 바꾸거나 불필요한 커밋을 합치기 위한 리베이스 

이 포스트에 기록한 가상 시나리오는 커밋 4개, 파일 1개라 굉장히 간단하다. 실제로는 커밋 36개, 수정할 파일이 대략 20개 정도였다. 여튼 이 포스트의 내용을 체득하기 위해 리베이스만 수십 번, 충돌 머지는 수백 번했다. 꼬박 이틀을 소비했다. 나처럼 무식하게 하지 않고, 더 쉽게 할 수 있는 방법이 분명히 있을 것이다. 

## 1. 데모용 프로젝트 생성

재연을 위해 새로운 프로젝트를 하나 만들었다.

```sh
$ git init rebase-demo && cd rebase-demo
$ touch foo.txt
```

`foo.txt`의 내용은 다음과 같다.

```sh
First message
Second message
Third message
Fourth message
```

커밋 로그는 다음과 같다(시간 역순 정렬).

```sh
* a36e27a (HEAD -> master) fourth commit
* 48b56d0 third commit
* 1f97602 second commit
* bb44c4b first commit
(END)
```

리베이스의 대상이 되는 프로젝트가 준비되었다. 이제 리베이스를 한다.

## 2. 첫번째 리베이스 - 수정

`bb44c4b first commit`에서 커밋한 내용에 오류가 있어서 수정해야한다고 가정하자. 

### 2.1. git rebase --interactive --root

`--root` 옵션을 붙여야 최초 커밋부터 리베이스할 수 있다.

```sh
(branch:master) $ git rebase --interactive --root
```

새로운 에디터 창이 뜬다. 리베이스에서는 (로그와 달리) 커밋을 시간 순으로 열거한다. 

```sh
e bb44c4b first commit
pick 1f97602 second commit
pick 48b56d0 third commit
pick a36e27a fourth commit

# Rebase a36e27a onto c15a027 (4 command(s))
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
# If you remove a line here THAT COMMIT WILL BE LOST.
# However, if you remove everything, the rebase will be aborted.
# Note that empty commits are commented out
```

첫번째 커밋인 `pick bb44c4b first commit`을 `e bb44c4b first commit`으로 바꾸고 저장하면 리베이스가 시작된다.

### 2.2. 코드 수정

`bb44c4b first commit` 당시의 `foo.txt`의 내용은 이렇다.

```sh
First message
```

코드 수정을 했다. 이 수정으로 인해 다음 커밋에서 무조건 충돌이 발생할 것이다.

```sh
First message (modified)
Interim message (new line)
```

### 2.3. git commit -aC HEAD@{1}

리베이스를 시작하는 순간 커밋의 SHA 해시는 바뀐다. 코드 수정이 끝났으니 커밋을 해야 하는데, 콘솔에 안내된 메시지대로 `$ git commit --amend`를 하면, 충돌 해결 후 커밋 로그가 사라진다. 커밋 로그를 유지하기 위해 `--amend` 옵션을 쓰지 않고 커밋하고, 대신 `-C` 옵션을 사용했다. `-C` 옵션은 기존의 커밋 메시지를 참조한다는 의미이고, `HEAD@{1}`은 현재 리베이스 중인 커밋의 메시지를 말한다. 

```sh
(branch:81c42b4) $ git commit -aC HEAD@{1}
# [detached HEAD 24959b0] first commit
#  Date: Mon Apr 25 16:56:13 2016 +0900
#  1 file changed, 2 insertions(+), 1 deletion(-)
```

### 2.4. git rebase --continue

커밋했으니, 다음 커밋으로 넘어간다. 충돌이 없으면 끝까지 한번에 진행할테고, 충돌이 있으면 멈출 것이다.

```sh
(branch:24959b0) $ git rebase --continue
# error: could not apply 1f97602... second commit
# 
# When you have resolved this problem, run "git rebase --continue".
# If you prefer to skip this patch, run "git rebase --skip" instead.
# To check out the original branch and stop rebasing, run "git rebase --abort".
# Could not apply 1f97602261123673cba6dbcfd75e37eed5ec1f4b... second commit
```

2.2에서 수정한 내용 때문에, 당연히 충돌이 발생한다. `$ git status` 명령으로 어떤 파일에서 충돌이 발생하는 지 확인한다. 여기서는 파일이 하나 밖에 없어서 굳이 확인할 필요도 없지만...

```sh
(branch:24959b0*) $ git status
# interactive rebase in progress; onto c15a027
# Last commands done (2 commands done):
#    e bb44c4b first commit
#    pick 1f97602 second commit
# Next commands to do (2 remaining commands):
#    pick 48b56d0 third commit
#    pick a36e27a fourth commit
#   (use "git rebase --edit-todo" to view and edit)
# You are currently rebasing branch 'master' on 'c15a027'.
#   (fix conflicts and then run "git rebase --continue")
#   (use "git rebase --skip" to skip this patch)
#   (use "git rebase --abort" to check out the original branch)
# 
# Unmerged paths:
#   (use "git reset HEAD <file>..." to unstage)
#   (use "git add <file>..." to mark resolution)
# 
# 	both modified:   foo.txt
# 
# no changes added to commit (use "git add" and/or "git commit -a")
```

### 2.5. 충돌 해결

`foo.txt`의 현재 상태는 이렇다.

```sh
<<<<<<< HEAD
First message (modified)
Interim message (new line)
=======
First message
Second message
>>>>>>> 1f97602... second commit
```

이렇게 수정했다.

```sh
First message (modified)
Interim message (new line)
Second message
```

2.3에서 했던 것 처럼 커밋한다.

```sh
(branch:24959b0*) $ git commit -aC HEAD@{1}
# [detached HEAD d05fc39] first commit
#  Date: Mon Apr 25 16:56:13 2016 +0900
#  1 file changed, 1 insertion(+)
```

다음 커밋으로 리베이스를 진행한다. 더 이상 충돌이 없기 때문에 리베이스가 끝났다.

```sh
(branch:d05fc39) $ git rebase --continue
# Successfully rebased and updated refs/heads/master.
```

### 2.6. 첫번째 리베이스 성공

원래 4개였던 커밋 로그가 5개로 늘었다. 그리고 커밋 메시지도 정확하지 않다.

```sh
* 60e2196 (HEAD -> master) fourth commit
* f29002e third commit
* d05fc39 first commit
* 24959b0 first commit
* 81c42b4 first commit
```

`81c42b4`은 수정하기 전의 최초 커밋이다. `24959b0`은 최초 내용을 수정한 커밋이다., `d05fc39`는 원래 `second commit`인데 충돌을 해결하면서 생긴 커밋이다. 이제 두번째 리베이스를 할 준비가 됐다.
 
## 3. 두번째 리베이스 - 커밋 로그 다듬기
 
각 커밋의 정체를 알면, 이제는 일반적인 리베이스 과정이다.

```sh
$ git rebase --interactive --root
```

### 3.1. 리베이스 작업 설정

에디터 창이 뜬다. `24959b0` 커밋은 `81c42b4`과 합친다(f, fixup). `d05fc39` 커밋은 메시지를 바꾼다(r, reword).

```sh
pick 81c42b4 first commit
f 24959b0 first commit
r d05fc39 first commit
pick f29002e third commit
pick 60e2196 fourth commit
```

### 3.2. 리베이스 작업

에디터를 닫는 순간 커밋 메시지 수정 에디터가 뜬다. fixup 작업은 충돌이 없기 때문에 자동으로 처리됐다.

```sh
first commit

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Mon Apr 25 16:56:13 2016 +0900
#
# interactive rebase in progress; onto 545b8d4
# Last commands done (3 commands done):
#    f 24959b0 first commit
#    r d05fc39 first commit
# Next commands to do (2 remaining commands):
#    pick f29002e third commit
#    pick 60e2196 fourth commit
# You are currently editing a commit while rebasing branch 'master' on '54$
#
# Changes to be committed:
#       modified:   foo.txt
#
```

`first commit` 를 `second commit`으로 바꾸고 저장하면 끝. 

## 4. 리베이스 결과

최종 커밋로그다.

```sh
* 89d6a2f (HEAD -> master) fourth commit
* 4d8cbc2 third commit
* fd4fbb8 second commit
* ace17e1 first commit
(END)
```

`foo.txt` 파일의 내용이다.

```sh
First message (modified)
Interim message (new line)
Second message
Third message
Fourth message
```

## 5. 결론

계속되는 리베이스 실패에 지쳐서 '아~ 그냥 라우트 사용법이 바뀌었으니, 소스코드는 작동하지 않을 수 있다고 말로 떼울까?'란 유혹에 여러 번 넘어갈 뻔 했다. 그 때마다 난 '집요함'이란 단어를 떠 올렸다. 개발자의 가장 큰 특징을 꼽으라면 난 이 단어를 꼽겠다. 단, 앞에 '현명한'이란 수식어를 붙여서 말이다. 
