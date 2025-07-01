import 'package:avisai4/bloc/auth/auth_bloc.dart';
import 'package:avisai4/services/user_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/usuario.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with TickerProviderStateMixin {
  Usuario? usuario;
  bool isLoading = true;
  bool _isContatosExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();

    // Configurar animação
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final userData = await UserLocalStorage.obterUsuario();
      setState(() {
        usuario = userData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatarCpf(String? cpf) {
    if (cpf == null || cpf.length != 11) return cpf ?? '';

    return '***${cpf.substring(3, 6)}.***-**';
  }

  void _toggleContatos() {
    setState(() {
      _isContatosExpanded = !_isContatosExpanded;
    });

    if (_isContatosExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _mostrarDialogExclusao(BuildContext context) async {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Usuário deve escolher uma opção
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(screenWidth * 0.06),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de aviso
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: screenWidth * 0.08,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: screenWidth * 0.04),

              // Título
              Text(
                'Excluir Conta',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenWidth * 0.03),

              // Mensagem de confirmação
              Text(
                'Tem certeza que deseja excluir sua conta? Esta ação é irreversível e todos os seus dados pessoais serão apagados do sistema.',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.black54,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenWidth * 0.06),

              // Botões
              Row(
                children: [
                  // Botão Cancelar
                  Expanded(
                    child: Container(
                      height: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: screenWidth * 0.03),

                  // Botão Excluir
                  Expanded(
                    child: Container(
                      height: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Aqui você chama a ação de exclusão
                          context.read<AuthBloc>().add(ExclusaoSolicitado());
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Excluir',
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarMenuAjuda(BuildContext context) async {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: screenWidth * 0.9,
            constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002569),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menu de Ajuda',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Conteúdo scrollável
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seção: Cadastro, Login e Troca de Senha
                        _buildHelpSection(
                          context,
                          'Cadastro, Login e Troca de Senha',
                          Icons.account_circle,
                          [
                            '• Depois do primeiro login, você consegue entrar automaticamente no app sem nenhum esforço.',
                            '• Caso você se desconecte do app, será necessário logar novamente com seus dados cadastrados (CPF e senha).',
                            '• Esqueceu sua senha? Toque em "Esqueci minha senha" na tela de login ou no botão "Alterar senha" na página de perfil e siga as instruções enviadas para seu e-mail.',
                            '• Se você não receber o e-mail de recuperação, verifique sua caixa de spam ou lixo eletrônico.',
                          ],
                          screenWidth,
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Seção: Como usar o App
                        _buildHelpSection(context, 'Como usar o App', Icons.smartphone, [
                          '• Este app serve para registrar irregularidades urbanas através de fotos.',
                          '• Principais categorias: buracos na via, postes com defeito, lixo descartado irregularmente.',
                          '• Para registrar: tire uma foto, selecione a categoria e adicione observações, se necessário.',
                          '• A localização é adquirida automaticamente, por isso é importante conceder permissão de acesso à sua localização na inicialização do app.',
                          '• Sem conexão com internet? Você pode registrar problemas offline e eles serão enviados automaticamente quando a conexão for restabelecida.',
                          '• Inicialmente, dados enviados de forma offline (sem internet) são marcados como "Não sincronizados". Para que a asincronização ocorra, é necessário que o app tenha acesso à internet.',
                          '• Tenha paciência com a sincronização, principalmente se houver muitos registros, pois ela pode levar alguns minutos dependendo da sua conexão.',
                          '• Para cada usuário, registros são enviados e armazenados de acordo com as distâncias entre si. Por isso, ao tentar fazer um novo registro a menos de 10 metros de outro já feito por você, o sistema interpretará como o mesmo registro e não o enviará novamente',
                          '• Mantenha um comportamento respeitoso e registre apenas problemas reais.',
                        ], screenWidth),

                        SizedBox(height: screenHeight * 0.02),

                        // Seção: Visualização de Registros
                        _buildHelpSection(context, 'Seus Registros', Icons.list_alt, [
                          '• Na tela "Histórico" você pode ver todos os seus registros assim como pode filtrá-los.',
                          '• Toque em um registro para ver mais detalhes sobre ele.',
                          '• O status no canto superior direito indica o andamento da solução pelos órgãos responsáveis. Cada um dos status tem um significado específico:\n- "Pendente": Registro criado, mas ainda não foi analisado.\n- "Validado": Registro analisado e aprovado.\n- "Não validado": Registro analisado, mas não aprovado (uma mensagem na tela de detalhes explica o motivo).\n- "Em rota": Uma equipe foi designada até o local e está em processo de resolução.\n- "Resolvido": O problema foi solucionado',
                          '• Na tela "Mapa", você pode visualizar a localização exata de seus registros.',
                          '• Recomendamos dar zoom no pin do mapa para maior precisão da localização do registro.',
                        ], screenWidth),

                        SizedBox(height: screenHeight * 0.02),

                        // Seção: Contato
                        _buildHelpSection(
                          context,
                          'Precisa de Ajuda?',
                          Icons.contact_support,
                          [
                            '• Está com dúvidas ou problemas com o app?',
                            '• Entre em contato conosco através do e-mail: avisaithepi@gmail.com',
                            '• Responderemos o mais breve possível!',
                            '• Agradecemos sua paciência e compreensão.',
                          ],
                          screenWidth,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> content,
    double screenWidth,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Row(
            children: [
              Icon(icon, color: const Color(0xFF002569), size: 24),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF002569),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.03),

          // Conteúdo da seção
          ...content
              .map(
                (text) => Padding(
                  padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF002569)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          children: [
            // Card do perfil do usuário
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              padding: EdgeInsets.all(screenWidth * 0.06),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ícone de perfil
                  Container(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A4A4A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: screenWidth * 0.15,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Nome do usuário
                  Text(
                    usuario?.nome ?? 'Nome não disponível',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.025),

                  // Informações do usuário
                  Column(
                    children: [
                      // Email
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.grey[800], size: 27),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'E-mail: ${usuario!.email}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black54,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // CPF
                      Row(
                        children: [
                          Icon(Icons.badge, color: Colors.grey[800], size: 27),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'CPF: ${_formatarCpf(usuario?.cpf)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black54,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Contatos (com dropdown animado)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header do Card Contatos
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    leading: Icon(
                      Icons.contacts,
                      color: Colors.grey[800],
                      size: 35,
                    ),
                    title: Text(
                      'Contatos',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                    trailing: AnimatedRotation(
                      turns: _isContatosExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[800],
                        size: 24,
                      ),
                    ),
                    onTap: _toggleContatos,
                  ),

                  // Conteúdo expandível
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04,
                        bottom: screenHeight * 0.02,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                'avisaithepi@gmail.com',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.black87,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                leading: Icon(
                  Icons.help_outline,
                  color: Colors.grey[800],
                  size: 35,
                ),
                title: Text(
                  'Ajuda',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[800],
                  size: 20,
                ),
                onTap: () {
                  _mostrarMenuAjuda(context);
                },
              ),
            ),

            // Card Alterar Senha
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                leading: Icon(
                  Icons.password,
                  color: Colors.grey[800],
                  size: 35,
                ),
                title: Text(
                  'Alterar Senha',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[800],
                  size: 20,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/forgot-password');
                },
              ),
            ),

            // Card Excluir Conta
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                leading: const Icon(Icons.delete, color: Colors.red, size: 30),
                title: Text(
                  'Excluir conta',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                    fontFamily: 'Inter',
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red,
                  size: 20,
                ),
                onTap: () {
                  _mostrarDialogExclusao(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
