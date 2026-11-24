import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';

void main() {
  testWidgets('жесты открывают, отмечают, редактируют и удаляют заметку', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());
    final longText = List.filled(35, 'Длинный текст заметки').join(' ');

    await tester.enterText(find.byType(TextFormField), longText);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Другая заметка');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('note-0'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();

    Offset cardPoint() => tester.getTopLeft(card) + const Offset(60, 20);

    await tester.tapAt(cardPoint());
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      longText,
    );
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    await tester.tapAt(cardPoint());
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(cardPoint());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('important-star')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.drag(card, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    expect(find.byKey(const ValueKey('important-star')), findsNothing);

    await tester.tapAt(cardPoint());
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(cardPoint());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('important-star')), findsOneWidget);

    await tester.longPressAt(cardPoint());
    await tester.pumpAndSettle();
    expect(find.text('Редактирование'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      longText,
    );
    await tester.enterText(find.byType(TextFormField), 'Изменённая заметка');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Изменённая заметка'), findsOneWidget);
    expect(find.text('Другая заметка'), findsOneWidget);
    expect(find.byKey(const ValueKey('important-star')), findsOneWidget);

    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.drag(card, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Изменённая заметка'), findsNothing);
    expect(find.text('Другая заметка'), findsOneWidget);
    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(find.text('Изменённая заметка'), findsOneWidget);
    expect(find.byKey(const ValueKey('important-star')), findsOneWidget);
  });

  testWidgets('создает заметку и проверяет пустой ввод', (tester) async {
    await tester.pumpWidget(const NotesApp());

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите текст заметки'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Купить тетрадь');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Купить тетрадь'), findsOneWidget);
    expect(find.text('1 заметка'), findsOneWidget);
  });

  testWidgets('редактирует, удаляет заметку и восстанавливает ее', (
    tester,
  ) async {
    await tester.pumpWidget(const NotesApp());

    await tester.enterText(find.byType(TextFormField), 'Черновик');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Редактировать'));
    await tester.tap(find.byTooltip('Редактировать'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Готовая заметка');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Готовая заметка'), findsOneWidget);
    expect(find.text('Черновик'), findsNothing);

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold)),
    ).hideCurrentSnackBar();
    Tooltip.dismissAllToolTips();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Готовая заметка'), findsNothing);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(find.text('Готовая заметка'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Здесь пока пусто'), findsOneWidget);
  });
}
