import 'dart:io';

import 'package:condotop/utils/session_service.dart';
import 'package:condotop/views/cadastro_areas_comuns.dart';
import 'package:condotop/views/configurar_placa.dart';
import 'package:condotop/views/editar_perfil.dart';
import 'package:condotop/views/lista_ocorrencias_sindico.dart';
import 'package:condotop/views/redefinir_senha.dart';
import 'package:condotop/views/validar_morador.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class DocumentosGerais extends StatefulWidget {
  const DocumentosGerais({super.key});

  @override
  State<DocumentosGerais> createState() => _DocumentosGeraisState();
}

class _DocumentosGeraisState extends State<DocumentosGerais> {
  final SessionService _session = SessionService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _fotoPerfil;
  final orangeColor = const Color.fromARGB(255, 255, 0, 0);

  @override
  void initState() {
    super.initState();
    _carregarFotoPerfil();
  }

  Future<void> _carregarFotoPerfil() async {
    final idMorador = _session.getIdMorador();
    if (idMorador == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('foto_perfil_$idMorador');
    if (savedPath == null || savedPath.isEmpty) {
      return;
    }

    final file = File(savedPath);
    if (!await file.exists()) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _fotoPerfil = file;
    });
  }

  Future<void> _selecionarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (picked == null) {
      return;
    }

    await _salvarFotoPerfil(File(picked.path));
  }

  Future<void> _salvarFotoPerfil(File file) async {
    final idMorador = _session.getIdMorador();
    if (idMorador == null) {
      return;
    }

    // Limpar cache da imagem anterior
    if (_fotoPerfil != null) {
      imageCache.evict(FileImage(_fotoPerfil!));
      imageCache.clear();
    }

    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${appDir.path}/perfil');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    final extension = file.path.split('.').last;
    final destinationPath =
        '${profileDir.path}/foto_perfil_$idMorador.$extension';
    final savedFile = await file.copy(destinationPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_perfil_$idMorador', savedFile.path);

    if (!mounted) {
      return;
    }

    setState(() {
      _fotoPerfil = savedFile;
    });
  }

  Future<void> _onRefresh() async {
    // Limpar cache da imagem anterior
    if (_fotoPerfil != null) {
      imageCache.evict(FileImage(_fotoPerfil!));
      imageCache.clear();
    }
    setState(() {
      _fotoPerfil = null;
    });
    await _carregarFotoPerfil();
  }

  bool _isSindico() {
    final tipo = (_session.getUserTipo() ?? '').trim().toUpperCase();
    return tipo == 'S' || tipo == 'SINDICO' || tipo == 'SÍNDICO';
  }

  Widget _buildPrimaryButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool showLoader = false,
  }) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey.shade400 : color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isLoading ? 0 : 4,
          shadowColor: color.withOpacity(0.4),
        ),
        child: showLoader && _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);
    const orangeColor = const Color.fromARGB(255, 255, 102, 1);
    final isSindico = _isSindico();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            )),
        backgroundColor: Color.fromARGB(225, 0, 68, 170),
        centerTitle: true,
        title: Text(
          "Meu Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: blueColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: blueColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _fotoPerfil != null
                              ? Image.file(
                                  _fotoPerfil!,
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  gaplessPlayback: true,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/logo/logo_condotop_without_bckground.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: 6,
                        child: GestureDetector(
                          onTap: _selecionarFoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: orangeColor,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  _buildPrimaryButton(
                    title: 'Editar perfil',
                    icon: Icons.edit_rounded,
                    color: blueColor,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditarPerfil(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    title: 'Configurar placa',
                    icon: Icons.bluetooth_connected_rounded,
                    color: blueColor,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ConfigurarPlaca(),
                        ),
                      );
                    },
                  ),
                  if (isSindico) ...[
                    const SizedBox(height: 12),
                    _buildPrimaryButton(
                      title: 'Validar morador',
                      icon: Icons.verified_user_outlined,
                      color: blueColor,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ValidarMorador(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPrimaryButton(
                      title: 'Cadastrar áreas comuns',
                      icon: Icons.add_business_outlined,
                      color: blueColor,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CadastroAreasComuns(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPrimaryButton(
                      title: 'Lista de defeitos',
                      icon: Icons.build_circle_outlined,
                      color: blueColor,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ListaOcorrenciasSindico(
                              tituloTela: 'Defeitos',
                              endpoint: '/defeitos/',
                              tituloItem: 'Defeito',
                              mensagemVazia:
                                  'Nenhum defeito encontrado no momento.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPrimaryButton(
                      title: 'Lista de reclamações',
                      icon: Icons.comment_bank_outlined,
                      color: blueColor,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ListaOcorrenciasSindico(
                              tituloTela: 'Reclamações',
                              endpoint: '/reclamacoes/',
                              tituloItem: 'Reclamação',
                              mensagemVazia:
                                  'Nenhuma reclamação encontrada no momento.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    title: 'Redefinir senha',
                    icon: Icons.lock_reset_rounded,
                    color: blueColor,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RedefinirSenha(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    title: 'Sair',
                    icon: Icons.login_rounded,
                    color: orangeColor,
                    showLoader: true,
                    onPressed: () {
                      _session.clearSession();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
