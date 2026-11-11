import 'package:flutter/material.dart';

class StorageLocationIconOption {
  const StorageLocationIconOption({
    required this.keyName,
    required this.label,
    required this.icon,
  });

  final String keyName;
  final String label;
  final IconData icon;
}

const storageLocationIconOptions = <StorageLocationIconOption>[
  StorageLocationIconOption(
    keyName: 'place',
    label: '位置',
    icon: Icons.place_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'door',
    label: '玄关',
    icon: Icons.door_front_door_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'living',
    label: '客厅',
    icon: Icons.weekend_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'bed',
    label: '卧室',
    icon: Icons.bed_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'book',
    label: '书房',
    icon: Icons.menu_book_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'kitchen',
    label: '厨房',
    icon: Icons.kitchen_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'bath',
    label: '卫浴',
    icon: Icons.bathtub_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'balcony',
    label: '阳台',
    icon: Icons.balcony_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'closet',
    label: '衣帽',
    icon: Icons.checkroom_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'bag',
    label: '包袋',
    icon: Icons.backpack_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'storage',
    label: '收纳',
    icon: Icons.inventory_2_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'garage',
    label: '车库',
    icon: Icons.directions_car_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'desk',
    label: '书桌',
    icon: Icons.desk_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'chair',
    label: '椅子',
    icon: Icons.chair_alt_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'dining',
    label: '餐厅',
    icon: Icons.dining_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'laundry',
    label: '洗衣',
    icon: Icons.local_laundry_service_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'toys',
    label: '玩具',
    icon: Icons.toys_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'sports',
    label: '运动',
    icon: Icons.sports_basketball_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'pets',
    label: '宠物',
    icon: Icons.pets_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'audio',
    label: '影音',
    icon: Icons.headphones_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'computer',
    label: '电脑',
    icon: Icons.computer_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'tools',
    label: '工具',
    icon: Icons.handyman_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'plants',
    label: '植物',
    icon: Icons.local_florist_outlined,
  ),
  StorageLocationIconOption(
    keyName: 'luggage',
    label: '行李',
    icon: Icons.luggage_outlined,
  ),
];

StorageLocationIconOption storageLocationIconOption(String keyName) {
  return storageLocationIconOptions.firstWhere(
    (option) => option.keyName == keyName,
    orElse: () => storageLocationIconOptions.first,
  );
}

String storageLocationDefaultIconKey(String location) {
  final normalized = location.trim().toLowerCase();
  if (normalized.contains('客厅')) return 'living';
  if (normalized.contains('卧室') || normalized.contains('床')) return 'bed';
  if (normalized.contains('书房') || normalized.contains('阅读')) return 'book';
  if (normalized.contains('厨房')) return 'kitchen';
  if (normalized.contains('卫生间') ||
      normalized.contains('浴室') ||
      normalized.contains('卫浴')) {
    return 'bath';
  }
  if (normalized.contains('玄关')) return 'door';
  if (normalized.contains('阳台')) return 'balcony';
  if (normalized.contains('衣帽') || normalized.contains('衣柜')) {
    return 'closet';
  }
  if (normalized.contains('包') || normalized.contains('通勤')) return 'bag';
  if (normalized.contains('车库') || normalized.contains('车')) return 'garage';
  if (normalized.contains('收纳') ||
      normalized.contains('抽屉') ||
      normalized.contains('柜')) {
    return 'storage';
  }
  return 'place';
}

IconData storageLocationIcon(String location, {String iconKey = ''}) {
  final resolvedKey = iconKey.trim().isEmpty
      ? storageLocationDefaultIconKey(location)
      : iconKey;
  return storageLocationIconOption(resolvedKey).icon;
}
