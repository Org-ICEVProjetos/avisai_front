import 'package:flutter/material.dart';
import '../../../data/models/registro.dart'; // Importando o arquivo onde está o enum StatusValidacao

class ValidationBadge extends StatelessWidget {
  final StatusValidacao status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Definir configurações de acordo com o status
    IconData icon;
    String texto;
    Color cor;

    switch (status) {
      case StatusValidacao.validado:
        icon = Icons.check_circle;
        texto = 'Validado';
        cor = Colors.green;
        break;
      case StatusValidacao.naoValidado:
        icon = Icons.warning;
        texto = 'Não validado';
        cor = Colors.orange;
        break;
      case StatusValidacao.pendente:
        icon = Icons.hourglass_empty;
        texto = 'Pendente';
        cor = Colors.amber;
        break;
      case StatusValidacao.emRota:
        icon = Icons.engineering;
        texto = 'Em rota';
        cor = Theme.of(context).colorScheme.primary;
        break;
      case StatusValidacao.resolvido:
        icon = Icons.task_alt;
        texto = 'Resolvido';
        cor = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16.0),
          const SizedBox(width: 4.0),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
