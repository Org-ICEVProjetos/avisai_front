import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ExportButton extends StatefulWidget {
  final VoidCallback? onExportSuccess;
  final Function(String)? onExportError;

  const ExportButton({Key? key, this.onExportSuccess, this.onExportError})
    : super(key: key);

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _isExporting = false;

  Future<void> _exportDatabase() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      String? caminhoBackup = await LocalStorageService().exportarBanco(
        compartilhar: true,
      );

      if (caminhoBackup != null) {
        // Sucesso na exportação
        widget.onExportSuccess?.call();

        // Mostra snackbar de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Banco exportado com sucesso!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Erro na exportação
      String errorMessage = 'Erro ao exportar banco: $e';
      widget.onExportError?.call(errorMessage);

      // Mostra snackbar de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isExporting ? null : _exportDatabase,
      icon:
          _isExporting
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
              : Icon(Icons.file_download),
      tooltip: 'Exportar banco de dados',
      iconSize: 24,
    );
  }
}
