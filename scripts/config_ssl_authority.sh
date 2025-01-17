#!/bin/bash

# Verifica se ORG_NAME está definido
if [ -z "$ORG_NAME" ]; then
    echo "Erro: A variável ORG_NAME não está definida."
    exit 1
fi

# Nome do arquivo de configuração
CONFIG_FILE="./models/openssl_authority.cnf"
NEW_CONFIG_FILE="./certificates/authority/openssl.cnf"

# Copia o arquivo para o novo local
cp "$CONFIG_FILE" "$NEW_CONFIG_FILE"

# Substitui o valor de organizationName
sed -i "s/organizationName = .*/organizationName = $ORG_NAME/" "$NEW_CONFIG_FILE"

echo "Arquivo $NEW_CONFIG_FILE atualizado com sucesso."