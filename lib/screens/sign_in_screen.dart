import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/company.dart';
import '../utils/format_utils.dart';
import '../services/mock_api_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _cpfController = TextEditingController();
  final _matriculaController = TextEditingController();
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadCompanies();
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  void _onCpfChanged(String value) {
    final formatted = FormatUtils.formatCpf(value);
    if (formatted != _cpfController.text) {
      _cpfController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _handleLogin() async {
    final cpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');
    final password = _matriculaController.text;

    if (cpf.isEmpty || password.isEmpty) {
      _showErrorDialog('Preencha todos os campos.');
      return;
    }

    // Verificar se empresa foi selecionada (apenas para API real)
    final authProvider = context.read<AuthProvider>();
    print('SignInScreen: Usando mock: ${MockApiService.isUsingMockData}');
    print(
      'SignInScreen: Empresa selecionada: ${_selectedCompany?.name} (ID: ${_selectedCompany?.id})',
    );

    if (!MockApiService.isUsingMockData && _selectedCompany == null) {
      _showErrorDialog('Selecione uma empresa.');
      return;
    }

    final success = await authProvider.login(
      cpf: cpf,
      password: password,
      company: _selectedCompany, // passa a empresa selecionada
    );

    if (success) {
      if (mounted) {
        context.go('/company');
      }
    } else {
      final errorMessage =
          authProvider.errorMessage ??
          'Dados não encontrados. Verifique as informações.';
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Atenção'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMockInfo() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Dados para Teste'),
          content: SingleChildScrollView(
            child: Text(MockApiService.mockInfo, textAlign: TextAlign.left),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: CupertinoColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Informações do Modo Mock (se ativo)
              if (MockApiService.isUsingMockData) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                    border: Border.all(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            color: CupertinoColors.systemBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'MODO TESTE/DEMONSTRAÇÃO',
                            style: TextStyle(
                              color: CupertinoColors.systemBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CPFs para teste: 12345678901, 98765432100, 11111111111\nSenha: 123456',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _showMockInfo(),
                        child: Text(
                          'Ver mais informações sobre dados de teste',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Dropdown de empresas (apenas no modo API real)
              if (!MockApiService.isUsingMockData) ...[
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading &&
                        authProvider.companies.isEmpty) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: CupertinoColors.white,
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(16),
                        onPressed: authProvider.companies.isNotEmpty
                            ? () => _showCompanyPicker(authProvider.companies)
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCompany?.value ?? 'Escolha a empresa',
                                style: TextStyle(
                                  color: _selectedCompany != null
                                      ? CupertinoColors.label
                                      : CupertinoColors.placeholderText,
                                ),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              color: CupertinoColors.systemGrey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Campo CPF
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CupertinoColors.white,
                ),
                child: CupertinoTextField(
                  controller: _cpfController,
                  placeholder: 'CPF',
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: _onCpfChanged,
                ),
              ),

              const SizedBox(height: 20),

              // Campo Matrícula
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CupertinoColors.white,
                ),
                child: CupertinoTextField(
                  controller: _matriculaController,
                  placeholder: MockApiService.isUsingMockData
                      ? 'Senha (123456)'
                      : 'Matrícula',
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(),
                  obscureText: MockApiService.isUsingMockData,
                ),
              ),

              const SizedBox(height: 30),

              // Botão de login
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          CupertinoColors.systemBlue,
                          CupertinoColors.activeBlue,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemBlue.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      child: authProvider.isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanyPicker(List<Company> companies) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Text(
                      'Selecionar Empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Concluído'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 50,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedCompany = companies[index];
                    });
                  },
                  children: companies.map((company) {
                    return Center(child: Text(company.value));
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
