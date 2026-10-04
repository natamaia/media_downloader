import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('MediaDownloaderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaDownloaderApp());
    expect(find.text('MediaDownloader'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
  });
}
