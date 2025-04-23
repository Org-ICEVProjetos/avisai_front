import 'package:avisai4/presentation/screens/mapa/detalhes_registro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../bloc/registro/registro_bloc.dart';
import '../../../data/models/registro.dart';

import '../widgets/registro_card.dart';

class MeusRegistrosScreen extends StatefulWidget {
  final String usuarioId;

  const MeusRegistrosScreen({super.key, required this.usuarioId});

  @override
  _MeusRegistrosScreenState createState() => _MeusRegistrosScreenState();
}

class _MeusRegistrosScreenState extends State<MeusRegistrosScreen> {
  @override
  void initState() {
    super.initState();

    // Carregar registros quando a tela for inicializada
    context.read<RegistroBloc>().add(CarregarRegistros());
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistroBloc, RegistroState>(
      listener: (context, state) {
        if (state is RegistroErro) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagem),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is RegistroOperacaoSucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagem),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is RegistroCarregando) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RegistroCarregado) {
          final registros =
              state.registros
                  .where((r) => r.usuarioId == widget.usuarioId)
                  .toList();

          if (registros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Você ainda não tem registros',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque em "Registrar" para adicionar uma irregularidade',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<RegistroBloc>().add(CarregarRegistros());
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final registro = registros[index];

                return RegistroCard(
                  categoria: _getCategoriaTexto(registro.categoria),
                  endereco: registro.endereco ?? 'Endereço não disponível',
                  data: _formatarData(registro.dataHora),
                  imagemUrl: registro.caminhoFoto,
                  validado: registro.status == StatusValidacao.validado,
                  sincronizado: registro.sincronizado,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                DetalheRegistroScreen(registro: registro),
                      ),
                    );
                  },
                  onDelete: () {
                    // Mostrar diálogo de confirmação
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Remover registro'),
                            content: const Text(
                              'Tem certeza que deseja remover este registro?',
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
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Remover'),
                              ),
                            ],
                          ),
                    );
                  },
                );
              },
            ),
          );
        } else {
          return const Center(
            child: Text('Erro ao carregar registros. Tente novamente.'),
          );
        }
      },
    );
  }
}
