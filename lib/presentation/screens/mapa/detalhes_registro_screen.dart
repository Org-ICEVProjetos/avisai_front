import 'dart:io';

import 'package:avisai4/data/models/registro.dart';
import 'package:avisai4/presentation/screens/widgets/custom_button.dart';
import 'package:avisai4/presentation/screens/widgets/offline_badge.dart';
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
      case StatusValidacao.emExecucao:
        return "Em execução";
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
        return Colors.green;
      case StatusValidacao.emExecucao:
        return Colors.deepOrange;
    }
  }

  Future<void> _abrirMapa(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o mapa.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _compartilharRegistro(BuildContext context) async {
    // Em uma implementação real, você usaria o pacote share_plus para compartilhar
    // a imagem e informações do registro

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Funcionalidade de compartilhamento será implementada em breve.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmarRemocao(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remover registro'),
            content: const Text(
              'Tem certeza que deseja remover este registro? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<RegistroBloc>().add(
                    RemoverRegistro(registroId: registro.id!),
                  );
                  Navigator.of(context).pop(); // Voltar para a tela anterior
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool imagemExiste = File(registro.caminhoFoto).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Irregularidade'),
        actions: [
          BlocBuilder<RegistroBloc, RegistroState>(
            builder: (context, state) {
              if (state is RegistroCarregado && !state.estaOnline) {
                return const OfflineBadge();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroOperacaoSucesso) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(state.mensagem),
            //     backgroundColor: Colors.green,
            //     duration: const Duration(seconds: 2),
            //   ),
            // );

            // Se a operação for sucesso e estiver relacionada a uma remoção,
            // voltar para a tela anterior
            if (state.mensagem.contains('removido')) {
              Navigator.of(context).pop();
            }
          } else if (state is RegistroErro) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(state.mensagem),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem principal
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
                      // Imagem
                      if (imagemExiste)
                        Image.file(
                          File(registro.caminhoFoto),
                          fit: BoxFit.cover,
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagem não disponível',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),

                      // Status badges
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
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sync,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pendente',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                    ],
                  ),
                ),
              ),

              // Informações detalhadas
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria
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

                    // Status
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

                    // Data
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

                    // Endereço
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

                    // Coordenadas
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

                    // Usuário
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

                    // Informações de validação
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

                    // Botões de ação
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            texto: 'Compartilhar',
                            icone: Icons.share,
                            cor: Colors.blue,
                            onPressed: () => _compartilharRegistro(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botão de remover
                    CustomButton(
                      texto: 'Remover Registro',
                      icone: Icons.delete_forever,
                      cor: Colors.red,
                      onPressed: () => _confirmarRemocao(context),
                    ),

                    const SizedBox(height: 24),
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
