import 'package:flutter/material.dart';

import '../services/ai_analyzer.dart';

import '../models/measurement.dart';

class FragAIPage extends StatefulWidget {

  final List<Measurement> measurements;

  const FragAIPage({

    super.key,

    required this.measurements,

  });

  @override

  State<FragAIPage> createState() => _FragAIPageState();

}

class _FragAIPageState extends State<FragAIPage> {

  final TextEditingController _controller = TextEditingController();

  final List<_ChatMessage> _messages = [];

  final ScrollController _scrollController = ScrollController();

  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }

  void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });
}

  void _sendMessage() {

    final text = _controller.text.trim();

    if (text.isEmpty) return;

    final analyzer = QSAnalyzer(widget.measurements);

    final result = analyzer.analyze(text);

    setState(() {

      _messages.add(

        _ChatMessage(

          text: text,

          isUser: true,

        ),

      );

      _messages.add(

        _ChatMessage(

          text: result.answer,

          isUser: false,

        ),

      );

    });

    _controller.clear();
    _scrollToBottom();

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(

        child: Column(

          children: [

            _buildHeader(),

            Expanded(

              child: _messages.isEmpty

                  ? _buildEmptyState()

                  : _buildChat(),

            ),

            _buildInput(),

          ],

        ),

      ),

    );

  }

  Widget _buildHeader() {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 20, 32, 24),

      decoration: const BoxDecoration(

        color: Colors.white,

        border: Border(

          bottom: BorderSide(

            color: Color(0xFFE2E8F0),

          ),

        ),

      ),

      child: Row(

        children: [

          IconButton(

            onPressed: () {

              if (Navigator.canPop(context)) {

                Navigator.pop(context);

              }

            },

            tooltip: 'Zurück',

            icon: const Icon(

              Icons.arrow_back,

              color: Color(0xFF334155),

              size: 22,

            ),

          ),

          const SizedBox(width: 8),

          Container(

            width: 48,

            height: 48,

            decoration: BoxDecoration(

              color: const Color(0xFFE0ECFF),

              borderRadius: BorderRadius.circular(14),

            ),

            child: const Icon(

              Icons.auto_awesome,

              color: Color(0xFF2563EB),

              size: 25,

            ),

          ),

          const SizedBox(width: 16),

          const Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                'Frag KI',

                style: TextStyle(

                  fontSize: 25,

                  fontWeight: FontWeight.bold,

                  color: Color(0xFF172033),

                ),

              ),

              SizedBox(height: 3),

              Text(

                'Intelligente Analyse deiner QS-Messdaten',

                style: TextStyle(

                  fontSize: 14,

                  color: Color(0xFF64748B),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }

  Widget _buildEmptyState() {

    return Center(

      child: SingleChildScrollView(

        padding: const EdgeInsets.all(32),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              width: 76,

              height: 76,

              decoration: BoxDecoration(

                color: const Color(0xFFE0ECFF),

                borderRadius: BorderRadius.circular(22),

              ),

              child: const Icon(

                Icons.auto_awesome,

                color: Color(0xFF2563EB),

                size: 38,

              ),

            ),

            const SizedBox(height: 22),

            const Text(

              'Wie kann ich dir helfen?',

              textAlign: TextAlign.center,

              style: TextStyle(

                fontSize: 24,

                fontWeight: FontWeight.bold,

                color: Color(0xFF172033),

              ),

            ),

            const SizedBox(height: 10),

            const Text(

              'Stelle eine Frage zu deinen Messungen,\n'

              'Farben, Abweichungen oder Trends.',

              textAlign: TextAlign.center,

              style: TextStyle(

                fontSize: 15,

                height: 1.5,

                color: Color(0xFF64748B),

              ),

            ),

            const SizedBox(height: 30),

            Wrap(

              spacing: 12,

              runSpacing: 12,

              alignment: WrapAlignment.center,

              children: [

                _suggestion(

                  'Welche Artikel haben die meisten Abweichungen?',

                ),

                _suggestion(

                  'Welche Messungen sind außerhalb der Toleranz?',

                ),

                _suggestion(

                  'Wie entwickelt sich ΔL* über die Zeit?',

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

  Widget _suggestion(String text) {

    return InkWell(

      onTap: () {

        _controller.text = text;

        _sendMessage();

      },

      borderRadius: BorderRadius.circular(12),

      child: Container(

        constraints: const BoxConstraints(

          maxWidth: 340,

        ),

        padding: const EdgeInsets.symmetric(

          horizontal: 16,

          vertical: 13,

        ),

        decoration: BoxDecoration(

          color: Colors.white,

          border: Border.all(

            color: const Color(0xFFD9E2EC),

          ),

          borderRadius: BorderRadius.circular(12),

        ),

        child: Text(

          text,

          style: const TextStyle(

            fontSize: 16,

            color: Color(0xFF334155),

          ),

        ),

      ),

    );

  }

  Widget _buildChat() {

    return ListView.builder(
      controller: _scrollController,

      padding: const EdgeInsets.symmetric(

        horizontal: 32,

        vertical: 28,

      ),

      itemCount: _messages.length,

      itemBuilder: (context, index) {

        final message = _messages[index];

        return Align(

          alignment: message.isUser

              ? Alignment.centerRight

              : Alignment.centerLeft,

          child: Container(

            constraints: const BoxConstraints(

              maxWidth: 760,

            ),

            margin: const EdgeInsets.only(bottom: 20),

            padding: EdgeInsets.symmetric(

              horizontal: message.isUser ? 18 : 24,

              vertical: message.isUser ? 14 : 20,

            ),

            decoration: BoxDecoration(

              color: message.isUser

                  ? const Color(0xFF2563EB)

                  : Colors.white,

              borderRadius: BorderRadius.circular(14),

              border: message.isUser

                  ? null

                  : Border.all(

                      color: const Color(0xFFE2E8F0),

                    ),

            ),

            child: message.isUser

                ? Text(

                    message.text,

                    style: const TextStyle(

                      fontSize: 15,

                      height: 1.5,

                      color: Colors.white,

                    ),

                  )

                : _buildAIResponse(message.text),

          ),

        );

      },

    );

  }

  Widget _buildAIResponse(String text) {

    final lines = text.split('\n');

    final widgets = <Widget>[];

    bool firstContentLine = true;

    for (final rawLine in lines) {

      final line = rawLine.trim();

      if (line.isEmpty) {

        widgets.add(

          const SizedBox(height: 10),

        );

        continue;

      }

      // Primeira linha da resposta:

      // apresentada como título principal.

      if (firstContentLine) {

        firstContentLine = false;

        widgets.add(

          Padding(

            padding: const EdgeInsets.only(

              bottom: 6,

            ),

            child: Text.rich(

              TextSpan(

                children: _parseBoldText(line),

              ),

              style: const TextStyle(

                fontSize: 18,

                height: 1.35,

                fontWeight: FontWeight.w700,

                color: Colors.black,

              ),

            ),

          ),

        );

        continue;

      }

      // Títulos das secções principais da análise.

      if (_isSectionTitle(line)) {

        widgets.add(

          Padding(

            padding: const EdgeInsets.only(

              top: 8,

              bottom: 5,

            ),

            child: Text(

              line,

              style: const TextStyle(

                fontSize: 15,

                height: 1.4,

                fontWeight: FontWeight.w700,

                color: Colors.black,

              ),

            ),

          ),

        );

        continue;

      }

      // Bullet points.

      if (line.startsWith('•')) {

        final bulletText = line.substring(1).trim();

        widgets.add(

          Padding(

            padding: const EdgeInsets.only(

              bottom: 5,

            ),

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Padding(

                  padding: EdgeInsets.only(

                    top: 1,

                    right: 9,

                  ),

                  child: Text(

                    '•',

                    style: TextStyle(

                      fontSize: 15,

                      height: 1.5,

                      fontWeight: FontWeight.w700,

                      color: Colors.black,

                    ),

                  ),

                ),

                Expanded(

                  child: _buildFormattedText(

                    bulletText,

                    fontSize: 15,

                  ),

                ),

              ],

            ),

          ),

        );

        continue;

      }

      // Listas numeradas, caso sejam usadas futuramente

      // pelo analyzer.

      if (_isNumberedListItem(line)) {

        final separatorIndex = line.indexOf('.');

        final number = line.substring(

          0,

          separatorIndex + 1,

        );

        final itemText = line.substring(

          separatorIndex + 1,

        ).trim();

        widgets.add(

          Padding(

            padding: const EdgeInsets.only(

              bottom: 5,

            ),

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                SizedBox(

                  width: 28,

                  child: Text(

                    number,

                    style: const TextStyle(

                      fontSize: 15,

                      height: 1.5,

                      fontWeight: FontWeight.w700,

                      color: Colors.black,

                    ),

                  ),

                ),

                Expanded(

                  child: _buildFormattedText(

                    itemText,

                    fontSize: 15,

                  ),

                ),

              ],

            ),

          ),

        );

        continue;

      }

      // Tabela estruturada produzida pelo analyzer.
      // Formato: TABLE|cab1|cab2|...;;cel1|cel2|...;;...
      if (line.startsWith('TABLE|')) {
        final encodedRows = line.substring('TABLE|'.length).split(';;');
        final rows = encodedRows
            .map(
              (row) => row
                  .split('|')
                  .map((cell) => cell.trim())
                  .toList(),
            )
            .where((row) => row.isNotEmpty)
            .toList();

        if (rows.isNotEmpty) {
          widgets.add(_buildAnalysisTable(rows));
        }
        continue;
      }

      // Texto normal.

      widgets.add(

        Padding(

          padding: const EdgeInsets.only(

            bottom: 3,

          ),

          child: _buildFormattedText(

            line,

            fontSize: 15,

          ),

        ),

      );

    }

    return SelectionArea(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: widgets,

      ),

    );

  }

  Widget _buildAnalysisTable(List<List<String>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final header = rows.first;
    final body = rows.skip(1).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.35),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.0),
            },
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE2E8F0)),
              verticalInside: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                children: header.map((cell) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      cell,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172033),
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...body.map(
                (row) => TableRow(
                  children: row.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Text(
                        cell,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSectionTitle(String line) {

    const titles = {

      'Ergebnis',

      'Auffälligkeiten',

      'Entscheidende Abweichung',

      'Einordnung',

      'Vergleich mit anderen BAs desselben Artikels',

      'Empfohlene Prüfung',

      'Hinweis',

    };

    return titles.contains(line);

  }

  bool _isNumberedListItem(String line) {

    return RegExp(r'^\d+\.\s+').hasMatch(line);

  }

  Widget _buildFormattedText(

    String text, {

    double fontSize = 15,

  }) {

    return Text.rich(

      TextSpan(

        children: _parseBoldText(text),

      ),

      style: TextStyle(

        fontSize: fontSize,

        height: 1.5,

        color: Colors.black,

      ),

    );

  }

  List<TextSpan> _parseBoldText(String text) {

    final spans = <TextSpan>[];

    final regex = RegExp(r'\*\*(.*?)\*\*');

    int currentIndex = 0;

    for (final match in regex.allMatches(text)) {

      if (match.start > currentIndex) {

        spans.add(

          TextSpan(

            text: text.substring(

              currentIndex,

              match.start,

            ),

          ),

        );

      }

      spans.add(

        TextSpan(

          text: match.group(1),

          style: const TextStyle(

            fontWeight: FontWeight.w700,

          ),

        ),

      );

      currentIndex = match.end;

    }

    if (currentIndex < text.length) {

      spans.add(

        TextSpan(

          text: text.substring(currentIndex),

        ),

      );

    }

    return spans;

  }

  Widget _buildInput() {

    return Container(

      padding: const EdgeInsets.fromLTRB(

        32,

        16,

        32,

        24,

      ),

      decoration: const BoxDecoration(

        color: Colors.white,

        border: Border(

          top: BorderSide(

            color: Color(0xFFE2E8F0),

          ),

        ),

      ),

      child: Center(

        child: ConstrainedBox(

          constraints: const BoxConstraints(

            maxWidth: 900,

          ),

          child: Row(

            children: [

              Expanded(

                child: TextField(

                  controller: _controller,

                  onSubmitted: (_) => _sendMessage(),

                  decoration: InputDecoration(

                    hintText: 'Frage eingeben...',

                    filled: true,

                    fillColor: const Color(0xFFF8FAFC),

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: const BorderSide(

                        color: Color(0xFFD9E2EC),

                      ),

                    ),

                    enabledBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: const BorderSide(

                        color: Color(0xFFD9E2EC),

                      ),

                    ),

                    focusedBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: const BorderSide(

                        color: Color(0xFF2563EB),

                      ),

                    ),

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 18,

                      vertical: 16,

                    ),

                  ),

                ),

              ),

              const SizedBox(width: 12),

              SizedBox(

                height: 54,

                width: 54,

                child: ElevatedButton(

                  onPressed: _sendMessage,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFF2563EB),

                    foregroundColor: Colors.white,

                    elevation: 0,

                    padding: EdgeInsets.zero,

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(14),

                    ),

                  ),

                  child: const Icon(

                    Icons.arrow_upward,

                    size: 22,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}

class _ChatMessage {

  final String text;

  final bool isUser;

  const _ChatMessage({

    required this.text,

    required this.isUser,

  });

}
