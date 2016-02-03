---
layout: post
title: Android Emulator 실행법-SDK 1.6, Windows Machine 기준
date: '2010-02-13 06:49:45 +0900'
categories:
- work-n-play
tags:
- android
- emulator
---

### 1. JDK

[JDK](https://cds.sun.com/is-bin/INTERSHOP.enfinity/WFS/CDS-CDS_Developer-Site/en_US/-/USD/ViewProductDetail-Start?ProductRef=jdk-6u16-oth-JPR@CDS-CDS_Developer) 를 다운로드하여 설치한다.

또는, [JRE <sup>Java Runtime Environment</sup>](http://cds.sun.com/is-bin/INTERSHOP.enfinity/WFS/CDS-CDS_Developer-Site/en_US/-/USD/VerifyItem-Start/jre-6u16-windows-i586.exe?BundledLineItemUUID=moFIBe.oaqEAAAEkk.UxdJ2G&OrderID=R1dIBe.onL8AAAEkiOUxdJ2G&ProductID=VP1IBe.nzvkAAAEiap9pOuDb&FileName=/jre-6u16-windows-i586.exe) 만 설치할 수도 있다. JDK Version 이 맞지 않으면, Emulator 가 정상적으로 실행되지 않는다.
 
### 2. Java Runtime 의 Path 를 Windows 환경 변수에 넣어 준다.

내 컴퓨터 > 속성 > 고급 > 환경변수 > 시스템 변수> Path 로 이동하여, Java Runtime (java.exe) 가 위치한 경로를 넣어 주어야 한다. 내 경우에는 C:Program Files\Javajdk1.6.0_16\bin 에 java.exe 가 있었다.

[그림 유실] 

### 3. SDK 다운로드

[SDK](http://developer.android.com/sdk/download.html?v=android-sdk_r3-windows.zip) 를 다운로드하고, 적절한 위치에 압축을 해제 한다.

### 4. 콘솔을 띄워, SDK에 미리 정의되어 있는 Target Device 를 확인한다.

```bash
\> cd path_to_your_android_sdktools
\> path_to_your_android_sdktoolsandroid list targets
```

4 개의 Device 가 있는 것이 확인되었고, 하드웨어 구성, Android Version, Google API 포함 여부가 서로 다르다. (Emulator 는 QEMU Platform Simulator 기반으로 작성되었으며, x86 CPU 를 ARM v5 로 Emulation 해 준다.)

[그림 유실]

### 5. AVD(Android Virtual Device)를 생성한다.

```bash
\> android create avd -n donut -c 2048M -t 1
# `-n donut`: donut 라는 이름의 avd를 생성한다.
# `-c 2048M`: 2048MB의 Smartcard 가상 이미지를 생성한다. 이후에 모든 컨텐츠는 여기에 담게 된다.
# `-t 1`: f에서 확인한 미리 정의된 Target Device 중 1번 Device를 생성한다.
```

한번 생성된 AVD 는 삭제하지 않는 이상 다시 만들 필요없다. AVD는 `c:\document and settings\UserName.Android` 아래에 생성된다.

또는, GUI를 이용할 수도 있다.

```bash
\> android
```

GUI 메뉴에서 Virtual Devices > New...

[그림 유실]
 
### 6. Emulator를 실행한다.

Emulator 부팅에는 수분의 시간이 걸린다.

```bash
\> emulator -avd donut </div>
```

[그림 유실]

`adb` (Android Debug Bridge)를 이용하여 로그를 확인할 수도 있다.

```bash
\> adb logcat
```

### 7. SD Card가 정상적으로 Mount 되었는지 확인한다.

Settings > SD Card & Phone Storage로 접근한다.

[그림 유실]

### 8. SD Card에 Contents를 복사한다.

-   방법 # 1 `adb` 를 이용하는 방법

    ```bash
    \> adb push d:0.jpg /sdcard
    # d:0.jpg : Local Contents 의 경로 및 파일 명
    # /sdcard/ : Remote SDCard 에 동일한 파일명으로 복사
    ```

-   방법 # 2 `ddms` (Dalvik Debug Monitor) 를 이용하는 방법

    ```bash
    \> ddms
    ```

  DDMS 실행되면 Device > File Explorer 로 접근하여, Local 탐색기에서 원하는 Contents를 선택한 후, DDMS File Explorer의 sdcard 노드에 Drag & Drop

[그림 유실]

### 9. **`중요`** Emulator &gt; Dev Tools &gt; Media Scanner

이 작업을 해 주지 않으면, SDCard에 복사한 Contents를 Emulator에서 재생할 수 없다.

### 10. Gallery 나 Music 으로 이동하여 복사한 Contents 를 재생해 본다.

Landscape/Portrait 모드로 토글은 Ctrl + F11.
 
[그림 유실]

### 11. Emulator, `ddms` 등은 창을 닫으면 모든 리소스가 반환되고, 프로그램이 종료된다.

### 12. 각 명령의 도움말은 -help 스위치를 사용한다.

```bash
\> android -help
\> emulator -hlep
\> adb -help
\> ddms -help
```

[Android Developer Site 의 도움말](http://developer.android.com/guide/developing/tools/emulator.html) 을 더 참고하자.
