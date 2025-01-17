#!/bin/bash
# Verifica se as variáveis de ambiente necessárias estão definidas
if [ -z "$ORG_NAME" ] || [ -z "$NAMESPACE_RABBIT" ] || [ -z "$REGION01" ] || [ -z "$DOMAIN" ]; then
    echo "Erro: Uma ou mais variáveis de ambiente necessárias não estão definidas."
    exit 1
fi

# Constrói o commonName concatenando as variáveis
COMMON_NAME="${NAMESPACE_RABBIT}-${REGION01}.${DOMAIN}"

# Define o arquivo de configuração original e o novo local
CONFIG_FILE="./models/openssl.cnf"
NEW_CONFIG_FILE="./certificates/${NAMESPACE_RABBIT}-${REGION01}/openssl.cnf"

# Copia o arquivo para o novo local
cp "$CONFIG_FILE" "$NEW_CONFIG_FILE"

# Substitui os valores no novo arquivo de configuração
sed -i "s/organizationName = .*/organizationName = $ORG_NAME/" "$NEW_CONFIG_FILE"
sed -i "s/commonName       = .*/commonName       = $COMMON_NAME/" "$NEW_CONFIG_FILE"
sed -i "s/DNS.1 = .*/DNS.1 = $COMMON_NAME/" "$NEW_CONFIG_FILE"

echo "Configuração atualizada com sucesso no novo local: $NEW_CONFIG_FILE"