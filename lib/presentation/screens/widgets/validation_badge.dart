import 'package:flutter/material.dart';

class ValidationBadge extends StatelessWidget {
  final bool validated;

  const ValidationBadge({
    super.key,
    required this.validated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: validated ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            validated ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 16.0,
          ),
          const SizedBox(width: 4.0),
          Text(
            validated ? 'Validado' : 'Não validado',
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
