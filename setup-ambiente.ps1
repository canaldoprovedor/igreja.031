# setup-ambiente.ps1

# Cores para output
$ESC = [char]27
$RED = "$ESC[91m"
$GREEN = "$ESC[92m"
$YELLOW = "$ESC[93m"
$NC = "$ESC[0m"

# Funções para logging
function Log {
    param($message)
    Write-Host "${GREEN}[SETUP]${NC} $message"
}

function Error {
    param($message)
    Write-Host "${RED}[ERRO]${NC} $message"
    exit 1
}

function Warning {
    param($message)
    Write-Host "${YELLOW}[AVISO]${NC} $message"
}

# Verifica requisitos
function Check-Requirements {
    Log "Verificando requisitos do sistema..."
    
    # Verifica Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Error "Docker não encontrado. Instale o Docker Desktop primeiro."
    }
    
    # Verifica Docker Compose
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Error "Docker Compose não encontrado. Instale o Docker Desktop primeiro."
    }
    
    # Verifica Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Error "Git não encontrado. Instale o Git para Windows: https://git-scm.com"
    }
    
    # Verifica cursor.ai
    if (-not (Test-Path "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe")) {
        Warning "cursor.ai não encontrado. Instale de: https://cursor.sh"
    }
    
    Log "✓ Todos os requisitos atendidos"
}

# Configura variáveis de ambiente
function Setup-Env {
    Log "Configurando variáveis de ambiente..."
    
    if (-not (Test-Path .env)) {
        Copy-Item .env.example .env
        
        # Gera APP_KEY
        $bytes = New-Object Byte[] 32
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $appKey = [Convert]::ToBase64String($bytes)
        (Get-Content .env) -replace 'APP_KEY=', "APP_KEY=base64:$appKey" | Set-Content .env
        
        # Configura banco de dados
        (Get-Content .env) -replace 'DB_HOST=.*', 'DB_HOST=pgsql' | Set-Content .env
        (Get-Content .env) -replace 'DB_DATABASE=.*', 'DB_DATABASE=igreja_dev' | Set-Content .env
        (Get-Content .env) -replace 'DB_USERNAME=.*', 'DB_USERNAME=igreja_user' | Set-Content .env
        (Get-Content .env) -replace 'DB_PASSWORD=.*', 'DB_PASSWORD=igreja_pass' | Set-Content .env
        
        # Configura Redis
        (Get-Content .env) -replace 'REDIS_HOST=.*', 'REDIS_HOST=redis' | Set-Content .env
        
        Log "✓ Arquivo .env configurado"
    }
    else {
        Warning "Arquivo .env já existe. Mantendo configuração atual."
    }
}

# Configura Laradock
function Setup-Laradock {
    Log "Configurando Laradock..."
    
    if (-not (Test-Path laradock)) {
        git clone https://github.com/Laradock/laradock.git
        Set-Location laradock
        Copy-Item env-example .env
        
        # Configurações do Laradock
        (Get-Content .env) -replace 'PHP_VERSION=.*', 'PHP_VERSION=8.2' | Set-Content .env
        (Get-Content .env) -replace 'POSTGRES_VERSION=.*', 'POSTGRES_VERSION=14' | Set-Content .env
        (Get-Content .env) -replace 'POSTGRES_DB=.*', 'POSTGRES_DB=igreja_dev' | Set-Content .env
        (Get-Content .env) -replace 'POSTGRES_USER=.*', 'POSTGRES_USER=igreja_user' | Set-Content .env
        (Get-Content .env) -replace 'POSTGRES_PASSWORD=.*', 'POSTGRES_PASSWORD=igreja_pass' | Set-Content .env
        
        Set-Location ..
        Log "✓ Laradock configurado"
    }
    else {
        Warning "Diretório laradock já existe. Pulando configuração."
    }
}

# Inicia containers
function Start-Containers {
    Log "Iniciando containers..."
    
    Set-Location laradock
    docker-compose up -d nginx postgres redis workspace
    
    # Aguarda containers
    Start-Sleep -Seconds 10
    
    Set-Location ..
    Log "✓ Containers iniciados"
}

# Configura projeto
function Setup-Project {
    Log "Configurando projeto..."
    
    docker-compose -f .\laradock\docker-compose.yml exec workspace powershell @"
        composer install
        php artisan key:generate
        php artisan migrate
        php artisan storage:link
        npm install
        npm run dev
"@
    
    Log "✓ Projeto configurado"
}

# Configura Git Hooks
function Setup-GitHooks {
    Log "Configurando Git Hooks..."
    
    $hookContent = @'
cd laradock
docker-compose exec workspace bash -c "
    ./vendor/bin/phpstan analyse
    ./vendor/bin/pint --test
    php artisan test
"
'@
    
    New-Item -Path .\.git\hooks\pre-commit -Value $hookContent -Force
    icacls .\.git\hooks\pre-commit /grant:r "$env:USERNAME:(RX)"
    
    Log "✓ Git hooks configurados"
}

# Configura cursor.ai
function Setup-Cursor {
    Log "Configurando cursor.ai..."
    
    New-Item -Path .\.cursor -ItemType Directory -Force | Out-Null
    
    $settings = @'
{
    "editor.formatOnSave": true,
    "php.validate.executablePath": "C:\\laradock\\workspace\\usr\\local\\bin\\php",
    "php.suggest.basic": false,
    "docker.enabled": true,
    "intelephense.environment.phpVersion": "8.2",
    "laravel.enabled": true,
    "laravel.format.enable": true,
    "files.associations": {
        "*.php": "php",
        ".env": "dotenv",
        "docker-compose.yml": "dockercompose"
    }
}
'@
    $settings | Set-Content .\.cursor\settings.json
    
    $workspace = @'
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
'@
    $workspace | Set-Content .\igreja-sistema.code-workspace
    
    Log "✓ cursor.ai configurado"
}

# Função principal
function Main {
    Log "Iniciando setup do ambiente de desenvolvimento..."
    
    Check-Requirements
    Setup-Env
    Setup-Laradock
    Start-Containers
    Setup-Project
    Setup-GitHooks
    Setup-Cursor
    
    Log "✓ Setup concluído com sucesso!"
    Log "Para iniciar o desenvolvimento:"
    Log "1. Abra o cursor.exe neste diretório"
    Log "2. Selecione o arquivo igreja-sistema.code-workspace"
    Log "3. O ambiente está pronto para uso!"
    Log "Dicas importantes:"
    Log "- Use 'Docker: Attach to Container' para acessar o container"
    Log "- Utilize o painel de IA para auxílio"
    Log "- Configure atalhos em .cursor/settings.json"
}

# Executa o script
Main