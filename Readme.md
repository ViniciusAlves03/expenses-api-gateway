# Despesa Simples - API Gateway (Kong)

![Kong](https://img.shields.io/badge/kong-%23003459.svg?style=for-the-badge&logo=kong&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Deck](https://img.shields.io/badge/Deck-336791?style=for-the-badge)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

Este é o repositório do **API Gateway** do sistema **Despesa Simples**. Ele atua como o ponto de entrada único (Single Point of Entry) para todas as requisições externas, orquestrando o acesso aos diversos microsserviços internos.

Construído sobre **Kong (v3.7.1)**, ele é responsável por aplicar políticas de segurança transversais, como autenticação (JWT) e autorização (ACL), antes de encaminhar o tráfego para o serviço de backend apropriado.

A configuração é gerenciada de forma declarativa usando **Kong Deck**.

## ✨ Principais Funcionalidades

* **Roteamento Centralizado:** Roteia dinamicamente o tráfego para todos os microsserviços do sistema: `account`, `budgets`, `categories`, `expenses`, `incomes` e `analytics`.
* **Autenticação (JWT):** Protege todos os serviços "privados" exigindo um JSON Web Token (JWT) válido. Serviços "públicos" são expostos sem autenticação.
* **Autorização por Papel (ACL):** Utiliza o plugin ACL do Kong para aplicar controle de acesso refinado baseado em grupos (`admin`, `holder`, `dependent`) em rotas específicas, garantindo que um usuário só possa acessar recursos que lhe são permitidos.
* **Handlers Lua Customizados:** Sobrescreve o comportamento padrão dos plugins `jwt` e `acl` com scripts Lua customizados para se adaptar às regras de negócio do sistema (ex: retornar mensagens de erro padronizadas).
* **Configuração Declarativa (Deck):** Toda a configuração de serviços, rotas, plugins e consumidores é gerenciada em um único arquivo `kong.yaml`, que é aplicado usando **Kong Deck**.
* **Script de Inicialização:** Utiliza um script de *entrypoint* (`start.sh`) que aguarda a inicialização do PostgreSQL, executa as migrações do Kong e, em seguida, sincroniza a configuração declarativa do Deck.
* **CORS Global:** Aplica uma política de Cross-Origin Resource Sharing (CORS) global em todas as rotas, permitindo que o frontend (hospedado em `DECK_WEB_APP_HOSTNAME`) acesse a API.

## 🚀 Tecnologias Utilizadas

* **API Gateway:** Kong
* **Configuração:** Kong Deck
* **Banco de Dados (Kong):** PostgreSQL
* **Customização:** Lua
* **Containerização:** Docker
* **Scripting:** Shell Script

## 📋 Pré-requisitos

Para executar este projeto localmente, você precisará ter os seguintes serviços instalados e em execução:

* Docker e Docker Compose
* Uma instância de **PostgreSQL** acessível para o Kong (para armazenar seus dados de configuração e consumidores).
* **Todos os microsserviços de backend** (`account`, `budgets`, `categories`, etc.) devem estar em execução e acessíveis na mesma rede Docker.

## ⚙️ Instalação e Execução

Este projeto é projetado para ser executado exclusivamente com Docker, idealmente como parte de um `docker-compose.yml` maior que também gerencia o PostgreSQL e os outros microsserviços.

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/ViniciusAlves03/DS-api-gateway.git
    cd DS-api-gateway
    ```

2.  **Configure as variáveis de ambiente:**
    Crie um arquivo `.env` na raiz do projeto, baseado no `.env.example`.
    ```bash
    cp .env.example .env
    ```
    * Certifique-se de que as variáveis `DECK_..._SERVICE` (ex: `DECK_ACCOUNT_SERVICE`) apontam para os nomes de serviço corretos na sua rede Docker.
    * **Nota:** Você também precisará fornecer as variáveis de ambiente do Kong para a conexão com o PostgreSQL (ex: `KONG_PG_HOST`, `KONG_PG_USER`, `KONG_PG_PASSWORD`), que são usadas pelo script `start.sh`.

3.  **Construa a imagem da aplicação:**
    Usando o Dockerfile fornecido, construa a imagem do gateway.
    ```bash
    docker build -t DS-api-gateway:latest .
    ```

4.  **Rode o contêiner da aplicação:**
    Este comando inicia o Kong, o conecta à sua rede Docker e injeta as variáveis de ambiente.
    ```bash
    docker run -d \
        --name exp-api-gateway \
        -p 8000:8000 \
        --network exp-network \
        --env-file .env \
        -e "KONG_DATABASE=postgres" \
        -e "KONG_PG_HOST=nome-do-seu-container-postgres" \
        -e "KONG_PG_USER=kong" \
        -e "KONG_PG_PASSWORD=kongpass" \
        DS-api-gateway:latest
    ```
    A aplicação estará sendo executada e o proxy acessível em `http://localhost:8000`.

## 🏗️ Estrutura do Projeto

```sh
config/
├── declarative/
│   └── kong.yaml    # Arquivo de configuração declarativa (serviços, rotas, plugins, ACLs)
├── plugins/
│   ├── acl/
│   │   └── handler.lua # Handler customizado do plugin ACL
│   └── jwt/
│       └── handler.lua # Handler customizado do plugin JWT
│
└── start.sh         # Script de Entrypoint do container
```

## 📖 Visão Geral da API (Endpoints)

Este serviço é o catálogo de endpoints. Ele não define lógica de negócio, mas sim roteia e protege o acesso aos outros microsserviços.

A configuração completa de rotas, plugins e regras de ACL está definida no arquivo `config/declarative/kong.yaml`.

### 📥 Serviços Gerenciados

Em resumo, os serviços gerenciados são:

| Nome do Serviço | Microsserviço de Destino | Proteção |
| :--- | :--- | :--- |
| `public-account` | `account-service` | Nenhuma (Rotas públicas de autenticação) |
| `private-account` | `account-service` | JWT + ACL (Rotas de gerenciamento de usuários) |
| `private-budgets` | `budgets-service` | JWT + ACL (Rotas de orçamentos) |
| `private-categories` | `categories-service` | JWT + ACL (Rotas de categorias) |
| `private-expenses` | `expenses-service` | JWT + ACL (Rotas de despesas) |
| `private-incomes` | `incomes-service` | JWT + ACL (Rotas de receitas) |
| `private-analytics` | `analytics-service` | JWT + ACL (Rotas de relatórios) |

## 🧑‍💻 Autor <a id="autor"></a>

<p align="center">Desenvolvido por Vinícius Alves <strong><a href="https://github.com/ViniciusAlves03">(eu)</a></strong>.</p>

---
