---
layout: post-minimal
title: '도커를 이용한 분산 서비스 아키텍처 맛보기' 
date: 2016-07-11 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- docker
---

같이 운동하는 동호회 형님(IoT 플랫폼 개발사 임원)을 통해서 '도커'라는 단어를 처음 접했던 것으로 기억한다(2015년). 당시엔 VM 프로비저닝을 위해 Vagrant를 사용하고 있었고, 도커는 VM/Vagrant보다 좀 더 가벼운 가상 개발 환경이란 느낌으로 다가왔다. 곧 AWS에서 도커를 지원한다는 소식을 접했고, 도커 자체적으로도 Swarm이란 컨테이너 배포 툴 프로젝트를 공개함으로써, 운영 환경에 바로 쓸 수 있는 도구로 재인식됐다. IoT, 마이크로 프레임워크, 마이크로 서비스 등 시대적 흐름과도 잘 부합하는 도구라 생각한다.

이 포스트는 *'맛보기'*다. 아래 목록은 구글링으로 쉽게 찾을 수 있어 이 포스트에서는 다루지 않는다. 도커를 경험해보지 않은 독자가 무작정 포스트를 따라해 보고 스스로 도커의 유용성을 경험하도록하는 것이 이 포스트의 목적이다. 

도커를 몰라도 된다. 라라벨을 몰라도 된다. 무작정 따라해 보면 된다. 중간에 중간에 각 명령에 대해 간략히만 설명을 추가했다.

- ~~도커란 무엇인가? 왜 써야 하는가?~~
- ~~Dockerfile 작성법~~
- ~~docker-compose.yml 작성법~~

<!--more-->
<div class="spacer">• • •</div>

이하 명령들은 모두 Mac OS 기준이다.
 
## 1. 도커 툴체인 설치

```sh
$ brew tap caskroom/cask
$ brew cask install dockertoolbox --appdir=/Applications
$ docker --version
# Docker version 1.11.1, build 5604cbe
```

## 2. Host VM 만들기

도커 엔진은 리눅스 운영체제에서만 구동할 수 있다. 이 절에서는 도커 호스트[^1]로 사용할 리눅스 VM을 만든다. 버추얼박스가 없다면 설치한다.

```sh
# 버추얼박스 설치
$ brew cask install virtualbox --appdir=/Applications

# 호스트로 사용할 VM 만들기
$ docker-machine create --driver virtualbox default
```

우리가 만든 VM의 이름은 `default`다. 다른 이름을 쓴다면, `docker-machine` 명령을 이용할 때마다 VM 이름을 명시해야 한다(e.g. `docker-machine ip foo`).

새로 만든 VM을 구동하고, IP를 확인한다. 

```sh
$ docker-machine start
$ docker-machine ip
# 192.168.99.100
```

Mac OS의 hosts 파일을 수정해서, 개발 중에 사용할 도메인 `quickstart.app`을 등록한다.

```sh
# /etc/hosts

192.168.99.100  quickstart.app
```

## 3. 프로젝트 복제

맛보기를 위해 필자가 만들어 놓은 라라벨 프로젝트를 `~/quickstart` 디렉터리로 복제한다. 이 프로젝트는 [라라벨의 Quickstart 프로젝트](https://github.com/laravel/quickstart-intermediate)를 포크한 후, 도커 컨테이너 프로젝트를 깃 서브 모듈로 추가하고, 환경 변수를 약간 수정한 것이다. 오리지널 프로젝트 대비 변경 내역은 [커밋 로그](https://github.com/appkr/quickstart-intermediate/commits/master)를 참조하라.

```sh
$ git clone git@github.com:appkr/quickstart-intermediate.git quickstart
```

컴포저로 라라벨 프로젝트의 의존성을 설치한다.

```sh
# 컴포저가 없다면
$ brew tap homebrew/php
$ brew install composer

# 의존성 설치
$ cd quickstart
~/quickstart $ composer install
```

도커 컨테이너 프로젝트도 설치한다. 컨테이너 프로젝트는 [Laradock](https://github.com/LaraDock/laradock)을 포크해서 필자가 수정한 것이다. 스케일 아웃을 위해, HAProxy 로드 밸런서 컨테이너(`lb`)를 추가하고, Nginx+PHP-FPM+Supervisor를 묶은 웹 및 애플리케이션 서버 컨테이너(`web`)을 추가한 것이다. 오리지널 프로젝트 대비 상세 변경 내역은 [`develop` 브랜치의 커밋 로그](https://github.com/appkr/laradock/commits/develop)를 참고하라.

```sh
~/quickstart $ git submodule init && git submodule update 
```

도커 컨테이너 프로젝트의 디렉터리 구조를 간단히 살펴보자. 라라벨 프로젝트(`.`) 안에 도커 컨테이너 프로젝트(`./laradock`)가 포함된 구조다.

```sh
.
├── app
├── # ...
├── laradock
│   ├── application         # 라라벨 프로젝트를 담고 있는 컨테이너
│   ├── beanstalkd          # Beanstalk 큐 워커 컨테이너
│   ├── beanstalkd-console  
│   ├── data                # 데이터베이스의 데이터 파일을 담고 있는 컨테이너
│   │                       # 컨테이너가 사라져도 데이터는 영속성을 유지해야 하므로
│   │                       # 운영 환경 적용시에는 호스트 OS의 파일시스템을 마운트해서 사용해야 한다.
│   ├── docker-compose.yml  # 도커 컨테이너간의 오케이스트레이션 설정 파일
│   │                       # 분산 환경을 편리하게 구성하기 위해 핵심적인 파일이다.
│   ├── lb                  # HAProxy 로드 밸런서 컨테이너
│   ├── logs                # 도커를 실행한 후 생성되고 Mac OS와 공유되는 디렉터리
│   │   ├── nginx
│   │   │   └── error.log       # Nginx 오류 로그
│   │   └── supervisor
│   │       └── supervisord.log # Supervisor 실행 로그
│   ├── mariadb             # MariaDB 데이터베이스 컨테이너
│   ├── memcached           # Memcache 데이터베이스 컨테이너
│   ├── mysql               # MySQL 데이터베이스 컨테이너
│   ├── neo4j               # Neo4J 데이터베이스 컨테이너
│   ├── nginx               # Nginx 웹 서버 컨테이너. 우리 예제에서 사용하지 않음.
│   ├── php-fpm             # PHP-FPM FastCGI 컨테이너. 우리 예제에서 사용하지 않음.
│   ├── postgres            # Postgres 데이터베이스 컨테이너
│   ├── redis               # Redis 데이터베이스 컨테이너
│   ├── web                 # 웹 및 애플리케이션 서버 컨테이너(Nginx+PHP-FPM+Supervisord)
│   └── workspace           # 도커 컨테이너로 구동되는 라라벨 프로젝트에 셸로 접근하기 위한 컨테이너
│                           # Bash, Git, Composer, NPM 등의 도구 사용 가능  
├── # ...
└── tests
```

## 4. 도커 컨테이너 구동

로드 밸런서, 웹 및 애플리케이션 서버, MySQL, 레디스를 구동할 것이다. 구동하기 전에 라라벨 프로젝트의 환경 설정을 변경한다.

```sh
# .env

DB_HOST=192.168.99.100
CACHE_DRIVER=redis
SESSION_DRIVER=redis
REDIS_HOST=192.168.99.100
```

위 설정은 다음을 의미한다. 라라벨 프로젝트는 192.168.99.100에 위치한 MySQL 서버에 데이터를 저장한다. 라라벨의 캐시와 세션은 192.168.99.100에 있는 레디스 서버에 저장한다.

구동해 보자. **처음 한번은 필요한 이미지를 다운로드 받아 프로비저닝하기 때문에 10분 이상이 걸린다.** 다음 번 구동할 때는 5초도 걸리지 않을 것이다.

```sh
~/quickstart $ cd laradock

# VM의 IP를 포함한 환경변수를 현재 셸에 적용한다.
~/quickstart/laradock $ eval $(docker-machine env)

# lb, web, mysql, redis 컨테이너를 구동한다.
~/quickstart/laradock $ docker-compose up -d lb web mysql redis 
```

`docker-compose` 명령은 `docker-compose.yml` 파일이 있는 위치에서 실행해야 한다. 이 파일은 도커를 이용한 분산 서비스 환경 구성을 위해 핵심적인 설정을 담고 있다. 가령, 컨테이너간의 의존성, 마운트할 볼륨 등의 설정 말이다. 

컨테이너 실행은 `up` 서브 명령으로 할 수 있으며, 인자로 구동할 컨테이너 이름을 제시해야 한다. `-d` 옵션을 이용하면 격리 모드(데몬 모드라 생각하면 됨)로 실행할 수 있다.

`ps` 서브 명령으로 구동 상태를 확인할 수 있다(Command 열은 삭제했다). 

```sh
~/quickstart/laradock $ docker-compose ps
#          Name            State           Ports
# -------------------------------------------------------------
# laradock_application_1   Exit 0
# laradock_data_1          Exit 0
# laradock_lb_1            Up       1936/tcp, 
#                                   0.0.0.0:443->443/tcp, 
#                                   0.0.0.0:80->80/tcp
# laradock_mysql_1         Up       0.0.0.0:3306->3306/tcp
# laradock_redis_1         Up       0.0.0.0:6379->6379/tcp
# laradock_web_1           Up       443/tcp, 80/tcp, 9000/tcp
# laradock_workspace_1     Up
```

`application`과 `data`는 단순 볼륨이기 때문에 `Exit 0`으로 출력된다. 포트 열을 보면 `lb` 컨테이너는 80과 443 포트가 열려 있고, 이를 다시 80, 443 내부 포트로 연결하는 것을 볼 수 있다. `web` 역시 80과 443 포트를 열고, `lb`에서 넘겨주는 작업을 받을 준비를 하고 있다. MySQL과 레디스는 외부에서도 접근할 수 있도록 각자의 포트를 열고 있다. 

이제 웹 및 애플리케이션 서버를 스케일 아웃할 것이다. `scale` 서버 명령을 이용하고, 인자로 컨테이너 이름과 복제할 인스턴스 개수를 지정한다. `scale` 명령은 `up` 명령을 실행하기 전에 해도 된다.

```sh
~/quickstart/laradock $ docker-compose scale web=3
# Creating and starting laradock_web_2 ... done
# Creating and starting laradock_web_3 ... done
```

## 5. 실험

`workspace` 컨테이너로 로그인해서 데이터베이스 스키마를  마이그레이션 한다. `artisan` REPL로 데이터베이스와 캐시가 정상 작동하는지도 확인해 본다.

```sh
# 컨테이너에 로그인
~/quickstart/laradock $ docker-compose run web bash

# 데이터베이스 마이그레이션
root@dca220f5e753:/var/www/laravel# php artisan migrate

# 데이터베이스 동작 확인
root@dca220f5e753:/var/www/laravel# php artisan tinker
>>> factory('App\User')->create();
>>> App\User::first();
# => App\User {#686
#      id: 1,
#      name: "Lottie Huels",
#      email: "rylan21@example.net",
#      created_at: "2016-07-11 06:13:03",
#      updated_at: "2016-07-11 06:14:08",
#    }

# 캐시 동작 확인
>>> Cache::put('foo', 'bar', 10);
# => null
>>> Cache::get('foo');
# => "bar"
>>> exit

# 컨테이너에서 로그아웃
root@dca220f5e753:/var/www/laravel# exit
```

브라우저에서 실험할 준비가 끝났다. http://quickstart.app을 열고 [사용자 등록](http://quickstart.app/register) 페이지에서 실험에 사용할 사용자를 등록하고, 할일 목록 UI에서 할일을 추가해 본다. 

로드 밸런서의 동작을 확인하기 위해 뷰에 다음 코드를 미리 추가해 두었다.

```html
<!-- // resources/views/layouts/app.blade.php -->

<span class="text-danger">
  @<strong>{% raw %}{{ gethostname() }}{% endraw %}</strong>
</span>
```

이제 여러 개의 브라우저 창을 열어 로드 밸런서가 잘 동작하는 지 확인하자. 아래 그림처럼 네이게이션 바의 컴퓨터 이름을 잘 보기 바란다. 이 값은 `web` 컨테이너의 컴퓨터 이름이다. 여러 개의 `web` 컨테이너가 `mysql`과 `redis` 컨테이너를 잘 공유하고 있다는 점도 알 수 있다.

[![Docker in Action](/images/2016-07-11-img-01.png)](/images/2016-07-11-img-01.png)

## 6. 요약

### 6.1. 끄기

실행 중인 도커 컨테이너를 끄는 방법은 다음과 같다. `stop` 대신 `down` 명령을 이용하면 컨테이너를 삭제한다. `down`하고 다시 `up`할 때는 이미지를 다시 받아 빌드하지는 않지만, 지난 번 구동할 때 사용자가 변경한 내용은 모두 유실된다. `stop` 상태에서 사용자 변경 내용을 삭제하려면 `rm` 명령을 이용한다(e.g. `docker-compose rm redis`).

```sh
~/quickstart/laradock $ docker-compose stop
~/quickstart/laradock $ docker-compose ps
#          Name                       Command               State
# -----------------------------------------------------------------
# laradock_application_1   true                             Exit 0
# laradock_data_1          true                             Exit 0
# laradock_lb_1            /sbin/tini -- dockercloud- ...   Exit 1
# laradock_mysql_1         docker-entrypoint.sh mysqld      Exit 0
# laradock_redis_1         docker-entrypoint.sh redis ...   Exit 0
# laradock_web_1           /usr/bin/supervisord -c /e ...   Exit 0
# laradock_web_2           /usr/bin/supervisord -c /e ...   Exit 0
# laradock_web_3           /usr/bin/supervisord -c /e ...   Exit 0
# laradock_workspace_1     /sbin/my_init                    Exit 0
```

### 6.2. 개발 환경 구성

맥에서 [Sequel Pro](http://www.sequelpro.com/)(MySQL GUI)로 도커에서 구동하는 `mysql` 컨테이너의 서비스에 접속하려면 다음 정보를 이용한다.

- Host: `quickstart.app` 또는 `192.168.99.100`
- Username: `homestead`
- Password: `secret` (루트 비밀번호는 `root`)
- Port: `3306`

[![Sequel Pro](/images/2016-07-11-img-02.png)](/images/2016-07-11-img-02.png)

맥에서 [Redis Desktop Manager](http://www.redisdesktop.com/)로 도커에서 구동하는 'redis' 컨테이너의 서비스에 접속하려면 다음 정보를 이용한다.

[![Redis Desktop Manager](/images/2016-07-11-img-03.png)](/images/2016-07-11-img-03.png)

- Host: `quickstart.app` 또는 `192.168.99.100`
- Port: `6379`

### 6.3. 큰 그림

예제로 구동한 내용과 운영체제 및 컨테이너간의 관계를 그림으로 표현하면 다음과 같다. 

[![Big Picture](/images/2016-07-11-img-04.png)](/images/2016-07-11-img-04.png)

## 7. 결론

이 포스트에서는 한 대의 리눅스 호스트에 총 9개의 컨테이너를 띄웠다. 쉽게 9대의 서로 다른 리눅스 머신이라 생각하면 된다. 맥 컴퓨터에 9대의 리눅스 VM을 동시에 띄우는 것은 불가능하다. 도커라면 가능하다.

한편 개발 환경에서 사용하던 컨테이너를 자유롭게 조합해서 운영 환경에 사용할 수 있다. 가령, `web`과 `application` 컨테이너를 한 대의 물리 서버에 놓고, 백엔드에 해당하는 인프라 및 파일 업로드 디렉터리등은 별도의 물리 서버로 분리할 수도 있을 것이다. 어떻게 구성하든 코드 배포할 때는 `application` 컨테이너만 신경쓰면 된다. 하나의 구성 예일 뿐이며 각자의 환경에 맞게 응용하시면 될 것이다.  

---

[^1]: 호스트_ VM을 실행하는 맥을 호스트, VM을 게스트라 한다. 여기서는 맥락상 게스트 컨테이너들의 플랫폼이 되는 VM을 별도의 독립된 리눅스 머신이라 생각하고 도커 호스트라 부르자. 
