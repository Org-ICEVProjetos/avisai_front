import 'package:avisai4/bloc/connectivity/connectivity_bloc.dart';
import 'package:avisai4/presentation/screens/mapa/detalhes_registro_screen.dart';
import 'package:avisai4/presentation/screens/widgets/registro_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../bloc/registro/registro_bloc.dart';
import '../../../data/models/registro.dart';

class MeusRegistrosScreen extends StatefulWidget {
  final String usuarioId;

  const MeusRegistrosScreen({super.key, required this.usuarioId});

  @override
  _MeusRegistrosScreenState createState() => _MeusRegistrosScreenState();
}

class _MeusRegistrosScreenState extends State<MeusRegistrosScreen> {
  StatusValidacao? _filtroStatus;
  CategoriaIrregularidade? _filtroCategoria;
  final bool _apenasNaoSincronizados = false;

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
    if (registros.isEmpty) {
      print("A lista de registros está vazia!");
      return [];
    }

    for (var reg in registros) {
      print(
        "Registro - ID: ${reg.id}, usuarioId: ${reg.usuarioId}, categoria: ${reg.categoria}",
      );
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho com título e botão fechar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 24),
                        ),
                        const Text(
                          'Filtro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Espaço vazio para centralizar o título
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Classificação da irregularidade
                    const Text(
                      'Classificação da irregularidade:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opções de classificação com checkboxes
                    _buildCheckboxOption(
                      'Todas as opções',
                      _filtroCategoria == null,
                      (value) {
                        setStateModal(() {
                          if (value == true) {
                            _filtroCategoria = null;
                          }
                        });
                      },
                    ),

                    _buildCheckboxOption(
                      'Buracos na pista',
                      _filtroCategoria == CategoriaIrregularidade.buraco,
                      (value) {
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

                    _buildCheckboxOption(
                      'Poste sem iluminação',
                      _filtroCategoria ==
                          CategoriaIrregularidade.posteDefeituoso,
                      (value) {
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

                    _buildCheckboxOption(
                      'Descarte irregular de lixo',
                      _filtroCategoria == CategoriaIrregularidade.lixoIrregular,
                      (value) {
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

                    const SizedBox(height: 24),

                    // Status do registro
                    const Text(
                      'Status do registro:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botões de status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildStatusButton(
                          'Pendente',
                          StatusValidacao.pendente,
                          setStateModal,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          'Aceito',
                          StatusValidacao.validado,
                          setStateModal,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          'Recusado',
                          StatusValidacao.naoValidado,
                          setStateModal,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botão Aplicar Filtro
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Atualiza a UI principal
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002569),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Aplicar Filtro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  // Widget para construir uma opção de checkbox
  Widget _buildCheckboxOption(
    String text,
    bool checked,
    Function(bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: const Color(0xFF002569),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Widget para construir um botão de status
  Widget _buildStatusButton(
    String text,
    StatusValidacao status,
    StateSetter setStateModal,
  ) {
    final bool isSelecionado = _filtroStatus == status;

    return Flexible(
      fit: FlexFit.loose,
      child: OutlinedButton(
        onPressed: () {
          setStateModal(() {
            _filtroStatus = isSelecionado ? null : status;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelecionado
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          minimumSize: Size(100, 30), // permite o tamanho mínimo possível
          tapTargetSize:
              MaterialTapTargetSize.shrinkWrap, // reduz área de toque
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                isSelecionado
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistroBloc, RegistroState>(
      listener: (context, state) {
        if (state is RegistroErro) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagem),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
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
            // Seção de filtros
            Container(
              padding: const EdgeInsets.all(16),
              // Fundo cinza claro como na imagem
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título "Filtro" com ícone - ao clicar abre o modal
                  GestureDetector(
                    onTap: _abrirFiltroAvancado,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.indigo[900],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botões de filtro (Chips)
                  SingleChildScrollView(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Botão Pendente
                        Flexible(
                          fit: FlexFit.loose,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus =
                                    _filtroStatus == StatusValidacao.pendente
                                        ? null
                                        : StatusValidacao.pendente;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _filtroStatus == StatusValidacao.pendente
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              minimumSize: Size(140, 30),
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap, // reduz área de toque
                            ),
                            child: Text(
                              'Pendente',
                              style: TextStyle(
                                color:
                                    _filtroStatus == StatusValidacao.pendente
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Botão Aceito
                        Flexible(
                          fit: FlexFit.loose,

                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus =
                                    _filtroStatus == StatusValidacao.validado
                                        ? null
                                        : StatusValidacao.validado;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _filtroStatus == StatusValidacao.validado
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              minimumSize: Size(140, 30),
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap, // reduz área de toque
                            ),
                            child: Text(
                              'Aceito',
                              style: TextStyle(
                                color:
                                    _filtroStatus == StatusValidacao.validado
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Botão Recusado
                        Flexible(
                          fit: FlexFit.loose,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus =
                                    _filtroStatus == StatusValidacao.naoValidado
                                        ? null
                                        : StatusValidacao.naoValidado;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _filtroStatus == StatusValidacao.naoValidado
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              minimumSize: Size(140, 30),
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap, // reduz área de toque
                            ),
                            child: Text(
                              'Recusado',
                              style: TextStyle(
                                color:
                                    _filtroStatus == StatusValidacao.naoValidado
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                  builder: (BuildContext context) {
                    // Get screen size
                    final Size screenSize = MediaQuery.of(context).size;
                    final double screenWidth = screenSize.width;
                    final double screenHeight = screenSize.height;

                    // Calculate responsive sizes
                    final double titleFontSize =
                        screenWidth * 0.05; // 5% of screen width
                    final double bodyFontSize =
                        screenWidth * 0.04; // 4% of screen width
                    final double buttonHeight =
                        screenHeight * 0.06; // 6% of screen height

                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.04,
                        ), // Responsive border radius
                      ),
                      contentPadding: EdgeInsets.fromLTRB(
                        screenWidth * 0.06, // Left padding
                        screenHeight * 0.03, // Top padding
                        screenWidth * 0.06, // Right padding
                        screenHeight * 0.02, // Bottom padding
                      ),
                      title: Text(
                        'Remover registro',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      content: Text(
                        'Tem certeza que deseja remover este registro?',
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          color: Colors.black87,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      actionsPadding: EdgeInsets.fromLTRB(
                        screenWidth * 0.06, // Left padding
                        0, // Top padding
                        screenWidth * 0.06, // Right padding
                        screenHeight * 0.03, // Bottom padding
                      ),
                      actions: [
                        // Layout de coluna para os botões ocuparem toda a largura
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Botão principal "Remover"
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.read<RegistroBloc>().add(
                                  RemoverRegistro(registroId: registro.id!),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.08,
                                  ),
                                ),
                                minimumSize: Size(
                                  double.infinity,
                                  buttonHeight,
                                ),
                              ),
                              child: Text(
                                'Remover',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  fontSize: bodyFontSize,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: screenHeight * 0.01,
                            ), // Espaçamento entre botões
                            // Botão secundário "Cancelar"
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                minimumSize: Size(
                                  double.infinity,
                                  buttonHeight *
                                      0.8, // Ligeiramente menor que o botão principal
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );
    } else if (state is RegistroOperacaoSucesso) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return const Center(
        child: Text('Erro ao carregar registros. Tente novamente.'),
      );
    }
  }
}
