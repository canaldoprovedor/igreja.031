# Restrições de Negócio e Técnicas Revisadas

## 1. Restrições de Negócio

### 1.1 Dados e Privacidade
- Dados financeiros acessíveis apenas por usuários autorizados
- Informações pessoais dos membros não podem ser compartilhadas entre congregações
- Registro obrigatório de responsável por operações financeiras
- Necessidade de aprovação para transferências entre congregações

### 1.2 Operacional
- Alterações em eventos agendados devem notificar participantes
- Cancelamentos financeiros precisam de justificativa
- Backup diário obrigatório dos dados
- Registro de presença limitado ao dia do evento

### 1.3 Administrativo
- Hierarquia de congregações deve ser respeitada
- Relatórios financeiros consolidados mensais obrigatórios
- Período máximo offline de 72 horas para sincronização
- Necessidade de termo de uso e privacidade

## 2. Restrições Técnicas

### 2.1 Infraestrutura
- Servidores em território nacional
- SSL/TLS obrigatório
- Backup em local geograficamente distinto
- Monitoramento básico de disponibilidade

### 2.2 Desenvolvimento
- Código-fonte versionado (Git)
- Testes automatizados com cobertura mínima de 70%
- Documentação técnica obrigatória
- Code review para todas alterações

### 2.3 Segurança
- Senhas com complexidade mínima obrigatória
- Sessões com tempo máximo de 8 horas
- Rate limiting para APIs
- 2FA para operações financeiras e administradores

### 2.4 Performance
- Máximo 2MB por página
- Tempo limite de 10s para sincronização e relatórios complexos
- Limite de 100 requisições/min por usuário
- Cache obrigatório para dados estáticos
