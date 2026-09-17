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

A aplicação está disponível publicamente no Render:

https://devsecops-lacrei-latest.onrender.com/

O endpoint utilizado para validação e health check pode ser acessado em:

https://devsecops-lacrei-latest.onrender.com/status

A resposta esperada é:

```json
{
  "status": "ok"
}
```

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

A imagem utiliza o usuário não-root `node` para executar a aplicação e instala somente as dependências necessárias para produção.

O Dockerfile também atualiza os pacotes `libssl3` e `libcrypto3` do Alpine e utiliza npm 11.19.1.

## Pipeline

A pipeline foi configurada utilizando GitHub Actions.

O workflow de CI executa os testes da aplicação e, após a aprovação dos testes, realiza o build da imagem Docker e sua publicação no Docker Hub utilizando uma tag baseada no SHA do commit.

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
Publicação da imagem com tag baseada no SHA
        |
        v
Deploy no Render
```

O deploy automático ocorre quando a alteração é integrada à branch `main`.

A análise de segurança é realizada em um workflow específico utilizando OWASP ZAP.

## Segurança

As credenciais utilizadas pela pipeline não ficam armazenadas no código-fonte.

Os seguintes valores são configurados como GitHub Secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
RENDER_DEPLOY_HOOK
```

Os valores dos secrets não são expostos no repositório ou nos arquivos de configuração.

O arquivo `.env` também está incluído no `.gitignore` e no `.dockerignore`.

Além disso, a pipeline utiliza o OWASP ZAP para realizar uma análise automatizada da aplicação antes da publicação da imagem.

O container também utiliza o usuário não-root `node`, reduzindo os privilégios do processo executado dentro da imagem.

## OWASP ZAP

O scan é realizado com o OWASP ZAP contra a aplicação em execução.

O workflow:

1. Faz o build da imagem Docker.
2. Inicia a aplicação em um container.
3. Aguarda o endpoint `/status` responder antes de iniciar o scan.
4. Executa o OWASP ZAP Baseline Scan.
5. Gera um relatório HTML.
6. Publica o relatório como artifact da execução do GitHub Actions.

O readiness check evita que o scan seja iniciado antes de a aplicação estar disponível.

A execução utiliza a opção `-I`, permitindo que alertas classificados como warnings pelo ZAP não façam o processo falhar automaticamente. Falhas na inicialização da aplicação, no readiness check ou na execução do próprio processo de scan continuam interrompendo o workflow.

O relatório é armazenado como artifact na execução do workflow de segurança.

Relatório ZAP:

https://github.com/MarcosJuniors/devsecops-lacrei/actions/runs/35059173986/artifacts/10431972093

## Docker Hub

A imagem é publicada no Docker Hub utilizando uma tag baseada no SHA do commit que gerou a imagem.

Formato utilizado:

```text
marcos98mj/devsecops-lacrei:<commit-sha>
```

Essa estratégia evita depender exclusivamente da tag `latest` e permite identificar exatamente qual código foi utilizado para gerar cada imagem.

As imagens identificadas pelo SHA também podem ser utilizadas para rollback.

## Deploy

O deploy foi realizado utilizando o Render a partir da imagem publicada no Docker Hub.

A configuração utilizada pelo serviço está registrada no arquivo `render.yaml`.

URL pública:

https://devsecops-lacrei-latest.onrender.com/

Endpoint de health check:

https://devsecops-lacrei-latest.onrender.com/status

O endpoint `/status` foi validado após o deploy e retorna:

```json
{
  "status": "ok"
}
```

O Render utiliza `/status` como health check da aplicação.

O workflow de CI utiliza um Deploy Hook do Render para disparar o deploy quando uma alteração é integrada à branch `main`.

## Proteção da branch

A branch `main` possui regras de proteção configuradas no GitHub.

Entre as regras utilizadas estão:

* necessidade de Pull Request para alterações na `main`;
* exigência dos checks `test`, `docker` e `zap`;
* bloqueio de force push;
* restrição à exclusão da branch.

As alterações são realizadas por meio de Pull Requests, permitindo que os checks de CI e segurança sejam executados antes da integração com a `main`.

## Evidências das execuções

As execuções dos workflows ficam disponíveis no GitHub Actions.

As evidências incluem:

* execução dos testes automatizados;
* build da imagem Docker;
* publicação da imagem utilizando tag baseada no SHA;
* execução do OWASP ZAP;
* geração do relatório de segurança;
* execução do processo de deploy após integração com a `main`.

Histórico dos workflows:

https://github.com/MarcosJuniors/devsecops-lacrei/actions

## Rollback

A estratégia de rollback utiliza imagens identificadas pelo SHA do commit que gerou cada versão.

Formato:

```text
marcos98mj/devsecops-lacrei:<commit-sha>
```

Caso uma versão apresente algum problema após o deploy, o procedimento é:

1. Identificar a versão atualmente em execução.
2. Identificar a última versão conhecida como estável.
3. Selecionar a imagem correspondente ao SHA da versão estável.
4. Atualizar o serviço para utilizar essa imagem.
5. Realizar o deploy da versão anterior.
6. Validar o endpoint `/status`.
7. Confirmar que a aplicação voltou a responder corretamente.

O rollback deve ser considerado quando uma alteração causar indisponibilidade da aplicação, falha no health check ou comportamento incorreto identificado após o deploy.

Após a reversão, o endpoint `/status` deve ser utilizado para validar a recuperação do serviço.

## Análise de dependências e imagem

Foram realizadas verificações de segurança tanto nas dependências da aplicação quanto na imagem Docker.

A análise das dependências foi realizada com:

```bash
npm audit
```

O resultado foi:

```text
found 0 vulnerabilities
```

A imagem Docker também foi analisada utilizando Docker Scout.

A análise final da imagem não identificou vulnerabilidades conhecidas:

```text
0 Critical
0 High
0 Medium
0 Low
```

Durante a análise, foram identificadas vulnerabilidades em componentes presentes na imagem base e em dependências utilizadas pelo npm. As versões vulneráveis foram atualizadas quando havia versão corrigida compatível.

A imagem final utiliza somente as dependências necessárias para execução em produção (`npm ci --omit=dev`) e executa a aplicação com o usuário não-root `node`.

## Decisões

O Docker foi utilizado para manter um ambiente de execução consistente entre desenvolvimento, pipeline e deploy.

O GitHub Actions foi escolhido para automatizar os testes, o build e a publicação da imagem.

O OWASP ZAP foi utilizado para incluir uma etapa de análise de segurança no processo de CI/CD.

O Docker Hub foi utilizado como registry para armazenar as imagens geradas pela pipeline.

O Render foi utilizado para realizar o deploy público da aplicação utilizando uma imagem Docker.

A utilização de tags baseadas no SHA do commit permite rastrear cada imagem publicada até o código que a originou e facilita o processo de rollback.

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
