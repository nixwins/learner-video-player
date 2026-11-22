import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/subtitles/presentation/clickable_subtitle.dart';

void main() {
  testWidgets('tapping a word reports exactly that word', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClickableSubtitle(text: 'Hello, world!', onWordTap: tapped.add),
        ),
      ),
    );

    await tester.tap(find.text('world'));
    expect(tapped, ['world']);
  });

  testWidgets('empty text renders nothing tappable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClickableSubtitle(text: '', onWordTap: (_) {}),
        ),
      ),
    );
    expect(find.byType(Wrap), findsNothing);
  });
}
