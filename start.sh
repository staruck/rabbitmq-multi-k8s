#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir o logo da AWS e 7inCloud
show_logo() {
    clear
    echo -e "${YELLOW}
 $$$$$$$\            $$\       $$\       $$\   $$\           $$\      $$\  $$$$$$\  
 $$  __$$\           $$ |      $$ |      \__|  $$ |          $$$\    $$$ |$$  __$$\ 
 $$ |  $$ | $$$$$$\  $$$$$$$\  $$$$$$$\  $$\ $$$$$$\         $$$$\  $$$$ |$$ /  $$ |
 $$$$$$$  | \____$$\ $$  __$$\ $$  __$$\ $$ |\_$$  _|        $$\$$\$$ $$ |$$ |  $$ |
 $$  __$$<  $$$$$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |          $$ \$$$  $$ |$$ |  $$ |
 $$ |  $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$\       $$ |\$  /$$ |$$ $$\$$ |
 $$ |  $$ |\$$$$$$$ |$$$$$$$  |$$$$$$$  |$$ |  \$$$$  |      $$ | \_/ $$ |\$$$$$$ / 
 \__|  \__| \_______|\_______/ \_______/ \__|   \____/       \__|     \__| \___$$$\ 
                                                                               \___|
${NC}${BLUE}
 _  __     _                          _            
| |/ /    | |                        | |           
| ' /_   _| |__   ___ _ __ _ __   ___| |_ ___  ___ 
|  <| | | | '_ \ / _ \ '__| '_ \ / _ \ __/ _ \/ __|
| . \ |_| | |_) |  __/ |  | | | |  __/ ||  __/\__ \
|_|\_\__,_|_.__/ \___|_|  |_| |_|\___|\__\___||___/
${NC}
${RED}https://7incloud.com ${NC}"
    echo
}

# Função para criar uma animação de carregamento
loading_animation() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${YELLOW}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Função para executar um script
run_script() {
    local script=$1
    echo -e "${GREEN}Executando $script...${NC}"
    ./$script &
    loading_animation $!
    sleep 2
    show_logo
}

# Função para exibir uma mensagem e pausar
pause_execution() {
    echo -e "${YELLOW}$1${NC}"
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
    echo
    echo
}

# Execução dos scripts
show_logo

run_script ./scripts/create_dirs.sh
pause_execution "Diretórios criados."

run_script ./scripts/config_ssl_region01.sh
pause_execution "Configuração SSL da Região 01 concluída."

run_script ./scripts/config_ssl_region02.sh
pause_execution "Configuração SSL da Região 02 concluída."

run_script ./scripts/config_ssl_authority.sh
pause_execution "Configuração da autoridade SSL concluída."

run_script ./scripts/config_rabbitmqcluster_region01.sh
pause_execution "Configuração do cluster RabbitMQ da Região 01 concluída."

run_script ./scripts/config_rabbitmqcluster_region02.sh
pause_execution "Configuração do cluster RabbitMQ da Região 02 concluída."

run_script ./scripts/config_service_region01.sh
pause_execution "Configuração do serviço da Região 01 concluída."

run_script ./scripts/config_service_region02.sh
pause_execution "Configuração do serviço da Região 02 concluída."

echo -e "${GREEN}Todos os scripts foram executados com sucesso!${NC}"
echo
