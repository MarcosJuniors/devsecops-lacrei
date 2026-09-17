# DevSecOps — Lacrei Saúde

Projeto desenvolvido para o desafio técnico de **DevSecOps da Lacrei Saúde**, com foco em automação de CI/CD, segurança de aplicações, containerização, rastreabilidade de versões e deploy automatizado.

## Links

* **Repositório:** https://github.com/MarcosJuniors/devsecops-lacrei
* **Aplicação em produção:** https://devsecops-lacrei-latest.onrender.com/
* **Health check:** https://devsecops-lacrei-latest.onrender.com/status
* **GitHub Actions:** https://github.com/MarcosJuniors/devsecops-lacrei/actions
* **Documentação completa no Notion:** https://cord-aerosteon-cfb.notion.site/3dedf9f11e1180c9b9a4f0dbca97bab2
* **Relatório OWASP ZAP:** https://github.com/MarcosJuniors/devsecops-lacrei/actions/runs/35059173986/artifacts/10431972093

---

## Visão geral

A solução implementa um pipeline DevSecOps utilizando:

* GitHub Actions
* Node.js 22
* Docker
* Docker Hub
* OWASP ZAP
* Render

O fluxo automatiza testes, construção da imagem, análise de segurança, publicação da imagem e deploy da aplicação.

---

## Arquitetura do fluxo

```text
Pull Request
     │
     ├── CI
     │    ├── npm ci
     │    ├── npm test
     │    └── Build da imagem Docker
     │
     └── Security Scan
          ├── Build da imagem
          ├── Inicialização da aplicação
          ├── Verificação de /status
          └── OWASP ZAP
     
Merge na main
     │
     ▼
Publicação da imagem com SHA
     │
     ▼
Deploy automático no Render
     │
     ▼
Health check
```

---

## CI/CD

O projeto utiliza GitHub Actions para automatizar o processo de integração e entrega.

### CI

O workflow de CI realiza:

1. Checkout do código.
2. Configuração do Node.js 22.
3. Instalação das dependências com `npm ci`.
4. Execução dos testes automatizados.
5. Login no Docker Hub utilizando Secrets.
6. Construção da imagem Docker.
7. Publicação da imagem utilizando o SHA do commit.
8. Acionamento do deploy no Render após alterações integradas na `main`.

### Tag imutável

A imagem é publicada utilizando o SHA do commit:

```text
marcos98mj/devsecops-lacrei:<GITHUB_SHA>
```

Essa estratégia permite identificar exatamente qual commit originou determinada imagem e facilita operações de rollback.

A tag `latest` permanece configurada no serviço para referência da aplicação, enquanto o pipeline utiliza a tag baseada no SHA para garantir rastreabilidade da versão publicada.

---

## Testes

Os testes são executados automaticamente pelo workflow:

```bash
npm ci
npm test
```

Os checks `test`, `docker` e `zap` são obrigatórios para integração na branch `main`.

---

## Segurança

O workflow `Security Scan` realiza uma análise de segurança utilizando o OWASP ZAP.

O processo segue as etapas:

1. Construção da imagem Docker.
2. Inicialização da aplicação em container.
3. Verificação da disponibilidade da aplicação.
4. Validação do endpoint `/status`.
5. Execução do OWASP ZAP Baseline Scan.
6. Geração do relatório.
7. Upload do relatório como artifact do GitHub Actions.

A aplicação precisa estar disponível antes da execução do scanner.

### Readiness

O pipeline aguarda a aplicação responder em:

```text
http://localhost:3000/status
```

Somente após a aplicação estar disponível o ZAP é executado.

### Comportamento dos alertas

O Baseline Scan utiliza a opção `-I`.

Essa configuração permite que alertas classificados como warnings pelo Baseline Scan não interrompam o workflow simplesmente por terem sido encontrados.

Falhas de execução do scanner, inicialização da aplicação ou readiness continuam sendo tratadas como falhas do processo.

---

## Relatório OWASP ZAP

O relatório gerado pelo ZAP é disponibilizado como artifact do GitHub Actions.

**Relatório:**

https://github.com/MarcosJuniors/devsecops-lacrei/actions/runs/35059173986/artifacts/10431972093

O histórico das execuções pode ser consultado em:

https://github.com/MarcosJuniors/devsecops-lacrei/actions

---

## Docker

A aplicação é executada utilizando uma imagem baseada em:

```dockerfile
FROM node:22-alpine
```

Foram aplicadas medidas de hardening no container:

* utilização de imagem Alpine;
* atualização dos pacotes `libssl3` e `libcrypto3`;
* instalação das dependências de produção com `npm ci --omit=dev`;
* atualização do npm para uma versão compatível com Node.js 22;
* execução da aplicação com o usuário não-root `node`;
* utilização de `.dockerignore`;
* exclusão das dependências de desenvolvimento da imagem final.

A aplicação não é executada como `root`.

---

## Análise de vulnerabilidades

Foram realizadas análises das dependências e da imagem Docker.

### npm audit

Resultado:

```text
found 0 vulnerabilities
```

### Docker Scout

A imagem final analisada não apresentou vulnerabilidades conhecidas nas categorias:

```text
Critical: 0
High:     0
Medium:   0
Low:      0
```

Durante a análise foram identificadas vulnerabilidades em componentes da imagem inicial. Foram realizados ajustes nas dependências e nos pacotes do sistema, seguida de uma nova construção e análise da imagem.

---

## Secrets

O GitHub Actions utiliza os seguintes Secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
RENDER_DEPLOY_HOOK
```

Os valores dos Secrets não fazem parte do código-fonte ou da documentação pública.

Eles são utilizados pelos workflows somente nas etapas que necessitam de autenticação.

---

## Deploy

O deploy da aplicação é realizado no Render.

Serviço:

```text
devsecops-lacrei
```

Health check:

```text
/status
```

Após o merge na `main`, o pipeline publica a imagem Docker e aciona o deploy no Render.

O deploy foi validado em produção.

### Aplicação

https://devsecops-lacrei-latest.onrender.com/

### Health check

https://devsecops-lacrei-latest.onrender.com/status

Resposta esperada:

```json
{
  "status": "ok"
}
```

---

## Proteção da branch `main`

A branch `main` possui regras de proteção para evitar alterações diretas e operações destrutivas.

As regras configuradas são:

* Pull Request obrigatório antes do merge;
* checks `test`, `docker` e `zap` obrigatórios;
* bloqueio de force push;
* restrição de exclusão da branch `main`.

Fluxo utilizado:

```text
Branch de trabalho
       ↓
Pull Request
       ↓
test + docker + zap
       ↓
Merge
       ↓
main
```

Como o repositório é mantido individualmente, não foi configurada aprovação obrigatória de outro mantenedor. A revisão ocorre por meio do Pull Request e das verificações automatizadas obrigatórias.

---

## Rollback

As imagens são publicadas utilizando o SHA do commit, permitindo identificar versões específicas da aplicação.

Em caso de falha após um deploy, o procedimento de rollback é:

1. Identificar o SHA da última versão conhecida como funcional.
2. Localizar a imagem correspondente no Docker Hub.
3. Configurar o serviço do Render para utilizar a imagem anterior.
4. Realizar o deploy da versão anterior.
5. Verificar o endpoint `/status`.
6. Conferir os logs da aplicação.
7. Registrar a causa da falha antes de uma nova implantação.

### Critérios para rollback

O rollback pode ser realizado quando ocorrer, por exemplo:

* falha no health check;
* indisponibilidade da aplicação;
* erro crítico após o deploy;
* falha na inicialização do container;
* comportamento inesperado que comprometa a aplicação.

### Validação após rollback

Após o rollback devem ser verificados:

* status do deploy no Render;
* endpoint `/status`;
* logs da aplicação;
* disponibilidade da aplicação.

---

## Execução local

### Pré-requisitos

* Node.js 22+
* npm
* Docker, caso queira executar a aplicação em container

### Instalação

```bash
npm ci
```

### Testes

```bash
npm test
```

### Execução

```bash
npm start
```

A aplicação será disponibilizada na porta `3000`.

Health check local:

```text
http://localhost:3000/status
```

---

## Execução com Docker

Construir a imagem:

```bash
docker build -t devsecops-lacrei .
```

Executar:

```bash
docker run -p 3000:3000 devsecops-lacrei
```

Health check:

```text
http://localhost:3000/status
```

---

## Evidências

### GitHub Actions

Os workflows foram executados com sucesso, incluindo:

* `test`;
* `docker`;
* `zap`.

Histórico:

https://github.com/MarcosJuniors/devsecops-lacrei/actions

### OWASP ZAP

Relatório:

https://github.com/MarcosJuniors/devsecops-lacrei/actions/runs/35059173986/artifacts/10431972093

### Produção

Aplicação:

https://devsecops-lacrei-latest.onrender.com/

Health check:

https://devsecops-lacrei-latest.onrender.com/status

---

## Decisões técnicas

### SHA para identificação das imagens

A utilização do SHA permite rastrear uma imagem até o commit responsável pela sua construção e facilita rollback.

### Container não-root

A aplicação utiliza o usuário `node`, reduzindo os privilégios disponíveis dentro do container.

### Dependências de produção

A imagem final utiliza:

```bash
npm ci --omit=dev
```

reduzindo componentes desnecessários no ambiente de execução.

### Readiness antes do ZAP

O pipeline verifica `/status` antes do scanner para garantir que a aplicação esteja disponível.

### Separação dos workflows

CI e Security Scan possuem responsabilidades distintas, facilitando a identificação de falhas durante o processo.

---

## Estrutura do projeto

```text
devsecops-lacrei/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── security.yml
├── src/
├── Dockerfile
├── .dockerignore
├── render.yaml
├── package.json
├── package-lock.json
└── README.md
```

---

## Documentação completa

A documentação detalhada do desafio está disponível no Notion:

**https://cord-aerosteon-cfb.notion.site/3dedf9f11e1180c9b9a4f0dbca97bab2**

Ela contém informações adicionais sobre:

* arquitetura DevSecOps;
* CI/CD;
* segurança;
* OWASP ZAP;
* Docker;
* análise de vulnerabilidades;
* deploy;
* proteção da `main`;
* rollback;
* Secrets;
* evidências;
* decisões técnicas.

---

## Status do projeto

**Concluído e pronto para entrega.**
