#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variáveis de configuração
LARADOCK_REPO="https://github.com/Laradock/laradock.git"
PROJECT_NAME="igreja-sistema"
DB_NAME="igreja_dev"
DB_USER="igreja_user"
DB_PASS="igreja_pass"
PHP_VERSION="8.2"
POSTGRES_VERSION="14"
WORKSPACE_DIR=$(pwd)
PHP_EXTENSIONS="php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-mbstring php$PHP_VERSION-pgsql php$PHP_VERSION-xml php$PHP_VERSION-zip php$PHP_VERSION-bcmath php$PHP_VERSION-intl php$PHP_VERSION-gd php$PHP_VERSION-fpm"

# Função para log
log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Instalação do Git
install_git() {
    info "Instalando Git..."
    sudo apt-get update
    sudo apt-get install -y git
    info "Git instalado."
}

# Instalação do Composer
install_composer() {
    info "Instalando Composer..."
    
    # Instala dependências necessárias
    sudo apt-get update
    sudo apt-get install -y php-cli unzip
    
    # Baixa o instalador do Composer
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    
    # Verifica o hash do instalador
    HASH="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    
    # Instala o Composer globalmente
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    
    # Remove o instalador
    php -r "unlink('composer-setup.php');"
    
    info "Composer instalado."
}

# Instalação do PHP e extensões
install_php() {
    info "Instalando PHP $PHP_VERSION e extensões necessárias..."
    
    # Adiciona repositório do PHP
    sudo apt-get update
    sudo apt-get install -y lsb-release apt-transport-https ca-certificates curl
    sudo curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
    
    # Instala PHP e extensões
    sudo apt-get update
    sudo apt-get install -y $PHP_EXTENSIONS
    
    info "PHP $PHP_VERSION e extensões instalados."
}

# Instalação do Nginx
install_nginx() {
    info "Instalando Nginx..."
    
    sudo apt-get update
    sudo apt-get install -y nginx
    
    # Habilita e inicia o Nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    
    info "Nginx instalado."
}

# Instalação do PostgreSQL
install_postgresql() {
    info "Instalando PostgreSQL $POSTGRES_VERSION..."
    
    # Adiciona repositório do PostgreSQL
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    
    sudo apt-get update
    sudo apt-get install -y postgresql-$POSTGRES_VERSION postgresql-contrib
    
    # Habilita e inicia o PostgreSQL
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    info "PostgreSQL $POSTGRES_VERSION instalado."
}

# Verifica e instala requisitos
check_and_install_requirements() {
    log "Verificando requisitos do sistema..."
    
    # Verifica se é Debian 12
    if ! grep -q "Debian GNU/Linux 12" /etc/os-release; then
        error "Este script é específico para Debian 12. Por favor, use a versão correta do sistema operacional."
    fi
    
    # Verifica wget
    if ! command -v wget &> /dev/null; then
        warning "wget não encontrado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y wget
        info "wget instalado."
    else
        info "wget já está instalado."
    fi
    
    # Verifica PHP
    if ! command -v php &> /dev/null; then
        warning "PHP não encontrado. Instalando..."
        install_php
    else
        installed_version=$(php -v | head -n1 | cut -d" " -f2 | cut -d"." -f1-2)
        if [ "$installed_version" != "$PHP_VERSION" ]; then
            warning "Versão do PHP incorreta. Instalando PHP $PHP_VERSION..."
            install_php
        else
            info "PHP $PHP_VERSION já está instalado."
        fi
    fi
    
    # Verifica Nginx
    if ! command -v nginx &> /dev/null; then
        warning "Nginx não encontrado. Instalando..."
        install_nginx
    else
        info "Nginx já está instalado."
    fi
    
    # Verifica PostgreSQL
    if ! command -v psql &> /dev/null; then
        warning "PostgreSQL não encontrado. Instalando..."
        install_postgresql
    else
        info "PostgreSQL já está instalado."
    fi
    
    # Verifica Docker
    if ! command -v docker &> /dev/null; then
        warning "Docker não encontrado. Instalando..."
        install_docker
    else
        info "Docker já está instalado."
    fi
    
    # Verifica Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        warning "Docker Compose não encontrado. Instalando..."
        install_docker_compose
    else
        info "Docker Compose já está instalado."
    fi
    
    # Verifica Git
    if ! command -v git &> /dev/null; then
        warning "Git não encontrado. Instalando..."
        install_git
    else
        info "Git já está instalado."
    fi
    
    # Verifica Composer
    if ! command -v composer &> /dev/null; then
        warning "Composer não encontrado. Instalando..."
        install_composer
    else
        info "Composer já está instalado."
    fi
    
    log "✓ Todos os requisitos verificados."
}

# Instalação do Docker
install_docker() {
    info "Instalando Docker no Debian 12..."
    
    # Atualiza o sistema e instala dependências
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    # Adiciona a chave GPG oficial do Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Configura o repositório do Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualiza o apt e instala o Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Adiciona o usuário atual ao grupo docker
    sudo usermod -aG docker $USER
    
    info "Docker instalado. Você precisará fazer logout e login novamente para usar o Docker sem sudo."
}

# Instalação do Docker Compose
install_docker_compose() {
    info "Instalando Docker Compose..."
    
    # Instala o Docker Compose via apt
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    
    # Cria um alias para compatibilidade
    echo 'alias docker-compose="docker compose"' >> ~/.bashrc
    source ~/.bashrc
    
    info "Docker Compose instalado."
}

# Configura as variáveis de ambiente
setup_env() {
    log "Configurando variáveis de ambiente..."
    
    if [ ! -f .env.example ]; then
        error "Arquivo .env.example não encontrado. Verifique se você está no diretório correto do projeto."
    fi
    
    if [ ! -f .env ]; then
        cp .env.example .env
        
        # Gera APP_KEY
        APP_KEY=$(openssl rand -base64 32)
        sed -i.bak "s/APP_KEY=/APP_KEY=base64:$APP_KEY/" .env
        
        # Configura banco de dados
        sed -i.bak "s/DB_CONNECTION=.*/DB_CONNECTION=pgsql/" .env
        sed -i.bak "s/DB_HOST=.*/DB_HOST=pgsql/" .env
        sed -i.bak "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
        sed -i.bak "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
        sed -i.bak "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
        
        # Configura Redis
        sed -i.bak "s/REDIS_HOST=.*/REDIS_HOST=redis/" .env
        
        # Remove arquivos de backup
        rm -f .env.bak
        
        log "✓ Arquivo .env configurado"
    else
        warning "Arquivo .env já existe. Mantendo configuração atual."
    fi
}

# Clona e configura Laradock
setup_laradock() {
    log "Configurando Laradock..."
    
    if [ ! -d "laradock" ]; then
        git clone $LARADOCK_REPO
        cd laradock || error "Falha ao acessar diretório laradock"
        
        if [ ! -f env-example ]; then
            error "Arquivo env-example não encontrado em laradock. Verifique o repositório Laradock."
        fi
        
        cp env-example .env
        
        # Configura Laradock
        sed -i.bak "s/PHP_VERSION=.*/PHP_VERSION=$PHP_VERSION/" .env
        sed -i.bak "s/POSTGRES_VERSION=.*/POSTGRES_VERSION=$POSTGRES_VERSION/" .env
        sed -i.bak "s/POSTGRES_DB=.*/POSTGRES_DB=$DB_NAME/" .env
        sed -i.bak "s/POSTGRES_USER=.*/POSTGRES_USER=$DB_USER/" .env
        sed -i.bak "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$DB_PASS/" .env
        
        # Remove arquivos de backup
        rm -f .env.bak
        
        # Retorna ao diretório original
        cd "$WORKSPACE_DIR" || error "Falha ao retornar ao diretório de trabalho"
        
        log "✓ Laradock configurado"
    else
        warning "Diretório laradock já existe. Verificando configuração..."
        
        # Verifica se o arquivo .env existe
        if [ ! -f "laradock/.env" ]; then
            cd laradock || error "Falha ao acessar diretório laradock"
            cp env-example .env
            
            # Configura Laradock
            sed -i.bak "s/PHP_VERSION=.*/PHP_VERSION=$PHP_VERSION/" .env
            sed -i.bak "s/POSTGRES_VERSION=.*/POSTGRES_VERSION=$POSTGRES_VERSION/" .env
            sed -i.bak "s/POSTGRES_DB=.*/POSTGRES_DB=$DB_NAME/" .env
            sed -i.bak "s/POSTGRES_USER=.*/POSTGRES_USER=$DB_USER/" .env
            sed -i.bak "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$DB_PASS/" .env
            
            # Remove arquivos de backup
            rm -f .env.bak
            
            # Retorna ao diretório original
            cd "$WORKSPACE_DIR" || error "Falha ao retornar ao diretório de trabalho"
            
            log "✓ Laradock configurado"
        else
            warning "Arquivo .env já existe em laradock. Mantendo configuração atual."
        fi
    fi
}

# Verifica se os containers estão prontos
wait_for_containers() {
    local max_attempts=30
    local attempts=0
    local service=$1
    
    log "Aguardando o serviço $service ficar disponível..."
    
    while [ $attempts -lt $max_attempts ]; do
        if docker-compose ps | grep -q "$service.*running"; then
            log "✓ Serviço $service está pronto"
            return 0
        fi
        attempts=$((attempts+1))
        info "Tentativa $attempts de $max_attempts. Aguardando..."
        sleep 3
    done
    
    error "Tempo limite excedido aguardando pelo serviço $service"
    return 1
}

# Inicia containers
start_containers() {
    log "Iniciando containers..."
    
    # Navega para o diretório laradock
    cd laradock || error "Falha ao acessar diretório laradock"
    
    # Inicia os containers
    docker-compose up -d nginx postgres redis workspace
    
    # Verifica status dos containers
    if [ $? -ne 0 ]; then
        error "Falha ao iniciar os containers. Verifique os logs do Docker."
    fi
    
    # Aguarda os serviços ficarem disponíveis
    wait_for_containers "postgres"
    wait_for_containers "redis"
    wait_for_containers "nginx"
    wait_for_containers "workspace"
    
    # Retorna ao diretório original
    cd "$WORKSPACE_DIR" || error "Falha ao retornar ao diretório de trabalho"
    
    log "✓ Containers iniciados com sucesso"
}

# Executa comando no workspace e verifica resultado
execute_in_workspace() {
    local command=$1
    local description=$2
    
    log "Executando: $description..."
    
    cd laradock || error "Falha ao acessar diretório laradock"
    
    docker-compose exec -T workspace bash -c "$command"
    
    if [ $? -ne 0 ]; then
        error "Falha ao executar: $description. Verifique os logs para mais detalhes."
    fi
    
    cd "$WORKSPACE_DIR" || error "Falha ao retornar ao diretório de trabalho"
    
    log "✓ $description concluído com sucesso"
}

# Instala dependências do projeto
setup_project() {
    log "Configurando projeto..."
    
    # Instala dependências do Composer
    execute_in_workspace "composer install" "Instalação de dependências do Composer"
    
    # Gera a chave do aplicativo
    execute_in_workspace "php artisan key:generate --no-interaction" "Geração da chave do aplicativo"
    
    # Executa as migrações
    execute_in_workspace "php artisan migrate --force" "Execução das migrações"
    
    # Cria link simbólico para armazenamento
    execute_in_workspace "php artisan storage:link" "Criação de link simbólico para armazenamento"
    
    # Instala dependências do npm
    execute_in_workspace "npm install" "Instalação de dependências do npm"
    
    # Compila assets
    execute_in_workspace "npm run dev" "Compilação de assets"
    
    log "✓ Projeto configurado com sucesso"
}

# Configura Git Hooks
setup_git_hooks() {
    log "Configurando Git Hooks..."
    
    # Verifica se o diretório .git existe
    if [ ! -d ".git" ]; then
        warning "Diretório .git não encontrado. Inicializando repositório Git..."
        git init
    fi
    
    # Cria diretório de hooks se não existir
    mkdir -p .git/hooks
    
    # Cria pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "Executando verificações de pré-commit..."

# Salva diretório atual
CURRENT_DIR=$(pwd)

# Navega para diretório laradock
cd laradock || { echo "Erro: Diretório laradock não encontrado"; exit 1; }

# Verifica se os containers estão rodando
if ! docker-compose ps | grep -q "workspace.*running"; then
    echo "Erro: Container workspace não está rodando. Inicie os containers primeiro."
    exit 1
fi

# Executa análise estática
echo "Executando PHPStan..."
docker-compose exec -T workspace bash -c "./vendor/bin/phpstan analyse"
if [ $? -ne 0 ]; then
    echo "Erro: PHPStan falhou. Corrija os erros antes de commitar."
    exit 1
fi

# Verifica formatação de código
echo "Verificando formatação de código com Laravel Pint..."
docker-compose exec -T workspace bash -c "./vendor/bin/pint --test"
if [ $? -ne 0 ]; then
    echo "Erro: Formatação de código não está correta. Execute 'vendor/bin/pint' para corrigir."
    exit 1
fi

# Executa testes
echo "Executando testes..."
docker-compose exec -T workspace bash -c "php artisan test"
if [ $? -ne 0 ]; then
    echo "Erro: Testes falharam. Corrija os testes antes de commitar."
    exit 1
fi

# Retorna ao diretório original
cd "$CURRENT_DIR"

echo "Todas as verificações passaram com sucesso!"
exit 0
EOF
    
    # Torna o hook executável
    chmod +x .git/hooks/pre-commit
    
    log "✓ Git hooks configurados com sucesso"
}

# Configura cursor.ai
setup_cursor() {
    log "Configurando cursor.ai..."
    
    # Cria diretório .cursor se não existir
    mkdir -p .cursor
    
    # Cria settings.json para cursor.ai
    cat > .cursor/settings.json << EOF
{
    "editor.formatOnSave": true,
    "php.validate.executablePath": "/usr/local/bin/php",
    "php.suggest.basic": false,
    "docker.enabled": true,
    "intelephense.environment.phpVersion": "$PHP_VERSION",
    "laravel.enabled": true,
    "laravel.format.enable": true,
    "files.associations": {
        "*.php": "php",
        ".env": "dotenv",
        "docker-compose.yml": "dockercompose"
    }
}
EOF
    
    # Cria arquivo de workspace do cursor.ai
    cat > $PROJECT_NAME.code-workspace << EOF
{
    "folders": [
        {
            "path": "."
        }
    ],
    "settings": {
        "git.enableSmartCommit": true,
        "git.autofetch": true,
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.fixAll": true
        }
    },
    "extensions": {
        "recommendations": [
            "intelephense",
            "docker",
            "dotenv",
            "laravel",
            "git-extension-pack"
        ]
    }
}
EOF
    
    log "✓ cursor.ai configurado com sucesso"
}

# Verifica projeto Laravel
check_laravel_project() {
    log "Verificando projeto Laravel..."
    
    # Cria e configura diretório do projeto
    sudo mkdir -p /var/www/html
    sudo chown -R $USER:$USER /var/www/html
    
    # Navega para o diretório do projeto
    cd /var/www/html || error "Falha ao acessar diretório /var/www/html"
    
    # Atualiza WORKSPACE_DIR
    WORKSPACE_DIR="/var/www/html"
    
    # Verifica se o arquivo composer.json existe
    if [ ! -f "composer.json" ]; then
        warning "Arquivo composer.json não encontrado. Criando novo projeto Laravel..."
        
        # Cria novo projeto Laravel
        composer create-project --prefer-dist laravel/laravel .
        
        if [ $? -ne 0 ]; then
            error "Falha ao criar projeto Laravel. Verifique se o Composer está instalado."
        fi
        
        # Configura permissões
        sudo chown -R $USER:www-data .
        sudo find . -type f -exec chmod 664 {} \;
        sudo find . -type d -exec chmod 775 {} \;
        sudo chmod 777 storage bootstrap/cache
        
        log "✓ Novo projeto Laravel criado"
    else
        # Verifica se é um projeto Laravel
        if ! grep -q "laravel/framework" composer.json; then
            warning "Este não parece ser um projeto Laravel. Verifique se você está no diretório correto."
            read -p "Deseja continuar mesmo assim? (S/n): " CONTINUE
            if [[ "$CONTINUE" == "n" || "$CONTINUE" == "N" ]]; then
                error "Instalação cancelada."
            fi
        else
            info "Projeto Laravel detectado."
            
            # Atualiza permissões do projeto existente
            sudo chown -R $USER:www-data .
            sudo find . -type f -exec chmod 664 {} \;
            sudo find . -type d -exec chmod 775 {} \;
            sudo chmod 777 storage bootstrap/cache
        fi
    fi
}

# Exibe informações sobre o ambiente
show_info() {
    log "Resumo do ambiente configurado:"
    
    echo ""
    echo -e "${BLUE}[INFO]${NC} Projeto: $PROJECT_NAME"
    echo -e "${BLUE}[INFO]${NC} PHP: $PHP_VERSION"
    echo -e "${BLUE}[INFO]${NC} PostgreSQL: $POSTGRES_VERSION"
    echo -e "${BLUE}[INFO]${NC} Banco de dados: $DB_NAME"
    echo -e "${BLUE}[INFO]${NC} Usuário BD: $DB_USER"
    
    # Verifica URL local
    cd laradock || error "Falha ao acessar diretório laradock"
    CONTAINER_ID=$(docker-compose ps -q nginx)
    cd "$WORKSPACE_DIR" || error "Falha ao retornar ao diretório de trabalho"
    
    if [ -n "$CONTAINER_ID" ]; then
        echo -e "${BLUE}[INFO]${NC} URL Local: http://localhost"
    fi
    
    echo ""
    log "Para acessar o container workspace:"
    echo -e "   cd laradock && docker-compose exec workspace bash"
    echo ""
}

# Limpeza em caso de erro
cleanup() {
    log "Limpando ambiente após erro..."
    
    # Restaura diretório de trabalho
    cd "$WORKSPACE_DIR" 2>/dev/null
    
    # Remove arquivos temporários
    rm -f .env.bak
    
    log "Limpeza concluída. Verifique os logs para identificar o problema."
}

# Define trap para limpeza em caso de erro
trap cleanup EXIT

# Função principal
main() {
    log "Iniciando setup do ambiente de desenvolvimento no Debian 12..."
    
    check_and_install_requirements
    check_laravel_project
    setup_env
    setup_laradock
    start_containers
    setup_project
    setup_git_hooks
    setup_cursor
    show_info
    
    log "✓ Setup concluído com sucesso!"
    log "IMPORTANTE: Se você acabou de instalar o Docker, faça logout e login novamente"
    log "            para que as permissões do grupo docker sejam aplicadas."
    log "Para iniciar o desenvolvimento:"
    log "1. Faça logout e login novamente (se necessário)"
    log "2. Execute 'docker ps' para verificar se tem acesso ao Docker"
    log "3. O ambiente está pronto para uso!"
    
    # Desativa trap
    trap - EXIT
}

# Executa função principal
main
