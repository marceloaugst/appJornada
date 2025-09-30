class FormatUtils {
  static String formatCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), ''); // Remove tudo que não é número

    if (cpf.length <= 3) {
      return cpf;
    } else if (cpf.length <= 6) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3)}';
    } else if (cpf.length <= 9) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6)}';
    } else {
      // Garantir que não ultrapasse o limite da string
      final length = cpf.length;
      final endIndex = length > 11 ? 11 : length;
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, endIndex)}';
    }
  }

  static String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
