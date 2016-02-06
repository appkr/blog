---
layout: post
title: Buffalo WZR-300HP-NH 가정용 공유기를 이용한 NAS 만들기
date: '2010-05-11 05:50:42 +0900'
categories:
- work-n-play
tags:
- homeserver
- 클라우드
- nas
- pc활용
---

[![](http://localhost:8000/wp-content/uploads/1/cfile29.uf.182889104CDBDDF90CD6EB.jpg)](http://localhost:8000/wp-content/uploads/1/cfile23.uf.122CF6044CDBDDF9444606.jpg) 
  
그림. Buffalo WZR-300HP-NH-AP 가정용 유무선 공유기
  
 
  
이 가정용 공유기 제품(WZR-300HP-NH-AP)의 **가장 큰 특징은 USB Host 기능을 지원하기 때문에, 공유기에 USB 스틱이나 USB 외장 하드디스크를 연결하여, 외부에서도 접속이 가능한 NAS (Network Attached Storage)로 활용이 가능**하다는 점이다. 공유기로서의 기본 기능 또한 우수한 편이다. 이 포스트는 돈을 받고 하는 리뷰가 아니며, 본 제품과 관련된 내 경험과 나만의 활용법을 공유하기 위하여 쓴 것임을 알린다. 이하, 이 제품을 AP-NAS라 칭하겠다.
  
 
  #### 엮인 글
  
a. [홈 미디어 시스템 만들기](http://systemscoaching.kr/162) 
  
 
  #### 전체 시스템 구성
  
 [![AP-NAS_Topology](http://localhost:8000/wp-content/uploads/1/cfile29.uf.127A0D144CE8B5712C0769.png "AP-NAS_Topology")](http://localhost:8000/wp-content/uploads/1/cfile6.uf.184801314CE8B5711B0185.png) 
  
그림. AP-NAS의 구성도 
  
 
  
Dynamic DNS를 등록해 놓아서, 집 밖에서 AP-NAS에 접속할 때는, IP(211.214.x.x) 주소 대신 Domain Name(suchcool.dyndns.org)을 이용한다. 난 그간에 들고 다니던 WD 2.5인치 120GB 외장 디스크를 붙였다.
  
 
  #### 사용 시나리오
  ##### 가정에서 파일 백업
  
HOMEPC에는 몇 년 동안 모은 소중한 음악, 사진, 비디오, 참고문서들이 들어 있다. 디스크가 고장이라도 나면 정말 낭패가 아닐 수 없다. HOMEPC와 AP-NAS간에 물린 USB 외장 HDD간의 동기화는 [Microsoft SyncToy](http://www.microsoft.com/downloads/details.aspx?FamilyID=c26efa36-98e0-4ee9-a7c5-98d0592d8c52&DisplayLang=en) (무료)를 이용한다.
  
 
  ##### 원격지(사무실)에서 가정에 있는 멀티미디어 컨텐츠 재생
  
![1-1](http://localhost:8000/wp-content/uploads/1/cfile25.uf.164C6C314CE8B5712DDBC9.png "1-1") ![1-2](http://localhost:8000/wp-content/uploads/1/cfile30.uf.122EE62E4CE8B57116919A.png "1-2") ![1-3](http://localhost:8000/wp-content/uploads/1/cfile24.uf.1911E4324CE8B572319BB0.png "1-3") ![1-4](http://localhost:8000/wp-content/uploads/1/cfile27.uf.1835722E4CE8B5721416A8.png "1-4") 
  
그림. 왼쪽 부터 AP-NAS에 Web Access로 접속한 초기 화면 (파일 브라우저), 사진 보기, 음악 듣기, 비디오 보기
  
 
  
크롬브라우저는 HTML5를 지원하고 있어, 별도의 플레이어 플러그인, 코덱 및 파일 포맷 플러그인 설치 없이 브라우저에서 바로 컨텐츠를 재생할 수 있다(위 그림에서는 jpg 이미지, mp3 음악, ogg 비디오). 다만, 크롬 브라우저에서 지원하지 않는 컨텐츠의 경우에는 다운로드가 된다. 반면, IE나 FireFox에서는 이미 설치되어 있는 MediaPlayer, QuickTime 플레이어 플러그인으로 재생된다.  
  
 
  ##### 원격지에서 득템한 컨텐츠를 가정에 있는 AP-NAS에 업로드
  
![2-1](http://localhost:8000/wp-content/uploads/1/cfile7.uf.135531124CE8B572586841.png "2-1") ![2-2](http://localhost:8000/wp-content/uploads/1/cfile24.uf.19746F364CE8B572174E28.png "2-2") 
  
그림. 왼쪽부터 새폴더 만들기, 파일 업로드
  
 
  ##### 멀리 계신 부모님/동기에게 항상 최신의 우리 가족 사진 보여 드리기
  
내가 사무실에서 가정에 있는 AP-NAS에 접근하는 거랑 다를 바 없다. 부모님들에게 필요한 것은 ⓐ약간의 컴퓨터 지식과, ⓑAP-NAS의 접속 주소, 그리고 ⓒ계정 뿐이다. 디카에서 뽑은 SD카드를 HOMEPC에 넣고, 사진들을 내 사진 폴더에 옮겨 놓으면, (PC가 켜지면) SyncToy Command Line Script가 자동으로 AP-NAS에 동기화 시켜 준다. 
  
 
  ##### HOMEPC 켜고 끄기: WOL (Wakeup On Lan)
  
![3-1](http://localhost:8000/wp-content/uploads/1/cfile7.uf.195268124CE8B5723C1B29.png "3-1") ![3-2](http://localhost:8000/wp-content/uploads/1/cfile9.uf.14228F2E4CE8B572224810.png "3-2") ![3-3](http://localhost:8000/wp-content/uploads/1/cfile1.uf.1816F2324CE8B5722702B3.png "3-3") 
  
그림. 왼쪽부터 AP-NAS의 Service List Page (AP-NAS에 연결된 장치가 List-up 되어 있고 그 옆에 WOL 버튼이 있다), 사무실에서 HOMEPC에 원격 데스크탑으로 연결한 화면, HOMEPC 끄기
  
 
  
NAS에 접속만으로 부족할 때가 있다. 가끔 집에 있는 HOMEPC를 이용해야 할 때가 있다. 이땐, AP-NAS Setting Page로 접속해서 AP-NAS에 물려 있는 PC 중 하나를 켜고, Terminal Service/Telnet/SSH로 접속해서 원하는 작업을 한 후 HOMEPC를 종료(실행 창에서 shutdown /s 또는 shutdown /i)시킬 수 있다. 
  
 
  
* 물론, 이런 식으로 사용하기 위해서는 원격지에서 시동하고자 하는 PC의 BIOS 셋팅, PC의 Lan Card Driver 셋팅, AP-NAS에서 22번, 25번, 3389번 등에 대한 Port Forwarding과 같은 약간 복잡한 설정을 해야 한다. (구글에서 WOL, Port Forwarding으로 검색하면 상세히 알 수 있음)
  
 
  #### AP-NAS의 좋은 점
  ##### 항상 켜져 있는 장치
  
가정에 있는 PC는 항상 켜져 있지 않지만, 공유기는 항상 켜져 있는 장치이다. 즉, 통신사의 DHCP(Dynamic Host Configuration Protocol, 자동으로 인터넷 주소체계를 할당해 주는 시스템)서버에서 할당 받은 유동 IP를 기본 대여 기간인 7일이 지났다고 해서 잃어 버리지 않는다. 유동 IP이지만, 마치 고정 IP처럼 사용할 수 있다는 의미이다. 
  
 
  ##### 소음과 전기 요금
  
PC에 붙어 있는 저장장치에 접근성을 높이기 위해 항상 PC를 켜놓는다는 것은 소음 환경적인 면에서도 안 좋을 뿐더러, 전기요금도 많이 나온다. 이 AP-NAS는 Linux 운영체제를 사용하며, 따라서 당연히 USB 장치 드라이버에서 전원 관리 옵션을 지원한다. AP-NAS Setting Page에서 ‘x분간 동작이 없으면 하드디스크 끄기’와 같은 옵션이 있다.
  
 
  #### AP-NAS의 불편한 점
  
[![AP-NAS_Stack](http://localhost:8000/wp-content/uploads/1/cfile3.uf.201CFB334CE8B5731C22C3.png "AP-NAS_Stack")](http://localhost:8000/wp-content/uploads/1/cfile1.uf.1950F8014CE8B5739D4AB5.png) 
  
그림. Samba Server가 탑재되지 않는 아쉬움
  
 
  
AP-NAS에 Web Access로 접속하여 파일을 업로드할 때 한번에 하나씩만 올릴 수 있어 많이 불편하다. Samba Server가 올라가 있다면, 탐색기에서 [suchcool.dyndns.orgshared_folder](//%5C%5Csuchcool.dyndns.org%5Cshared_folder) 와 같이 접속해서 대용량으로 파일을 올리고 내리고 할 수 있으려만… SSH로 접속된다면 Samba Server는 설치할 수 있다. 접속을 시도해 보았다. 막혀 있었다. [소스코드](http://opensource.buffalo.jp/gpl_wireless.html)를 다운로드 받아 막아 놓은 SSH 포트를 열어서 빌드해서 이미지를 다시 구워볼 생각을 했지만, 빌드 옵션들이 공개되어 있지 않고, 자신이 없어서 그냥 패스! 했다.
  
 
  
* 참고로, AP-NAS Setting Page는 xxxx번 포트, Web Access Page는 yyyy번 포트를 사용한다. DNS 주소와 포트번호를 모두 안다고 브라우저에 내 소유의 NAS에 접근하려 하지 마시라. 계정이 있어야 내용을 볼 수 있으니까.
  
 
  #### 앞으로 가정용 미디어 게이트웨이는
  
**앞으로 가정용 미디어 게이트웨이는 공유기가 될 것이다.** 가정 내에 IP를 가진 장치는 모두 이 공유기에 붙어야 하고, 공유기는 외부세계와 내부세계를 연결해 주는, 가정 내에서 최고의 권력자가 될 것이기 때문이다. 이제 막 가정용 공유기에 USB Host가 지원되어, 외장 USB 저장장치를 붙일 수 있고, 외장 USB 저장장치를 제어하는 소프트웨어 솔루션이 탑재된 제품들이 나오고 있다. 지금은 외장형이지만 디스크가 교체 가능한 형태의 내장형으로 시장은 발전할 것으로 생각된다.
  
 
  
구글과 같은 클라우드 서비스들을 사람들은 편하게 사용하고 있지만, 문제는 **저장용량과 Privacy 문제**이다. AP-NAS는 이런 문제점들을 해결해 주는 **Personal 클라우드**라고 부를 수도 있을 듯 하다.
  
 
  
이런 생각을 해 본다. 휴대용 외장형 하드디스크에 32bit RISC CPU, WiFI, Battery, Linux, Web Server, Samba Server를 탑재하면 어떨까? USB로 PC에 연결해서 컨텐츠를 담는 것이 아니라, 씽크대든 책상이든 아무데나 던져 놓고는 PC에서 Web Access나 Samba로 접속해서 컨텐츠를 담는다. 이동 중에 iPhone 등에서 WiFi AdHoc Mode로 가방 속에 배터리로 동작하는 디스크에 접속해서 멀티미디어 컨텐츠를 즐긴다. 회사에서는 그냥 책상 위에 두고, 여러 명의 프로젝트 멤버들이 접속해서 프로젝트 파일들을 공유한다. 이런 거 나오면, 내가 회사에 말해서 1대 사달라고 할텐데…
