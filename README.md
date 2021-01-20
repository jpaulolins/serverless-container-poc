# Serveless Container POC

## Introdução

O Objetivo desse repositório é realizar um teste em relação a melhor forma de
fazer um deploy usando o novo conceito de Lambda Container. A prova de conceito
foi feita tendo como base e ponto de partida o artigo de lançamento da funcionalidade da
[AWS.](https://aws.amazon.com/pt/blogs/aws/new-for-aws-lambda-container-image-support/)

## Requisitos

O principal requisito para esse estudo é manter a facilidade de deploy
e a portabilidade de código do desenvolvedor em relação a desenvolvimento no
modelo Serverless, em espacial, para utilização de Lambdas como APIs HTTP.

Além disso, também são pontos a serem considerados:

* Facilidade para desenvolvimento e teste local
* Não dependência de Frameworks externos
* Portabilidade de código e baixo acoplamento em relação ao provedor de nuvem
* Possibilidade de expandir ou migrar as funções para outras soluções de Container (Fargate, ECS, Kubernetes, Cloudrun,etc) de maneira
  simples
* Padronização e Segurança


## Possibilidades

Visando atender os requisitos citados anteriormente as principais
linhas analisadas foram as seguintes:

1. Usar a API de emulação de Lambda para simulações em DEV.
    - Informações sobre essa API. [Lambda - Runtime Interface Emulator
      AWS.](https://github.com/aws/aws-lambda-runtime-interface-emulator/)
      Teria que colocar esse emulador dentro do container apenas para testes
      em ambiente de desenvolvimento. Na ida para produção esse ponto poderia
      ser desconsiderado.

2. Em relação a chamada da função Lambda para execução tratamento de uma
   requisição HTTP. Teriamos algumas opções:

    * Ir na linha do próprio artigo de lançamento e usar uma imagem pronta da
      AWS que já vem com tudo pronto desde API de Runtime, API de Emulação
      e tudo mais que é necessário para rodar. Nesse caso é basicamente seguir
      o passos do artigo da [AWS.](https://aws.amazon.com/pt/blogs/aws/new-for-aws-lambda-container-image-support/)
      Evitei ir por essa linha pela falta de controle e pelo fato de ter que
      usar uma imagem da pronta da AWS o qual não teria tando controle em
      relação a "tudo que tem dentro". A ideia é ter padronização e segurança, para isso
      saber tudo que tem no Conteiner ou ter a possibilidade de fazer um build
      usando o conceito de
      [distrolless](https://github.com/GoogleContainerTools/distroless) foi
      o mais razoável para questões de segurança e controle desejados.


    * A outra opção seria implementar a [Runtime Extension Api do Lambda,](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-extensions-api.html)
      no modelo de proxy. Nesse caso como a ideia era resolver o problema para
      serviços HTTP, bastaria implementar um proxy que recebesse um request do
      [API Gateway da AWS ou HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html) 
      e transfira a chamada para o meu server HTTP local
      dentro do container. Eu já tinha visto algo nessa linha anteriormente
      para um framework chamado [UP](https://github.com/apex/up). Foi evitado
      ir nessa linha pois possivelmente dentro do container teriamos que
      colocar essa tradução como um binário/comando de tradução que seria executado
      a cada chamada / request e isso poderia ter um overhead maior. Na prática
      o ideal seria testar para ver as questões de performace. Ainda assim dado
      a documentação e o propósito que consegui entender do que é um Lambda
      Extension / Layer esse pelo menos me

    * Por fim o conceito que me pareceu mais interessante foi o do [Lambda
      Layers / Extensions.](https://aws.amazon.com/blogs/compute/working-with-lambda-layers-and-extensions-in-container-images/) 
      Lendo a documentação e comparando com o propósito do que estava sendo
      requisitado essa opção parecia atender ou facilitar alcançar rapidamente 
      os requisitos enumerado anteriormente inclusive a criação de uma imagem 
      própria com tudo que era necessario para rodar a solução. 
      [Documentação sobre Lambda e criação de imagens](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms)


3. Para parte de emulação e testes locais
    * A documentação que fala de testes locais de Lambda em conteiners e foi
      fundamental para conseguir realizar os testes encontra-se [aqui.](https://docs.aws.amazon.com/lambda/latest/dg/images-test.html)

## Arquitetura da solução

A figura abaixo mostra de maneira macro o funcionamento da Execução de um
ambiente Lambda para os casos de Extensions API e Runtime API. 
![Lambda Execution
Enviroment](https://d2908q01vomqb2.cloudfront.net/1b6453892473a467d07372d45eb05abc2031647a/2020/10/07/1-AWS-Lambda-execution-environment-with-the-Extensions-API.png)

Uma figura que mostra em detalhes como o ambiente de Extensions funciona está
logo abaixo:

![Lambda
Extension](https://docs.aws.amazon.com/lambda/latest/dg/images/Overview-Full-Sequence.png)

Para um melhor entendimento de como a extensions do Lambda funciona
recomenda-se a leitura dos seguintes artigos:

1. [Introducing AWS Lambda Extensions](https://aws.amazon.com/blogs/compute/introducing-aws-lambda-extensions-in-preview/)
2. [Runtime API](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-extensions-api.html)
3. [Building Extension for AWS](https://aws.amazon.com/blogs/compute/building-extensions-for-aws-lambda-in-preview/)

## Executando a solução

Como dito a ideia inicial seria partir para o desenvolvimento de uma Extensão Lambda que
pudesse ser colocada dentro do container e magicamente fazer a tradução de um
request vindo do API Gateway ([Lambda proxy integrations](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-create-api-as-simple-proxy)) da AWS para o server HTTP local. 

Para minha sorte acabei achando um repositório no [Github](https://github.com/glassechidna/serverlessish) com o pessoal que fez exatamente o que eu queria fazer. Com isso, busquei apenas criar um repositório que já use essa extensão e documentar o processo, uma vez que a documentação lá não é tão legal.

### Dev

Abaixo  é possível ver um docker file que foi criado para o ambiente de DEV

```dockerfile

FROM golang:1.15 AS build
WORKDIR /example
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w"

FROM public.ecr.aws/c2t6n2x5/serverlessish:2 AS s

FROM alpine

RUN apk add --no-cache bash

ADD
https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie
/usr/bin/aws-lambda-rie

RUN chmod 755 /usr/bin/aws-lambda-rie
COPY entry.sh /
RUN chmod 755 /entry.sh

COPY --from=s /opt/extensions/serverlessish /opt/extensions/serverlessish
COPY --from=build /example/example /example

ENV PORT=8081

ENTRYPOINT ["/entry.sh"]

```

No caso ambiente de DEV foi criado um container do alpine para se instalar um
Bash e desta forma conseguir fazer algum teste / depuração.



### Produção

Para o ambiente de produção basta fazer o buid da imagem seguindo o arquivo `Dockerfile-PROD`.

Observe que nesse caso está sendo usado o conceito de Distroless e foram
removidos a parte de emulação. Com isso basta apenas .... e pronto.


