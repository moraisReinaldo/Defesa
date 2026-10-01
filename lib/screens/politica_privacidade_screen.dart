import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class PoliticaPrivacidadeScreen extends StatefulWidget {
  final bool isRegistration;

  const PoliticaPrivacidadeScreen({super.key, this.isRegistration = false});

  @override
  State<PoliticaPrivacidadeScreen> createState() => _PoliticaPrivacidadeScreenState();
}

class _PoliticaPrivacidadeScreenState extends State<PoliticaPrivacidadeScreen> {
  String _htmlContent = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      final html = await rootBundle.loadString('assets/html/politica.html');
      setState(() {
        _htmlContent = html;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _htmlContent = '<p>Erro ao carregar a política de privacidade.</p>';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade e Termos'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: HtmlWidget(
                _htmlContent,
              ),
            ),
      bottomNavigationBar: widget.isRegistration
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true); // Accepted
                },
                child: const Text('Li e Concordo'),
              ),
            )
          : null,
    );
  }
}
