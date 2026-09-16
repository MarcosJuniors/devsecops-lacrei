# DevSecOps Lacrei Saúde

Este projeto apresenta uma pipeline de CI/CD para uma API simples em Node.js, com testes automatizados, Docker, análise de segurança com OWASP ZAP, publicação da imagem no Docker Hub e deploy em ambiente público.

## Aplicação

A API possui o endpoint:

```text
GET /status
```

Resposta:

```json
{
  "status": "ok"
}
```

A aplicação está disponível em:

https://devsecops-lacrei-latest.onrender.com/status

## Tecnologias utilizadas

* Node.js
* Express
* Jest
* Supertest
* Docker
* GitHub Actions
* OWASP ZAP
* Docker Hub
* Render

## Executando localmente

### Pré-requisitos

* Node.js 22 ou superior
* npm
* Docker, caso queira executar a aplicação em container

### Instalação

```bash
npm ci
```

### Executar os testes

```bash
npm test
```

### Iniciar a aplicação

```bash
node src/server.js
```

A API ficará disponível em:

```text
http://localhost:3000
```

Para verificar o funcionamento:

```text
http://localhost:3000/status
```

## Docker

Para criar a imagem:

```bash
docker build -t devsecops-lacrei .
```

Para executar:

```bash
docker run -p 3000:3000 devsecops-lacrei
```

Depois, acesse:

```text
http://localhost:3000/status
```

## Pipeline

A pipeline foi configurada utilizando GitHub Actions.

O processo executa os testes da aplicação, cria a imagem Docker, realiza a análise de segurança com OWASP ZAP e, caso as etapas anteriores sejam concluídas, publica a imagem no Docker Hub.

O fluxo principal é:

```text
Push ou Pull Request
        |
        v
Instalação das dependências
        |
        v
Testes automatizados
        |
        v
Build da imagem Docker
        |
        v
Análise com OWASP ZAP
        |
        v
Publicação no Docker Hub
```

## Segurança

As credenciais utilizadas pela pipeline não ficam armazenadas no código-fonte.

As credenciais do Docker Hub são armazenadas como GitHub Secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

O arquivo `.env` também está incluído no `.gitignore`.

Além disso, a pipeline utiliza o OWASP ZAP para realizar uma análise automatizada da aplicação. O relatório gerado pelo scan fica disponível como artifact da execução do GitHub Actions.

## OWASP ZAP

O scan é realizado com o OWASP ZAP contra a aplicação em execução.

O workflow gera um relatório HTML ao final da análise e disponibiliza o arquivo como artifact da execução.

## Docker Hub

A imagem publicada pela pipeline está disponível no Docker Hub:

```text
marcos98mj/devsecops-lacrei:latest
```

## Deploy

O deploy foi realizado utilizando o Render a partir da imagem publicada no Docker Hub.

A configuração utilizada pelo serviço está registrada no arquivo `render.yaml`.

Endpoint público:

```text
https://devsecops-lacrei-latest.onrender.com/status
```

## Rollback

Para um ambiente de produção, a estratégia de rollback seria manter versões identificadas pelo commit que gerou cada imagem.

Por exemplo:

```text
marcos98mj/devsecops-lacrei:<commit-sha>
```

Caso uma versão apresente algum problema, seria possível retornar para uma imagem anterior conhecida e estável.

O processo seria:

1. Identificar a versão anterior estável.
2. Selecionar a imagem correspondente ao commit.
3. Atualizar o serviço para utilizar essa imagem.
4. Testar o endpoint `/status`.
5. Verificar se a aplicação voltou a funcionar normalmente.

A utilização de tags associadas ao commit também evita depender exclusivamente da tag `latest`.

## Decisões

O Docker foi utilizado para manter um ambiente de execução consistente entre desenvolvimento, pipeline e deploy.

O GitHub Actions foi escolhido para automatizar os testes, o build e a publicação da imagem.

O OWASP ZAP foi utilizado para incluir uma etapa de análise de segurança no processo de CI/CD.

O Docker Hub foi utilizado como registry para armazenar as imagens geradas pela pipeline.

O Render foi utilizado para realizar o deploy público da aplicação utilizando a imagem Docker.

## Estrutura do projeto

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── security.yml
├── src/
│   ├── app.js
│   └── server.js
├── tests/
│   └── app.test.js
├── .dockerignore
├── .gitignore
├── Dockerfile
├── package-lock.json
├── package.json
├── render.yaml
└── README.md
```

## Repositório

GitHub:

https://github.com/MarcosJuniors/devsecops-lacrei
