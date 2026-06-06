# Murim Cloud

AWS EC2 환경에서 Nginx, FastAPI, MariaDB를 Docker Compose로 운영하고,  
GitHub Actions 기반 CI/CD와 Terraform 기반 IaC를 적용한 인프라 실습 프로젝트입니다.

## Project Overview

이 프로젝트는 단일 EC2 환경에서 웹 계층, 애플리케이션 계층, 데이터 계층을 분리 운영하고,  
GitHub Actions를 통해 자동 배포를 수행하며, Terraform으로 AWS 인프라를 코드로 관리하는 것을 목표로 했습니다.

## Objectives

- 웹 / 애플리케이션 / 데이터 계층 분리 운영
- GitHub Actions 기반 자동 배포 파이프라인 구축
- Terraform을 활용한 AWS 인프라 코드화
- 트러블슈팅 경험 문서화를 통한 운영 관점 강화

## Architecture

![Architecture](./docs/architecture.png)

## Tech Stack

### Cloud / Infra
- AWS EC2
- VPC
- Public Subnet
- Internet Gateway
- Route Table
- Security Group
- Terraform

### Container / App
- Docker
- Docker Compose
- Nginx
- FastAPI
- MariaDB

### CI/CD
- GitHub Actions
- SSH
- GitHub Secrets

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── deploy.yml
├── backend/
├── frontend/
├── terraform/
├── docs/
│   ├── architecture.png
├── docker-compose.yml
├── nginx.conf
└── README.md
```

## Troubleshooting

프로젝트를 진행하며 마주친 운영 이슈와 해결 과정을 정리했습니다.

### 1. Terraform / AWS — EC2 재생성으로 인한 상태 변경
- **증상:** `terraform apply` 시 EC2가 파괴 후 재생성되어 공인 IP와 서버 상태가 변경됨
- **원인:** Immutable Infrastructure 특성상 일부 리소스 변경이 인스턴스 교체를 유발
- **해결:** 변경된 공인 IP를 GitHub Secrets(HOST)와 DB 접속 도구에 최신화하여 배포 파이프라인 정상화

### 2. Security Group — 포트 누락으로 인한 접근 차단
- **증상:** 80번 포트만 열려 있어 실제 서비스 포트(8085)와 DB 포트(3306) 접근이 차단됨
- **원인:** main.tf에 서비스/DB 포트에 대한 ingress 규칙 미정의
- **해결:** main.tf에 8085(Web), 3306(DB), 22(SSH) ingress 규칙을 추가해 인프라 설계와 런타임 포트의 일치 확인

### 3. Docker Network — 백엔드 DB 연결 실패
- **증상:** 백엔드에서 DB 연결 실패 (Connection Refused)
- **원인:** 컨테이너 내부에서 `localhost`로 DB에 접근 시도
- **해결:** 컨테이너 간 통신은 서비스명을 호스트로 사용해야 함을 확인하고, DB_HOST를 docker compose 서비스명(my-db)과 일치시킴

### 4. Data Persistence — 서버 재구축 후 데이터 소멸
- **증상:** 서버 재구축 후 DB 테이블과 데이터가 소멸
- **원인:** 인스턴스 파괴 시 로컬 볼륨 폴더도 함께 삭제됨
- **해결:** 데이터 영속성을 위해 운영 환경에서는 RDS 또는 EBS 분리 전략이 필요함을 정리
