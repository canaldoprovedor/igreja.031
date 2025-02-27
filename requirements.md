# Requisitos Revisados - Sistema de Gestão para Igreja
## 1. Módulos Principais

### 1.1 Autenticação e Controle de Acesso
- Login com níveis de acesso hierárquicos
- Recuperação de senha via email
- Autenticação com Sanctum (simplificado em relação a JWT)
- Registro de logs de operações críticas
- 2FA para operações financeiras e administradores

### 1.2 Gestão de Pessoas
- Cadastro unificado de membros e visitantes
- Registro de participação em ministérios e grupos
- Histórico de acompanhamento pastoral
- Gestão de documentos básicos

### 1.3 Eventos e Celebrações
- Agenda unificada de eventos
- Gestão de equipes e recursos
- Controle de presença
- Sistema básico de inscrições

### 1.4 Ensino e Grupos
- Gestão de cursos e grupos pequenos
- Controle de frequência
- Biblioteca digital de materiais
- Certificados digitais

### 1.5 Financeiro
- Registro de entradas (dízimos/ofertas)
- Controle de despesas
- Relatórios financeiros básicos

### 1.6 Patrimônio
- Gestão de bens e patrimônio
- Controle de manutenções
- Relatórios de inventário

### 1.7 Administração
- Gestão de congregações
- Relatórios gerenciais
- Backup e restauração
- Configurações do sistema

## 2. Requisitos Técnicos

### 2.1 Tecnologias Base
- Laravel Framework 10+
- PostgreSQL 14+
- Redis para cache
- API REST para integrações

### 2.2 Arquitetura
- Multi-tenant baseado em ID de congregação
- Autenticação via Laravel Sanctum
- Cache em dois níveis (Redis + Navegador)
- PWA com funcionalidades offline básicas para módulos não-críticos

### 2.3 Performance
- Tempo de resposta < 2s para operações comuns
- Tempo máximo de 10s para relatórios complexos e sincronização
- Suporte a 1000 usuários simultâneos
- Disponibilidade 99%
- Otimização para dispositivos móveis

### 2.4 Segurança
- Criptografia de dados sensíveis
- Controle de acesso baseado em papéis
- Backup diário automatizado
- Logs de auditoria para operações críticas
