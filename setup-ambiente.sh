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

# Verifica e instala requisitos
check_and_install_requirements() {
    log "Verificando requisitos do sistema..."
    
    # Verifica Docker
    if ! command -v docker &> /dev/null; then
        warning "Docker não encontrado. Tentando instalar..."
        install_docker
    else
        info "Docker já está instalado."
    fi
    
    # Verifica Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        warning "Docker Compose não encontrado. Tentando instalar..."
        install_docker_compose
    else
        info "Docker Compose já está instalado."
    fi
    
    # Verifica Git
    if ! command -v git &> /dev/null; then
        warning "Git não encontrado. Tentando instalar..."
        install_git
    else
        info "Git já está instalado."
    fi

    # Verifica cursor.ai
    if ! command -v cursor &> /dev/null; then
        warning "cursor.ai não encontrado. Você pode instalar em https://cursor.sh"
        read -p "Deseja continuar sem o cursor.ai? (S/n): " CONTINUE
        if [[ "$CONTINUE" == "n" || "$CONTINUE" == "N" ]]; then
            error "Instalação cancelada. Por favor, instale o cursor.ai e execute o script novamente."
        fi
    else
        info "cursor.ai já está instalado."
    fi
    
    log "✓ Todos os requisitos atendidos ou ignorados."
}

# Instalação do Docker
install_docker() {
    info "Instalando Docker..."
    
    # Detecta o sistema operacional
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Para sistemas baseados em Debian/Ubuntu
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo usermod -aG docker $USER
            info "Docker instalado. Você pode precisar reiniciar seu terminal para usar o Docker sem sudo."
        
        # Para sistemas baseados em Red Hat/CentOS
        elif command -v yum &> /dev/null; then
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            info "Docker instalado. Você pode precisar reiniciar seu terminal para usar o Docker sem sudo."
        else
            error "Não foi possível determinar o gerenciador de pacotes. Por favor, instale o Docker manualmente."
        fi
    
    # Para macOS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        warning "Para macOS, recomendamos instalar o Docker Desktop a partir de https://www.docker.com/products/docker-desktop"
        error "Por favor, instale o Docker Desktop e execute o script novamente."
    
    # Para Windows
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        warning "Para Windows, recomendamos instalar o Docker Desktop a partir de https://www.docker.com/products/docker-desktop"
        error "Por favor, instale o Docker Desktop e execute o script novamente."
    
    else
        error "Sistema operacional não suportado para instalação automática do Docker."
    fi
    
    # Verifica se a instalação foi bem-sucedida
    if ! command -v docker &> /dev/null; then
        error "Falha ao instalar o Docker. Por favor, instale manualmente."
    fi
}

# Instalação do Docker Compose
install_docker_compose() {
    info "Instalando Docker Compose..."
    
    # Detecta o sistema operacional
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Encontra a última versão do Docker Compose
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        
        # Baixa e instala o Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Cria link simbólico
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        info "Docker Compose instalado."
    else
        warning "Para outros sistemas operacionais, o Docker Compose é instalado junto com o Docker Desktop."
        warning "Por favor, instale o Docker Desktop que inclui o Docker Compose."
    fi
    
    # Verifica se a instalação foi bem-sucedida
    if ! command -v docker-compose &> /dev/null; then
        error "Falha ao instalar o Docker Compose. Por favor, instale manualmente."
    fi
}

# Instalação do Git
install_git() {
    info "Instalando Git..."
    
    # Detecta o sistema operacional
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Para sistemas baseados em Debian/Ubuntu
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y git
        
        # Para sistemas baseados em Red Hat/CentOS
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        else
            error "Não foi possível determinar o gerenciador de pacotes. Por favor, instale o Git manualmente."
        fi
    
    # Para macOS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        warning "Para macOS, recomendamos instalar o Git via Homebrew ou baixar de https://git-scm.com/download/mac"
        error "Por favor, instale o Git e execute o script novamente."
    
    # Para Windows
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        warning "Para Windows, recomendamos baixar o Git de https://git-scm.com/download/win"
        error "Por favor, instale o Git e execute o script novamente."
    
    else
        error "Sistema operacional não suportado para instalação automática do Git."
    fi
    
    # Verifica se a instalação foi bem-sucedida
    if ! command -v git &> /dev/null; then
        error "Falha ao instalar o Git. Por favor, instale manualmente."
    fi
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
    
    # Verifica se o arquivo composer.json existe
    if [ ! -f "composer.json" ]; then
        warning "Arquivo composer.json não encontrado. Criando novo projeto Laravel..."
        
        # Cria novo projeto Laravel
        composer create-project --prefer-dist laravel/laravel .
        
        if [ $? -ne 0 ]; then
            error "Falha ao criar projeto Laravel. Verifique se o Composer está instalado."
        fi
        
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
    log "Iniciando setup do ambiente de desenvolvimento..."
    
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
    log "Para iniciar o desenvolvimento:"
    log "1. Abra o cursor.ai neste diretório"
    log "2. Selecione o arquivo $PROJECT_NAME.code-workspace"
    log "3. O ambiente está pronto para uso!"
    log "Dicas importantes para o cursor.ai:"
    log "- Use o comando 'Docker: Attach to Container' para acessar o container"
    log "- Utilize o painel de AI para auxílio no desenvolvimento"
    log "- Configure atalhos personalizados em .cursor/settings.json"
    
    # Desativa trap
    trap - EXIT
}

# Executa função principal
main
