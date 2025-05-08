import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final IconData? icone;
  final Color? cor;
  final bool fullWidth;
  final bool outlined;
  final double textSize;

  const CustomButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icone,
    this.cor,
    this.fullWidth = true,
    this.outlined = false,
    this.textSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = cor ?? Theme.of(context).primaryColor;

    // Em vez de SizedBox, usamos um widget que lida melhor com restrições
    Widget button =
        outlined
            ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: buttonColor),
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _buildButtonContent(buttonColor),
            )
            : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _buildButtonContent(Colors.white),
            );

    // Somente aplicamos largura total se solicitado
    if (fullWidth) {
      return SizedBox(
        width: double.maxFinite, // Usar maxFinite em vez de infinity
        child: button,
      );
    } else {
      return button; // Retorna o botão diretamente sem restrições de largura
    }
  }

  Widget _buildButtonContent(Color textColor) {
    return Row(
      mainAxisSize:
          MainAxisSize.min, // Importante para evitar expansão infinita
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icone != null) ...[
          Icon(icone, color: textColor),
          SizedBox(width: 8.0),
        ],
        Flexible(
          // Adicionamos Flexible para permitir que o texto quebre se necessário
          child: Text(
            texto,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
