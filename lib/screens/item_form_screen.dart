import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_store.dart';
import '../components/stored_image.dart';
import '../models.dart';
import '../storage/local_image_store.dart';
import '../widgets.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.initial});

  final InventoryItem? initial;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _currentValue;
  late int _quantityValue;
  late final TextEditingController _usageCount;
  late final TextEditingController _targetDays;
  late final TextEditingController _note;
  late final TextEditingController _tag;
  late final TextEditingController _netWeight;
  late final TextEditingController _remainingWeight;

  late String _category;
  late String? _subcategory;
  late String _status;
  late String _usageMode;
  late String _purchaseDate;
  late String _purchaseChannel;
  late String _location;
  late String _warranty;
  late String _warrantyEndDate;
  late String _currency;
  late List<String> _tags;
  late List<String> _imagePaths;
  late final List<String> _initialImagePaths;
  bool _saving = false;
  bool _saved = false;

  static const _channels = [
    '官网',
    '门店',
    '淘宝',
    '京东',
    '唯品会',
    '山姆',
    '代购',
    '二手平台',
    '其他',
  ];
  static const _warranties = ['', '一年', '二年', '三年', '五年', '其他'];

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _price = TextEditingController(
      text: item == null ? '' : formatMoney(item.purchasePrice),
    );
    _currentValue = TextEditingController(
      text: item == null ? '' : formatMoney(item.currentValue),
    );
    _quantityValue = math.max(1, item?.quantity.round() ?? 1);
    _usageCount = TextEditingController(text: '${item?.manualUsageCount ?? 0}');
    _targetDays = TextEditingController(
      text: item == null || item.targetUseDays == 0
          ? ''
          : '${item.targetUseDays}',
    );
    _note = TextEditingController(text: item?.note ?? '');
    _tag = TextEditingController();
    _netWeight = TextEditingController(text: item?.netWeight ?? '');
    _remainingWeight = TextEditingController(
      text: item?.remainingNetWeight ?? '',
    );
    _category = item?.category ?? 'digital';
    _subcategory = item?.subcategory.isEmpty == false
        ? item!.subcategory
        : null;
    _status = item?.status ?? 'inuse';
    _usageMode = item?.usageMode ?? 'auto';
    _purchaseDate = item?.purchaseDate ?? formatDate(DateTime.now());
    _purchaseChannel = _channels.contains(item?.purchaseChannel)
        ? item!.purchaseChannel
        : '官网';
    _location = item?.storageLocation ?? '';
    _warranty = _warranties.contains(item?.warrantyPeriod)
        ? item!.warrantyPeriod
        : '';
    _warrantyEndDate = item?.warrantyEndDate ?? '';
    _currency = item?.purchaseCurrency ?? 'CNY';
    _tags = List<String>.from(item?.tags ?? const []);
    _imagePaths = List<String>.from(item?.imagePaths ?? const []);
    _initialImagePaths = List<String>.from(_imagePaths);
    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recoverLostImages();
      });
    }
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final path in _imagePaths) {
        if (!_initialImagePaths.contains(path)) {
          unawaited(LocalImageStore.instance.delete(path));
        }
      }
    }
    _name.dispose();
    _price.dispose();
    _currentValue.dispose();
    _usageCount.dispose();
    _targetDays.dispose();
    _note.dispose();
    _tag.dispose();
    _netWeight.dispose();
    _remainingWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryById(_category);
    final currency = currencyByCode(_currency);
    return PageFrame(
      title: _editing ? '整理这件物' : '拾一件',
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoEditor(
              paths: _imagePaths,
              category: category,
              onPick: _pickPhotos,
              onRemove: _removePhoto,
            ),
            const SectionHeading(title: '基本信息'),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: '物品名称',
                      hintText: '例如：富士 X100V',
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '请输入物品名称'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  BottomSelectField<String>(
                    label: '生活分类',
                    value: _category,
                    options: [
                      for (final category in itemCategories)
                        BottomSelectOption(
                          value: category.id,
                          label: category.name,
                          leading: Image.asset(
                            category.asset,
                            width: 28,
                            height: 28,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _category = value;
                        _subcategory = null;
                      });
                    },
                  ),
                  const SizedBox(height: 13),
                  BottomSelectField<String>(
                    label: '二级分类',
                    value: category.subcategories.contains(_subcategory)
                        ? _subcategory
                        : null,
                    options: [
                      const BottomSelectOption<String>(
                        value: null,
                        label: '暂不选择',
                      ),
                      for (final subcategory in category.subcategories)
                        BottomSelectOption(
                          value: subcategory,
                          label: subcategory,
                        ),
                    ],
                    onChanged: (value) => setState(() => _subcategory = value),
                  ),
                ],
              ),
            ),
            const SectionHeading(title: '状态与使用'),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('当前状态'),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in itemStatuses)
                        ChoiceChip(
                          selected: _status == status.id,
                          onSelected: (_) =>
                              setState(() => _status = status.id),
                          showCheckmark: false,
                          selectedColor: status.softColor,
                          backgroundColor: const Color(0xFFF8F5F1),
                          side: BorderSide.none,
                          label: Text(
                            status.name,
                            style: TextStyle(
                              color: _status == status.id
                                  ? status.color
                                  : appMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'auto', label: Text('自动按天')),
                      ButtonSegment(value: 'manual', label: Text('手动记次数')),
                    ],
                    selected: {_usageMode},
                    onSelectionChanged: (value) =>
                        setState(() => _usageMode = value.first),
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      foregroundColor: appMuted,
                      backgroundColor: const Color(0xFFF6F2ED),
                      selectedForegroundColor: Theme.of(context)
                          .colorScheme
                          .primary,
                      selectedBackgroundColor: Color.lerp(
                        Theme.of(context).colorScheme.primary,
                        Colors.white,
                        0.82,
                      ),
                      side: BorderSide.none,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                  if (_usageMode == 'manual') ...[
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: _usageCount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '已使用次数'),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');
                        return number == null || number < 0
                            ? '使用次数不能小于 0'
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _targetDays,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _usageMode == 'manual'
                          ? '目标使用次数（选填）'
                          : '目标使用天数（选填）',
                      hintText: _usageMode == 'manual' ? '例如：100' : '例如：730',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final number = int.tryParse(value);
                      return number == null || number <= 0
                          ? _usageMode == 'manual'
                                ? '目标次数必须大于 0'
                                : '目标天数必须大于 0'
                          : null;
                    },
                  ),
                ],
              ),
            ),
            const SectionHeading(title: '价值与购入'),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  BottomSelectField<String>(
                    label: '购买币种',
                    value: _currency,
                    options: [
                      for (final option in currencyOptions)
                        BottomSelectOption(
                          value: option.code,
                          label: '${option.name}（${option.symbol}）',
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _currency = value);
                    },
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '购入价（$_currency）',
                            prefixText: '${currency.symbol} ',
                          ),
                          validator: _validatePurchasePrice,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _currentValue,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '当前估值（$_currency）',
                            prefixText: '${currency.symbol} ',
                          ),
                          validator: _validateNonNegativeAmount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: '数量'),
                          child: Row(
                            children: [
                              _QuantityButton(
                                key: const Key('quantity-minus'),
                                icon: Icons.remove_rounded,
                                onTap: _quantityValue > 1
                                    ? () => setState(() => _quantityValue -= 1)
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  '$_quantityValue',
                                  key: const Key('quantity-value'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                key: const Key('quantity-plus'),
                                icon: Icons.add_rounded,
                                onTap: () =>
                                    setState(() => _quantityValue += 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _choosePurchaseDate,
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '购入日期',
                            ),
                            child: Text(_purchaseDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  BottomSelectField<String>(
                    label: '购买渠道',
                    value: _purchaseChannel,
                    options: [
                      for (final channel in _channels)
                        BottomSelectOption(value: channel, label: channel),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _purchaseChannel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: BottomSelectField<String>(
                          label: '收纳位置',
                          value: _location.isEmpty ? null : _location,
                          hint: '暂不设置',
                          options: [
                            const BottomSelectOption(value: '', label: '暂不设置'),
                            for (final location
                                in AppStore.instance.storageLocations)
                              BottomSelectOption(
                                value: location,
                                label: location,
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _location = value ?? ''),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BottomSelectField<String>(
                          label: '保修/质期',
                          value: _warranty,
                          options: [
                            for (final warranty in _warranties)
                              BottomSelectOption(
                                value: warranty,
                                label: warranty.isEmpty ? '未记录' : warranty,
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _warranty = value ?? ''),
                        ),
                      ),
                    ],
                  ),
                  if (_warranty == '其他') ...[
                    const SizedBox(height: 13),
                    InkWell(
                      onTap: _chooseWarrantyDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: '到期日期'),
                        child: Text(
                          _warrantyEndDate.isEmpty ? '请选择日期' : _warrantyEndDate,
                          style: TextStyle(
                            color: _warrantyEndDate.isEmpty
                                ? appMuted
                                : appText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SectionHeading(title: '更多记录'),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _netWeight,
                          decoration: const InputDecoration(
                            labelText: '净含量/克重',
                            hintText: '例如：50g',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _remainingWeight,
                          decoration: const InputDecoration(
                            labelText: '剩余量',
                            hintText: '例如：8g',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tag,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addTag(),
                          decoration: const InputDecoration(
                            labelText: '添加标签',
                            hintText: '回车确认',
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        height: 52,
                        child: IconButton.filledTonal(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final tag in _tags)
                            InputChip(
                              label: Text(tag),
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 14,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 13),
                  TextField(
                    controller: _note,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      hintText: '记下这件物品的故事、用途或提醒…',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _saving ? '保存中…' : (_editing ? '保存修改' : '放入匣中'),
              icon: Icons.inventory_2_outlined,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    if (_imagePaths.length >= 9) {
      showAppSnack(context, '最多保存 9 张物品照片');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              subtitle: const Text('可一次选择多张'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final remaining = 9 - _imagePaths.length;
      final picked = source == ImageSource.gallery
          ? await picker.pickMultiImage(
              imageQuality: 82,
              maxWidth: 1800,
              limit: remaining,
            )
          : [
              ?await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 82,
                maxWidth: 1800,
              ),
            ];
      if (picked.isEmpty) return;
      final added = <String>[];
      try {
        for (final photo in picked.take(remaining)) {
          added.add(await LocalImageStore.instance.persist(photo));
        }
      } catch (_) {
        for (final path in added) {
          try {
            await LocalImageStore.instance.delete(path);
          } on Object {
            // Keep the original photo error as the user-facing failure.
          }
        }
        rethrow;
      }
      if (mounted) setState(() => _imagePaths.addAll(added));
    } catch (_) {
      if (mounted) showAppSnack(context, '照片选择失败，请检查相册或相机权限');
    }
  }

  Future<void> _recoverLostImages() async {
    if (!mounted) return;
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty) return;
      if (response.exception != null) {
        if (mounted) showAppSnack(context, '上次选择的照片未能恢复，请重新选择');
        return;
      }
      final files =
          response.files ?? [if (response.file != null) response.file!];
      if (files.isEmpty) return;
      final remaining = 9 - _imagePaths.length;
      if (remaining <= 0) return;
      final recovered = <String>[];
      for (final photo in files.take(remaining)) {
        recovered.add(await LocalImageStore.instance.persist(photo));
      }
      if (mounted && recovered.isNotEmpty) {
        setState(() => _imagePaths.addAll(recovered));
      }
    } on Object {
      if (mounted) showAppSnack(context, '上次选择的照片未能恢复，请重新选择');
    }
  }

  Future<void> _removePhoto(int index) async {
    if (index < 0 || index >= _imagePaths.length) return;
    final path = _imagePaths.removeAt(index);
    setState(() {});
    if (!_initialImagePaths.contains(path)) {
      await LocalImageStore.instance.delete(path);
    }
  }

  Future<void> _choosePurchaseDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: parseDate(_purchaseDate) ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
      title: '选择购入日期',
      confirmLabel: '确定购入日期',
    );
    if (picked != null) {
      setState(() => _purchaseDate = formatDate(picked));
    }
  }

  Future<void> _chooseWarrantyDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate:
          parseDate(_warrantyEndDate) ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
      title: '选择保修到期日期',
      confirmLabel: '确定到期日期',
    );
    if (picked != null) {
      setState(() => _warrantyEndDate = formatDate(picked));
    }
  }

  void _addTag() {
    final clean = _tag.text.trim();
    if (clean.isEmpty) return;
    if (_tags.length >= 8) {
      showAppSnack(context, '最多添加 8 个标签');
      return;
    }
    setState(() {
      if (!_tags.contains(clean)) _tags.add(clean);
      _tag.clear();
    });
  }

  String? _validateNonNegativeAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final amount = double.tryParse(text.replaceAll(',', ''));
    return amount == null || amount < 0 ? '请输入有效金额' : null;
  }

  String? _validatePurchasePrice(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入购入价';
    return _validateNonNegativeAmount(value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final price = double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
    final current =
        double.tryParse(_currentValue.text.replaceAll(',', '')) ?? price;
    final quantity = _quantityValue;
    final original = widget.initial;
    final history = List<StatusEvent>.from(
      original?.statusHistory ??
          [
            StatusEvent(
              status: _status,
              at: now.toIso8601String(),
              note: '物品初始状态',
            ),
          ],
    );
    if (original != null && original.status != _status) {
      history.add(
        StatusEvent(
          status: _status,
          at: now.toIso8601String(),
          note: '编辑时更新状态',
        ),
      );
    }
    final item = InventoryItem(
      id: original?.id ?? 'it_${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      subcategory: _subcategory ?? '',
      status: _status,
      usageMode: _usageMode,
      manualUsageCount: int.tryParse(_usageCount.text) ?? 0,
      purchasePrice: price,
      currentValue: current,
      purchaseCurrency: _currency,
      purchaseDate: _purchaseDate,
      createdAt: original?.createdAt ?? now.toIso8601String(),
      quantity: quantity.toDouble(),
      netWeight: _netWeight.text.trim(),
      remainingNetWeight: _remainingWeight.text.trim(),
      purchaseChannel: _purchaseChannel,
      storageLocation: _location,
      warrantyPeriod: _warranty,
      warrantyEndDate: _warranty == '其他' ? _warrantyEndDate : '',
      targetUseDays: int.tryParse(_targetDays.text) ?? 0,
      note: _note.text.trim(),
      tags: List<String>.from(_tags),
      usageRecords: original?.usageRecords ?? const [],
      statusHistory: history,
      favorite: original?.favorite ?? false,
      imagePaths: List<String>.from(_imagePaths),
      relatedItemIds: original?.relatedItemIds ?? const [],
      idleReason: original?.idleReason ?? '',
      repairPlatform: original?.repairPlatform ?? '',
      repairDays: original?.repairDays ?? 0,
      repairContactName: original?.repairContactName ?? '',
      repairContactPhone: original?.repairContactPhone ?? '',
      disposalMethod: original?.disposalMethod ?? '',
      disposalDetail: original?.disposalDetail ?? '',
      disposalPlatform: original?.disposalPlatform ?? '',
      disposalContact: original?.disposalContact ?? '',
      disposalPrice: original?.disposalPrice ?? 0,
      disposalCost: original?.disposalCost ?? 0,
      processDate: original?.processDate ?? '',
      recoveryMethod: original?.recoveryMethod ?? '',
      recoveryTargetPrice: original?.recoveryTargetPrice ?? 0,
      recoveryDeadline: original?.recoveryDeadline ?? '',
      recoveryPlatform: original?.recoveryPlatform ?? '',
      recoveryContact: original?.recoveryContact ?? '',
      recoveryNote: original?.recoveryNote ?? '',
    );
    try {
      if (original == null) {
        await AppStore.instance.addItem(item);
      } else {
        await AppStore.instance.updateItem(item);
      }
      _saved = true;
      if (original != null) {
        for (final oldImage in original.imagePaths) {
          if (_imagePaths.contains(oldImage)) continue;
          try {
            await LocalImageStore.instance.delete(oldImage);
          } on Object {
            // Saving the record succeeded; an orphaned old image is non-fatal.
          }
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, original == null ? '已拾入匣中' : '物品已更新');
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: appMuted,
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton.filledTonal(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

class _PhotoEditor extends StatelessWidget {
  const _PhotoEditor({
    required this.paths,
    required this.category,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> paths;
  final ItemCategory category;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: category.softColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Image.asset(category.asset),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '物品照片',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '最多 9 张，第一张作为封面',
                      style: TextStyle(color: appMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                '${paths.length}/9',
                style: const TextStyle(color: appMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 6 : 4;
              final canAdd = paths.length < 9;
              final count = paths.length + (canAdd ? 1 : 0);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: count,
                itemBuilder: (context, index) {
                  if (index == paths.length) {
                    return InkWell(
                      onTap: onPick,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: category.softColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: category.color.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    );
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _StoredImage(path: paths[index], size: 100),
                      ),
                      Positioned(
                        right: 3,
                        top: 3,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onRemove(index),
                            child: const SizedBox(
                              width: 23,
                              height: 23,
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              '封面',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoredImage extends StatelessWidget {
  const _StoredImage({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return StoredImage(
      path: path,
      fit: BoxFit.cover,
      cacheWidth: cacheSize,
      fallback: const SizedBox.shrink(),
    );
  }
}
