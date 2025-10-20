# Implementação da API Real

Este documento descreve as mudanças feitas para implementar a API real no lugar dos dados mockados.

## Mudanças Realizadas

### 1. ApiService.dart
- **Adicionado import**: `import '../models/vehicle.dart';`
- **Novo método**: `fetchVehicles(int companyId)` para buscar veículos de uma empresa específica
  - Endpoint: `tipoConsulta: 'obterVeiculos'`
  - Parâmetro: `empresaId: companyId`

### 2. AuthProvider.dart
- **Implementação do login real**: Substituiu o `throw Exception('API real não configurada!!')` por uma implementação completa
- **Parâmetros do login**:
  - `cpf`: CPF do usuário
  - `matricula`: Vem do campo "password" do formulário
  - `database`: Código da empresa selecionada (ou 'DEFAULT' se não houver empresa)
- **Tratamento de resposta flexível**:
  - Suporta diferentes formatos de resposta da API
  - Verifica múltiplos campos de sucesso/erro
  - Cria objetos User e Company a partir da resposta

- **Implementação de getVehiclesForCompany**: Agora usa `ApiService.fetchVehicles()` quando não está em modo mock

### 3. Configuração Mock/Real
- **MockApiService**: A constante `_useMockData` está definida como `false`
- **Para alternar entre mock e real**: Altere o valor de `_useMockData` em `MockApiService`
  - `true`: Usa dados mockados
  - `false`: Usa API real

## Como Usar

### Status Atual: USANDO API REAL
✅ **Configurado para usar API real** conforme solicitado pelo usuário

**Configuração**:
- `_useMockData = false` - API real ativada
- Logs detalhados adicionados para debug
- Tratamento robusto de erros implementado

### Para testar com API real (quando disponível):
1. Altere `_useMockData = false` em `MockApiService`
2. A aplicação automaticamente usará os endpoints reais
3. Login requer CPF válido e matrícula válida no sistema

### Para voltar aos dados mock:
1. Altere `_useMockData = true` em `MockApiService`
2. Use os CPFs e senha padrão definidos em `MockData`

## Endpoints da API Real Utilizados

1. **Login**:
   ```json
   {
     "tipoConsulta": "obterLogin",
     "matricula": "matricula_usuario",
     "cpf": "cpf_usuario",
     "banco": "codigo_empresa"
   }
   ```

2. **Buscar Empresas**:
   ```json
   {
     "tipoConsulta": "obterDadosEmpresas"
   }
   ```

3. **Buscar Veículos**:
   ```json
   {
     "tipoConsulta": "obterVeiculos",
     "empresaId": empresa_id
   }
   ```

## Tratamento de Erros

A implementação trata diferentes formatos de resposta de erro:
- `success: false`
- `erro: true` com `mensagem`
- Campos `error` ou `message`
- Fallback para "Credenciais inválidas"

## Formato de Dados Esperado

Os modelos `User`, `Company` e `Vehicle` são flexíveis e suportam tanto os nomes de campos da API quanto nomes alternativos para compatibilidade.

### User
- Suporta: `id`/`id_pessoal`, `name`/`nome`, etc.

### Company
- Suporta: `id`, `name`, `code`, `key`, `value`

### Vehicle
- Suporta: `id`/`id_veiculo`, `plate`/`placa`, `model`/`modelo`

## ⚠️ Problemas Conhecidos e Soluções

### 1. Erro de Conexão com Banco de Dados
**Erro**: `SQLSTATE[08006] [7] connection to server at "10.101.3.6" port 5432 failed`
**Solução**: Configurado para usar dados mock temporariamente

### 2. Erro "FATAL: não existe o banco de dados 'DEFAULT'"
**Problema**: Login tentava usar banco "DEFAULT" quando empresa não selecionada
**Solução**:
- Modificado AuthProvider para aceitar empresa como parâmetro
- SignInScreen agora passa empresa selecionada para o login
- Para API real, empresa deve ser selecionada antes do login

### Mudanças na Implementação
- `AuthProvider.login()` agora aceita parâmetro opcional `company`
- `SignInScreen` valida seleção de empresa para API real
- Login sem empresa só funciona no modo mock

**Soluções Implementadas**:
1. **Fallback automático**: Se a API falhar, mensagem amigável é exibida
2. **Mock temporário**: Configurado para usar dados mock até problema ser resolvido
3. **Teste de conectividade**: Método `ApiService.testConnection()` para verificar disponibilidade

**Para o administrador do servidor**:
- Verificar se o PostgreSQL está rodando na porta 5432
- Verificar conectividade de rede entre o servidor web e banco
- Verificar credenciais de banco de dados
- Verificar firewall/regras de segurança

**Status**: Implementação da API real está completa, aguardando correção no servidor.
