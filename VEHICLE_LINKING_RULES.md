# Regras de Negócio - Vinculação de Veículos

Este documento descreve as regras de negócio implementadas para a vinculação de veículos aos motoristas no aplicativo Jornada Flutter.

## 📋 Visão Geral

O sistema de vinculação de veículos permite que motoristas se conectem a veículos específicos da frota da empresa, garantindo controle e rastreabilidade das jornadas.

## 🎯 Regras de Negócio Principal

### 1. **Filtro de Veículos Disponíveis**
- **Regra**: Motoristas só veem veículos disponíveis ou já vinculados a eles
- **Implementação**: Campo `id_pessoal` na tabela veículo
- **Critério de Filtro**:
  - ✅ Mostrar: Veículos sem `id_pessoal` (livres)
  - ✅ Mostrar: Veículos com `id_pessoal` = ID do motorista atual
  - ❌ Ocultar: Veículos com `id_pessoal` de outros motoristas

### 2. **Processo de Vinculação**
```
Fluxo de Vinculação:
1. Motorista seleciona veículo da lista filtrada
2. Sistema valida disponibilidade
3. Sistema desvincula veículo anterior (se existir)
4. Sistema vincula novo veículo ao motorista
5. Sistema atualiza base de dados
6. Sistema confirma operação ao usuário
```

### 3. **Validações de Segurança**
- **Verificação de Disponibilidade**: Confirma que veículo está livre
- **Verificação de Permissões**: Valida que motorista pode usar o veículo
- **Verificação de Estado**: Confirma que não há jornada ativa em outro veículo
- **Transação Atômica**: Desvinculação + Vinculação em uma operação

### 4. **Estados do Veículo**
| Estado | Descrição | `id_pessoal` | Ação Permitida |
|--------|-----------|--------------|----------------|
| **Livre** | Disponível para qualquer motorista | `null` | ✅ Vincular |
| **Vinculado ao Usuário** | Já vinculado ao motorista atual | `= user_id` | ✅ Usar / ❌ Vincular novamente |
| **Ocupado** | Vinculado a outro motorista | `!= user_id` | ❌ Oculto da lista |

## 🔄 Fluxos de Operação

### **Vinculação de Veículo**
```dart
// Endpoint: vincularVeiculoMotorista
{
  "tipoConsulta": "vincularVeiculoMotorista",
  "banco": "cli_wafran",
  "cpf": "motorista_cpf",
  "matricula": "motorista_matricula",
  "id_veiculo": 123,
  "id_motorista": 456,
  "acao": "vincular"
}
```

### **Desvinculação de Veículo**
```dart
// Endpoint: vincularVeiculoMotorista
{
  "tipoConsulta": "vincularVeiculoMotorista",
  "banco": "cli_wafran",
  "cpf": "motorista_cpf",
  "matricula": "motorista_matricula",
  "id_veiculo": 123,
  "id_motorista": 456,
  "acao": "desvincular"
}
```

## 🛡️ Tratamento de Erros

### **Cenários de Erro Comum**
1. **Veículo Já Ocupado**
   - Mensagem: "Veículo não está disponível"
   - Ação: Recarregar lista de veículos

2. **Falha de Comunicação**
   - Mensagem: "Erro de comunicação com servidor"
   - Ação: Tentar novamente

3. **Dados Inválidos**
   - Mensagem: "Dados de autenticação inválidos"
   - Ação: Relogar no sistema

4. **Jornada Ativa**
   - Mensagem: "Finalize a jornada atual antes de trocar de veículo"
   - Ação: Encerrar jornada primeiro

## 🔧 Arquitetura Técnica

### **Componentes Envolvidos**
1. **VehicleService**: Comunicação com API para vinculação
2. **AuthProvider**: Gerenciamento de estado e persistência
3. **CompanyScreen**: Interface de seleção de veículos
4. **ApiService**: Filtro e listagem de veículos

### **Persistência de Dados**
- **Local**: SharedPreferences (cache de veículo vinculado)
- **Servidor**: Base de dados via API REST
- **Sincronização**: Validação a cada operação

## 📱 Interface do Usuário

### **Elementos de UI**
1. **Lista de Veículos**: Picker com veículos disponíveis
2. **Botão Vincular**: Confirma seleção de veículo
3. **Botão Desvincular**: Remove vinculação atual
4. **Indicadores de Status**: Loading e feedback de operações

### **Feedback Visual**
- ⏳ **Loading**: Durante operações de vinculação/desvinculação
- ✅ **Sucesso**: Confirmação verde com mensagem
- ❌ **Erro**: Alerta vermelho com detalhes do erro
- 🔄 **Atualização**: Recarregamento automático da lista

## 🔍 Monitoramento e Logs

### **Logs de Debug**
```dart
print('VehicleService: Vinculando veículo $vehicleId ao motorista $driverId');
print('VehicleService: Request body: $requestBody');
print('VehicleService: Response status: ${response.statusCode}');
```

### **Métricas de Operação**
- Tempo de resposta da vinculação
- Taxa de sucesso/erro por operação
- Veículos mais utilizados por empresa

## 🧪 Modo de Teste (Mock)

Para desenvolvimento e testes, o sistema oferece um modo mock que:
- Simula vinculação instantânea
- Não requer conexão com servidor
- Persiste dados localmente
- Facilita testes de UI e fluxos

## 📈 Melhorias Futuras

### **Funcionalidades Planejadas**
1. **Histórico de Vinculações**: Rastrear uso de veículos por motorista
2. **Notificações Push**: Alertas sobre mudanças de veículo
3. **Validação Biométrica**: Segurança adicional para vinculação
4. **Geofencing**: Verificar localização antes de vincular
5. **Manutenção Preventiva**: Bloqueio de veículos em manutenção

### **Otimizações Técnicas**
1. **Cache Inteligente**: Reduzir chamadas de API
2. **Retry Automático**: Tentar novamente em caso de falha
3. **Sincronização Offline**: Operar sem conexão
4. **Compressão de Dados**: Otimizar tráfego de rede

---

## 🔗 Referências Técnicas

- **Arquivo Principal**: `lib/services/vehicle_service.dart`
- **Provider**: `lib/providers/auth_provider.dart`
- **Interface**: `lib/screens/company_screen.dart`
- **Modelos**: `lib/models/vehicle.dart`

*Documentação atualizada em: 20 de outubro de 2025*
