import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const NotesApp());
}

class Note {
  const Note({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.isImportant = false,
  });

  final int id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isImportant;
}

class NotesProvider extends ChangeNotifier {
  final List<Note> _notes = [];
  int _nextId = 0;
  int? _editId;

  List<Note> get notes => List.unmodifiable(_notes);
  int? get editId => _editId;
  bool get isEditing => _editId != null;

  void startEditing(int noteId) {
    _editId = noteId;
    notifyListeners();
  }

  void cancelEditing() {
    _editId = null;
    notifyListeners();
  }

  void addNote(String text) {
    final now = DateTime.now();
    _notes.insert(
      0,
      Note(id: _nextId++, text: text, createdAt: now, updatedAt: now),
    );
    notifyListeners();
  }

  void updateNote(int id, String text) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    final note = _notes[index];
    _notes[index] = Note(
      id: note.id,
      text: text,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      isImportant: note.isImportant,
    );
    notifyListeners();
  }

  void setImportant(int id, bool isImportant) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1 || _notes[index].isImportant == isImportant) return;

    final note = _notes[index];
    _notes[index] = Note(
      id: note.id,
      text: note.text,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isImportant: isImportant,
    );
    notifyListeners();
  }

  ({Note note, int index})? deleteNote(int id) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return null;

    final note = _notes.removeAt(index);
    notifyListeners();
    return (note: note, index: index);
  }

  void restoreNote(Note note, int index) {
    _notes.insert(index.clamp(0, _notes.length).toInt(), note);
    notifyListeners();
  }
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesProvider(),
      child: MaterialApp(
        title: 'Мои заметки',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        home: const NotesPage(),
      ),
    );
  }

  ThemeData _lightTheme() {
    const teal = Color(0xFF197C72);
    const ink = Color(0xFF202A35);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F7F4),
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        onSurface: ink,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F7F4),
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9F7),
        hintStyle: TextStyle(color: ink.withValues(alpha: 0.42)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8ECE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
        ),
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _form = GlobalKey<FormState>();
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (!(_form.currentState?.validate() ?? false)) return;

    final notes = context.read<NotesProvider>();
    final editId = notes.editId;
    final text = _text.text.trim();
    if (editId == null) {
      notes.addNote(text);
    } else {
      notes.updateNote(editId, text);
      notes.cancelEditing();
    }

    _resetForm();
    FocusManager.instance.primaryFocus?.unfocus();
    _showMessage(editId == null ? 'Заметка добавлена' : 'Изменения сохранены');
  }

  void _startEditing(Note note) {
    context.read<NotesProvider>().startEditing(note.id);
    _text.text = note.text;
    final formContext = _form.currentContext;
    if (formContext != null) {
      Scrollable.ensureVisible(
        formContext,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  void _showNote(Note note) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заметка'),
        content: SingleChildScrollView(child: SelectableText(note.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _cancelEditing() {
    context.read<NotesProvider>().cancelEditing();
    _resetForm();
  }

  void _resetForm() {
    _text.clear();
    _form.currentState?.reset();
  }

  void _deleteNote(Note note) {
    final notes = context.read<NotesProvider>();
    final isEditingNote = notes.editId == note.id;
    final removed = notes.deleteNote(note.id);
    if (removed == null) return;

    if (isEditingNote) {
      notes.cancelEditing();
      _resetForm();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Заметка удалена'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () => context.read<NotesProvider>().restoreNote(
              removed.note,
              removed.index,
            ),
          ),
        ),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotesProvider>();
    final notes = state.notes;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF2EC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                color: Color(0xFF197C72),
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'Мои заметки',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _buildWelcomeHeader(notes.length),
                const SizedBox(height: 22),
                _buildEditor(state),
                const SizedBox(height: 28),
                _buildNotesHeading(notes.length),
                const SizedBox(height: 12),
                if (notes.isEmpty)
                  _buildEmptyState()
                else
                  ...notes.map(_buildNoteCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Записывайте важное',
                style: TextStyle(
                  color: Color(0xFF202A35),
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Все ваши мысли — в одном месте',
                style: TextStyle(color: Color(0xFF7A858C), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE8ECE8)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notes_rounded,
                size: 17,
                color: Color(0xFF197C72),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF202A35),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(NotesProvider state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A202A35),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isEditing
                      ? Icons.edit_note_rounded
                      : Icons.add_circle_outline,
                  size: 20,
                  color: const Color(0xFF197C72),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isEditing ? 'Редактирование' : 'Новая заметка',
                  style: const TextStyle(
                    color: Color(0xFF202A35),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _text,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Напишите, что важно запомнить…',
                counterStyle: TextStyle(color: Color(0xFF7A858C), fontSize: 11),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите текст заметки';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (state.isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEditing,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: const Color(0xFF42505A),
                        side: const BorderSide(color: Color(0xFFDDE4DF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: state.isEditing ? 2 : 1,
                  child: FilledButton.icon(
                    onPressed: _saveNote,
                    icon: Icon(
                      state.isEditing
                          ? Icons.check_rounded
                          : Icons.save_rounded,
                    ),
                    label: const Text('Сохранить'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFF197C72),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesHeading(int count) {
    final label = switch (count % 10) {
      1 when count % 100 != 11 => 'заметка',
      2 || 3 || 4 when count % 100 < 12 || count % 100 > 14 => 'заметки',
      _ => 'заметок',
    };

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Список заметок',
            style: TextStyle(
              color: Color(0xFF202A35),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count $label',
          style: const TextStyle(color: Color(0xFF7A858C), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF197C72),
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Здесь пока пусто',
            style: TextStyle(
              color: Color(0xFF202A35),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Добавьте первую заметку — она появится в этом списке.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF202A35).withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Dismissible(
      key: ValueKey('note-${note.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(isDelete: false),
      secondaryBackground: _swipeBackground(isDelete: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) return true;
        context.read<NotesProvider>().setImportant(note.id, false);
        return false;
      },
      onDismissed: (_) => _deleteNote(note),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showNote(note),
        onDoubleTap: () =>
            context.read<NotesProvider>().setImportant(note.id, true),
        onLongPress: () => _startEditing(note),
        child: Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.fromLTRB(16, 15, 10, 12),
          decoration: BoxDecoration(
            color: note.isImportant ? const Color(0xFFFFF7DB) : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE8ECE8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF28343C),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (note.isImportant) ...[
                          const Icon(
                            Icons.star_rounded,
                            key: ValueKey('important-star'),
                            size: 16,
                            color: Color(0xFFB48000),
                            semanticLabel: 'Важная заметка',
                          ),
                          const SizedBox(width: 5),
                        ],
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF8A9599),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(note.updatedAt),
                          style: const TextStyle(
                            color: Color(0xFF8A9599),
                            fontSize: 11,
                          ),
                        ),
                        if (note.updatedAt != note.createdAt) ...[
                          const SizedBox(width: 5),
                          const Text(
                            '· изменено',
                            style: TextStyle(
                              color: Color(0xFF8A9599),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () => _startEditing(note),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    color: const Color(0xFF197C72),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: () => _deleteNote(note),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: const Color(0xFF9A6C65),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground({required bool isDelete}) {
    return Container(
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDelete ? const Color(0xFFF8E4DF) : const Color(0xFFDFF2EC),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Icon(
        isDelete ? Icons.delete_outline_rounded : Icons.star_border_rounded,
        color: isDelete ? const Color(0xFF9A6C65) : const Color(0xFF197C72),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year}, '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
