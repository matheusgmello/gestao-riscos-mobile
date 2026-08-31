# Gestão de Risco — API (Mobile)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Python](https://img.shields.io/badge/Python-3.11%20%7C%203.12-blue)
![Django](https://img.shields.io/badge/Django-5.2-092E20)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1)

API REST em Django REST Framework, extraída do [projeto Gestão de Risco UFSM](https://github.com/matheusgmello/gestao-riscos-ufsm) para servir de backend a um app **Flutter/Dart** desenvolvido para a disciplina de Programação Mobile.

Este repositório é independente do sistema web em produção usado pela UFSM — mudanças aqui não afetam aquele.

## Documentação

- [docs/api.md](docs/api.md) — endpoints, autenticação, payloads e parâmetros de filtro.
- [docs/banco-de-dados.md](docs/banco-de-dados.md) — modelo de dados.

## Rodar via Docker Compose

```bash
git clone git@github.com:matheusgmello/gestao-riscos-mobile.git
cd gestao-riscos-mobile
docker compose up --build
```

Backend disponível em `http://localhost:8000/`.

Para popular dados de demonstração (dentro do container ou de uma instalação local):

```bash
python manage.py seed_apresentacao
```

Login padrão: SIAPE `202512603`, senha `12345678`.

> Do emulador Android, use `http://10.0.2.2:8000` para acessar a API rodando no host. iOS simulator aceita `http://localhost:8000` direto.

## Rodar sem Docker

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\Activate.ps1
pip install -r backend/requirements.txt
cp .env.example .env
docker compose up -d db     # só o banco
cd backend
python manage.py migrate
python manage.py runserver
```

## Licença

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE) para o texto completo.
