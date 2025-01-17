#!/bin/bash
# Verifica se as variáveis de ambiente necessárias estão definidas
if [ -z "$NAMESPACE_RABBIT" ] || [ -z "$REGION02" ] || [ -z "$DOMAIN" ]; then
    echo "Erro: As variáveis de ambiente NAMESPACE, REGION e DOMAIN devem estar definidas."
    exit 1
fi

FILE_NAME="./models/service.yaml"
NEW_FILE_NAME="./kubernetes/${K8S02}/${NAMESPACE_RABBIT}/service.yaml"

# Copia o arquivo para o novo local
cp "$FILE_NAME" "$NEW_FILE_NAME"

# Cria o novo valor para external-dns
NEW_HOSTNAME="${NAMESPACE_RABBIT}-${REGION02}.${DOMAIN}"

# Atualiza o valor de external-dns e namespace no arquivo
sed -i "s/namespace: rabbitmq/namespace: $NAMESPACE_RABBIT/" $NEW_FILE_NAME
sed -i "s|external-dns.alpha.kubernetes.io/hostname: .*|external-dns.alpha.kubernetes.io/hostname: $NEW_HOSTNAME|" $NEW_FILE_NAME

echo "Arquivo $NEW_FILE_NAME atualizado com sucesso!"
echo "Novo valor de external-dns: $NEW_HOSTNAME"