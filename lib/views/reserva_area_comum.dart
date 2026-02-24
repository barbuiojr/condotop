import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ReservaAreaComum extends StatefulWidget {
  const ReservaAreaComum({super.key});

  @override
  State<ReservaAreaComum> createState() => _ReservaAreaComumState();
}

class _ReservaAreaComumState extends State<ReservaAreaComum> {
  final _apiService = ApiService();
  final _sessionService = SessionService();

  DateTime _selectedDate = _stripTime(DateTime.now());
  String? _errorMessage;
  String? _successMessage;
  static const int _minMinute = 7 * 60; // 07:00
  static const int _maxMinute = 22 * 60; // 22:00
  List<DateTime> datasBloqueadas = [];

  static DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isDiaBloqueado(DateTime day) {
    final normalized = _stripTime(day);
    return datasBloqueadas.any((data) => data == normalized);
  }

  bool _isDiaBloqueadoNaLista(DateTime day, List<DateTime> bloqueadas) {
    final normalized = _stripTime(day);
    return bloqueadas.any((data) => data == normalized);
  }

  DateTime? _proximaDataDisponivel(DateTime startDate, DateTime lastDate) {
    var cursor = _stripTime(startDate);
    final end = _stripTime(lastDate);

    while (!cursor.isAfter(end)) {
      if (!_isDiaBloqueado(cursor)) {
        return cursor;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return null;
  }

  DateTime? _proximaDataDisponivelComLista(
    DateTime startDate,
    DateTime lastDate,
    List<DateTime> bloqueadas,
  ) {
    var cursor = _stripTime(startDate);
    final end = _stripTime(lastDate);

    while (!cursor.isAfter(end)) {
      if (!_isDiaBloqueadoNaLista(cursor, bloqueadas)) {
        return cursor;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return null;
  }

  Future<void> buscaReservas({bool ajustarDataSelecionada = true}) async {
    final idCondominio = _sessionService.getIdCondominio();
    if (idCondominio == null) {
      return;
    }

    try {
      final response = await _apiService
          .get('/reservas-area-comum/condominio/$idCondominio');
      print("Reservas: ${response.data}");
      final reservas = (response.data as List)
          .map((reserva) {
            final dataTexto = (reserva['data_reserva'] ?? '').toString();
            final parteData = dataTexto.split('T').first;
            return DateTime.parse(parteData);
          })
          .map(_stripTime)
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));

      if (!mounted) {
        return;
      }

      final hoje = _stripTime(DateTime.now());
      final ultimoDia = hoje.add(const Duration(days: 365));
      final proximaDisponivel =
          _proximaDataDisponivelComLista(hoje, ultimoDia, reservas);

      setState(() {
        datasBloqueadas = reservas;
        if (ajustarDataSelecionada) {
          _selectedDate = proximaDisponivel ?? hoje;
        }
      });

      // Processar reservas conforme necessário
    } catch (e) {
      print("Erro ao buscar reservas: $e");
    }
  }

  initState() {
    super.initState();
    buscaReservas();
  }

  @override
  Widget build(BuildContext context) {
    final firstDate = _stripTime(DateTime.now());
    final lastDate = _stripTime(DateTime.now().add(const Duration(days: 365)));
    final hasAvailableDate =
        _proximaDataDisponivel(firstDate, lastDate) != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(225, 0, 68, 170),
        centerTitle: true,
        title: const Text(
          "Reserva de Área Comum",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              "Selecione uma data para reservar",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),

            // Calendário
            if (hasAvailableDate)
              Container(
                decoration: BoxDecoration(
                  // color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  selectableDayPredicate: (DateTime day) {
                    return !_isDiaBloqueado(day);
                  },
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = _stripTime(date);
                    });
                    _abrirDialogReserva(date);
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Não há datas disponíveis para reserva no período.',
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _successMessage!,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _compararHoras(TimeOfDay hora1, TimeOfDay hora2) {
    final minutos1 = hora1.hour * 60 + hora1.minute;
    final minutos2 = hora2.hour * 60 + hora2.minute;
    return minutos1.compareTo(minutos2);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23);
    final m = (minutes % 60).clamp(0, 59);
    return TimeOfDay(hour: h, minute: m);
  }

  bool _isInAllowedRange(TimeOfDay t) {
    final m = _toMinutes(t);
    return m >= _minMinute && m <= _maxMinute;
  }

  String _allowedRangeText() => "07:00–22:00";

  Future<void> _abrirDialogReserva(DateTime dataSelecionada) async {
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);
    TimeOfDay horaInicio = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay horaFim = const TimeOfDay(hour: 22, minute: 0);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> selecionarHoraInicio() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: horaInicio,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setStateDialog(() {
                  // Aplicar faixa permitida (07:00–22:00)
                  if (!_isInAllowedRange(picked)) {
                    final m = _toMinutes(picked);
                    horaInicio =
                        _fromMinutes(m < _minMinute ? _minMinute : _maxMinute);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Horário permitido: ${_allowedRangeText()}'),
                      ),
                    );
                  } else {
                    horaInicio = picked;
                  }

                  // Hora fim não pode ser menor/igual ao início → ajustar para pelo menos +1min
                  if (_toMinutes(horaFim) <= _toMinutes(horaInicio)) {
                    final adjusted = (_toMinutes(horaInicio) + 1)
                        .clamp(_minMinute, _maxMinute);
                    horaFim = _fromMinutes(adjusted);
                  }
                });
              }
            }

            Future<void> selecionarHoraFim() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: horaFim,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setStateDialog(() {
                  // Aplicar faixa permitida (07:00–22:00)
                  TimeOfDay novoFim = picked;
                  if (!_isInAllowedRange(novoFim)) {
                    final m = _toMinutes(novoFim);
                    novoFim =
                        _fromMinutes(m < _minMinute ? _minMinute : _maxMinute);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Horário permitido: ${_allowedRangeText()}'),
                      ),
                    );
                  }

                  // Hora fim não pode ser menor/igual ao início
                  if (_toMinutes(novoFim) <= _toMinutes(horaInicio)) {
                    final adjusted = (_toMinutes(horaInicio) + 1)
                        .clamp(_minMinute, _maxMinute);
                    novoFim = _fromMinutes(adjusted);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Hora de fim deve ser depois da hora de início'),
                      ),
                    );
                  }

                  horaFim = novoFim;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Nova Reserva",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Data selecionada: ${_formatarData(dataSelecionada)}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hora início
                    Text(
                      "Hora de início: 07:00",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    // const SizedBox(height: 4),
                    // InkWell(
                    //   onTap: selecionarHoraInicio,
                    //   child: _buildTimeField(
                    //     label: _formatarHora(horaInicio),
                    //     icon: Icons.access_time,
                    //   ),
                    // ),

                    const SizedBox(height: 12),

                    // Hora fim
                    Text(
                      "Hora de fim: 22:00",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // InkWell(
                    //   onTap: selecionarHoraFim,
                    //   child: _buildTimeField(
                    //     label: _formatarHora(horaFim),
                    //     icon: Icons.access_time_filled,
                    //   ),
                    // ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // Validação: hora fim deve ser depois da hora início
                    final minutosInicio =
                        horaInicio.hour * 60 + horaInicio.minute;
                    final minutosFim = horaFim.hour * 60 + horaFim.minute;

                    if (minutosInicio < _minMinute ||
                        minutosInicio > _maxMinute) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Hora de início deve estar entre ${_allowedRangeText()}'),
                        ),
                      );
                      return;
                    }
                    if (minutosFim < _minMinute || minutosFim > _maxMinute) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Hora de fim deve estar entre ${_allowedRangeText()}'),
                        ),
                      );
                      return;
                    }
                    if (minutosFim <= minutosInicio) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Hora de fim deve ser depois da hora de início'),
                        ),
                      );
                      return;
                    }

                    // Combinar data selecionada com as horas
                    final horaInicioCompleta = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      horaInicio.hour,
                      horaInicio.minute,
                    );

                    final horaFimCompleta = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      horaFim.hour,
                      horaFim.minute,
                    );

                    await _registrarReserva(
                        horaInicioCompleta, horaFimCompleta, dataSelecionada);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    "Registrar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeField({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarHora(TimeOfDay hora) {
    final horaStr = hora.hour.toString().padLeft(2, '0');
    final minutoStr = hora.minute.toString().padLeft(2, '0');
    return "$horaStr:$minutoStr";
  }

  String _formatarData(DateTime date) {
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final ano = date.year.toString();
    return "$dia/$mes/$ano";
  }

  Future<void> _registrarReserva(
      DateTime horaInicio, DateTime horaFim, DateTime dataEscolhida) async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final idMorador = _sessionService.getIdMorador();
      final idCondominio = _sessionService.getIdCondominio();

      if (idMorador == null || idCondominio == null) {
        setState(() {
          _errorMessage =
              'Erro: Dados do usuário não encontrados. Faça login novamente.';
        });
        return;
      }

      // Verificar novamente no backend se o dia ainda está livre
      await buscaReservas(ajustarDataSelecionada: false);
      if (_isDiaBloqueado(dataEscolhida)) {
        setState(() {
          _errorMessage =
              'Esta data já foi reservada por outro usuário. Selecione outro dia.';
        });
        return;
      }

      final body = {
        "id_morador": idMorador,
        "id_condominio": idCondominio,
        "hora_inicio": horaInicio.toString(),
        "hora_fim": horaFim.toString(),
        "data_reserva": dataEscolhida.toIso8601String(),
      };

      // Ajuste a rota conforme seu backend
      final response = await _apiService.post('/reservas-area-comum/', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _successMessage = 'Reserva registrada com sucesso!';
        });
        await buscaReservas(); // Atualizar reservas para bloquear a data recém-reservada
      } else {
        setState(() {
          _errorMessage = 'Erro ao registrar reserva. Tente novamente.';
        });
      }
    } catch (e) {
      String msg = 'Erro ao registrar reserva. Tente novamente.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['message'] != null) {
          msg = data['message'].toString();
        } else if (data['error'] != null) {
          msg = data['error'].toString();
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    }
  }
}
