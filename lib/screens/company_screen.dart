import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/vehicle.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicles();
    });
  }

  Future<void> _loadVehicles() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.company?.id != null) {
      setState(() => _isLoadingVehicles = true);
      try {
        final vehicles = await authProvider.getVehiclesForCompany(authProvider.company!.id!);
        setState(() {
          _vehicles = vehicles;
          _selectedVehicle = authProvider.vehicle;
        });
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Erro ao carregar veículos: $e');
        }
      } finally {
        setState(() => _isLoadingVehicles = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVehiclePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
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
                    'Selecionar Veículo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (_selectedVehicle != null) {
                        context.read<AuthProvider>().setVehicle(_selectedVehicle!);
                      }
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedVehicle = _vehicles[index];
                  });
                },
                children: _vehicles.map((vehicle) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '${vehicle.plate} - ${vehicle.model}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

                  const SizedBox(height: 30),

                  // Seção de seleção de veículo
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
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.car_detailed,
                              color: CupertinoColors.systemBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Vincular Veículo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingVehicles)
                          const Center(
                            child: CupertinoActivityIndicator(),
                          )
                        else if (_vehicles.isEmpty)
                          const Text(
                            'Nenhum veículo disponível para esta empresa.',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          )
                        else
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.all(16),
                                  onPressed: _showVehiclePicker,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Consumer<AuthProvider>(
                                          builder: (context, authProvider, child) {
                                            final vehicle = authProvider.vehicle;
                                            return Text(
                                              vehicle != null
                                                  ? '${vehicle.plate} - ${vehicle.model}'
                                                  : 'Selecionar veículo...',
                                              style: TextStyle(
                                                color: vehicle != null
                                                    ? CupertinoColors.label
                                                    : CupertinoColors.placeholderText,
                                                fontSize: 16,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.chevron_down,
                                        color: CupertinoColors.systemGrey,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Selecione um veículo para iniciar sua jornada',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final hasVehicle = authProvider.vehicle != null;
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: hasVehicle
                              ? () => context.go('/home')
                              : () => _showErrorDialog(
                                    'Por favor, selecione um veículo antes de continuar.',
                                  ),
                          child: Text(
                            hasVehicle ? 'Continuar' : 'Selecione um Veículo',
                            style: TextStyle(
                              color: hasVehicle
                                  ? CupertinoColors.white
                                  : CupertinoColors.white.withValues(alpha: 0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
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
