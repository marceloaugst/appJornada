import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Informações'),
        backgroundColor: CupertinoColors.systemBlue,
      ),
      child: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Card de informações do usuário
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações do Motorista',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInfoRow(
                          'Nome:',
                          authProvider.user?.name ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Empresa:',
                          authProvider.company?.name ??
                              authProvider.company?.value ??
                              'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Placa:',
                          authProvider.vehicle?.plate ?? 'Não informado',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botão continuar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          CupertinoColors.systemGreen,
                          Color(0xFF32D74B),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGreen.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () => context.go('/home'),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botão logout
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemRed,
                        width: 1,
                      ),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () => _showLogoutDialog(context),
                      child: const Text(
                        'Sair',
                        style: TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Confirmar'),
          content: const Text('Deseja realmente sair?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(context).pop();
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }
}
