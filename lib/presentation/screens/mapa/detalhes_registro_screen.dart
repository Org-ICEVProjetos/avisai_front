import 'dart:io';

import 'package:avisai4/bloc/connectivity/connectivity_bloc.dart';
import 'package:avisai4/data/models/registro.dart';
import 'package:avisai4/presentation/screens/widgets/custom_button.dart';
import 'package:avisai4/presentation/screens/widgets/validation_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../bloc/registro/registro_bloc.dart';

class DetalheRegistroScreen extends StatelessWidget {
  final Registro registro;

  const DetalheRegistroScreen({super.key, required this.registro});

  String _getCategoriaTexto(CategoriaIrregularidade categoria) {
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return 'Buraco na via';
      case CategoriaIrregularidade.posteDefeituoso:
        return 'Poste com defeito';
      case CategoriaIrregularidade.lixoIrregular:
        return 'Descarte irregular de lixo';
      case CategoriaIrregularidade.outro:
        return "Outro";
    }
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  String _getStatusTexto(StatusValidacao status) {
    switch (status) {
      case StatusValidacao.validado:
        return 'Validado';
      case StatusValidacao.naoValidado:
        return 'Não validado';
      case StatusValidacao.pendente:
        return 'Pendente de validação';
      case StatusValidacao.resolvido:
        return "Resolvido";
      case StatusValidacao.emRota:
        return "Em rota";
    }
  }

  Color _getCorStatus(StatusValidacao status) {
    switch (status) {
      case StatusValidacao.validado:
        return Colors.green;
      case StatusValidacao.naoValidado:
        return Colors.orange;
      case StatusValidacao.pendente:
        return Colors.blue;
      case StatusValidacao.resolvido:
        return Colors.greenAccent;
      case StatusValidacao.emRota:
        return Colors.deepOrange;
    }
  }

  Future<void> _abrirMapa(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o mapa.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageFromURI(String uriString) {
    try {
      if (uriString.isEmpty) {
        return _buildImagePlaceholder();
      }

      return Image.file(File(uriString), fit: BoxFit.cover);
    } catch (e) {
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            'Imagem não disponível',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _expandirImagem(BuildContext context, String photoPath) {
    if (photoPath.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(photoPath), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detalhes",
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),

        backgroundColor: const Color(0xFF002569),
        centerTitle: false,
        elevation: 0,
        foregroundColor: Colors.white,
        toolbarHeight: 80,
      ),
      body: BlocListener<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroOperacaoSucesso) {
            if (state.mensagem.contains('removido')) {
              Navigator.of(context).pop();
            }
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, state) {
                  if (state is ConnectivityDisconnected) {
                    return Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 16,
                      ),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              Hero(
                tag: 'imagem_${registro.id}',
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageFromURI(registro.photoPath),

                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ValidationBadge(status: registro.status),
                            if (!registro.sincronizado) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.wifi_off,
                                      color: Colors.white,
                                      size: 16.0,
                                    ),
                                    SizedBox(width: 4.0),
                                    Text(
                                      'Não sincronizado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (registro.photoPath.isNotEmpty)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.zoom_out_map,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => _expandirImagem(
                                    context,
                                    registro.photoPath,
                                  ),
                              tooltip: 'Expandir imagem',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          color: Theme.of(context).primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCategoriaTexto(registro.categoria),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          registro.status == StatusValidacao.validado
                              ? Icons.check_circle
                              : registro.status == StatusValidacao.naoValidado
                              ? Icons.warning
                              : Icons.hourglass_empty,
                          color: _getCorStatus(registro.status),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_getStatusTexto(registro.status)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[700],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Registrado em: ${_formatarData(registro.dataHora)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Endereço:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                registro.endereco ?? 'Não disponível',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (registro.bairro != null ||
                                  registro.cidade != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${registro.bairro ?? ''}, ${registro.cidade ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          Icons.location_searching,
                          color: Colors.grey[700],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Coordenadas: ${registro.latitude.toStringAsFixed(6)}, ${registro.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Monospace',
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Visibility(
                      visible:
                          registro.observation != null &&
                          registro.observation!.isNotEmpty,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, color: Colors.grey[700], size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Observação:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    registro.observation!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[700], size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Registrado por: ${registro.usuarioNome}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    if (registro.status == StatusValidacao.validado &&
                        registro.validadoPorUsuarioId != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Informações de validação',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.green,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Validado por: ID ${registro.validadoPorUsuarioId}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (registro.dataValidacao != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey[700],
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Data de validação: ${_formatarData(registro.dataValidacao!)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      const Divider(),
                    ],
                    if (registro.status == StatusValidacao.naoValidado &&
                        registro.resposta != null &&
                        registro.resposta!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Motivo da não validação',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange[200]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Feedback do validador:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    registro.resposta!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                    ],

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            texto: 'Ver no Mapa',
                            icone: Icons.map,
                            onPressed:
                                () => _abrirMapa(
                                  context,
                                  registro.latitude,
                                  registro.longitude,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
