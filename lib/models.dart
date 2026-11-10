import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const appBackground = Color(0xFFFCFAF7);
const appSurface = Color(0xFFFFFFFF);
const appPrimary = Color(0xFF3A9D8A);
const appText = Color(0xFF30312D);
const appMuted = Color(0xFF918C83);
const appBorder = Color(0xFFE9E3DA);
const appPink = Color(0xFFE7849A);
const appAmber = Color(0xFFE4B15C);
const appBlue = Color(0xFF6C9FE8);
const aggregateCurrencyCode = 'CNY';
const activeItemStatuses = {'inuse', 'idle', 'repairing'};

class AppSkin {
  const AppSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.background,
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.text,
    required this.muted,
    required this.heroStart,
    required this.heroEnd,
  });

  final String id;
  final String name;
  final String description;
  final Color background;
  final Color primary;
  final Color primarySoft;
  final Color accent;
  final Color text;
  final Color muted;
  final Color heroStart;
  final Color heroEnd;
}

const appSkins = <AppSkin>[
  AppSkin(
    id: 'camellia',
    name: '山茶暖白',
    description: '温润米白与清透青绿，保留花拾归匣原本的收藏感。',
    background: Color(0xFFFCFAF7),
    primary: Color(0xFF3A9D8A),
    primarySoft: Color(0xFFE7F6F1),
    accent: Color(0xFFD97A90),
    text: Color(0xFF302F2C),
    muted: Color(0xFF969189),
    heroStart: Color(0xFF62CDB5),
    heroEnd: Color(0xFF6C9FE8),
  ),
  AppSkin(
    id: 'mist',
    name: '晨雾蓝',
    description: '清冷蓝调搭配雾白底色，适合更安静理性的使用氛围。',
    background: Color(0xFFF6FAFF),
    primary: Color(0xFF5B8FE3),
    primarySoft: Color(0xFFEAF1FC),
    accent: Color(0xFF43AFC6),
    text: Color(0xFF29313D),
    muted: Color(0xFF8B97A8),
    heroStart: Color(0xFF78B7F2),
    heroEnd: Color(0xFF70CDBE),
  ),
  AppSkin(
    id: 'rose',
    name: '山茶粉',
    description: '柔和粉色与暖金点缀，轻盈、明亮，带一点浪漫气息。',
    background: Color(0xFFFFF8FA),
    primary: Color(0xFFD46A8A),
    primarySoft: Color(0xFFFCEAF0),
    accent: Color(0xFFE0A05F),
    text: Color(0xFF3B2E32),
    muted: Color(0xFFA18A91),
    heroStart: Color(0xFFE98BAB),
    heroEnd: Color(0xFFF0B46E),
  ),
  AppSkin(
    id: 'pine',
    name: '松间绿',
    description: '沉稳松绿配自然浅底，更接近安静整理和长期记录的感觉。',
    background: Color(0xFFF5FBF8),
    primary: Color(0xFF4E9A7A),
    primarySoft: Color(0xFFE6F4EC),
    accent: Color(0xFFC9A95E),
    text: Color(0xFF29352F),
    muted: Color(0xFF87978F),
    heroStart: Color(0xFF68B59C),
    heroEnd: Color(0xFF78B3A8),
  ),
  AppSkin(
    id: 'lilac',
    name: '藕荷紫',
    description: '低饱和藕荷色与灰粉搭配，安静柔和，适合喜欢细腻氛围的用户。',
    background: Color(0xFFFAF8FF),
    primary: Color(0xFF7C6AB4),
    primarySoft: Color(0xFFEFEBFA),
    accent: Color(0xFFD8899B),
    text: Color(0xFF302C3D),
    muted: Color(0xFF918A9F),
    heroStart: Color(0xFF9A87D5),
    heroEnd: Color(0xFF7CB8C9),
  ),
  AppSkin(
    id: 'ocean',
    name: '海盐青',
    description: '清爽海盐青搭配浅蓝底色，明亮干净，适合轻快的工作节奏。',
    background: Color(0xFFF4FBFC),
    primary: Color(0xFF278E9B),
    primarySoft: Color(0xFFE1F4F5),
    accent: Color(0xFFE0A55C),
    text: Color(0xFF26383B),
    muted: Color(0xFF82999D),
    heroStart: Color(0xFF58B9BF),
    heroEnd: Color(0xFF6EA8D9),
  ),
  AppSkin(
    id: 'amber',
    name: '琥珀暖阳',
    description: '温暖琥珀色与珊瑚红组合，适合喜欢明亮、有生活温度的主题。',
    background: Color(0xFFFFF9F2),
    primary: Color(0xFFC77D38),
    primarySoft: Color(0xFFF9EEDC),
    accent: Color(0xFFD8546B),
    text: Color(0xFF3D3129),
    muted: Color(0xFFA18D7D),
    heroStart: Color(0xFFE8AD5C),
    heroEnd: Color(0xFFDF7C6D),
  ),
  AppSkin(
    id: 'graphite',
    name: '墨石灰',
    description: '沉稳灰蓝与暖金属色点缀，视觉更克制，适合偏理性的信息浏览。',
    background: Color(0xFFF7F8F9),
    primary: Color(0xFF596A70),
    primarySoft: Color(0xFFE8EEF0),
    accent: Color(0xFFB38B55),
    text: Color(0xFF293035),
    muted: Color(0xFF899197),
    heroStart: Color(0xFF71848A),
    heroEnd: Color(0xFF93A7A2),
  ),
  AppSkin(
    id: 'peach',
    name: '蜜桃奶油',
    description: '柔和蜜桃色与奶油底搭配，轻盈温暖，适合更柔和的日常记录。',
    background: Color(0xFFFFF8F4),
    primary: Color(0xFFD77A66),
    primarySoft: Color(0xFFFCEAE3),
    accent: Color(0xFFE2A65B),
    text: Color(0xFF3D2E2A),
    muted: Color(0xFFA18B83),
    heroStart: Color(0xFFF0A27E),
    heroEnd: Color(0xFFE7B86E),
  ),
  AppSkin(
    id: 'bamboo',
    name: '竹影墨绿',
    description: '深竹绿与自然棕点缀，沉静耐看，适合长期记录和整理。',
    background: Color(0xFFF5F8F5),
    primary: Color(0xFF426B57),
    primarySoft: Color(0xFFE5EFE9),
    accent: Color(0xFFA47B47),
    text: Color(0xFF29342E),
    muted: Color(0xFF839087),
    heroStart: Color(0xFF5F8E72),
    heroEnd: Color(0xFF7EA68E),
  ),
];

AppSkin appSkinAt(int index) => appSkins[index % appSkins.length];

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
    asset: 'static/image/items/digital.png',
    subcategories: ['手机', '耳机', '电脑', '手表'],
  ),
  ItemCategory(
    id: 'clothing',
    name: '服饰箱包',
    color: Color(0xFFC98C4E),
    softColor: Color(0xFFF8F0E3),
    asset: 'static/image/items/clothing.png',
    subcategories: ['上衣', '裤子', '袜子', '鞋子', '帽子', '箱包'],
  ),
  ItemCategory(
    id: 'furniture',
    name: '家具',
    color: Color(0xFF4B9F91),
    softColor: Color(0xFFE7F5F2),
    asset: 'static/image/items/furniture.png',
    subcategories: ['灯具', '床品', '收纳'],
  ),
  ItemCategory(
    id: 'appliances',
    name: '家电',
    color: Color(0xFFD5A13D),
    softColor: Color(0xFFFAF2DF),
    asset: 'static/image/items/appliances.png',
    subcategories: ['厨房电器', '清洁电器', '生活电器', '影音设备'],
  ),
  ItemCategory(
    id: 'book',
    name: '教育图书',
    color: Color(0xFF786BC2),
    softColor: Color(0xFFEFEDFA),
    asset: 'static/image/items/book.png',
    subcategories: ['文学', '经管', '教材', '童书'],
  ),
  ItemCategory(
    id: 'sports',
    name: '运动',
    color: Color(0xFF52A96F),
    softColor: Color(0xFFE9F6EE),
    asset: 'static/image/items/sports.png',
    subcategories: ['健身器材', '球类', '户外装备'],
  ),
  ItemCategory(
    id: 'beauty',
    name: '美妆个护',
    color: Color(0xFFD77FA5),
    softColor: Color(0xFFFAEDF3),
    asset: 'static/image/items/beauty.png',
    subcategories: ['护肤品', '彩妆品', '香氛', '美容工具'],
  ),
  ItemCategory(
    id: 'car',
    name: '车辆',
    color: Color(0xFF557C9B),
    softColor: Color(0xFFEAF0F5),
    asset: 'static/image/items/car.png',
    subcategories: ['小轿车', '电瓶车', '自行车'],
  ),
  ItemCategory(
    id: 'card',
    name: '证卡证件',
    color: Color(0xFF8B5F84),
    softColor: Color(0xFFF5ECF4),
    asset: 'static/image/items/card.png',
    subcategories: ['身份证', '银行卡', '驾照', '护照'],
  ),
  ItemCategory(
    id: 'virtual',
    name: '虚拟资产',
    color: Color(0xFF13899A),
    softColor: Color(0xFFE5F5F8),
    asset: 'static/image/items/virtual.png',
    subcategories: ['App会员', '视频会员', '音乐会员'],
  ),
  ItemCategory(
    id: 'collect',
    name: '收藏爱好',
    color: Color(0xFFB96A63),
    softColor: Color(0xFFF7EAE7),
    asset: 'static/image/items/collect.png',
    subcategories: ['手办', '卡牌', '艺术品'],
  ),
  ItemCategory(
    id: 'other',
    name: '其他',
    color: Color(0xFF8C879A),
    softColor: Color(0xFFF1EFF4),
    asset: 'static/image/items/other.png',
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
  ItemStatus('inuse', '使用中', Color(0xFF4DA88F), Color(0xFFE7F6F1)),
  ItemStatus('idle', '闲置', Color(0xFFC58B2B), Color(0xFFFBF3DF)),
  ItemStatus('repairing', '维修中', Color(0xFFE88778), Color(0xFFFBEDEA)),
  ItemStatus('processed', '已处理', Color(0xFF607FC7), Color(0xFFEDF2FB)),
  ItemStatus('retired', '已退役', Color(0xFF8B78C9), Color(0xFFF2EFF9)),
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
    this.targetUseDays = 0,
    this.note = '',
    this.tags = const [],
    this.usageRecords = const [],
    this.statusHistory = const [],
    this.favorite = false,
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
  final int targetUseDays;
  final String note;
  final List<String> tags;
  final List<String> usageRecords;
  final List<StatusEvent> statusHistory;
  final bool favorite;
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

  int get ownedDays => ownedDaysAsOf(DateTime.now());
  int get usageDays => usageDaysAsOf(DateTime.now());
  int get idleDays => idleDaysAsOf(DateTime.now());

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

  int get effectiveTargetDays {
    if (targetUseDays > 0) return targetUseDays;
    return switch (warrantyPeriod) {
      '一年' => 365,
      '二年' || '两年' => 730,
      '三年' => 1095,
      '五年' => 1825,
      _ => 0,
    };
  }

  double get ownedDailyCost => ownedDays == 0 ? 0 : purchaseTotal / ownedDays;
  double get usageDailyCost => usageDays == 0 ? 0 : purchaseTotal / usageDays;
  double get targetDailyCost =>
      effectiveTargetDays == 0 ? 0 : purchaseTotal / effectiveTargetDays;

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
    int? targetUseDays,
    String? note,
    List<String>? tags,
    List<String>? usageRecords,
    List<StatusEvent>? statusHistory,
    bool? favorite,
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
      targetUseDays: targetUseDays ?? this.targetUseDays,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      usageRecords: usageRecords ?? this.usageRecords,
      statusHistory: statusHistory ?? this.statusHistory,
      favorite: favorite ?? this.favorite,
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
    'targetUseDays': targetUseDays,
    'note': note,
    'tags': tags,
    'usageRecords': usageRecords,
    'statusHistory': statusHistory.map((entry) => entry.toJson()).toList(),
    'favorite': favorite,
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
      targetUseDays: _asInt(json['targetUseDays']),
      note: json['note']?.toString() ?? '',
      tags: (json['tags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      usageRecords: (json['usageRecords'] as List? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      statusHistory: history,
      favorite: json['favorite'] == true,
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

  DateTime get createdAtDate => DateTime.tryParse(createdAt) ?? DateTime.now();
  DateTime get decisionDue => createdAtDate.add(Duration(days: coolingDays));
  int get remainingDays =>
      math.max(0, decisionDue.difference(DateTime.now()).inDays + 1);
  int get elapsedDays => math.min(
    coolingDays,
    math.max(0, DateTime.now().difference(createdAtDate).inDays),
  );
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
    );
  }
}
