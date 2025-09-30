# Dados Mock para Teste da Aplicação Jornada Flutter

## 🎯 Objetivo
Este sistema de dados mock permite testar todas as funcionalidades da aplicação sem depender de uma API real.

## 📋 Dados Disponíveis para Teste

### CPFs Válidos
- **12345678901** - João Silva (Transportes São Paulo LTDA)
- **98765432100** - Maria Santos (Transportes São Paulo LTDA)
- **11111111111** - Pedro Oliveira (Logística Rio de Janeiro S.A.)
- **22222222222** - Ana Costa (Frota Minas Gerais EIRELI)
- **33333333333** - Carlos Ferreira (Transportadora Nacional Express)

### Senha Padrão
- **123456** (para todos os usuários)

### Empresas Disponíveis
1. **Transportes São Paulo LTDA** (TSP001)
2. **Logística Rio de Janeiro S.A.** (LRJ002)
3. **Frota Minas Gerais EIRELI** (FMG003)
4. **Transportadora Nacional Express** (TNE004)
5. **Cargo Sul Distribuidora** (CSD005)

### Veículos por Empresa
- **Transportes São Paulo**: ABC-1234 (Volvo FH 540), DEF-5678 (Scania R 450)
- **Logística Rio de Janeiro**: GHI-9012 (Mercedes-Benz Actros), JKL-3456 (MAN TGX 28.480)
- **Frota Minas Gerais**: MNO-7890 (Iveco Stralis), PQR-1357 (DAF XF 105)
- **Transportadora Nacional**: STU-2468 (Ford Cargo 2429)
- **Cargo Sul**: VWX-9753 (Volkswagen Constellation)

## 🚀 Como Testar

### 1. Tela de Login
1. Digite um dos CPFs válidos (ex: 12345678901)
2. Digite a senha: 123456
3. Clique em "Entrar"
4. ✅ Login será realizado automaticamente

### 2. Tela de Empresa
- Os dados do usuário e empresa serão exibidos automaticamente
- ✅ Veículos da empresa serão carregados

### 3. Tela Principal (Home)
- Selecione um veículo da lista
- ✅ Teste todos os botões de status:
  - **Iniciar Jornada** - Inicia cronômetro
  - **Em Direção** - Altera status para dirigindo
  - **Refeição** - Pausa para alimentação
  - **Espera** - Status de aguardo
  - **Descansar** - Período de descanso
  - **Trocar Placa** - Mudança de veículo
  - **Encerrar** - Finaliza a jornada

## 🎭 Simulações Incluídas

### Recursos Funcionais
- ✅ **Cronômetro em tempo real** para cada status
- ✅ **Persistência de dados** (mantém estado entre sessões)
- ✅ **Simulação de localização** (coordenadas de São Paulo)
- ✅ **Delay de rede realista** (500-1500ms)
- ✅ **Erros ocasionais** (5% das requisições para simular problemas reais)
- ✅ **Histórico de jornadas** mock

### Experiência de Usuário
- 📱 **Interface nativa iOS** com Cupertino Design
- 🎨 **Animações e transições** suaves
- 🔄 **Loading states** durante operações
- ⚠️ **Mensagens de erro** informativas
- 💾 **Dados persistentes** usando SharedPreferences

## 🔧 Configuração

### Alternar Entre Mock e API Real
No arquivo `lib/services/mock_api_service.dart`, altere:
```dart
static const bool _useMockData = true; // false para API real
```

### Adicionar Novos Dados Mock
Edite `lib/services/mock_data.dart` para:
- Adicionar novos usuários, empresas ou veículos
- Modificar CPFs válidos
- Alterar senhas padrão
- Personalizar respostas da API

## 📊 Monitoramento

### Logs Disponíveis
- Status de login (sucesso/erro)
- Mudanças de status da jornada
- Erros de localização
- Operações de API mock

### Debug
- Use Flutter DevTools para monitorar estado
- Verifique console para logs detalhados
- Provider pattern permite inspeção em tempo real

## 🎉 Funcionalidades Testáveis

✅ **Login completo** com validação  
✅ **Seleção de empresa e veículo**  
✅ **Cronômetro de jornada** em tempo real  
✅ **Todos os status de trabalho**  
✅ **Persistência entre sessões**  
✅ **Simulação de erros de rede**  
✅ **Interface nativa iOS**  
✅ **Geolocalização simulada**  
✅ **Histórico de jornadas**  

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs no console do Flutter
2. Confirme que está usando um CPF válido da lista
3. Certifique-se de que a senha é "123456"
4. Consulte este documento para dados disponíveis

---

**Nota**: Este sistema mock é ideal para demonstrações, testes e desenvolvimento sem necessidade de configuração de servidor.