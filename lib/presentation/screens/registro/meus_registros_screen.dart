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
  StatusValidacao? _filtroStatus;
  CategoriaIrregularidade? _filtroCategoria;
  bool _apenasNaoSincronizados = false;

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

  // Filtra a lista de registros com base nos filtros aplicados
  List<Registro> _filtrarRegistros(List<Registro> registros) {
    return registros.where((registro) {
      // Filtrar por usuário
      if (registro.usuarioId != widget.usuarioId) {
        return false;
      }

      // Filtrar por status
      if (_filtroStatus != null && registro.status != _filtroStatus) {
        return false;
      }

      // Filtrar por categoria
      if (_filtroCategoria != null && registro.categoria != _filtroCategoria) {
        return false;
      }

      // Filtrar por sincronização
      if (_apenasNaoSincronizados && registro.sincronizado) {
        return false;
      }

      return true;
    }).toList();
  }

  // Abre o modal de filtro avançado
  void _abrirFiltroAvancado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateModal) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho com título e botão fechar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Classificação da irregularidade
                    const Text(
                      'Classificação da irregularidade:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Opção "Todas as opções"
                    CheckboxListTile(
                      title: const Text('Todas as opções'),
                      value: _filtroCategoria == null,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setStateModal(() {
                          if (value == true) {
                            _filtroCategoria = null;
                          }
                        });
                      },
                    ),

                    // Opção "Buracos na pista"
                    CheckboxListTile(
                      title: const Text('Buracos na pista'),
                      value: _filtroCategoria == CategoriaIrregularidade.buraco,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setStateModal(() {
                          if (value == true) {
                            _filtroCategoria = CategoriaIrregularidade.buraco;
                          } else if (_filtroCategoria ==
                              CategoriaIrregularidade.buraco) {
                            _filtroCategoria = null;
                          }
                        });
                      },
                    ),

                    // Opção "Poste sem iluminação"
                    CheckboxListTile(
                      title: const Text('Poste sem iluminação'),
                      value:
                          _filtroCategoria ==
                          CategoriaIrregularidade.posteDefeituoso,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setStateModal(() {
                          if (value == true) {
                            _filtroCategoria =
                                CategoriaIrregularidade.posteDefeituoso;
                          } else if (_filtroCategoria ==
                              CategoriaIrregularidade.posteDefeituoso) {
                            _filtroCategoria = null;
                          }
                        });
                      },
                    ),

                    // Opção "Descarte irregular de lixo"
                    CheckboxListTile(
                      title: const Text('Descarte irregular de lixo'),
                      value:
                          _filtroCategoria ==
                          CategoriaIrregularidade.lixoIrregular,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setStateModal(() {
                          if (value == true) {
                            _filtroCategoria =
                                CategoriaIrregularidade.lixoIrregular;
                          } else if (_filtroCategoria ==
                              CategoriaIrregularidade.lixoIrregular) {
                            _filtroCategoria = null;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Status do registro:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Status options as choice chips
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Pendente'),
                          selected: _filtroStatus == StatusValidacao.pendente,
                          onSelected: (selected) {
                            setStateModal(() {
                              _filtroStatus =
                                  selected ? StatusValidacao.pendente : null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Aceito'),
                          selected: _filtroStatus == StatusValidacao.validado,
                          onSelected: (selected) {
                            setStateModal(() {
                              _filtroStatus =
                                  selected ? StatusValidacao.validado : null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Recusado'),
                          selected:
                              _filtroStatus == StatusValidacao.naoValidado,
                          onSelected: (selected) {
                            setStateModal(() {
                              _filtroStatus =
                                  selected ? StatusValidacao.naoValidado : null;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botão para aplicar o filtro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Aplicar filtros e fechar o modal
                          setState(() {}); // Atualiza a UI principal
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Aplicar Filtro',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
    );
  }

  // Limpa todos os filtros aplicados
  void _limparFiltros() {
    setState(() {
      _filtroStatus = null;
      _filtroCategoria = null;
      _apenasNaoSincronizados = false;
    });
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
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Seção de filtros
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com título e botão de filtro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Filtro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.filter_list,
                              color: Colors.blue,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _abrirFiltroAvancado,
                          ),
                        ],
                      ),
                      // Filtros aplicados? Mostrar botão para limpar
                      if (_filtroStatus != null ||
                          _filtroCategoria != null ||
                          _apenasNaoSincronizados)
                        TextButton(
                          onPressed: _limparFiltros,
                          child: const Text(
                            'Limpar filtros',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Choice chips para filtro rápido
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Chip para Pendente
                        FilterChip(
                          label: const Text('Pendente'),
                          selected: _filtroStatus == StatusValidacao.pendente,
                          onSelected: (selected) {
                            setState(() {
                              _filtroStatus =
                                  selected ? StatusValidacao.pendente : null;
                            });
                          },
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  _filtroStatus == StatusValidacao.pendente
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Chip para Aprovado
                        FilterChip(
                          label: const Text('Aceito'),
                          selected: _filtroStatus == StatusValidacao.validado,
                          onSelected: (selected) {
                            setState(() {
                              _filtroStatus =
                                  selected ? StatusValidacao.validado : null;
                            });
                          },
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  _filtroStatus == StatusValidacao.validado
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Chip para Recusado
                        FilterChip(
                          label: const Text('Recusado'),
                          selected:
                              _filtroStatus == StatusValidacao.naoValidado,
                          onSelected: (selected) {
                            setState(() {
                              _filtroStatus =
                                  selected ? StatusValidacao.naoValidado : null;
                            });
                          },
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  _filtroStatus == StatusValidacao.naoValidado
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Chip para Não Sincronizado
                        FilterChip(
                          label: const Text('Não Sincronizado'),
                          selected: _apenasNaoSincronizados,
                          onSelected: (selected) {
                            setState(() {
                              _apenasNaoSincronizados = selected;
                            });
                          },
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  _apenasNaoSincronizados
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, thickness: 1),

            // Lista de registros
            Expanded(child: _buildRegistrosList(state)),
          ],
        );
      },
    );
  }

  Widget _buildRegistrosList(RegistroState state) {
    if (state is RegistroCarregando) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is RegistroCarregado) {
      final filteredRegistros = _filtrarRegistros(state.registros);

      if (filteredRegistros.isEmpty) {
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
                'Nenhum registro encontrado',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              if (_filtroStatus != null ||
                  _filtroCategoria != null ||
                  _apenasNaoSincronizados)
                Text(
                  'Tente remover os filtros ou registrar uma nova irregularidade',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                )
              else
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
          itemCount: filteredRegistros.length,
          itemBuilder: (context, index) {
            final registro = filteredRegistros[index];

            return RegistroCard(
              categoria: _getCategoriaTexto(registro.categoria),
              endereco: registro.endereco ?? 'Endereço não disponível',
              data: _formatarData(registro.dataHora),
              imagemUrl: registro.base64Foto,
              status: registro.status,
              sincronizado: registro.sincronizado,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => DetalheRegistroScreen(registro: registro),
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
  }
}
