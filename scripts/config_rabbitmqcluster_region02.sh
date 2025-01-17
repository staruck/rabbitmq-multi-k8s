#!/bin/bash
# Verifica se as variáveis de ambiente necessárias estão definidas
if [ -z "$$NAMESPACE_RABBIT" ] || [ -z "$REGION02" ]; then
    echo "Erro: As variáveis de ambiente NAMESPACE e REGION devem estar definidas."
    exit 1
fi

FILE_NAME="./models/rabbitmqcluster.yaml"
NEW_FILE_NAME="./kubernetes/${K8S02}/${NAMESPACE_RABBIT}/rabbitmqcluster.yaml"

# Copia o arquivo para o novo local
cp "$FILE_NAME" "$NEW_FILE_NAME"

# Atualiza o namespace
sed -i "s/namespace: rabbitmq/namespace: $NAMESPACE_RABBIT/" $NEW_FILE_NAME

# Atualiza secretName e caSecretName
NEW_SECRET_NAME="${NAMESPACE_RABBIT}-${REGION02}-certificate"
sed -i "s/secretName: .*/secretName: $NEW_SECRET_NAME/" $NEW_FILE_NAME
sed -i "s/caSecretName: .*/caSecretName: $NEW_SECRET_NAME/" $NEW_FILE_NAME

echo "Arquivo $NEW_FILE_NAME atualizado com sucesso!"
echo "Novo namespace: $NAMESPACE_RABBIT"
echo "Novo secretName e caSecretName: $NEW_SECRET_NAME"