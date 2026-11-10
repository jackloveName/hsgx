import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/theme.dart';
import 'package:hsgx/widgets.dart';

void main() {
  test('每套皮肤都会向页面和导航提供同一组主题令牌', () {
    for (var index = 0; index < appSkins.length; index++) {
      final skin = appSkinAt(index);
      final theme = buildAppTheme(index);
      final tokens = theme.extension<AppThemeTokens>()!;

      expect(theme.colorScheme.primary, skin.primary);
      expect(tokens.heroStart, skin.heroStart);
      expect(tokens.heroEnd, skin.heroEnd);
      expect(tokens.softPrimary, Color.lerp(skin.primary, Colors.white, 0.88));
    }
  });

  testWidgets('页面渐变默认使用当前主题令牌', (tester) async {
    final theme = buildAppTheme(2);
    final tokens = theme.extension<AppThemeTokens>()!;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: GradientCard(child: SizedBox(height: 80))),
      ),
    );

    final decorations = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(GradientCard),
            matching: find.byType(Container),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    final gradient = decorations.first.gradient! as LinearGradient;

    expect(gradient.colors, [tokens.heroStart, tokens.heroEnd]);
  });

  testWidgets('TabBar 选中态和悬浮按钮跟随当前主题色', (tester) async {
    final skin = appSkinAt(4);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(4), home: const MainShell()),
    );
    await tester.pump();

    final selectedLabel = tester.widget<Text>(find.text('首页').first);
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );

    expect(selectedLabel.style?.color, skin.primary);
    expect(fab.backgroundColor, skin.primary);
  });
}
