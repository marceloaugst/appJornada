import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';
import '../widgets/journey_button.dart';
import '../utils/format_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Consumer2<AuthProvider, JourneyProvider>(
          builder: (context, authProvider, journeyProvider, child) {
            return CustomScrollView(
              slivers: [
                // Header com informações do usuário
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olá, ${authProvider.user?.name ?? 'Motorista'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Placa: ${authProvider.vehicle?.plate ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _showUserMenu(context),
                              child: const Icon(
                                CupertinoIcons.person_circle,
                                size: 32,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),

                        if (journeyProvider.isJourneyStarted) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.clock,
                                  color: CupertinoColors.systemGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Jornada iniciada: ${_formatDateTime(journeyProvider.journeyStartTime)}',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Botões de ação
                if (!journeyProvider.isJourneyStarted)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: JourneyButton(
                        title: 'Iniciar Jornada',
                        icon: CupertinoIcons.play_circle_fill,
                        color: CupertinoColors.systemGreen,
                        onPressed: journeyProvider.isSaving
                            ? null
                            : () => journeyProvider.startJourney(),
                        isLoading: journeyProvider.isSaving,
                      ),
                    ),
                  )
                else ...[
                  // Grade de botões de atividades
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildListDelegate([
                        JourneyButton(
                          title: 'Direção',
                          subtitle: _getTimeDisplay(
                            journeyProvider.totalDrivingTime,
                            journeyProvider.journeyState.direcao
                                ? journeyProvider.currentActivityTime
                                : null,
                          ),
                          icon: CupertinoIcons.car_detailed,
                          color: CupertinoColors.systemBlue,
                          isActive: journeyProvider.journeyState.direcao,
                          onPressed: journeyProvider.isSaving
                              ? null
                              : () => journeyProvider.setActivity(
                                  driving:
                                      !journeyProvider.journeyState.direcao,
                                ),
                          isLoading: journeyProvider.isSaving,
                        ),

                        JourneyButton(
                          title: 'Refeição',
                          subtitle: _getTimeDisplay(
                            journeyProvider.totalMealTime,
                            journeyProvider.journeyState.refeicao
                                ? journeyProvider.currentActivityTime
                                : null,
                          ),
                          icon: CupertinoIcons.tray_full,
                          color: CupertinoColors.systemOrange,
                          isActive: journeyProvider.journeyState.refeicao,
                          onPressed: journeyProvider.isSaving
                              ? null
                              : () => journeyProvider.setActivity(
                                  meal: !journeyProvider.journeyState.refeicao,
                                ),
                          isLoading: journeyProvider.isSaving,
                        ),

                        JourneyButton(
                          title: 'Espera',
                          subtitle: _getTimeDisplay(
                            journeyProvider.totalWaitingTime,
                            journeyProvider.journeyState.espera
                                ? journeyProvider.currentActivityTime
                                : null,
                          ),
                          icon: CupertinoIcons.timer,
                          color: CupertinoColors.systemYellow,
                          isActive: journeyProvider.journeyState.espera,
                          onPressed: journeyProvider.isSaving
                              ? null
                              : () => journeyProvider.setActivity(
                                  waiting: !journeyProvider.journeyState.espera,
                                ),
                          isLoading: journeyProvider.isSaving,
                        ),

                        JourneyButton(
                          title: 'Descanso',
                          subtitle: _getTimeDisplay(
                            journeyProvider.totalRestingTime,
                            journeyProvider.journeyState.descansar
                                ? journeyProvider.currentActivityTime
                                : null,
                          ),
                          icon: CupertinoIcons.bed_double,
                          color: CupertinoColors.systemPurple,
                          isActive: journeyProvider.journeyState.descansar,
                          onPressed: journeyProvider.isSaving
                              ? null
                              : () => journeyProvider.setActivity(
                                  resting:
                                      !journeyProvider.journeyState.descansar,
                                ),
                          isLoading: journeyProvider.isSaving,
                        ),
                      ]),
                    ),
                  ),

                  // Botão de encerrar jornada
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: JourneyButton(
                        title: 'Encerrar Jornada',
                        icon: CupertinoIcons.stop_circle_fill,
                        color: CupertinoColors.systemRed,
                        onPressed: journeyProvider.isSaving
                            ? null
                            : () => _showEndJourneyDialog(context),
                        isLoading: journeyProvider.isSaving,
                      ),
                    ),
                  ),
                ],

                // Espaçamento final
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getTimeDisplay(int totalTime, int? currentTime) {
    final timeToDisplay = currentTime ?? totalTime;
    return FormatUtils.formatTime(timeToDisplay);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showUserMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Opções'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/company');
              },
              child: const Text('Ver Informações'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _showLogoutDialog(context);
              },
              child: const Text('Sair'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        );
      },
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

  void _showEndJourneyDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Encerrar Jornada'),
          content: const Text('Deseja realmente encerrar a jornada?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.read<JourneyProvider>().endJourney();
              },
              child: const Text('Encerrar'),
            ),
          ],
        );
      },
    );
  }
}
