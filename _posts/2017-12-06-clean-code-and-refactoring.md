---
layout: post-minimal
title: '클린코드와 리팩토링'
date: 2017-12-06 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- CleanCode
- Refactoring
---

**MVP<sub>Minimum Viable Product</sub>**로 개발한 서비스는 시장성 및 사업성이 검증되면 버리고 다시 짜야 합니다. MVP는 **"더럽지만, 신속하게, 작동하는 서비스를 확보한다"**는게 가치이기 때문입니다. 사업 모델이 검증되면, 투자를 받고 사람을 뽑아서 오랫동안 유지할 코드 베이스, 성장을 이끌어 낼 수 있는 코드 베이스를 확보해야 합니다. 대부분의 스타트업들이 이 타이밍을 놓치고 있고, 제가 속한 회사도 예외는 아닙니다. 

본문의 예제를 보기전에 예제 코드가 쓰이는 사업 이해를 위해 간단히 설명을 드립니다.

(회사의 공식 입장이 아닌, 직원으로서 나름의 생각입니다) 우리 회사는 현재 **"이륜차 네트워크를 이용한 근거리 배송 대행 서비스"**를 업으로 하고 있으며, 사업 모델(= 서비스 모델 + 비즈니스 모델)은 다음과 같습니다.

#### 서비스 모델

- 출발지 A 지점에서 도착지 B 지점으로 소형 화물을 이동시킨다.
- A ~ B간의 거리는 일반적으로 3Km 이내이며, 
- 이동 수단으로 이륜차를 이용하고, 
- 서비스를 위해 IT 기술을 이용한다.
- 화물 운송은 대체로 40분 이내에 끝난다.

#### 비즈니스 모델 

- 화물 운송 니즈가 있는 S 화주에게 배송 대행 수수료를 받아, 실제로 물건을 이동시키는 K 기사에게 비용을 지불하고 마진을 챙긴다. 
- 배송 건수에 따라 S 화주로 부터 월 단위 시스템 사용료도 받는다.

본문에 사용한 예제는 화주 S로 부터 배송 대행 요청을 받아, K 기사 네트워크를 보유하고 배송을 수행하는 시스템에 위임하는 코드입니다. 공개를 위해 이름을 약간 바꾸긴 했지만, 실제 상용 서비스에 사용하는 코드입니다. 하나의 배송 대행 요청에 대해 웹/앱 인스턴스에서 큐 메시지로 전송하기 위해 한 번, 큐 워커 인스턴스에서 메시지를 핸들링 하기 위해 한번, 총 두 번 사용됩니다(= 비동기 처리). 현재 우리 회사의 사업 규모로 볼 때 컴퓨터(서버)가 이 코드를 하루에 10만번 정도 읽고 실행합니다.

<div class="spacer">• • •</div>

여기서 질문! 

그렇다면 개발자는 이 코드를 몇 번이나 읽을까요? 성공적인 서비스에서 유지보수가 되어야 하는 코드는 개발자와 개발자를 거치면서 만 번 정도 읽힌다고 합니다. 컴퓨터가 이해할 수 있는 코드는 작동하기만 한다면 아무렇게나 짜도 됩니다. 그런데, 사람이 읽어야 하는 코드는, 그것도 서비스 유지보수를 위해 수 천번 이상을 읽어야 하는 코드는 어떻게 짜야 할까요?

클린코드(엉클밥), 리팩토링(마틴파울러)의 책을 완벽히 이해하지도 못했고, 이해했다고 해도 모든 내용을 실천하지는 못합니다. 지금 MVP를 짜고 있나요? 그렇지 않다면, 몇 달 뒤의 자기 자신과 이 코드를 읽게 될 동료/후배 개발자들을 위해 좀 더 깔끔한 코드를 짜면 좋겠습니다. 디자인 원칙과 모범 사례를 지킨 코드는 버그와 사이드 이펙트를 현저히 줄여주고, 생산성을 월등히 끌어올려줍니다.

이 글을 읽는 분 중에 Before 코드를 쓰신 선배님이 있을 수 있습니다. 비록 유지보수가 편리한 코드로 바꾸는 타이밍을 놓치긴했지만(이건 경영진과 매니저의 잘못), MVP를 만들어 주셔서 제가 월급을 받으며 일할 수 있기에 존경과 감사의 마음을 글로나마 전달합니다. 해서 Before 코드에 대한 설명은 달지 않겠습니다. 

이제 예제를 볼까요? 

<!--more-->
<div class="spacer">• • •</div>

## Before

```php
<?php // 2016-05-24 ~ 2016-11-28, 10 커밋, 4 명의 커미터
namespace App\Jobs;

use ...;

class OrderCreationJob
{
    /**
     * @var Creator
     */
    private $orderCreator;
    /**
     * @var DeliveryOrderMapRepository
     */
    private $repository;
    private $timerStopSeconds;
    private $timerStartSeconds;

    public function __construct(
        Creator $orderCreator,
        DeliveryOrderMapRepository $repository
    ) {
        $this->orderCreator = $orderCreator;
        $this->repository = $repository;
    }

    public function fire(QueueJob $job, $data)
    {
        /**
         * @var Delivery $delivery
         */
        $deliveryId = $data['delivery_id'];
        $creator = $this->orderCreator;

        \Log::info("[OrderCreationJob] ** Started for Delivery [ID:{$deliveryId}]");

        if (!$this->repository->existsNonNullMap($deliveryId)) {

            if ($job->attempts() > 5) {
                \Log::info("[OrderCreationJob] ** FAILED and GIVING UP for Delivery [ID:{$deliveryId}]");
            } else {
                $delivery = Delivery::findOrFail($deliveryId);

                if ($delivery->deliveryTrackingStatus->tracking_status !== DeliveryStatus::SUBMITTED()) {
                    $job->delete();
                    \Log::info("[OrderCreationJob] ** Delivery Tracking Status Modified for Delivery [ID:{$deliveryId}] Not Creating  Order");
                    return;
                }

                \Log::info("[OrderCreationJob] **** Creating  2.0 Order for Delivery [ID:{$deliveryId}]");
                $this->startTimer();
                $orderDto = $creator->createOrder($delivery);
                $time = $this->stopTimer();
                \Log::info("[OrderCreationJob] **** Created  2.0 Order [ID:{$deliveryId} -> {$orderDto->getId()}]. Took {$time} seconds.");
                $job->delete();
            }
        } else {
            \Log::info("[OrderCreationJob] ** Already created for Delivery [ID:{$deliveryId}]");
            $job->delete();
        }
    }

    private function startTimer()
    {
        $this->timerStartSeconds = microtime(true);
    }

    private function stopTimer() : float
    {
        $this->timerStopSeconds = microtime(true);

        return $this->timerStopSeconds - $this->timerStartSeconds;
    }
}
```

## After

```php
<?php // 2017-11-28

namespace App\Jobs;

use ...;

class OrderCreationJob
{
    const ALLOWED_NUMBER_OF_RETRY = 5;

    private $orderCreator;
    private $deliveryOrderMapRepository;
    private $deliveryRetriever;

    public function __construct(
        OrderCreator $orderCreator,
        DeliveryOrderMapRepository $deliveryOrderMapRepository,
        DeliveryRetriever $deliveryRetriever
    ) {
        $this->orderCreator = $orderCreator;
        $this->deliveryOrderMapRepository = $deliveryOrderMapRepository;
        $this->deliveryRetriever = $deliveryRetriever;
    }

    public function fire(QueueJob $job, array $data)
    {
        $deliveryId = $data['delivery_id'];
        $context = [
            'deliveryId' => $deliveryId,
        ];

        $this->logProgress('오더 생성 잡 처리를 시작합니다.', 'info', $context);

        try {
            $this->checkIfAlreadyCreated($deliveryId);
            $this->checkIfAllowedRetryCountReached($job, $deliveryId);
            $delivery = $this->deliveryRetriever->retrieveById($deliveryId);
            $this->checkIfDeliveryStatusAlreadyChanged($delivery);
            $orderDto = $this->createOrder($delivery);
            $job->delete();
        } catch (OrderAlreadyCreatedException $e) {
            $this->logProgress($e->getMessage(), 'info', $e->getArgs());
            $job->delete();
        } catch (DeliveryStatusAlreadyChangedException $e) {
            $this->logProgress($e->getMessage(), 'info', $e->getArgs());
            $job->delete();
        } catch (OrderCreationFailedException $e) {
            $this->logProgress($e->getMessage(), 'error', $e->getArgs());
            $job->delete();
            throw $e;
        }

        $this->logProgress('오더 생성 잡 처리를 마칩니다.', 'info', $context);
    }

    private function checkIfAlreadyCreated(int $deliveryId)
    {
        if ($this->deliveryOrderMapRepository->existsNonNullMap($deliveryId)) {
            throw new OrderAlreadyCreatedException([
                'deliveryId' => $deliveryId,
            ]);
        }
    }

    private function checkIfAllowedRetryCountReached(QueueJob $job, int $deliveryId)
    {
        if ($job->attempts() > self::ALLOWED_NUMBER_OF_RETRY) {
            throw new OrderCreationFailedException(null, [
                'deliveryId' => $deliveryId,
                'retryCount' => self::ALLOWED_NUMBER_OF_RETRY,
            ]);
        }
    }

    private function checkIfDeliveryStatusAlreadyChanged(Delivery $delivery)
    {
        $deliveryTrackingStatus = $delivery->deliveryTrackingStatus->tracking_status;

        if ($deliveryTrackingStatus !== DeliveryStatus::SUBMITTED()) {
            throw new DeliveryStatusAlreadyChangedException([
                'deliveryId' => $delivery->id,
                'deliveryTrackingStatus' => $deliveryTrackingStatus
            ]);
        }
    }

    private function createOrder(Delivery $delivery)
    {
        $this->logProgress('오더를 생성합니다.', 'info', [
            'deliveryId' => $delivery->id,
        ]);

        $startTime = microtime(true);
        $orderDto = $this->orderCreator->createOrder($delivery);
        $elapsedTimeInSeconds = microtime(true) - $startTime;

        $this->logProgress('오더를 생성했습니다.', 'info', [
            'deliveryId' => $delivery->id,
            'orderId' => $orderDto->getId(),
            'elapsedTimeInSeconds' => $elapsedTimeInSeconds,
        ]);

        return $orderDto;
    }

    private function logProgress(string $message, string $level = 'info', $context = [])
    {
        Log::log($level, "[OrderCreationJob] {$message}", $context);
    }
}
```
