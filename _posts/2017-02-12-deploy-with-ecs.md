---
layout: post-minimal
title: 'AWS ECS/ECR을 이용한 서비스 배포' 
date: 2017-02-12 00:00:00 +0900
categories:
  - work-n-play
tags:
  - 개발자
  - Docker
image: http://img.youtube.com/vi/zBqjh61QcB4/0.jpg
---

**AWS ECS(EC2 Container Service)**는 갓마존이 제공하는 도커 기반 서비스 인프라입니다. EC2 인스턴스 위에 도커 엔진을 올려 놓은 것이라 생각하면 쉽습니다. **AWS ECR(Container Registry)**은 빌드한 도커 이미지를 올리고 내릴 수 있는 사설 도커 허브라 생각할 수 있습니다.

아래는 ECS 랜딩 페이지에 걸린 공식 유튜브 동영상입니다(그림을 클릭하여 재생).

[![Introduction to Amazon EC2 Container Service (ECS) - Docker Management on AWS](http://img.youtube.com/vi/zBqjh61QcB4/0.jpg)](https://www.youtube.com/watch?v=zBqjh61QcB4)

AWS에서 어떤 협찬도 받지 않았지만, 필자가 느낀 ECS의 장점은 다음과 같습니다<small>(협찬 좀...)</small>.

1.  이미 익숙한 AWS Console 및 서비스를 그대로 이용할 수 있다. 
2.  Service Discovery나 Container Orchestration등을 위해 [쿠버네티스(Kubernetes)](https://kubernetes.io/)와 같이 어려운 도구를 다룰 필요가 없다.

그런데 **아직 서울 지역는 오픈되지 않았습니다.** 빨리 좀 오픈해 주세요~ 갓마존.

**이 포스트에서는 ECS에 라라벨 서비스를 배포하는 방법을 다룹니다. 사실 다른 플랫폼이나 프레임워크라고 해도 `Dockerfile` 레시피만 달라질 뿐 ECS를 사용하는 방법 자체에는 큰 차이가 없습니다.**

<!--more-->
<div class="spacer">• • •</div>

## 1. 예제 프로젝트 설치

ECS에 배포할 서비스가 있어야겠죠? 아래 주소를 방문하여 가이드에 따라 프로젝트를 설치하고, 도커 이미지를 빌드합니다.

[https://github.com/appkr/deploy-laravel-with-ecs-and-ecr](https://github.com/appkr/deploy-laravel-with-ecs-and-ecr)

이 예제에서는 로컬의 `.env` 파일을 도커 이미지에 포함하여 애플리케이션의 실행 환경 변수를 설정하고 있습니다. 실제 배포에서는 AWS Console/로컬 셸에서 환경 변수를 등록하거나, `Dockerfile`에서 S3 등에 저장된 `.env`를 도커 이미지로 다운로드 받아 사용하도록 하는 것이 안전할 것입니다.
 
## 2. Hello ECS

AWS Console에 로그인합니다. 가장 먼저 해야할 일은 리전을 Tokyo나 Singapore 등 ECS가 오픈된 지역으로 변경하는 일입니다. 필자는 Tokyo로 선택했습니다.

Services 목록에서 <kbd>EC2 Container Service</kbd>로 진입하고 <kbd>Get Started</kbd> 버튼을 누릅니다. 

다음 화면이 나오면 체크박스를 모두 체크하고 <kbd>Continue</kbd> 버튼을 누릅니다.

-   [v] Deploy a sample application onto Amazon ECS Cluster
-   [v] Store container images securely with Amazon ECR

[![Getting Started with Amazon EC2 Container Service(ECS)](/images/2017-02-12-img-02.png)](/images/2017-02-12-img-02.png)

지금부터 여섯 단계를 거칩니다.

### 2.1. Step 1: Configure repository

ECR 레지스트리에 저장소 이름을 정하는 화면입니다. `appkr/myshop`으로 이름을 정했습니다.

[![Step 1: Configure repository](/images/2017-02-12-img-03.png)](/images/2017-02-12-img-03.png)

### 2.2. Step 2: Build, tag, and push Docker image

화면에 ECR을 초기화하기 위한 자세한 안내가 나옵니다. 1 절에서 이미지는 빌드하고 테스트했으므로 빌드 과정은 건너 뜁니다. `appkr/myshop:latest` 이미지를 빌드했고, 실행하여 작동 테스트를 완료했다고 가정합니다. 나머지 과정은 다음과 같습니다. 

로컬 셸에서 ECR 서비스에 로그인합니다. 도커 허브나 [도커 레지스트리](https://docs.docker.com/registry/)에 로그인하는 방법과 같습니다. 굉장히 긴 비밀번호가 달린 명령문을 콘솔에 출력하는데 그대로 복사해서 붙여 넣고 로그인합니다.
 
```bash
~/any $ aws ecr get-login --region ap-northeast-1

~/any $ docker login -u AWS -p <LONG_PASS_STRING> -e none https://628988759087.dkr.ecr.ap-northeast-1.amazonaws.com
```

이제 ECR 레지스트리 URL을 포함한 네임스페이스를 달아 태깅하고, 태깅된 이미지를 ECR에 푸쉬합니다.

```bash
~/any $ docker tag appkr/myshop:latest 628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop:latest

~/any $ docker images
# REPOSITORY                                                       TAG       IMAGE ID         CREATED           SIZE
# appkr/myshop                                                     latest    126f36ac9412     58 minutes ago    549 MB
# 628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop   latest    126f36ac9412     58 minutes ago    549 MB

~/any $ docker push 628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop:latest
# The push refers to a repository [628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop]
# ...
# latest: digest: sha256:b8d0e4d0ab86db7436943573b11d06bdac34deb3d874423005670dfd47a39908 size: 5331
```

### 2.3. Step 3: Create a task definition

필자도 ECS를 배우고 있는 과정으로, 두 번 밖에 사용해 보지 않았기에 갓마존에서 말하는 `task`의 개념을 정확히 이해하지 못했습니다. <kbd>Create a task definition</kbd> 창에 다음과 같이 입력했습니다.

-   Task definition name*: deploy
-   Container name*: myshop
-   Image*: 628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop:latest
-   Memory Limits (MB)*: Hard limit 256
-   Port mappings: 80 80 tcp

### 2.4. Step 4: Configure service

서비스를 설정하고, ELB(Elastic Load Balancer)를 활성화했습니다.

-   Service name*: myshop
-   Desired number of tasks*: 1
-   Elastic load balancing
    -   Container name: myshop:80
    -   ELB listener protocol*: HTTP
    -   ELB health check: http:80/
    -   ELB listener port*: 80

### 2.5. Step 5: Configure cluster

클러스터는 서비스를 구성하기 위한 서버(컨테이너)들의 논리적 집합이라 이해하고 있습니다. 가령 지금 배포하는 애플리케이션이 RDS나 ElasticCache를 쓸 수도 있지만, MySQL과 Redis를 직접 컨테이너로 구성해서 클러스터에 넣을 수도 있을 겁니다. 여튼 다음과 같이 설정했습니다.

-   Cluster name*: myshop
-   EC2 instance type*: t2.micro
-   Number of instances*: 1
-   Key pair: aws-tokyo-ecs
-   Security group
    -   Allowed ingress source(s)*: Anywhere

Key pair는 컨테이너에 SSH 접속을 위해 필요합니다. 인스턴스 타입도 실험해 보고 지울 것이므로 가장 작은 것으로 선택하고, 인스턴스는 1개만 선택했습니다. AWS를 쓰던 사용자라면 각 입력 박스의 의미를 이해할 수 있을 것입니다.

### 2.6. Step 6: Review

지금까지 설정한 값들을 보여줍니다. <kbd>Launch</kbd> 버튼을 누르면 환경 구성이 시작됩니다. 환경 구성이 완료되면 <kbd>View Instance</kbd> 버튼이 활성화됩니다.

[![Step 6: Review](/images/2017-02-12-img-04.png)](/images/2017-02-12-img-04.png)

우선 여기까지 수행하면 애플리케이션이 ECS에서 작동하고 있는 상태가 됩니다.

## 3. 로드 밸런싱 및 오토 스케일링

### 3.1. 로드 밸런서

<kbd>Cluster</kbd> 메뉴에서 `myshop` 서비스를 선택하면, <kbd>Load Balancing</kbd> 섹션을 볼 수 있습니다. 누르면 다음 화면을 볼 수 있습니다.

[![EC2 Load Balancing](/images/2017-02-12-img-05.png)](/images/2017-02-12-img-05.png)

하이라이트된 URL이 도커 컨테이너에서 실행 중인 서비스로서, 사용자가 접근할 수 있는 URL이 됩니다. 브라우저에서 열어보면 컨테이너 `59450439db83`에서 서비스가 실행 중인 것을 확인할 수 있습니다.
 
[![EC2 Load Balancing](/images/2017-02-12-img-06.png)](/images/2017-02-12-img-06.png)

### 3.2. 오토 스케일링

아직 트래픽을 많이 만들지 못해서 오토 스케일링은 경험하지 못했습니다. 오토 스케일링을 설정한 후, 다음 스크립트를 여러 개의 셸에서 실행해서 서버에 부하를 주었지만 좀 처럼 CPU 로드가 올라가진 않더라구요ㅜ. 

```bash
~/any $ while true; do curl http://ec2contai-ecselast-1lgfqkql0okbd-452428627.ap-northeast-1.elb.amazonaws.com:80\; sleep 1; done
```

어쨌든 Elastic Beanstalk처럼 인스턴스를 처음부터 만들고, 서버 인프라를 구성하고, 환경변수를 추가하고, 애플리케이션 코드를 복제해야 하는 것과 달리, 도커는 애플리케이션까지 포함된 이미지를 ECR에서 받아 실행만 하는 것으므로, (로컬 환경의 경험으로 부터 유추해 보아) 대략 수 초 내에 새 컨테이너를 띄울 수 있을 것입니다.

<kbd>Cluster</kbd> 메뉴에서 <kbd>Update</kbd> 버튼을 눌러 오토 스케일링 옵션을 설정했습니다. 총 세 단계를 거칩니다.

#### 1 단계: Min, Max Tasks 설정

그림과 같습니다. 필자는 최소 1대, 최대 2대로 설정했습니다.

[![EC2 Load Balancing](/images/2017-02-12-img-07.png)](/images/2017-02-12-img-07.png)

#### 2~3 단계: 오토 스케일링 조건 및 액션 설정

직전 5분 동안 CPU 사용량이 40%를 넘어서면 스케일링 아웃하도록 설정했습니다. 아~ 아까비!! 이 값을 5% 정도로 낮게 설정했다면 오토 스케일을 볼 수 있었을 텐데... 지금은 모든 환경을 지운 상태라 실험해 볼 수 없네요.

[![EC2 Load Balancing](/images/2017-02-12-img-08.png)](/images/2017-02-12-img-08.png)

[![EC2 Load Balancing](/images/2017-02-12-img-09.png)](/images/2017-02-12-img-09.png)

## 4. 워크 플로우

이제 로컬 개발 환경에서 애플리케이션 코드가 변경되면, `docker build` -> `docker tag` -> `docker push` 명령만으로 변경된 애플리케이션을 AWS ECS 클러스터에 배포할 수 있습니다.

```bash
~/deploy-laravel-with-ecs-and-ecr $ docker build --tag appkr/myshop .

~/any $ docker tag appkr/myshop:latest 628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop:latest

~/any $ docker push 628988759087.dkr.ecr.ap-northeast-1.amazonaws.com/appkr/myshop:latest
```

이상의 과정을 Jenkins등 CI/CD 도구에 걸어 놓으면, 코드 변경 -> `git push` -> Test by CI tool -> Deploy by CD tool 등으로 애플리케이션 개발 및 수정 이후의 모든 과정을 완전 자동화할 수 있을 겁니다. 도커, CI/CD를 통한 테스트 및 배포 자동화는 배포에 대한 개발자의 두려움을 없애 줍니다. 

배포 및 운영만을 담당하는 엔지니어가 별도로 있는 조오~은 회사가 아니라면, 결과적으로 ECS/ECR를 이용한 서비스 배포는 개발자가 비즈니스 로직 개발에만 집중할 수 있도록 함으로써, 비즈니스 싸이클이 빨리지는 효과를 얻을 수 있습니다.

---

도커 이용의 장점이나 사용법을 배우려면 `subicura`님의 블로그 포스트를 참고하시기 바랍니다.

[초보를 위한 도커 안내서 by subicura(김충섭)](https://subicura.com/2017/01/19/docker-guide-for-beginners-1.html)





