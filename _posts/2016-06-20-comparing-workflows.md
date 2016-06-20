---
layout: post-minimal
title: 'Git을 이용한 협업 워크플로우 배우기'
date: 2016-06-20 00:00:00 +0900
categories:
- learn-n-think
tags:
- 개발자
- git
- workflow
---

이 문서는 Atlassian社에서 쓴 'Getting Git Right' 튜토리얼 중 ['Comparing Worflows'](https://www.atlassian.com/git/tutorials/comparing-workflows)라는 글을 한글로 번역한 것이다. 총 네 개의 워크플로우를 설명한다.

1.  Centralized Workflow
2.  Feature Branch Workflow
3.  Gitflow Workflow
4.  Forking Workflow

---

![](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/hero.svg)

이 글에서는 여러 엔터프라이즈 개발팀을 조사하여 정리한 대표적인 Git 협업 워크플로우를 소개한다.

이 글에서 제시하는 워크플로우들은 엄격한 규칙이라기 보다 일종의 가이드로 이해해 주면 좋겠다. 이 글을 참고한 후, 여러 분들의 입맛에 맞는 방식을 선택하시기 바란다.

<!--more-->
<div class="spacer">• • •</div>

## 1. Centralized Workflow

![Git Workflows: SVN-style Workflow](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/01.svg)

Git과 같은 분산 버전 관리 시스템으로의 전환은 굉장히 어려워 보이지만, 지금 소개하는 Centralized Workflow는 사실 기존의 Subversion(SVN)으로 협업할 때와 크게 다를 바 없다.

다만 SVN과 비교했을 때, Git은 몇 가지 장점이 있다. 첫째, 팀의 모든 구성원이 로컬 저장소를 이용해서 개발한다는 점이다. 로컬 저장소는 중앙 저장소로 부터 완벽히 격리된 상태이므로, 다른 팀 구성원 및 중앙 저장소의 변경 내용을 신경 쓰지 않고 자신의 작업에만 집중할 수 있도록 한다.

둘째, Git의 브랜치와 병합 기능의 이점을 활용할 수 있다. Git 브랜치를 이용하면 안전하게 코드를 변경하고 다른 브랜치에 통합할 수 있다.

### 1.1. 작동 원리

Centralized Workflow는 프로젝트의 변경 내용을 추적하는 단일 중앙 저장소에 의존한다. Subversion의 `trunk` 대신, `master`란 브랜치를 사용하고, 모든 변경 내용은 이 브랜치에 커밋(commit)한다. 이 워크플로우에서는 다른 브랜치는 필요 없고, `master` 브랜치 하나만 사용한다.

팀 구성원은 중앙 저장소를 복제하여 로컬 저장소를 만든 후, 로컬 저장소의 파일을 수정하고 변경 내용을 커밋한다(SVN과 달리 변경 내용은 로컬 저장소에 기록된다). 로컬 저장소는 언제든 중앙 저장소와 동기화할 수 있고, 동기화 시점은 자유롭게 정할 수 있다.

로컬 `master` 브랜치의 변경 내용을 프로젝트의 중앙 저장소에 올리고자할 때는 "push" 명령을 이용한다. `svn commit`과 비슷하지만, 로컬 저장소의 커밋 이력이 중앙 저장소에 그대로 기록된다는 점은 다르다.

![Central and local repositories](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/02.svg)

#### 1.1.1. 충돌 처리

항상 중앙 저장소의 커밋이 기준이 된다. 만약에 로컬 저장소의 변경 내용을 중앙 저장소에 푸시(push)하려고 할 때, 푸시하려는 커밋 이력과 중앙 저장소의 커밋 이력이 서로 충돌한다면 Git은 중앙 저장소의 커밋을 보호하기 위해 푸시를 받지 않고 거부한다.

![Managing Conflicts](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/03.svg)

이 때는 중앙 저장소의 변경 내용을 먼저 로컬 저장소로 가져와서(fetch), 자신의 변경 내용을 조정(rebase)해야 한다. 바꾸어 말하면, 다른 팀 구성원이 이미 변경한 내용에 자신의 변경 내용을 덧 붙이는 식이다.

리베이스하는 중에 중앙 저장소의 변경 내용과 자신의 변경 내용이 충돌한다면, 리베이스 절차는 잠시 멈춤상태가 되고, 수작업으로 충돌을 해결하라고 한다. 충돌을 잡고 난 후, 커밋할 때처럼 `git status`나 `git add` 명령으로 충돌 해결 과정을 마친다. 만약 리베이스 중에 문제가 발생하면 언제든 리베이스를 취소하고 처음부터 다시 할 수 있다.

### 1.2. 적용 사례

철이와 미애, 두 명의 개발자로 구성된 작은 팀이 Centralized Workflow를 이용하여 협업하는 지 살펴보자.

#### 1.2.1. 중앙 저장소 생성

![Git Workflows: Initialize Central Bare Repository](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/04.svg)

누군가 중앙 저장소를 생성해야 한다. Git 또는 SVN으로 관리하는 기존 프로젝트라면 가져 오고, 새로운 프로젝트라면 빈 저장소를 만들면 된다.

중앙 저장소는 다음 명령 처럼 항상 bare 상태(작업 디렉터리가 없다)로 만들어야 한다.

```sh
$ ssh user@host git init --bare /path/to/repo.git
```

`user`는 SSH 사용자 이름이고, `host`는 중앙 저장소 역할을 할 서버의 도메인 이름 또는 IP 주소, `/path/to/repo.git`은 Git 저장소의 위치다. bare 저장소에는 `.git` 확장자를 붙이는 것이 관례다.

#### 1.2.2. 중앙 저장소 복제

![Git Workflows: Clone Central Repo](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/05.svg)

모든 팀 구성원이 `git clone` 명령으로 중앙 저장소를 복제해서 로컬 저장소를 만든다.

```sh
$ git clone ssh://user@host/path/to/repo.git
```

저장소를 클론하면 Git은 로컬 저장소가 연결된 중앙 저장소(원격 저장소)를 기억하기 위해 `origin`이라는 별칭을 만든다. 앞으로 이 별칭을 이용해서 중앙 저장소와 여러 가지 상호작용을 하게 된다.

#### 1.2.3. 철이의 작업

![Git Workflows: Edit Stage Commit Feature Process](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/06.svg)

철이는 로컬 저장소를 이용해서 자신의 맡은 기능을 개발하고, 일반적인 Git 명령을 이용해서 변경 내용을 기록한다. 스테이지(stage)라는 개념을 접하게 되는데, 작업 디렉터리 전체가 아니라 딱 변경분만 커밋하기 위해, 변경분을 임시로 담아 두는 개념적인 공간이라 이해하자.

```sh
$ git status            # 로컬 저장소의 상태 확인
$ git add <some-file>   # 스테이징 영역에 some-file 추가
$ git commit            # some-file의 변경 내역을 커밋
```

중앙 저장소가 아니라 로컬 저장소에 커밋하는 것이므로, 중앙 저장소의 변경 내용을 신경쓰지 않고, 얼마든지 변경하고, 스테이징하고, 커밋하는 과정을 반복할 수 있다. 큰 기능을 개발할 때도 커밋을 이용하면 변경 내용을 아주 작은 단위로 쪼개서 기록할 수 있다.

#### 1.2.4. 미애의 작업

![Git Workflows: Edit Stage Commit Feature](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/07.svg)

미애도 철이처럼 로컬 저장소를 만들고, 자신이 맡은 기능을 개발하고, 스테이징하고 커밋한다.

#### 1.2.5. 철이의 작업 내용 발행

![Git Workflows: Publish Feature](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/08.svg)

철이는 `git push` 명령으로 자신의 로컬 커밋 이력을 중앙 저장소에 올려 다른 팀 구성원과 공유하려한다.

```sh
$ git push origin master
```

`origin`은 철이가 중앙 저장소를 복제할 때 만든 별칭이고, 로컬 저장소와 중앙 저장소를 연결한다고 말한 바 있다. `master` 인자(argument)는 로컬 `master` 브랜치를 `origin`의 `master` 브랜치에 동기화하겠다는 뜻이다. 철이와 미애가 중앙 저장소를 복제한 후 아무로 중앙 저장소를 변경하지 않았기 때문에, 철이의 푸시는 충돌없이 순조롭게 진행된다.

#### 1.2.6. 미애의 작업 내용 발행

![Git Workflows: Push Command Error](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/09.svg)

철이가 발행한 후 미애가 로컬 커밋을 푸시하려 하면 어떤 일이 벌어질지 살펴보자.

```sh
$ git push origin master
```

미애의 커밋 이력은 중앙 저장소 커밋 이력을 포함하고 있지 않아(diverge), 미애의 푸시를 받아 주지 않는다. 이는 중앙 저장소의 커밋 이력을 보호하기 위한 장치다.

```sh
# error: failed to push some refs to '/path/to/repo.git'
# hint: Updates were rejected because the tip of your current branch is behind
# hint: its remote counterpart. Merge the remote changes (e.g. 'git pull')
# hint: before pushing again.
# hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

미애는 철이의 커밋 이력을 로컬로 받아온 후, 자신의 로컬 커밋 이력과 통합한 후, 다시 푸시해야 한다.

#### 1.2.7. 미애의 리베이스

![Git Workflows: Git Pull Rebase](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/10.svg)

미애는 `git pull` 명령으로 중앙 저장소의 변경 이력을 로컬 저장소로 내려 받는다. 이 명령은 내려 받는 동작과 로컬 이력과 합치는 동작을 한 번에 한다.

```sh
$ git pull --rebase origin master
```

`--rebase` 옵션을 주면 중앙 저장소의 커밋 이력을 미애의 커밋 이력 앞에 끼워 넣는다.

![Rebasing to Master](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/11.svg)

`--rebase` 옵션 없이 쓸 수도 있다. 다만, 불필요한 병합 커밋을 한 번 더해야 하는 번거로움이 있다. `--rebase` 옵션을 쓰는 것이 모범 사례다.

#### 1.2.8. 미애의 충돌 해결

![Git Workflows: Rebasing on Commits](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/12.svg)

리베이스는 미애의 로컬 커밋을 새로 내려 받은 `master` 브랜치에 하나 하나 대입, 대조해 가면서 작동한다. 이런 동작 특성때문에, 버그가 있는 부분을 쉽게 발견할 수도 있고, 커밋 이력도 깔끔하게 유지할 수 있다.

철이와 미애가 서로 다른 기능을 개발했다면, 리베이스 과정에 충돌이 발생할 가능성은 적다. 같은 기능을 개발했든 아니든, 리베이스 과정에 충돌이 발생하면 현재 커밋에서 리베이스를 멈추고, 다음과 같은 메시지를 뿜어 낸다.

```sh
# CONFLICT (content): Merge conflict in <some-file>
```

![Conflict Resolution](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/13.svg)

이 사례에서, 미애는 `git status` 명령으로 쉽게 충돌이 발생한 파일을 찾을 수 있다(*Unmerged paths:* 섹션에서).

```sh
$ git status
# Unmerged paths:
# (use "git reset HEAD <some-file>..." to unstage)
# (use "git add/rm <some-file>..." as appropriate to mark resolution)
#
# both modified: <some-file>
```

이제 `some-file`을 열어 충돌을 해결하고, 스테이징 영역에 변경된 파일을 추가한 후, 리베이스를 계속 하면 된다.

```sh
$ git add <some-file>
$ git rebase --continue
```

리베이스는 다음 커밋으로 넘어가고, 더 이상 충돌이 없다면 리베이스는 끝난다.

리베이스 중에 뭔가 잘못되었다면, 다음 명령으로 `git pull --rebase`하기 이전 상태로 되돌릴 수 있다.

```sh
$ git rebase --abort
```

#### 1.2.9. 미애의 작업 내용 재발행

![Git Workflows: Synchronize Central Repo](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/centralized-workflow/14.svg)

이제 중앙 저장소에 올리면 된다.

```sh
$ git push origin master
```

### 1.3. 다음 단계

지금까지 봤듯이 몇 개의 Git 명령어만으로도 Subversion의 전통적 작업 흐름을 그대로 재현할 수 있다. Centralized Workflow는 Git의 특장점인 분산 버전 관리의 이점은 누리지 못하더라도, 최소한 SVN 개발 환경을 Git으로 전환할 수 있는 시작점이다.

Centralized Workflow를 이용하면서 협업을 좀 더 유연하게 하려면 바로 다음에 소개할 Feature Branch Workflow를 검토해 보기 바란다. 각 기능을 개별 브랜치로 분리함으로써, `master` 브랜치에 새로 개발한 기능을 병합하기 전에 충분한 토론을 할 수 있는 장점이 있다.

 ## 2. Feature Branch Workflow

![Feature Branch Workflow](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/01.svg)

현재 Centralized Workflow에 머물러 있다면, 팀 구성원간에 소통을 활성화하여 협업 성과를 이끌어 내기 위해 Feature Branch Workflow를 도입해보라.

Feature Branch Workflow의 핵심 컨셉은 `master` 브랜치가 아니라 기능별 브랜치를 만들어서 작업하는 것이다. 기능 브랜치는 격리된 작업 환경을 제공하기 때문에 다수의 팀 구성원이 메인 코드 베이스(`master`)를 중심으로 해서 안전하게 새로운 기능을 개발할 수 있다. 따라서 `master` 브랜치는 버그 프리 상태로 유지할 수 있어, 지속적 통합(Continuout Integration)을 적용하기도 수월하다. 또, 풀 리퀘스트를 적용하기도 쉽다.

## 2.1. 작동 원리

이 워크플로우도 중앙 저장소를 이용하고, 프로젝트의 공식적인 변경 이력을 기록하기 위해서 `master` 브랜치를 사용한다. 그런데, `master` 브랜치에 직접 커밋하지는 않고, 새로운 기능을 개발할 때마다 브랜치를 만들어서 작업한다. 보통 `animated-menu-items` 또는 `issue-#1061`처럼 의미를 담고 있는 브랜치 이름을 사용한다.

사실 Git은 `master` 브랜치와 다른 브랜치를 기술적으로 구분하지는 않는다. 따라서 Centrailized Workflow에서 본 것처럼, 새 브랜치에서 코드를 수정하고 커밋하면 된다.

게다가 새로 만든 기능 개발용 브랜치로 중앙 저장소로 올려야 한다. 그래야 팀 구성원들과 개발 내용에 대한 의견(코드 리뷰 등)을 나눌 수 있다. `master` 브랜치를 손대지 않기 때문에 다른 브랜치를 얼마든지 올려도 되는데, 이는 일종의 로컬 저장소 백업 역할을 하기도 한다.

### 2.1.1. 풀 리퀘스트

브랜치를 이용하면 격리된 영역에서 안전하게 개발할 수 있을 뿐만아니라, 풀 리퀘스트르를 이용해서 브랜치에 대한 토론을 이끌어 낼 수도 있다. 기능 개발을 끝내고 `master`에 바로 병합하는 것이 아니라, 브랜치를 중앙 저장소에 올리고 `master`에 병합해달라고 요청하는 것이 풀 리퀘스트다.

풀 리퀘스트는 특정 브랜치에 대한 코드 리뷰의 시작점이라 볼 수 있다. 따라서 기능 개발 초기 단계에 미리 풀 리퀘스트를 보낸다고 문제될 것은 없다. 예를 들어, 기능 개발 중에 막히는 부분은 미리 풀 리퀘스트를 던져서 다른 팀 구성원들의 도움을 받을 수도 있을 것이다. 좋은 점은 풀 리퀘스트의 각 커밋에 의견을 제시할 수 있고, 토론 참여자들에게 알림을 보낼 수도 있다는 점이다.

풀 리퀘스트를 수용하면, 그 이후의 작업 절차는 Centralized Workflow와 거의 같다. 먼저 로컬 `master`가 최신 상태인지 확인한다. 그 다음 기능 브랜치를 `master`에 병합하고, 중앙 저장소의 `master` 브랜치로 푸시하면 된다.

풀 리퀘스트는 [Bitbucket Cloud](http://bitbucket.org)이나 [Bitbucket Server](http://www.atlassian.com/stash)을 이용하면 편리하다.

역주) Atlassian이 작성한 글이라 빗버킷을 제안하는데, 깃허브도 똑같은 기능을 제공한다.

### 2.2. 적용 사례

이 사례에서는 풀 리퀘스트를 코드 리뷰를 위해 이용하지만, 풀 리퀘스트의 쓰임새는 다양하다는 점을 잊지 말자.

#### 2.2.1. 미애의 작업

![New Feature Branch](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/02.svg)

새로운 기능을 개발하기에 앞서 격리된 작업 브랜치를 만들어야 한다.

```sh
$ git checkout -b miae-feature master
```

`miae-feature`브랜치로 체크아웃하는 명령이다. `-b` 옵션을 주면 체크아웃하려는 브랜치가 없으면 `master` 브랜치를 기준으로 해서 만든다. 이 브랜치에서 미애는 평상시 하던대로 기능을 개발하고 커밋하면 된다.

```sh
$ git status
$ git add <some-file>
$ git commit
```

#### 2.2.2. 미애의 점심 시간

![Git Workflows: Feature Commits](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/03.svg)

미애는 오전 동안 새로 만든 브랜치에 꽤 여러 번의 커밋을 남겼다. 점심을 먹으러 나가기 전에 그간의 작업 내용을 중앙 저장소에 푸시해 놓기로 했다. 이는 로컬 저장소의 백업 역할을 할 뿐만 아니라, 다른 팀 구성원들이 미애의 작업 내용과 진도를 확인할 수 있어서 좋은 습관이다.

```sh
$ git push -u origin miae-feature
```

`miae-feature` 브랜치를 중앙 저장소(origin)에 푸시하는 명령이다. `-u | --set-upstream` 옵션이 중요하다. 이는 로컬 브랜치와 중앙 저장소의 브랜치를 연결하는 역할을 한다. 한번 연결한 후에는 `git push` 명령만으로 푸시할 수 있다.

#### 2.2.3. 미애의 기능 개발 완료

![Git Workflows: Pull Request](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/04.svg)

점심 먹고 돌아 와서 오후에 맡은 기능 개발을 완료했다. `master` 브랜치에 병합하기 전에 풀 리퀘스트를 던져서 팀 구성원들에게 작업 완료 사실을 알려야 한다. 물론 그 전에 중앙 저장소에 작업 내용을 올려야 한다.

```sh
$ git push
```

`miae-feature` 브랜치를 `master` 브랜치에 병합해 달라고 요청하는 풀 리퀘스트를 던지면, 팀 구성원들은 알림을 받게된다(GUI 도구 이용). 풀 리퀘스트는 팀 구성원 누구나 커밋에 변경 내용에 대해 질문을 남기거나 의견을 달 수 있어서 좋다.

#### 2.2.4. 혁 팀장의 풀 리퀘스트 검토

![Git Workflows: Feature Pull Requests](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/05.svg)

혁 팀장이 `miae-feature` 브랜치를 검토하다가, 공식 저장소에 병합하기 전에 몇 가지 수정이 필요하다고 판단하고, 미애에게 수정 의견을 제시했다.

#### 2.2.5. 미애의 수정 요청 반영

![Git Workflows: Central Repository Push](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/06.svg)

혁 팀장의 수정 요청 사항을 반영하기 위해서, 미애는 기능 개발할 때와 똑같은 작업 절차를 거친다. 수정 요청을 검토하고 코드에 반영해서 커밋하고 중앙 저장소에 푸시하는 일련의 과정 말이다. 미애가 수정한 내용은 기존 풀 리퀘스트에 전부 표시되고, 혁 팀장도 수정 내용에 대해 언제든 의견을 남길 수 있다.

#### 2.2.6. 미애가 개발한 기능 병합 완료

![Merging a Feature Branch](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/feature-branch-workflow/07.svg)

혁 팀장이 마침내 미애의 풀 리퀘스트를 수용하기로 결정했다. 누군가 병합 작업을 해야 한다(병합은 혁 팀장이든 미애든 누구나 할 수 있다).

```sh
$ git checkout master
$ git pull
$ git pull origin miae-feature
$ git push
```

먼저 `master` 브랜치로 체크아웃하고 최신 상태인지를 확인해야 한다. 그 다음 `miae-feature` 브랜치를 로컬로 가져오고, 로컬에 이미 해당 브랜치가 있다면 최신 상태로 병합한다. 그냥 `git merge miae-feature` 명령을 이용할 수 있지만, 항상 중앙 저장소의 최신 변경 내용을 로컬에 반영하기 위해서 `git pull origin miae-feature` 명령을 이용하는 것이 좋다. 마지막으로 병합된 `master` 브랜치를 중앙 저장소로 다시 올린다.

이 과정을 거치면 병합 커밋이 생기는데, 개인마다 호불호가 갈리는 부분이다. 어떤 개발자는 코드 베이스에 기능 추가된 이력을 시각적으로 인지할 수 있어서 좋아한다. 반면 기능 추가 이력을 숨기로 한 줄로된 이력을 선호한다면, 병합 전에 리베이스를 할 수도 있다(fast-forward 병합이 적용됨).

이 복잡한 과정을 풀 리퀘스트 처리 과정을 '수락' 버튼 하나로 할 수 있는 GUI 도구도 있다.

#### 2.2.7. 철이의 작업

`miae-feature` 브랜치를 놓고 혁 팀장과 미애가 일할 동안, 철이도 기능 브랜치를 따서 자신이 맡은 기능을 개발하고 있었다. 거듭말하지만, 이 워크플로우는 격리된 브랜치로 안전하게 작업하면서, 또 필요할 때는 팀 구성원들과 중간 작업을 공유하는 것도 아주 쉽다.

### 2.3. 다음 단계

Bitbucket의 기능 브랜치를 요리 조리 시험해 보고 있다면, [Using Git Branches documentation](https://confluence.atlassian.com/display/BITBUCKET/Using+Git+branches?_ga=1.101607041.186402936.1466129646) 글도 읽어 볼 것을 권장한다. 지금까지 `master` 브랜치와 기능 브랜치를 이용해서 Centralized Workflow를 확장하는 방법을 살펴봤다. 뿐만아니라, Feature Branch Workflow는 풀 리퀘스트를 적극 활용함으로써, 팀 구성원간의 특정 커밋에 대한 의견을 나누어 코드 품질을 높이는 부수 효과도 얻을 수 있다.

현장에서 이 워크플로우를 적용할 때의 유연성은 장점이기도 하지만, 단점이 될 수도 있다. 특히 팀이 크고, 프로젝트 규모가 크면 브랜치마다 좀 더 특별한 의미를 부여하는 것이 더 낫다. 다음에 살펴볼 Gitflow Workflow는 기능 개발과, 릴리즈, 유지보수를 위해 좀 더 통제된 워크플로우를 제시한다.

## 3. Gitflow Workflow

![Gitflow Workflow](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/01.svg)

이번 절에 소개하는 Gitflow Workflow는 [nvie.com](http://nvie.com/) 빈센트 드리센(Vincent Driessen)이 제안한 것이다.

Gitflow Workflow는 코드 릴리스를 중심으로 좀 더 엄격한 브랜칭 모델을 제시한다. Feature Branch Workflow보다는 복잡하지만, 대형 프로젝트에 적용할 수 있는 강건한 작업 절차다.

### 3.1. 작동 원리

Gitflow Workflow도 팀 구성원간의 협업을 위한 창구로 중앙 저장소를 사용하고, 다른 워크플로우와 마찬가지로 로컬 브랜치에서 작업하고 중앙 저장소에 작업 브랜치를 푸시한다. 단지 브랜치의 구조만 다를 뿐이다.

### 3.2. 이력을 기록하는 브랜치

`master` 브랜치 뿐만아니라, 이 워크플로우에서는 두 개의 다른 브랜치도 변경 이력을 유지하기 위해 사용한다. `master` 브랜치는 릴리스 이력을 관리하기 위해 사용하고, `develop` 브랜치는 기능 개발을 위한 브랜치들을 병합하기 위해 사용한다. 그래서, `master` 브랜치는 릴리스 태그를 매기기에 아주 적합하다.

![Historical Branches](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/02.svg)

이 워크플로우의 나머지 작업 절차들은 이 두 개의 브랜치를 대상으로 한다.

### 3.3. 기능 브랜치

새로운 기능은 각각의 브랜치에서 개발하고, 백업 및 협업을 위해서 중앙 저장소에 푸시한다. 그런데, `master` 브랜치에서 기능 개발을 위한 브랜치를 따는 것이 아니라, `develop` 브랜치에서 딴다. 그리고, 기능 개발이 끝나면 다시 `develop` 브랜치에 작업 내용을 병합한다. 다시 말하면, 기능 개발을 위한 브랜치는 `master` 브랜치와는 어떤 상호 작용도 하지 않는다.

![Feature Branches](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/03.svg)

Feature Branch Workflow에서는 `develop` 브랜치에 개발한 기능을 병합하는 것으로 모든 과정이 끝났다면, Gitflow Workflow는 아직 할 일이 더 남았다.

### 3.4. 릴리스 브랜치

![Release Branches](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/04.svg)

`develop` 브랜치에 릴리스를 할 수 있는 수준의 기능이 모아지면(또는 정해진 릴리스 일정이 되면), `develop` 브랜치를 기준으로 릴리스를 위한 브랜치를 딴다. 이 브랜치를 만드는 순간부터 릴리스 사이클이 시작되고, 버그 수정, 문서 추가, 릴리스와 직접적으로 관련된 작업들을 제외하고는 이 브랜치에 새로운 기능을 추가 병합하지 않는다. 릴리스 준비가 완료되면 `master` 브랜치에 병합하고 버전 태그를 부여한다. 그리고, `develop` 브랜치에도 병합한다(릴리스를 준비하는 동안 `develop` 브랜치는 변경되었을 수 있다).

릴리스를 위한 전용 브랜치를 사용함으로써 릴리스를 한 팀이 준비하는 동안 다른 팀은 다름 릴리스를 위한 기능 개발을 계속할 수 있다. 즉, 딱딱 끊어지는 개발 단계를 정의하기에 아주 좋다. 예를 들어, 이번 주에 버전 4.0 릴리스를 목표로한다라고 팀 구성원들과 쉽게 합의할 수 있다는 말이다.

릴리스 브랜치는 `release-*` 또는 `release/*`처럼 이름 짓는 것이 일반적인 관례다.

### 3.5. 유지 보수를 위한 브랜치

![Maintenance Branches](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/05.svg)

운영환경에 릴리스한 후 발견된 긴급 패치는 'hotfix' 브랜치를 이용한다. 'hotfix' 브랜치만 `master`에서 바로 따낼 수 있다. 패치가 준비되면 `master`와 `develop` 브랜치 양쪽에 병합하고, 새로운 버전 이름으로 태그를 매겨야 한다.

버그 수정만을 위한 개발 브랜치를 따로 만들었기때문에, 다음 릴리스를 위해 개발하던 작업 내용에 전혀 영향을 주지 않는다. 'hotfix' 브랜치는 `master` 브랜치를 부모로 하는 임시 브랜치라고 생각하면 된다.

### 3.6. 적용 사례

다음 사례는 한 번의 릴리스 사이클만을 예로 들고 있다. 이미 중앙 저장소는 만들었다고 가정한다.

#### 3.6.1. develop 브랜치 만들기

![Create a Develop Branch](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/06.svg)

`master` 브랜치를 기준으로 `develop` 브랜치를 만드는 것이 가장 먼저 할 일이다. 팀 구성원 중 한 명이 자신의 로컬 저장소에 빈 `develop` 브랜치를 만들고 중앙 저장소로 푸시하면 된다.

```sh
$ git branch develop
$ git push -u origin develop
```

`master` 브랜치는 축약된 프로젝트 이력만 담고 있는 반면, 이 개발 브랜치는 모든 개발 이력을 다 담을 것이다. 이제 다른 팀 구성원이 중앙 저장소를 복제하고, 중앙 저장소와 연결된 개발 브랜치를 만들어야 한다.

```sh
$ git clone ssh://user@host/path/to/repo.git
$ git checkout -b develop origin/develop
```

이제 팀 구성원 모두가 이 워크플로우를 적용하기 위한 준비가 되었다고 가정하자.

#### 3.6.2. 철이와 미애의 작업

![New Feature Branches](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/07.svg)

이 사례에서는 철이와 미애가 각자 맡은 기능에 해당하는 기능 브랜치를 만들고 서로 다른 기능을 개발한다고 가정한다. `master`를 베이스로 하지 않고, `develop` 브랜치를 기준으로 기능 브랜치를 따야 한다.

```sh
$ git checkout -b some-feature develop
```

항상 하던대로 개발하고 변경 내용을 커밋한다.

```sh
$ git status
$ git add <some-file>
$ git commit
```

#### 3.6.3. 미애의 작업 완료 처리

![Merging a Feature Branch](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/08.svg)

몇 번의 커밋 끝에, 미애는 맡은 기능 개발을 완료했다. 만약에 팀이 풀 리퀘스트를 하기로 약속했다면, 미애는 자신의 기능 브랜치를 `develop` 브랜치에 병합해 달라고 풀 리퀘스트를 보낼 수 있다. 풀 리퀘스트를 이용하지 않기로 했다면 다음과 같이 직접 `develop` 브랜치에 병합하고 중앙 저장소에 푸시하면 된다.

```sh
$ git pull origin develop
$ git checkout develop
$ git merge some-feature
$ git push
$ git branch -d some-feature
```

기능 브랜치를 병합하기 전에 반드시 `develop` 브랜치에 중앙 저장소의 변경 내용을 반영해서 최신 상태로 만들어야 한다. `master`에 직접 병합하지 않도록 주의해야 한다. 병합할 때 충돌이 발생하면 Centralized Workflow에서 본 바와 같이 해결한다.

#### 3.6.4. 미애의 릴리스 준비

![Preparing a Release](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/09.svg)

철이는 여전히 기능 개발에 몰두하고 있는 와중에, 미애는 첫 공식 릴리스를 준비하고 있다. 기능 개발과 마찬가지로 릴리스 과정을 캡슐화할 새로운 브랜치를 만들어야 한다. 이 과정에서 버전 번호를 부여한다.

```sh
$ git checkout -b release-0.1 develop
```

이 브랜치는 테스트를 하거나, 문서를 수정하는 등 릴리스와 관련된 여러 가지 작업들을 처리하기 위한 격리 공간이다. 미애가 이 브랜치를 만든 이후에 완성되고 `develop` 브랜치에 병합된 기능은 릴리스 대상에서 제외된다. 이번에 포함되지 않은 기능들은 다음 릴리스에 포함된다.

#### 3.6.5. 미애의 릴리스 완료

![Merging Release into Master](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/10.svg)

릴리스 준비가 끝나면, 릴리스 브랜치를 `master`와 `develop` 브랜치에 병합하고, 릴리즈 브랜치는 삭제한다. `develop` 브랜치에도 병합하는 이유는 릴리스를 준비하는 과정에 개발 중인 다른 기능에 영향을 줄 수도 있는 변경을 했을 수도 있기 때문이다. 미애의 팀이 코드 리뷰를 엄격하게 지키고 있다면, 병합을 요청하는 풀 리퀘스트를 보낼 수도 있다.

```sh
$ git checkout master
$ git merge release-0.1
$ git push
$ git checkout develop
$ git merge release-0.1
$ git push
$ git branch -d release-0.1
```

릴리스 브랜치는 기능 개발(`develop`)과 프로젝트의 공식 릴리스 사이의 가교 역할을 한다. `master` 브랜치에 병합할 때는 태그를 부여하는 것이 나중을 위해서 여러 모로 편리하다.

```sh
$ git tag -a 0.1 -m "Initial public release" master
$ git push --tags
```

Git은 저장소에 어떤 이벤트가 발생할 때 스크립트를 자동으로 실행할 수 있는 훅(hook) 기능을 포함하고 있다. 중앙 저장소의 `master` 브랜치에 푸시하거나 태그를 푸시할 때, 자동으로 공개 릴리스를 빌드하는 훅을 거는 것도 가능하다.

#### 3.6.6. 버그 신고

![Maintenance Branch](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/gitflow-workflow/11.svg)

릴리스를 배포한 후에, 철이와 함께 다음 릴리스를 준비하기 위해 일상으로 돌아갔다. 그런데 사용자가 현재 릴리스에 버그가 있다고 보고해왔다. 버그를 해결 하기 위해 미애(또는 철이)는 작업하던 기능 개발을 잠시 미뤄두고, `master` 브랜치를 기준으로 유지 보수 브랜치를 만들고, 버그를 수정하고 커밋한다. 버그 수정이 끝나면 `master` 브랜치에 바로 병합한다.

```sh
$ git checkout -b issue-#001 master
# Fix the bug
$ git checkout master
$ git merge issue-#001
$ git push
```

릴리스 브랜치와 마찬가지로, 유지 보수 브랜치에서의 변경 사항은 개발 중인 기능에도 반영되어야 하므로 `develop` 브랜치에도 병합해야 한다. 병합이 끝나면 유지 보수 브랜치는 삭제해도 좋다.

```sh
$ git checkout develop
$ git merge issue-#001
$ git push
$ git branch -d issue-#001
```

### 3.7. 다음 단계

세 가지 워크플로우를 통해 이제 여러분은 로컬 저장소의 개념을 충분히 이해했을 것이다. 푸시와 풀 패턴을 이해하고, Git의 브랜칭과 병합의 이점도 이해했으리라.

어디까지나 여기에 소개한 내용만 가지고 현업에 적용하기에는 무리가 있다. 해서 어떤 부분을 취하고 어떤 부분을 버릴 지는 여러분의 선택이다.

## 4. Forking Workflow

Forking Worflow는 다른 워크플로우와 근본적으로 다르다. 서버 측에 하나의 중앙 저장소를 이용하는 것이 아니라, 개개인마다 서로 다른 리모트 저장소를 운영하는 방식이다. 모든 프로젝트 기여자가 개인적인 로컬 저장소와 공개된 원격 저장소, 즉 두 개씩의 Git 저장소를 가지는 방식이다.

![Git Workflows: Forking](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/01.svg)

모든 코드 기여자가 하나의 중앙 저장소에 푸시하는 것이 아니라, 각자 자신의 원격 저장소에 푸시하고, 프로젝트 관리자만 다른 개발자들의 기여분을 병합하고 공식 저장소에 기여할 수 있다는 점이 가장 큰 특장점이다. 즉, 프로젝트 관리자는 다른 개발자들에게 공식 저장소에 쓸 수 있는 권한을 주지 않고도 다른 개발자의 커밋을 수용할 수 있다.

프로젝트와 직접 관련이 없는 제 삼자뿐만아니라, 아주 큰 규모의 분산된 팀과 안전하게 협업하기에 좋은 방법이다. 특히, 오픈 소스 프로젝트에서 많이 사용하는 방식이다.

### 4.1. 작동 원리

서버에 만든 공식 저장소로 시작한다는 점은 다른 워크플로우와 같다. 그런데, 다른 개발자가 이 프로젝트에 참여할 때는 이 공식 저장소를 직접 복제하는 것이 아니다.

대신 공식 저장소를 포크(fork)해서 자신만의 원격 저장소를 만든다. 이제 이 복제본 저장소는 개인의 공개 저장소 역할을 하고, 다른 개발자는 이 원격 저장소에 푸시할 수 없다(내려 받는 것은 가능하다). 프로젝트 참여자는 서버측 복제본을 만든 다음, `git clone` 명령으로 로컬 저장소를 만든다. 다른 워크플로우처럼 이 로컬 저장소에서 작업을 수행한다.

로컬 저장소의 커밋 이력을 원격 저장소에 푸시할 때는 프로젝트의 공식 저장소가 아니라, 자신의 원격 복제본에 푸시한다. 그 다음 프로젝트 관리자에게 자신의 기여분을 반영해 달라는 풀 리퀘스트를 던진다. 앞서 봤듯이 풀 리퀘스트는 기여한 코드에 대한 의견을 주고 받는 좋은 채널이 된다.

공식 저장소에 기여받은 코드를 병합할 때는, 프로젝트 관리자가 기여자의 변경분을 로컬 저장소로 내려 받고, 기존 코드 베이스에 부작용을 일으키지 않는 지 확인한 후, 로컬 `master` 브랜치에 병합하고, 프로젝트 공식 저장소의 `master` 브랜치에 반영한다. 이제 기여분이 반영된 공식 코드 베이스를 다른 기여자들로 내려 받아 작업을 계속할 수 있다.

### 4.2. 프로젝트 공식 저장소

Git은 기술적으로 공식과 기여자의 복제본을 구분하지 않기 때문에, 이 워크플로우에서 '공식'이란 상징적인 의미일 뿐이다. 프로젝트 관리자의 공개 저장소이기 때문에 공식이란 단어가 붙은 것 뿐이다.

### 4.3. Forking Workflow에서 브랜치

각 기여자의 원격 저장소는 다른 기여자와 변경 내용을 공유하기 위한 편의장치일 뿐이다. 따라서, Feature Branch Worflow나 Gitflow Workflow처럼 새로운 기능 개발을 위해 격리된 브랜치를 만드는 것은 각자의 자유다. 대신 브랜치를 공유하는 방법만 다르다. 다른 워크플로우에서는 공식 저장소에 브랜치를 푸시해서 팀 구성원들이 공유했다면, Forking Workflow에서는 다른 개발자의 브랜치를 로컬 저장소로 내려 받아 참고하고 병합한다.

### 4.4. 적용 사례

#### 4.4.1. 프로젝트 공식 저장소 생성

![Forking Workflow: Shared Repository](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/02.svg)

Git을 이용한 팀 협업의 시작점은 서버에 공식 저장소를 만드는 것으로부터다. 보통 이 저장소가 프로젝트 관리자의 공개 저장소다.

공개 저장소는 다음과 같이 항상 bare 상태로 생성한다.

```sh
$ ssh user@host
$ git init --bare /path/to/repo.git
```

Bitbucket은 위 명령을 편리하게 도와주는 GUI 도구를 제공한다. 다른 워크플로우와 똑같은 명령 똑 같은 절차다. 프로젝트 관리자는 필요하다면 지금까지 작성한 코드를 푸시할 수도 있을 것이다.

역주) Atlassian이 작성한 글이라 빗버킷 GUI 도구를 말하는데, 깃허브도 대칭되는 도구가 있다.

#### 4.4.2. 프로젝트 공식 저장소 포크

![Forking Workflow: Forking the official repository.](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/03.svg)

이제 모든 프로젝트 참여자가 공식 저장소를 포크해야 한다. 포크는 서버 측에서 복제이므로, 서버에 SSH로 로그인한 후 `git clone` 명령을 이용하면 된다. Bitbucket은 클릭 한 번으로 포크할 수 있다.

이 과정이 마치면, 이제 모든 프로젝트 참여자들이 자신들의 서버측 원격 저장소를 하나씩 가지게 된다. 프로젝트 공식 저장소와 마찬가지로 이 저장소들도 bare 저장소다.

#### 4.4.3. 포크한 원격 저장소 복제

![Forking Workflow: Cloning the forked repositories](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/04.svg)

이제 프로젝트 참여자들은 친숙한 `git clone` 명령으로 자신의 원격 저장소를 복제하여 로컬 저장소를 만들 수 있다.

이 사례에서는 원격 저장소로 Bitbucket을 사용한다고 가정한다. 그리고, 프로젝트 참여자는 Bitbucket 계정을 가지고 있다고 간주한다.

```sh
$ git clone https://user@bitbucket.org/user/repo.git
```

다른 워크플로우에서는 중앙 저장소와 연결된 단 하나의 `origin`만 썼다면, Forking Workflow에서는 두 개의 원격 저장소가 필요한다. 하나는 포크한 원격 저장소이고, 다른 하나는 프로젝트 공식 저장소이다. 이름은 아무렇게나 붙여도 되지만, 일반적으로 포크한 원격 저장소는 `origin`(`git clone`할 때 자동으로 만들어진다), 프로젝트 공식 저장소는 `upsteram`으로 붙이는 것이 관례다.

```sh
$ git remote add upstream https://bitbucket.org/maintainer/repo.git
```

`upstream` 별칭은 위 명령을 참고해서 직접 지정해줘야 한다. 이렇게 연결해 줘야만 로컬 저장소에 프로젝트 공식 저장소의 변경 내용을 내려 받아 최신 상태로 유지할 수 있다. 만약, 오픈 소스 프로젝트가 아니라서 사용자 식별을 위한 인증 정보를 제공해야 한다면 다음과 같이 한다.

```sh
$ git remote add upstream https://user@bitbucket.org/maintainer/repo.git
```

이렇게 사용자 이름을 제공하더라도, 프로젝트 원격 저장소의 변경 내용을 내려 받을 때는 비밀번호를 제시해야 한다.

#### 4.4.4. 기능 개발

![Forking Workflow: Developers work on features](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/05.svg)

복제한 로컬 저장소에서 다른 워크플로우처럼 코드를 수정하고, 브랜치를 따고, 변경 내용을 커밋할 수 있다.

```sh
$ git checkout -b some-feature
# Edit some code
$ git commit -a -m "Add first draft of some feature"
```

자신의 원격 저장소에 변경 내용을 올리기 전까지는 변경 내용은 누구에게도 공개되지 않는다. 프로젝트 공식 저장소의 코드 베이스에 새로운 커밋이 있다면 다음과 같이 가져올 수 있다.

```sh
$ git pull upstream master
```

보통 개발자들이 격리된 브랜치에서 기능 개발을 하기때문에, 나중에 [fast-forward 병합](https://www.atlassian.com/git/tutorials/using-branches/git-merge)을 하게 된다.

#### 4.4.5. 개발 내용 제출

![Forking Workflow: Developers publish features](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/06.svg)

새로운 기능 개발을 공개하려면 다음 두 가지 절차를 거쳐야 한다. 첫째, 자신의 원격 저장소에 변경 내역을 올려서 다른 개발자가 볼 수 있도록 한다. `origin`을 이미 등록해두었으므로 다음 명령만 하면 된다.

```sh
$ git push origin feature-branch
```

메인 코드 베이스가 아니라, 개발자 자신의 서버측 원격 저장소에 올린다는 점이 다른 워크플로우와의 차이점이다.

둘째, 프로젝트 관리자에게 자신의 기여분을 공식 코드 베이스에 반영해 줄것을 요청해야 한다. Bitbucket의 '풀 리퀘스트' 버튼을 이용하면, 어떤 브랜치를 제출할 지 정할 수 있다. 보통 이번에 추가한 기능 브랜치를 프로젝트 공식 저장소의 `master` 브랜치에 병합해 달라고 요청할 것이다.

#### 4.4.6. 프로젝트 관리자의 기여분 병합

![Forking Workflow: Integrate Features](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/07.svg)

풀 리퀘스트를 받은 프로젝트 관리자는 기여 받은 변경 내용을 공식 코드 베이스에 반영할지 말지를 결정해야 한다. 보통 다음 두 가지 중 하나의 방법을 사용한다.

    1.  풀 리퀘스트의 코드를 직접 검토한다.
    2.  코드를 로컬 저장소로 가져와 수동으로 병합한다.

변경 내용을 확인하고, 의견을 제시하고, GUI를 이용해서 병합 작업을 할 수 있기 때문에 첫번째 방법이 훨씬 쉽다. 그럼에도 불구하고, 풀 리퀘스트가 메인 코드 베이스와 충돌을 일으킨다면 두번째 방법을 이용해야 한다. 이 사례에서는 프로젝트 관리자가 기여자의 원격 저장소로 부터 기능 브랜치를 로컬 저장소로 가져와서 `master` 브랜치로 병합하면서 충돌을 해결하는 장면을 보여준다.

```sh
$ git fetch https://bitbucket.org/user/repo feature-branch
# Inspect the changes
$ git checkout master
$ git merge FETCH_HEAD
```

변경 내용을 로컬 저장소의 `master` 브랜치에 전부 병합한 후, 다른 개발자들도 접근할 수 있도록 원격 저장소에 푸시한다.

```sh
$ git push origin master
```

프로젝트 관리자의 `origin`은 프로젝트 공식 저장소의 공식 코드 베이스이므로 기여자가 제출한 신규 기능은 이제 메인 코드 베이스에 포함되었다.

#### 4.4.7. 다른 개발자들의 프로젝트 공식 저장소 동기화

![Forking Workflow: Synchronize with the official repository](https://www.atlassian.com/git/images/tutorials/collaborating/comparing-workflows/forking-workflow/08.svg)

메인 코드 베이가 변경되었으므로, 프로젝트 참여하는 모든 개발자가 자신의 로컬 저장소를 최신 상태로 동기화해야 한다.

```sh
$ git pull upstream master
```

## 4.5. 다음 단계

이 글을 통해 어떤 개발자의 기여 활동이 어떻게 프로젝트의 공식 저장소에 반영될 수 있는지를 설명했다. 꼭 공식 저장소가 아니더라도 어떤 저장소에든 이 방법을 적용할 수 있다. 예를 들어, 서브 팀이 특정 기능을 개발할 때, 메인 저장소를 건드리지 않고 팀 구성원들이 작업 내용을 공유할 수도 있을 것이다.

누구든 다른 개발자와 자신의 변경 내용을 쉽게 공유할 수 있고, 어떤 브랜치든 공식 코드 베이스에 병합할 수 있기 때문에, 느슨한 팀 구조에서도 Forking Workflow는 강력한 협업 환경을 제공한다.

---

#### 원문의 라이선스

Except where otherwise noted, all content is licensed under a [Creative Commons Attribution 2.5 Australia License](http://creativecommons.org/licenses/by/2.5/au/).

#### 번역문의 라이선스

[Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/)를 따른다.
