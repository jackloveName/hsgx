import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/theme.dart';
import 'package:hsgx/widgets.dart';

void main() {
  test('皮肤列表收敛为三套差异化主题', () {
    expect(appSkins, hasLength(3));
    expect(appSkins.map((skin) => skin.id).toSet(), {
      'camellia',
      'blossom',
      'night',
    });
  });

  test('每套皮肤都会向页面和导航提供同一组主题令牌', () {
    for (var index = 0; index < appSkins.length; index++) {
      final skin = appSkinAt(index);
      final theme = buildAppTheme(index);
      final tokens = theme.extension<AppThemeTokens>()!;

      expect(theme.colorScheme.primary, skin.primary);
      expect(theme.colorScheme.surfaceContainerLowest, skin.surface);
      expect(theme.colorScheme.surfaceContainer, skin.surfaceMuted);
      expect(theme.colorScheme.onSurfaceVariant, skin.muted);
      expect(theme.colorScheme.outlineVariant, skin.border);
      expect(theme.inputDecorationTheme.hintStyle?.color, skin.placeholder);
      expect(theme.brightness, skin.brightness);
      expect(tokens.heroStart, skin.heroStart);
      expect(tokens.heroEnd, skin.heroEnd);
      expect(tokens.softPrimary, skin.primarySoft);
      expect(tokens.heroAccent, skin.heroAccent);
    }
  });

  test('输入框占位文字使用较浅的弱化色', () {
    final skin = appSkins.first;
    final hintStyle = buildAppTheme().inputDecorationTheme.hintStyle!;
    expect(hintStyle.color, skin.placeholder);
  });

  test('夜匣使用完整的深色语义色和可读正文', () {
    final skin = appSkins.last;
    final theme = buildAppTheme(appSkins.length - 1);
    final surfaceLuminance = skin.surface.computeLuminance();
    final textLuminance = skin.text.computeLuminance();

    expect(skin.name, '夜匣');
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, skin.background);
    expect(theme.colorScheme.onSurface, skin.text);
    expect(theme.colorScheme.onPrimary, skin.onPrimary);
    expect(textLuminance, greaterThan(surfaceLuminance));
  });

  test('三套皮肤正文、辅助文字和主按钮都保持清晰对比', () {
    for (final skin in appSkins) {
      expect(_contrastRatio(skin.text, skin.surface), greaterThanOrEqualTo(7));
      expect(
        _contrastRatio(skin.muted, skin.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(skin.primary, skin.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(skin.onPrimary, skin.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('夜匣卡片边框保持低对比度且不会刺眼', () {
    for (final skin in appSkins) {
      final borderContrast = _contrastRatio(skin.border, skin.surface);
      expect(borderContrast, greaterThan(1.1));
      expect(borderContrast, lessThan(1.8));
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

  testWidgets('输入框占位文字明显浅于用户输入文字', (tester) async {
    for (var index = 0; index < appSkins.length; index++) {
      final skin = appSkinAt(index);
      final theme = buildAppTheme(index);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TextField(
              key: ValueKey(index),
              decoration: InputDecoration(hintText: 'placeholder-$index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hint = tester.widget<Text>(find.text('placeholder-$index'));
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      final hintColor = hint.style!.color!;
      final inputColor = editable.style.color ?? theme.colorScheme.onSurface;

      expect(hintColor, skin.placeholder);
      expect(
        _contrastRatio(hintColor, skin.surface),
        lessThan(_contrastRatio(inputColor, skin.surface)),
      );
    }
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

  testWidgets('统一内容分隔线默认在右侧保留内缩', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: ContentDivider(indent: 54)),
      ),
    );

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.indent, 54);
    expect(divider.endIndent, 14);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final light = foreground.computeLuminance();
  final dark = background.computeLuminance();
  return (light > dark ? light + 0.05 : dark + 0.05) /
      (light > dark ? dark + 0.05 : light + 0.05);
}
