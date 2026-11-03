import 'package:flutter/material.dart';
import 'comun.dart';

/// CHAT de un match, en tiempo real (Supabase Realtime)
class ChatScreen extends StatefulWidget {
  final String matchId;
  final String nombreOtra;
  const ChatScreen({super.key, required this.matchId, required this.nombreOtra});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _texto = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _mensajes;

  @override
  void initState() {
    super.initState();
    // stream(): Supabase avisa a la app cada vez que llega un mensaje nuevo
    _mensajes = supabase
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('match_id', widget.matchId)
        .order('created_at', ascending: false);
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty) return;
    _texto.clear();
    try {
      await supabase.from('mensajes').insert({'match_id': widget.matchId, 'autor_id': miId, 'texto': texto});
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo enviar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colores.fondo, title: Text('Chat con el dueño de ${widget.nombreOtra}')),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _mensajes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colores.rosa));
              final mensajes = snapshot.data!;
              if (mensajes.isEmpty) {
                return const Center(
                    child: Text('Saluden y coordinen una salida 🐶', style: TextStyle(color: Colors.white70)));
              }
              return ListView.builder(
                reverse: true, // el más nuevo abajo
                padding: const EdgeInsets.all(12),
                itemCount: mensajes.length,
                itemBuilder: (_, i) {
                  final m = mensajes[i];
                  final esMio = m['autor_id'] == miId;
                  return Align(
                    alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: esMio ? Colores.rosa.withOpacity(0.85) : Colores.tarjeta,
                        borderRadius: BorderRadius.circular(16),
                        border: esMio ? null : Border.all(color: Colores.morado),
                      ),
                      child: Text(m['texto'] as String, style: const TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _texto,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decoracionCampo('Escribe un mensaje...'),
                  onSubmitted: (_) => _enviar(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colores.rosa,
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _enviar),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
