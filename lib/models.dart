import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const appBackground = Color(0xFFF6F2EB);
const appSurface = Color(0xFFFFFFFF);
const appPrimary = Color(0xFF315F57);
const appText = Color(0xFF272A26);
const appMuted = Color(0xFF7F817A);
const appBorder = Color(0xFFE4DED4);
const appPink = Color(0xFFB56D78);
const appAmber = Color(0xFFA77F4E);
const appBlue = Color(0xFF647B91);
const aggregateCurrencyCode = 'CNY';
const activeItemStatuses = {'inuse', 'idle', 'repairing'};

class AppSkin {
  const AppSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.text,
    required this.muted,
    required this.placeholder,
    required this.border,
    required this.heroStart,
    required this.heroEnd,
    required this.heroAccent,
  });

  final String id;
  final String name;
  final String description;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;
  final Color text;
  final Color muted;
  final Color placeholder;
  final Color border;
  final Color heroStart;
  final Color heroEnd;
  final Color heroAccent;
}

const appSkins = <AppSkin>[
  AppSkin(
    id: 'camellia',
    name: '归青',
    description: '暖米纸色、墨青瓷与旧黄铜，像把物品轻轻收回匣中。',
    brightness: Brightness.light,
    background: Color(0xFFF4F0E8),
    surface: Color(0xFFFCFAF5),
    surfaceMuted: Color(0xFFECE7DE),
    primary: Color(0xFF315F57),
    onPrimary: Colors.white,
    primarySoft: Color(0xFFE6EFEB),
    accent: Color(0xFFB08A5A),
    accentSoft: Color(0xFFF1E5D2),
    text: Color(0xFF272A26),
    muted: Color(0xFF6F756E),
    placeholder: Color(0xFFA8ABA3),
    border: Color(0xFFDED7CB),
    heroStart: Color(0xFF263F39),
    heroEnd: Color(0xFF596F67),
    heroAccent: Color(0xFFD8BD86),
  ),
  AppSkin(
    id: 'blossom',
    name: '花笺',
    description: '低饱和海棠灰红、胭脂纸与旧铜，保留花笺般的温柔手感。',
    brightness: Brightness.light,
    background: Color(0xFFF8F1EF),
    surface: Color(0xFFFEFBFA),
    surfaceMuted: Color(0xFFF3E7E6),
    primary: Color(0xFF8D5D66),
    onPrimary: Colors.white,
    primarySoft: Color(0xFFF1E2E5),
    accent: Color(0xFFB27F63),
    accentSoft: Color(0xFFF2E5DB),
    text: Color(0xFF34272A),
    muted: Color(0xFF806E72),
    placeholder: Color(0xFFB5A5A9),
    border: Color(0xFFE7D7D9),
    heroStart: Color(0xFF71474F),
    heroEnd: Color(0xFFB17A7C),
    heroAccent: Color(0xFFF2D8CC),
  ),
  AppSkin(
    id: 'night',
    name: '夜匣',
    description: '烟墨、乌木与暖黄铜，像一只只在夜晚打开的私人收藏匣。',
    brightness: Brightness.dark,
    background: Color(0xFF171B19),
    surface: Color(0xFF222825),
    surfaceMuted: Color(0xFF2B322E),
    primary: Color(0xFFC1A36C),
    onPrimary: Color(0xFF231F17),
    primarySoft: Color(0xFF383329),
    accent: Color(0xFF8FA99A),
    accentSoft: Color(0xFF293630),
    text: Color(0xFFF1EDE4),
    muted: Color(0xFFA7A79E),
    placeholder: Color(0xFF777D75),
    border: Color(0xFF3B423E),
    heroStart: Color(0xFF141815),
    heroEnd: Color(0xFF39443D),
    heroAccent: Color(0xFFD8BB7E),
  ),
];

AppSkin appSkinAt(int index) => appSkins[index % appSkins.length];

extension AppThemeColorContext on BuildContext {
  ColorScheme get appColorScheme => Theme.of(this).colorScheme;

  Color get appSurfaceColor => appColorScheme.surfaceContainerLowest;

  Color get appSurfaceMutedColor => appColorScheme.surfaceContainer;

  Color get appTextColor => appColorScheme.onSurface;

  Color get appMutedColor => appColorScheme.onSurfaceVariant;

  Color get appPlaceholderColor =>
      Theme.of(this).inputDecorationTheme.hintStyle?.color ??
      appMutedColor.withValues(alpha: 0.5);

  Color get appBorderColor => appColorScheme.outlineVariant;
}

class CurrencyOption {
  const CurrencyOption(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;
}

const currencyOptions = <CurrencyOption>[
  CurrencyOption('CNY', '¥', '人民币'),
  CurrencyOption('USD', '\$', '美元'),
  CurrencyOption('HKD', 'HK\$', '港币'),
  CurrencyOption('EUR', '€', '欧元'),
  CurrencyOption('JPY', '¥', '日元'),
  CurrencyOption('GBP', '£', '英镑'),
];

CurrencyOption currencyByCode(String code) {
  return currencyOptions.firstWhere(
    (currency) => currency.code == code,
    orElse: () => currencyOptions.first,
  );
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _asStringList(Object? value) {
  Object? current = value;
  if (current is String) {
    final text = current.trim();
    if (text.isEmpty) return const [];
    if ((text.startsWith('[') && text.endsWith(']')) ||
        (text.startsWith('{') && text.endsWith('}'))) {
      try {
        current = jsonDecode(text);
      } on FormatException {
        return const [];
      }
    } else {
      return text
          .split(RegExp(r'[,，\n]'))
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
  }
  if (current is! List) {
    final single = current?.toString().trim() ?? '';
    return single.isEmpty ? const [] : [single];
  }
  return current
      .map((entry) {
        if (entry is Map) {
          return (entry['url'] ??
                  entry['publicUrl'] ??
                  entry['filePath'] ??
                  entry['path'] ??
                  entry['image'] ??
                  entry['previewUrl'] ??
                  '')
              .toString()
              .trim();
        }
        return entry.toString().trim();
      })
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList();
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  if (value is String && value.trim().startsWith('{')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      return const {};
    }
  }
  return const {};
}

DateTime? parseDate(Object? value) {
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  if (value == null) return null;
  final match = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})')
      .firstMatch(value.toString());
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

String formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}

String formatMoney(num value, {bool compact = false}) {
  if (!value.isFinite) return '--';
  final safe = value.abs();
  if (compact && safe >= 10000) {
    return '${(value / 10000).toStringAsFixed(safe >= 100000 ? 0 : 1)}万';
  }
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.005) {
    return rounded.toInt().toString().replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }
  return value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '')
      .replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'), (_) => ',');
}

class ItemCategory {
  const ItemCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.softColor,
    required this.asset,
    this.subcategories = const [],
  });

  final String id;
  final String name;
  final Color color;
  final Color softColor;
  final String asset;
  final List<String> subcategories;
}

const itemCategories = <ItemCategory>[
  ItemCategory(
    id: 'digital',
    name: '数码产品',
    color: Color(0xFF5B8FE3),
    softColor: Color(0xFFEAF1FC),
    asset: 'static/image/items/digital.webp',
    subcategories: ['手机', '耳机', '电脑', '手表'],
  ),
  ItemCategory(
    id: 'clothing',
    name: '服饰箱包',
    color: Color(0xFFC98C4E),
    softColor: Color(0xFFF8F0E3),
    asset: 'static/image/items/clothing.webp',
    subcategories: ['上衣', '裤子', '袜子', '鞋子', '帽子', '箱包'],
  ),
  ItemCategory(
    id: 'furniture',
    name: '家具',
    color: Color(0xFF4B9F91),
    softColor: Color(0xFFE7F5F2),
    asset: 'static/image/items/furniture.webp',
    subcategories: ['灯具', '床品', '收纳'],
  ),
  ItemCategory(
    id: 'appliances',
    name: '家电',
    color: Color(0xFFD5A13D),
    softColor: Color(0xFFFAF2DF),
    asset: 'static/image/items/appliances.webp',
    subcategories: ['厨房电器', '清洁电器', '生活电器', '影音设备'],
  ),
  ItemCategory(
    id: 'book',
    name: '教育图书',
    color: Color(0xFF786BC2),
    softColor: Color(0xFFEFEDFA),
    asset: 'static/image/items/book.webp',
    subcategories: ['文学', '经管', '教材', '童书'],
  ),
  ItemCategory(
    id: 'sports',
    name: '运动',
    color: Color(0xFF52A96F),
    softColor: Color(0xFFE9F6EE),
    asset: 'static/image/items/sports.webp',
    subcategories: ['健身器材', '球类', '户外装备'],
  ),
  ItemCategory(
    id: 'beauty',
    name: '美妆个护',
    color: Color(0xFFD77FA5),
    softColor: Color(0xFFFAEDF3),
    asset: 'static/image/items/beauty.webp',
    subcategories: ['护肤品', '彩妆品', '香氛', '美容工具'],
  ),
  ItemCategory(
    id: 'car',
    name: '车辆',
    color: Color(0xFF557C9B),
    softColor: Color(0xFFEAF0F5),
    asset: 'static/image/items/car.webp',
    subcategories: ['小轿车', '电瓶车', '自行车'],
  ),
  ItemCategory(
    id: 'card',
    name: '证卡证件',
    color: Color(0xFF8B5F84),
    softColor: Color(0xFFF5ECF4),
    asset: 'static/image/items/card.webp',
    subcategories: ['身份证', '银行卡', '驾照', '护照'],
  ),
  ItemCategory(
    id: 'virtual',
    name: '虚拟资产',
    color: Color(0xFF13899A),
    softColor: Color(0xFFE5F5F8),
    asset: 'static/image/items/virtual.webp',
    subcategories: ['App会员', '视频会员', '音乐会员'],
  ),
  ItemCategory(
    id: 'collect',
    name: '收藏爱好',
    color: Color(0xFFB96A63),
    softColor: Color(0xFFF7EAE7),
    asset: 'static/image/items/collect.webp',
    subcategories: ['手办', '卡牌', '艺术品'],
  ),
  ItemCategory(
    id: 'other',
    name: '其他',
    color: Color(0xFF8C879A),
    softColor: Color(0xFFF1EFF4),
    asset: 'static/image/items/other.webp',
    subcategories: ['日常用品', '药品', '宠物用品', '保养', '保险'],
  ),
];

ItemCategory categoryById(String id) {
  return itemCategories.firstWhere(
    (category) => category.id == id,
    orElse: () => itemCategories.last,
  );
}

class ItemStatus {
  const ItemStatus(this.id, this.name, this.color, this.softColor);

  final String id;
  final String name;
  final Color color;
  final Color softColor;
}

const itemStatuses = <ItemStatus>[
  ItemStatus('inuse', '使用中', Color(0xFF315F57), Color(0xFFE6EFEB)),
  ItemStatus('idle', '闲置', Color(0xFF987446), Color(0xFFF3EBDD)),
  ItemStatus('repairing', '维修中', Color(0xFFA8665C), Color(0xFFF3E8E5)),
  ItemStatus('processed', '已处理', Color(0xFF5D7085), Color(0xFFE8EDF1)),
  ItemStatus('retired', '已退役', Color(0xFF766988), Color(0xFFECE8F1)),
];

ItemStatus statusById(String id) {
  return itemStatuses.firstWhere(
    (status) => status.id == id,
    orElse: () => itemStatuses.first,
  );
}

class StatusEvent {
  StatusEvent({required this.status, required this.at, this.note = ''});

  final String status;
  final String at;
  final String note;

  Map<String, Object?> toJson() => {'status': status, 'at': at, 'note': note};

  factory StatusEvent.fromJson(Map<String, Object?> json) {
    return StatusEvent(
      status: json['status']?.toString() ?? 'inuse',
      at: json['at']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    this.category = 'digital',
    this.subcategory = '',
    this.status = 'inuse',
    this.usageMode = 'auto',
    this.manualUsageCount = 0,
    this.purchasePrice = 0,
    this.currentValue = 0,
    this.purchaseCurrency = 'CNY',
    required this.purchaseDate,
    required this.createdAt,
    this.quantity = 1,
    this.netWeight = '',
    this.remainingNetWeight = '',
    this.purchaseChannel = '',
    this.storageLocation = '',
    this.warrantyPeriod = '',
    this.warrantyEndDate = '',
    this.targetUsageValue = 0,
    this.targetUsageUnit = 'day',
    this.note = '',
    this.tags = const [],
    this.usageRecords = const [],
    this.statusHistory = const [],
    this.favorite = false,
    this.favoriteAt = '',
    List<String>? imagePaths,
    String imagePath = '',
    this.relatedItemIds = const [],
    this.idleReason = '',
    this.repairPlatform = '',
    this.repairDays = 0,
    this.repairContactName = '',
    this.repairContactPhone = '',
    this.disposalMethod = '',
    this.disposalDetail = '',
    this.disposalPlatform = '',
    this.disposalContact = '',
    this.disposalPrice = 0,
    this.disposalCost = 0,
    this.processDate = '',
    this.recoveryMethod = '',
    this.recoveryTargetPrice = 0,
    this.recoveryDeadline = '',
    this.recoveryPlatform = '',
    this.recoveryContact = '',
    this.recoveryNote = '',
  }) : imagePaths = _asStringList(
         imagePaths == null || imagePaths.isEmpty
             ? (imagePath.trim().isEmpty ? const [] : [imagePath])
             : imagePaths,
       );

  final String id;
  final String name;
  final String category;
  final String subcategory;
  final String status;
  final String usageMode;
  final int manualUsageCount;
  final double purchasePrice;
  final double currentValue;
  final String purchaseCurrency;
  final String purchaseDate;
  final String createdAt;
  final double quantity;
  final String netWeight;
  final String remainingNetWeight;
  final String purchaseChannel;
  final String storageLocation;
  final String warrantyPeriod;
  final String warrantyEndDate;
  final int targetUsageValue;
  final String targetUsageUnit;
  final String note;
  final List<String> tags;
  final List<String> usageRecords;
  final List<StatusEvent> statusHistory;
  final bool favorite;
  final String favoriteAt;
  final List<String> imagePaths;
  final List<String> relatedItemIds;
  final String idleReason;
  final String repairPlatform;
  final int repairDays;
  final String repairContactName;
  final String repairContactPhone;
  final String disposalMethod;
  final String disposalDetail;
  final String disposalPlatform;
  final String disposalContact;
  final double disposalPrice;
  final double disposalCost;
  final String processDate;
  final String recoveryMethod;
  final double recoveryTargetPrice;
  final String recoveryDeadline;
  final String recoveryPlatform;
  final String recoveryContact;
  final String recoveryNote;

  ItemCategory get categoryInfo => categoryById(category);
  ItemStatus get statusInfo => statusById(status);
  CurrencyOption get currency => currencyByCode(purchaseCurrency);
  String get currencySymbol => currency.symbol;
  bool get isActive => activeItemStatuses.contains(status);
  bool get canAggregateInBaseCurrency =>
      purchaseCurrency.toUpperCase() == aggregateCurrencyCode;
  bool get isCashRecovery => disposalMethod == '转卖' || disposalMethod == '回收';
  double get cashRecoveredAmount =>
      isCashRecovery ? math.max(0, disposalPrice - disposalCost) : 0;
  bool get hasRecoveryPlan => recoveryMethod.isNotEmpty;
  double get recoveryEstimateLow => math.max(0, currentTotal * 0.6);
  double get recoveryEstimateHigh => math.max(0, currentTotal * 0.8);
  String get imagePath => imagePaths.isEmpty ? '' : imagePaths.first;
  double get purchaseTotal => purchasePrice * quantity;
  double get currentTotal => currentValue * quantity;

  DateTime get purchaseDateTime =>
      parseDate(purchaseDate) ?? parseDate(createdAt) ?? DateTime.now();
  DateTime get favoriteDateTime =>
      parseDate(favoriteAt) ?? parseDate(createdAt) ?? DateTime.now();

  DateTime? get ownedStopDate {
    if (status == 'processed') {
      return parseDate(processDate) ??
          _latestStatusDate(const {'processed', 'retired'});
    }
    if (status == 'retired') {
      return _latestStatusDate(const {'retired'});
    }
    return null;
  }

  DateTime? get usageStopDate {
    return switch (status) {
      'processed' => ownedStopDate,
      'retired' => ownedStopDate,
      'idle' => _latestStatusDate(const {'idle'}),
      'repairing' => _latestStatusDate(const {'repairing'}),
      _ => null,
    };
  }

  DateTime? _latestStatusDate(Set<String> statuses) {
    final events =
        statusHistory
            .map((event) => (event: event, date: parseDate(event.at)))
            .where(
              (entry) =>
                  entry.date != null && statuses.contains(entry.event.status),
            )
            .toList()
          ..sort((first, second) => first.date!.compareTo(second.date!));
    return events.isEmpty ? null : events.last.date;
  }

  List<({String status, DateTime date})> _statusIntervals() {
    return statusHistory
        .map((event) => (status: event.status, date: parseDate(event.at)))
        .where((entry) => entry.date != null)
        .map((entry) => (status: entry.status, date: entry.date!))
        .toList()
      ..sort((first, second) => first.date.compareTo(second.date));
  }

  int ownedDaysAsOf(DateTime now) {
    final today = _startOfDay(now);
    final stop = ownedStopDate;
    final end = stop != null && stop.isBefore(today) ? stop : today;
    return math.max(1, end.difference(purchaseDateTime).inDays + 1);
  }

  List<({DateTime start, DateTime end})> usageIntervalsAsOf(DateTime now) {
    final purchase = purchaseDateTime;
    final requestedEnd = _startOfDay(now);
    if (requestedEnd.isBefore(purchase)) return const [];

    final history = _statusIntervals();
    final hasInUseHistory = history.any((entry) => entry.status == 'inuse');

    // Older records may only keep the current non-use state. In that case,
    // treat the purchase date as the first use period up to the recorded stop.
    if (!hasInUseHistory) {
      if (history.isEmpty && status == 'inuse') {
        return [(start: purchase, end: requestedEnd)];
      }
      final fallbackStop =
          usageStopDate ?? (history.isEmpty ? null : history.first.date);
      if (fallbackStop == null) return const [];
      final effectiveStop = fallbackStop.isBefore(requestedEnd)
          ? fallbackStop
          : requestedEnd;
      final exclusiveEnd = effectiveStop.subtract(const Duration(days: 1));
      return exclusiveEnd.isBefore(purchase)
          ? const []
          : [(start: purchase, end: exclusiveEnd)];
    }

    final intervals = <({DateTime start, DateTime end})>[];
    for (var index = 0; index < history.length; index++) {
      final entry = history[index];
      if (entry.status != 'inuse') continue;

      final startsAtPurchase = index == 0 && entry.date.isAfter(purchase);
      final rawStart = startsAtPurchase ? purchase : entry.date;
      final start = rawStart.isBefore(purchase) ? purchase : rawStart;
      if (start.isAfter(requestedEnd)) continue;

      DateTime end;
      if (index + 1 < history.length) {
        end = history[index + 1].date.subtract(const Duration(days: 1));
      } else {
        end = requestedEnd;
        final stop = usageStopDate;
        if (stop != null &&
            stop.subtract(const Duration(days: 1)).isBefore(end)) {
          end = stop.subtract(const Duration(days: 1));
        }
      }
      if (end.isAfter(requestedEnd)) end = requestedEnd;
      if (!end.isBefore(start)) intervals.add((start: start, end: end));
    }

    final merged = <({DateTime start, DateTime end})>[];
    for (final interval in intervals) {
      if (merged.isEmpty || interval.start.isAfter(merged.last.end)) {
        merged.add(interval);
      } else if (interval.end.isAfter(merged.last.end)) {
        merged[merged.length - 1] = (
          start: merged.last.start,
          end: interval.end,
        );
      }
    }
    return merged;
  }

  int usageDaysAsOf(DateTime now) {
    if (usageMode == 'manual') return math.max(0, manualUsageCount);
    return usageIntervalsAsOf(now).fold(
      0,
      (sum, interval) =>
          sum + interval.end.difference(interval.start).inDays + 1,
    );
  }

  int idleDaysAsOf(DateTime now) {
    if (status != 'idle') return 0;
    final start = _latestStatusDate(const {'idle'});
    if (start == null) return 0;
    final end = _startOfDay(now);
    return end.isBefore(start) ? 0 : end.difference(start).inDays + 1;
  }

  int retiredDaysAsOf(DateTime now) {
    if (status != 'retired') return 0;
    final start = _latestStatusDate(const {'retired'});
    if (start == null) return 0;
    final end = _startOfDay(now);
    return end.isBefore(start) ? 0 : end.difference(start).inDays + 1;
  }

  int get ownedDays => ownedDaysAsOf(DateTime.now());
  int get usageDays => usageDaysAsOf(DateTime.now());
  int get idleDays => idleDaysAsOf(DateTime.now());
  int get retiredDays => retiredDaysAsOf(DateTime.now());
  bool get canRecordManualUsage => status == 'inuse' && usageMode == 'manual';

  int usageDaysInLastDays(int days, {DateTime? now}) {
    final end = _startOfDay(now ?? DateTime.now());
    final start = end.subtract(Duration(days: math.max(1, days) - 1));
    if (usageMode == 'manual') {
      return usageRecords.map(DateTime.tryParse).whereType<DateTime>().where((
        entry,
      ) {
        final date = _startOfDay(entry);
        return !date.isBefore(start) && !date.isAfter(end);
      }).length;
    }
    return usageIntervalsAsOf(end).fold(0, (sum, interval) {
      final overlapStart = interval.start.isBefore(start)
          ? start
          : interval.start;
      final overlapEnd = interval.end.isAfter(end) ? end : interval.end;
      return overlapStart.isAfter(overlapEnd)
          ? sum
          : sum + overlapEnd.difference(overlapStart).inDays + 1;
    });
  }

  DateTime? lastUsedAtAsOf(DateTime now) {
    if (usageMode == 'manual') {
      final dates =
          usageRecords.map(DateTime.tryParse).whereType<DateTime>().toList()
            ..sort();
      return dates.isEmpty ? null : dates.last;
    }
    if (status == 'inuse') return _startOfDay(now);
    final intervals = usageIntervalsAsOf(now);
    return intervals.isEmpty ? null : intervals.last.end;
  }

  DateTime? get lastUsedAt => lastUsedAtAsOf(DateTime.now());

  String get targetUsageUnitLabel => targetUsageUnit == 'count' ? '次' : '天';

  int get effectiveTargetValue {
    if (targetUsageValue > 0) return targetUsageValue;
    if (usageMode == 'manual') return 0;
    return switch (warrantyPeriod) {
      '一年' => 365,
      '二年' || '两年' => 730,
      '三年' => 1095,
      '五年' => 1825,
      _ => 0,
    };
  }

  double get ownedDailyCost => ownedDays == 0 ? 0 : purchaseTotal / ownedDays;
  double get usageAverageCost => usageDays == 0 ? 0 : purchaseTotal / usageDays;
  double get targetAverageCost =>
      effectiveTargetValue == 0 ? 0 : purchaseTotal / effectiveTargetValue;

  DateTime? get warrantyEnd {
    final explicit = parseDate(warrantyEndDate);
    if (explicit != null) return explicit;
    final days = switch (warrantyPeriod) {
      '一年' => 365,
      '二年' || '两年' => 730,
      '三年' => 1095,
      '五年' => 1825,
      _ => 0,
    };
    return days == 0 ? null : purchaseDateTime.add(Duration(days: days));
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    String? status,
    String? usageMode,
    int? manualUsageCount,
    double? purchasePrice,
    double? currentValue,
    String? purchaseCurrency,
    String? purchaseDate,
    double? quantity,
    String? netWeight,
    String? remainingNetWeight,
    String? purchaseChannel,
    String? storageLocation,
    String? warrantyPeriod,
    String? warrantyEndDate,
    int? targetUsageValue,
    String? targetUsageUnit,
    String? note,
    List<String>? tags,
    List<String>? usageRecords,
    List<StatusEvent>? statusHistory,
    bool? favorite,
    String? favoriteAt,
    List<String>? imagePaths,
    String? imagePath,
    List<String>? relatedItemIds,
    String? idleReason,
    String? repairPlatform,
    int? repairDays,
    String? repairContactName,
    String? repairContactPhone,
    String? disposalMethod,
    String? disposalDetail,
    String? disposalPlatform,
    String? disposalContact,
    double? disposalPrice,
    double? disposalCost,
    String? processDate,
    String? recoveryMethod,
    double? recoveryTargetPrice,
    String? recoveryDeadline,
    String? recoveryPlatform,
    String? recoveryContact,
    String? recoveryNote,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      status: status ?? this.status,
      usageMode: usageMode ?? this.usageMode,
      manualUsageCount: manualUsageCount ?? this.manualUsageCount,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt,
      quantity: quantity ?? this.quantity,
      netWeight: netWeight ?? this.netWeight,
      remainingNetWeight: remainingNetWeight ?? this.remainingNetWeight,
      purchaseChannel: purchaseChannel ?? this.purchaseChannel,
      storageLocation: storageLocation ?? this.storageLocation,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      targetUsageValue: targetUsageValue ?? this.targetUsageValue,
      targetUsageUnit: targetUsageUnit ?? this.targetUsageUnit,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      usageRecords: usageRecords ?? this.usageRecords,
      statusHistory: statusHistory ?? this.statusHistory,
      favorite: favorite ?? this.favorite,
      favoriteAt: favoriteAt ?? this.favoriteAt,
      imagePaths:
          imagePaths ?? (imagePath == null ? this.imagePaths : [imagePath]),
      relatedItemIds: relatedItemIds ?? this.relatedItemIds,
      idleReason: idleReason ?? this.idleReason,
      repairPlatform: repairPlatform ?? this.repairPlatform,
      repairDays: repairDays ?? this.repairDays,
      repairContactName: repairContactName ?? this.repairContactName,
      repairContactPhone: repairContactPhone ?? this.repairContactPhone,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      disposalDetail: disposalDetail ?? this.disposalDetail,
      disposalPlatform: disposalPlatform ?? this.disposalPlatform,
      disposalContact: disposalContact ?? this.disposalContact,
      disposalPrice: disposalPrice ?? this.disposalPrice,
      disposalCost: disposalCost ?? this.disposalCost,
      processDate: processDate ?? this.processDate,
      recoveryMethod: recoveryMethod ?? this.recoveryMethod,
      recoveryTargetPrice: recoveryTargetPrice ?? this.recoveryTargetPrice,
      recoveryDeadline: recoveryDeadline ?? this.recoveryDeadline,
      recoveryPlatform: recoveryPlatform ?? this.recoveryPlatform,
      recoveryContact: recoveryContact ?? this.recoveryContact,
      recoveryNote: recoveryNote ?? this.recoveryNote,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'subcategory': subcategory,
    'status': status,
    'usageMode': usageMode,
    'manualUsageCount': manualUsageCount,
    'purchasePrice': purchasePrice,
    'currentValue': currentValue,
    'purchaseCurrency': purchaseCurrency,
    'currency': purchaseCurrency,
    'purchaseDate': purchaseDate,
    'createdAt': createdAt,
    'quantity': quantity,
    'netWeight': netWeight,
    'remainingNetWeight': remainingNetWeight,
    'purchaseChannel': purchaseChannel,
    'storageLocation': storageLocation,
    'warrantyPeriod': warrantyPeriod,
    'warrantyEndDate': warrantyEndDate,
    'targetUsageValue': targetUsageValue,
    'targetUsageUnit': targetUsageUnit,
    // Keep the legacy field for older clients while the schema transition completes.
    'targetUseDays': targetUsageUnit == 'day' ? targetUsageValue : 0,
    'note': note,
    'tags': tags,
    'usageRecords': usageRecords,
    'statusHistory': statusHistory.map((entry) => entry.toJson()).toList(),
    'favorite': favorite,
    'favoriteAt': favoriteAt,
    'imagePath': imagePath,
    'image': imagePath,
    'images': imagePaths,
    'relatedItemIds': relatedItemIds,
    'idleReason': idleReason,
    'repairPlatform': repairPlatform,
    'repairDays': repairDays,
    'repairContactName': repairContactName,
    'repairContactPhone': repairContactPhone,
    'repairInfo': {
      'platform': repairPlatform,
      'days': repairDays,
      'contactName': repairContactName,
      'contactPhone': repairContactPhone,
    },
    'disposalMethod': disposalMethod,
    'disposalDetail': disposalDetail,
    'disposalPlatform': disposalPlatform,
    'disposalContact': disposalContact,
    'disposalPrice': disposalPrice,
    'disposalCost': disposalCost,
    'disposalInfo': {
      'method': disposalMethod,
      'salePlatform': disposalMethod == '转卖' ? disposalPlatform : '',
      'recyclePlatform': disposalMethod == '回收' ? disposalPlatform : '',
      'sellerName': disposalMethod == '转卖' ? disposalContact : '',
      'recipient': disposalMethod == '转赠' ? disposalContact : '',
      'finalPrice': disposalPrice,
      'cost': disposalCost,
      'actualProcessDate': processDate,
    },
    'processDate': processDate,
    'recoveryMethod': recoveryMethod,
    'recoveryTargetPrice': recoveryTargetPrice,
    'recoveryDeadline': recoveryDeadline,
    'recoveryPlatform': recoveryPlatform,
    'recoveryContact': recoveryContact,
    'recoveryNote': recoveryNote,
  };

  factory InventoryItem.fromJson(Map<String, Object?> json) {
    final history = (json['statusHistory'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => StatusEvent.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
    final idleInfo = _asMap(json['idleInfo']);
    final repairInfo = _asMap(json['repairInfo']);
    final disposalInfo = _asMap(json['disposalInfo']);
    final related = <String>[
      ..._asStringList(json['relatedItemIds']),
      ..._asStringList(json['relatedItems']),
    ];
    final images = <String>{
      ..._asStringList(json['imagePaths']),
      ..._asStringList(json['images']),
      ..._asStringList(json['imagePath']),
      ..._asStringList(json['image']),
    }.toList();
    final currency = (json['purchaseCurrency'] ?? json['currency'] ?? 'CNY')
        .toString()
        .trim();
    final disposalMethod =
        (json['disposalMethod'] ?? disposalInfo['method'] ?? '').toString();
    final disposalPlatform =
        (json['disposalPlatform'] ??
                disposalInfo['salePlatform'] ??
                disposalInfo['recyclePlatform'] ??
                '')
            .toString();
    final disposalContact =
        (json['disposalContact'] ??
                disposalInfo['sellerName'] ??
                disposalInfo['recipient'] ??
                '')
            .toString();
    final disposalDetail =
        (json['disposalDetail'] ??
                (disposalMethod == '回收'
                    ? disposalPlatform
                    : disposalMethod == '转赠'
                    ? disposalContact
                    : disposalPlatform))
            .toString();
    final disposalPrice = _asDouble(
      json['disposalPrice'] ??
          disposalInfo['finalPrice'] ??
          disposalInfo['salePrice'] ??
          disposalInfo['recyclePrice'],
    );
    return InventoryItem(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '未命名物品',
      category: json['category']?.toString() ?? 'other',
      subcategory: json['subcategory']?.toString() ?? '',
      status: json['status']?.toString() ?? 'inuse',
      usageMode: json['usageMode']?.toString() ?? 'auto',
      manualUsageCount: _asInt(json['manualUsageCount']),
      purchasePrice: _asDouble(json['purchasePrice']),
      currentValue: _asDouble(json['currentValue']),
      purchaseCurrency: currency.isEmpty ? 'CNY' : currency,
      purchaseDate:
          json['purchaseDate']?.toString() ?? formatDate(DateTime.now()),
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      quantity: math.max(1, _asDouble(json['quantity'])),
      netWeight: json['netWeight']?.toString() ?? '',
      remainingNetWeight: json['remainingNetWeight']?.toString() ?? '',
      purchaseChannel: json['purchaseChannel']?.toString() ?? '',
      storageLocation: json['storageLocation']?.toString() ?? '',
      warrantyPeriod: json['warrantyPeriod']?.toString() ?? '',
      warrantyEndDate: json['warrantyEndDate']?.toString() ?? '',
      targetUsageValue: _asInt(
        json['targetUsageValue'] ?? json['targetUseDays'],
      ),
      targetUsageUnit:
          json['targetUsageUnit']?.toString() == 'count' ||
              (json['targetUsageUnit'] == null &&
                  json['usageMode']?.toString() == 'manual')
          ? 'count'
          : 'day',
      note: json['note']?.toString() ?? '',
      tags: (json['tags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      usageRecords: (json['usageRecords'] as List? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      statusHistory: history,
      favorite: json['favorite'] == true,
      favoriteAt: json['favoriteAt']?.toString() ?? '',
      imagePaths: images,
      relatedItemIds: related.toSet().toList(),
      idleReason: (json['idleReason'] ?? idleInfo['reason'] ?? '').toString(),
      repairPlatform: (json['repairPlatform'] ?? repairInfo['platform'] ?? '')
          .toString(),
      repairDays: _asInt(json['repairDays'] ?? repairInfo['days']),
      repairContactName:
          (json['repairContactName'] ?? repairInfo['contactName'] ?? '')
              .toString(),
      repairContactPhone:
          (json['repairContactPhone'] ?? repairInfo['contactPhone'] ?? '')
              .toString(),
      disposalMethod: disposalMethod,
      disposalDetail: disposalDetail,
      disposalPlatform: disposalPlatform,
      disposalContact: disposalContact,
      disposalPrice: disposalPrice,
      disposalCost: _asDouble(json['disposalCost'] ?? disposalInfo['cost']),
      processDate:
          (json['processDate'] ??
                  json['actualProcessDate'] ??
                  disposalInfo['actualProcessDate'] ??
                  '')
              .toString(),
      recoveryMethod: json['recoveryMethod']?.toString() ?? '',
      recoveryTargetPrice: _asDouble(json['recoveryTargetPrice']),
      recoveryDeadline: json['recoveryDeadline']?.toString() ?? '',
      recoveryPlatform: json['recoveryPlatform']?.toString() ?? '',
      recoveryContact: json['recoveryContact']?.toString() ?? '',
      recoveryNote: json['recoveryNote']?.toString() ?? '',
    );
  }
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class WishEntry {
  WishEntry({
    required this.id,
    required this.name,
    this.category = 'digital',
    this.expectedPrice = 0,
    this.reason = '',
    this.coolingDays = 7,
    required this.createdAt,
    this.status = 'cooling',
    this.desireType = '',
    this.achievedAt = '',
  });

  final String id;
  final String name;
  final String category;
  final double expectedPrice;
  final String reason;
  final int coolingDays;
  final String createdAt;
  final String status;
  final String desireType;
  final String achievedAt;

  DateTime get createdAtDate => DateTime.tryParse(createdAt) ?? DateTime.now();
  DateTime? get achievedAtDate => DateTime.tryParse(achievedAt);
  DateTime get decisionDue => createdAtDate.add(Duration(days: coolingDays));
  int get remainingDays =>
      math.max(0, decisionDue.difference(DateTime.now()).inDays + 1);
  int get elapsedDays =>
      math.max(0, DateTime.now().difference(createdAtDate).inDays);
  ItemCategory get categoryInfo => categoryById(category);

  WishEntry copyWith({
    String? id,
    String? name,
    String? category,
    double? expectedPrice,
    String? reason,
    int? coolingDays,
    String? createdAt,
    String? status,
    String? desireType,
    String? achievedAt,
  }) => WishEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    expectedPrice: expectedPrice ?? this.expectedPrice,
    reason: reason ?? this.reason,
    coolingDays: coolingDays ?? this.coolingDays,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    desireType: desireType ?? this.desireType,
    achievedAt: achievedAt ?? this.achievedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'expectedPrice': expectedPrice,
    'reason': reason,
    'coolingDays': coolingDays,
    'createdAt': createdAt,
    'status': status,
    'desireType': desireType,
    'achievedAt': achievedAt,
  };

  factory WishEntry.fromJson(Map<String, Object?> json) {
    return WishEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '未命名心愿',
      category: json['category']?.toString() ?? 'other',
      expectedPrice: _asDouble(json['expectedPrice']),
      reason: json['reason']?.toString() ?? '',
      coolingDays: math.max(1, _asInt(json['coolingDays'])),
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      status: json['status']?.toString() ?? 'cooling',
      desireType: json['desireType']?.toString() ?? '',
      achievedAt: json['achievedAt']?.toString() ?? '',
    );
  }
}
