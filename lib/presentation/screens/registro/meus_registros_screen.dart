import 'package:avisai4/bloc/connectivity/connectivity_bloc.dart';
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
      case CategoriaIrregularidade.outro:
        return 'Outro';
    }
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  List<Registro> _filtrarRegistros(List<Registro> registros) {
    if (registros.isEmpty) {
      return [];
    }

    return registros.where((registro) {
        if (registro.usuarioId != widget.usuarioId) {
          return false;
        }

        if (_filtroStatus != null && registro.status != _filtroStatus) {
          return false;
        }

        if (_filtroCategoria != null &&
            registro.categoria != _filtroCategoria) {
          return false;
        }

        if (_apenasNaoSincronizados && registro.sincronizado) {
          return false;
        }

        return true;
      }).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  }

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

                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Classificação da irregularidade:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    _buildCheckboxOption(
                      'Outros',
                      _filtroCategoria == CategoriaIrregularidade.outro,
                      (value) {
                        setStateModal(() {
                          if (value == true) {
                            _filtroCategoria = CategoriaIrregularidade.outro;
                          } else if (_filtroCategoria ==
                              CategoriaIrregularidade.outro) {
                            _filtroCategoria = null;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Status do registro:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
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
                          const SizedBox(width: 8),
                          _buildStatusButton(
                            'Em rota',
                            StatusValidacao.emRota,
                            setStateModal,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusButton(
                            'Resolvido',
                            StatusValidacao.resolvido,
                            setStateModal,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
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

  Widget _buildStatusButton(
    String text,
    StatusValidacao status,
    StateSetter setStateModal,
  ) {
    final bool isSelecionado = _filtroStatus == status;

    return SizedBox(
      width: 100,
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
          minimumSize: Size(100, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              duration: Duration(seconds: 3),
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

            Container(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                        SizedBox(
                          width: 140,

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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                        SizedBox(
                          width: 140,
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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        const SizedBox(width: 8),

                        SizedBox(
                          width: 140,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus =
                                    _filtroStatus == StatusValidacao.emRota
                                        ? null
                                        : StatusValidacao.emRota;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _filtroStatus == StatusValidacao.emRota
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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Em rota',
                              style: TextStyle(
                                color:
                                    _filtroStatus == StatusValidacao.emRota
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        SizedBox(
                          width: 140,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus =
                                    _filtroStatus == StatusValidacao.resolvido
                                        ? null
                                        : StatusValidacao.resolvido;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _filtroStatus == StatusValidacao.resolvido
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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Resolvido',
                              style: TextStyle(
                                color:
                                    _filtroStatus == StatusValidacao.resolvido
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
          context.read<RegistroBloc>().add(
            SincronizarRegistrosPendentes(context: context, silencioso: true),
          );
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
              imagemUrl: registro.photoPath,
              status: registro.status,
              sincronizado: registro.sincronizado,
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/registro/detalhe',
                  arguments: {'registro': registro},
                );
              },
              onDelete: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final Size screenSize = MediaQuery.of(context).size;
                    final double screenWidth = screenSize.width;
                    final double screenHeight = screenSize.height;

                    final double titleFontSize = screenWidth * 0.05;
                    final double bodyFontSize = screenWidth * 0.04;
                    final double buttonHeight = screenHeight * 0.06;

                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      contentPadding: EdgeInsets.fromLTRB(
                        screenWidth * 0.06,
                        screenHeight * 0.03,
                        screenWidth * 0.06,
                        screenHeight * 0.02,
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
                        screenWidth * 0.06,
                        0,
                        screenWidth * 0.06,
                        screenHeight * 0.03,
                      ),
                      actions: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.read<RegistroBloc>().add(
                                  RemoverRegistro(
                                    registro.sincronizado,
                                    registro.id!,
                                  ),
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

                            SizedBox(height: screenHeight * 0.01),

                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                minimumSize: Size(
                                  double.infinity,
                                  buttonHeight * 0.8,
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
      return const Center(child: CircularProgressIndicator());
    }
  }
}
