# RabbitMQ Multi-Cluster Deployment on Kubernetes

## Introdução

Este projeto fornece uma solução automatizada para o deployment de clusters RabbitMQ em ambientes Kubernetes distribuídos. Ele é projetado para facilitar a configuração e gerenciamento de uma infraestrutura de mensageria robusta e escalável em múltiplas regiões da AWS, utilizando as melhores práticas de segurança e alta disponibilidade.

## Descrição do Projeto

O projeto automatiza o processo de deployment de dois clusters RabbitMQ em diferentes clusters Kubernetes, localizados em regiões AWS distintas, mas na mesma conta. Esta solução abrange:

- Configuração de conexão aos clusters Kubernetes
- Instalação e configuração do RabbitMQ Operator
- Geração e gerenciamento de certificados SSL/TLS
- Deployment de Load Balancers
- Configuração do external-dns para registro de serviços
- Estabelecimento de federação entre os clusters RabbitMQ

Ideal para organizações que necessitam de uma infraestrutura de mensageria distribuída, resiliente e segura, este projeto simplifica significativamente o processo de setup e manutenção de clusters RabbitMQ em ambientes Kubernetes multi-região.

## Principais Características

- Automação completa do deployment
- Suporte para múltiplas regiões AWS
- Configuração de segurança com certificados SSL/TLS
- Integração com external-dns para gerenciamento de DNS
- Federação entre clusters para alta disponibilidade
- Scripts de backup para certificados e manifestos Kubernetes

## Requisitos
- Addon do K8s (CSI Driver) para storage persistente (EBS)
- Addon do external-dns configurado nos 2 clusters para o mesmo domínio
- Conexão de rede entre as VPC's (principalmente da porta 5671)
- Repositório S3 para cópia dos certificados e das chaves privadas / públicas
- Helm instalado
- kubectl instalado
- jq instalado

## Sumário
1 - Preparação do ambiente
2 - Certificados
3 - Cópias de segurança (backup)
4 - Kubernetes - instala operator e cluster do RabbitMQ
5 - Configuração RabbitMQ - federação e tls
### Tempo estimado: 20 minutos (Pode variar dependendo do tempo de publicação do DNS)

# 1 - Preparação do ambiente

## Cópia dos dados, ajuste de permissões e variáveis
- Copiar os arquivos do projeto
```
aws s3 sync s3://seven-deploy-rabbit-template .
```
- Ajuste permissões de execução
```
cd RabbitMQ_on_k8s/
chmod +x *.sh
chmod +x ./scripts/*.sh
```
- Edita as Variáveis de ambiente com os dados da organização
```
vi ./env_vars.sh
```
## Carrega Variaveis de ambiente
```
source ./env_vars.sh
```
## Executa o script de preparação
```
./start.sh
```

# 2 - Certificados

### Certificate Authority Certificate

#### Geração da chave
```
openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out ./certificates/authority/key.pem
```
#### Geração do Certificado
```
openssl req \
    -x509 \
    -config ./certificates/authority/openssl.cnf \
    -key ./certificates/authority/key.pem \
    -days 3650 \
    -out ./certificates/authority/crt.pem
```
#### Leitura do certificado (validação)
```
openssl x509 \
    -in ./certificates/authority/crt.pem \
    -noout \
    -text
```

### $NAMESPACE_RABBIT-$REGION01 Certificate
#### Geração da chave
```
openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out ./certificates/$NAMESPACE_RABBIT-$REGION01/key.pem
```
#### Requisição do Certificado na CA
```
openssl req \
    -new \
    -config ./certificates/$NAMESPACE_RABBIT-$REGION01/openssl.cnf \
    -key ./certificates/$NAMESPACE_RABBIT-$REGION01/key.pem \
    -out ./certificates/$NAMESPACE_RABBIT-$REGION01/req.pem
```
#### Emissão do Certificado na CA
```
openssl x509 \
    -req \
    -CA ./certificates/authority/crt.pem \
    -CAkey ./certificates/authority/key.pem \
    -CAcreateserial \
    -extfile ./certificates/$NAMESPACE_RABBIT-$REGION01/openssl.cnf \
    -extensions req_ext \
    -in ./certificates/$NAMESPACE_RABBIT-$REGION01/req.pem \
    -days 3650 \
    -out ./certificates/$NAMESPACE_RABBIT-$REGION01/crt.pem
```
#### Leitura do certificado (validação)
```
openssl x509 \
    -in ./certificates/$NAMESPACE_RABBIT-$REGION01/crt.pem \
    -noout \
    -text
```

### $NAMESPACE_RABBIT-$REGION02 Certificate
#### Geração da chave
```
openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out ./certificates/$NAMESPACE_RABBIT-$REGION02/key.pem
```
#### Requisição do Certificado na CA
```
openssl req \
    -new \
    -config ./certificates/$NAMESPACE_RABBIT-$REGION02/openssl.cnf \
    -key ./certificates/$NAMESPACE_RABBIT-$REGION02/key.pem \
    -out ./certificates/$NAMESPACE_RABBIT-$REGION02/req.pem
```
#### Emissão do Certificado na CA
```
openssl x509 \
    -req \
    -CA ./certificates/authority/crt.pem \
    -CAkey ./certificates/authority/key.pem \
    -CAcreateserial \
    -extfile ./certificates/$NAMESPACE_RABBIT-$REGION02/openssl.cnf \
    -extensions req_ext \
    -in ./certificates/$NAMESPACE_RABBIT-$REGION02/req.pem \
    -days 3650 \
    -out ./certificates/$NAMESPACE_RABBIT-$REGION02/crt.pem
```
#### Leitura do certificado (validação)
```
openssl x509 \
    -in ./certificates/$NAMESPACE_RABBIT-$REGION02/crt.pem \
    -noout \
    -text
```

# 3 - Cópia de segurança dos certificados e dos manifestos do Kubernetes

## Realiza a cópia dos arquivos do kubernetes
```
aws s3 sync ./kubernetes s3://$BUCKETBACKUP/kubernetes
```
## Realiza a cópia dos certificados

```
aws s3 sync ./certificates s3://$BUCKETBACKUP/certificates
```

# 4 - Kubernetes

## Configurar os acessos ao Kubernetes
- Suponha que você já configurou suas credenciais IAM ou está no cloudshell da AWS
- Caso não tenha configurado, digite aws configure e siga as orientações da tela

### Cluster 1
```
aws eks update-kubeconfig \
    --region $REGION01 \
    --name $K8S01
```
### Cluster 2
```
aws eks update-kubeconfig \
    --region $REGION02 \
    --name $K8S02
```

## Instalação Operator
### Cluster 1
- Cria o Namespace
```
kubectl create namespace $NAMESPACE_OPERATOR \
--context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01
```
- Instala o repositório do rabbit e instala o rabbitmq operator
```
helm repo add bitnami https://charts.bitnami.com/bitnami
kubectl config use-context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01 
helm install rabbitmq-cluster-operator bitnami/rabbitmq-cluster-operator -n $NAMESPACE_OPERATOR
```
### Cluster 2
- Cria o Namespace
```
kubectl create namespace $NAMESPACE_OPERATOR \
--context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02
```
- Instala o repositório do rabbit e instala o rabbitmq operator
```
kubectl config use-context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02
helm install rabbitmq-cluster-operator bitnami/rabbitmq-cluster-operator -n $NAMESPACE_OPERATOR
```

## Deploy do Cluster RabbitMQ
### Cluster 1
- Cria o Namespace
```
kubectl create namespace $NAMESPACE_RABBIT --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01
```
- Cria Secret dos certificados
```
kubectl create secret generic $NAMESPACE_RABBIT-$REGION01-certificate \
    --from-file ca.crt=./certificates/authority/crt.pem \
    --from-file tls.crt=./certificates/$NAMESPACE_RABBIT-$REGION01/crt.pem \
    --from-file tls.key=./certificates/$NAMESPACE_RABBIT-$REGION01/key.pem \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01
```
- Faz deploy do Cluster
```
kubectl apply \
    --filename ./kubernetes/$K8S01/$NAMESPACE_RABBIT/rabbitmqcluster.yaml \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01
```
- Deploy do Serviço
```
kubectl apply \
    --filename ./kubernetes/$K8S01/$NAMESPACE_RABBIT/service.yaml \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01
```

### Cluster 2
- Cria o Namespace
```
kubectl create namespace $NAMESPACE_RABBIT --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02
```
- Cria Secret dos certificados
```
kubectl create secret generic $NAMESPACE_RABBIT-$REGION02-certificate \
    --from-file ca.crt=./certificates/authority/crt.pem \
    --from-file tls.crt=./certificates/$NAMESPACE_RABBIT-$REGION02/crt.pem \
    --from-file tls.key=./certificates/$NAMESPACE_RABBIT-$REGION02/key.pem \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02
```
- Faz deploy do Cluster
```
kubectl apply \
    --filename ./kubernetes/$K8S02/$NAMESPACE_RABBIT/rabbitmqcluster.yaml \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02
```
- Deploy do Serviço
```
kubectl apply \
    --filename ./kubernetes/$K8S02/$NAMESPACE_RABBIT/service.yaml \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02
```

# 5 - RabbitMQ

## Configuração do RabbitMQ
### Cluster 1
- Cria senha
```
RABBITMQ_UE1_PASSWORD=`openssl rand -hex 20`
```
- Cria usuário de federação do cluster 1 no cluster 2
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02 \
    -- \
        rabbitmqctl add_user federation-$REGION01 "$RABBITMQ_UE1_PASSWORD"
```
- Define as permissões do usuário de federação
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02 \
    -- \
        rabbitmqctl set_permissions federation-$REGION01 ".*" ".*" ".*" \
            --vhost /
```
- Cria o json com os parâmetros de configuração do upstream
```
RABBITMQ_UE1_FEDERATION=`
    jq '{"uri":$RABBITMQ_UE1_URI,"expires":3600000}' \
        --null-input \
        --arg RABBITMQ_UE1_URI "amqps://federation-$REGION01:$RABBITMQ_UE1_PASSWORD@$NAMESPACE_RABBIT-$REGION02.$DOMAIN:5671?cacertfile=/etc/rabbitmq-tls/ca.crt&certfile=/etc/rabbitmq-tls/tls.crt&keyfile=/etc/rabbitmq-tls/tls.key&verify=verify_peer" \
        --compact-output
`
```
- Cria o upstream
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01 \
    -- \
        rabbitmqctl set_parameter federation-upstream $REGION02 "$RABBITMQ_UE1_FEDERATION"
```
- Define a política de replicação default
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01 \
    -- \
        rabbitmqctl set_policy federation-$REGION02 '^amq\.' '{"federation-upstream-set":"all"}' \
            --apply-to exchanges
```
- Verifica se o status está ok
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01 \
    -- \
        rabbitmqctl federation_status \
            --formatter json \
                | jq
```

### Cluster 2
- Cria senha
```
RABBITMQ_UW1_PASSWORD=`openssl rand -hex 20`
```
- Cria usuário de federação do cluster 2 no cluster 1
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01 \
    -- \
        rabbitmqctl add_user federation-$REGION02 "$RABBITMQ_UW1_PASSWORD"
```
- Define as permissões do usuário de federação
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION01:$AWS_ID:cluster/$K8S01 \
    -- \
        rabbitmqctl set_permissions federation-$REGION02 ".*" ".*" ".*" \
            --vhost /
```
- Cria o json com os parâmetros de configuração do upstream
```
RABBITMQ_UW1_FEDERATION=`
    jq '{"uri":$RABBITMQ_UW1_URI,"expires":3600000}' \
        --null-input \
        --arg RABBITMQ_UW1_URI "amqps://federation-$REGION02:$RABBITMQ_UW1_PASSWORD@$NAMESPACE_RABBIT-$REGION01.$DOMAIN:5671?cacertfile=/etc/rabbitmq-tls/ca.crt&certfile=/etc/rabbitmq-tls/tls.crt&keyfile=/etc/rabbitmq-tls/tls.key&verify=verify_peer" \
        --compact-output
`
```
- Cria o upstream
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02 \
    -- \
        rabbitmqctl set_parameter federation-upstream $REGION01 "$RABBITMQ_UW1_FEDERATION"
```
- Define a política de replicação default
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02 \
    -- \
        rabbitmqctl set_policy federation-$REGION01 '^amq\.' '{"federation-upstream-set":"all"}' \
            --apply-to exchanges
```
- Verifica se o status está ok
```
kubectl exec \
    rabbitmq-server-0 \
    --container rabbitmq \
    --namespace $NAMESPACE_RABBIT \
    --context arn:aws:eks:$REGION02:$AWS_ID:cluster/$K8S02 \
    -- \
        rabbitmqctl federation_status \
            --formatter json \
                | jq
```
# FIM!