import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_store.dart';
import '../components/stored_image.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../storage/local_image_store.dart';
import '../widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService(
    onUnauthorized: AppStore.instance.handleUnauthorized,
  );
  late final TextEditingController _name;
  late String _avatarPath;
  late String _birthday;
  late String _gender;
  String? _newLocalAvatar;
  bool _saving = false;
  bool _saved = false;

  static const _genders = ['未设置', '男', '女', '其他'];

  @override
  void initState() {
    super.initState();
    final store = AppStore.instance;
    _name = TextEditingController(text: store.accountName);
    _avatarPath = store.accountAvatarPath;
    _birthday = store.accountBirthday;
    _gender = _genders.contains(store.accountGender)
        ? store.accountGender
        : '未设置';
    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recoverLostAvatar();
      });
    }
  }

  @override
  void dispose() {
    if (!_saved &&
        _newLocalAvatar != null &&
        _newLocalAvatar != widgetInitialAvatar()) {
      LocalImageStore.instance.delete(_newLocalAvatar!);
    }
    _name.dispose();
    _auth.close();
    super.dispose();
  }

  String widgetInitialAvatar() => AppStore.instance.accountAvatarPath;

  Future<void> _recoverLostAvatar() async {
    if (!mounted) return;
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty) return;
      if (response.exception != null) {
        if (mounted) showAppSnack(context, '上次选择的头像未能恢复，请重新选择');
        return;
      }
      final files = response.files;
      final file =
          response.file ??
          (files != null && files.isNotEmpty ? files.last : null);
      if (file == null) return;
      final path = await LocalImageStore.instance.persist(file);
      final previousNew = _newLocalAvatar;
      if (!mounted) {
        await LocalImageStore.instance.delete(path);
        return;
      }
      setState(() {
        _avatarPath = path;
        _newLocalAvatar = path;
      });
      if (previousNew != null &&
          previousNew != widgetInitialAvatar() &&
          previousNew != path) {
        await LocalImageStore.instance.delete(previousNew);
      }
    } on Object {
      if (mounted) showAppSnack(context, '上次选择的头像未能恢复，请重新选择');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return PageFrame(
      title: '个人信息',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.16),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _AvatarImage(
                            path: _avatarPath,
                            fallback: _name.text.isEmpty
                                ? '拾'
                                : _name.text.characters.first,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: 2,
                        child: Material(
                          color: Theme.of(context).colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _saving ? null : _chooseAvatar,
                            child: const SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                Icons.photo_camera_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _newLocalAvatar == null ? '点击更换头像' : '新头像将在保存后生效',
                    style: const TextStyle(color: appMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SectionHeading(title: '基础资料'),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 20,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      counterText: '',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '请输入用户名' : null,
                  ),
                  const SizedBox(height: 13),
                  InkWell(
                    onTap: _saving ? null : _chooseBirthday,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '生日'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _birthday.isEmpty ? '请选择生日' : _birthday,
                              style: TextStyle(
                                color: _birthday.isEmpty ? appMuted : appText,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 19,
                            color: appMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  BottomSelectField<String>(
                    label: '性别',
                    value: _gender,
                    options: [
                      for (final gender in _genders)
                        BottomSelectOption(value: gender, label: gender),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _gender = value);
                    },
                  ),
                  const SizedBox(height: 13),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: '手机号'),
                    child: Text(
                      store.accountPhone.isEmpty ? '未绑定' : store.accountPhone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _saving ? '保存中…' : '保存修改',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseAvatar() async {
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
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      if (picked == null) return;
      final path = await LocalImageStore.instance.persist(picked);
      final previousNew = _newLocalAvatar;
      if (previousNew != null) {
        await LocalImageStore.instance.delete(previousNew);
      }
      if (mounted) {
        setState(() {
          _avatarPath = path;
          _newLocalAvatar = path;
        });
      }
    } catch (_) {
      if (mounted) showAppSnack(context, '头像选择失败，请检查相册或相机权限');
    }
  }

  Future<void> _chooseBirthday() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: parseDate(_birthday) ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      title: '选择生日',
      confirmLabel: '确定生日',
    );
    if (picked != null) setState(() => _birthday = formatDate(picked));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final store = AppStore.instance;
    if (!store.isAuthenticated) {
      showAppSnack(context, '游客模式暂不支持修改资料，请先登录');
      return;
    }
    setState(() => _saving = true);
    try {
      var avatar = _avatarPath;
      if (_newLocalAvatar != null && avatar == _newLocalAvatar) {
        avatar = await _auth.uploadAvatar(
          token: store.sessionToken,
          localPath: _newLocalAvatar!,
        );
      }
      await _auth.updateUserProfile(
        token: store.sessionToken,
        name: _name.text.trim(),
        avatarPath: avatar,
        birthday: _birthday,
        gender: _gender == '未设置' ? '' : _gender,
      );
      try {
        await store.updateAccountProfile(
          name: _name.text.trim(),
          avatarPath: avatar,
          birthday: _birthday,
          gender: _gender == '未设置' ? '' : _gender,
        );
      } catch (_) {
        try {
          await _auth.updateUserProfile(
            token: store.sessionToken,
            name: store.accountName,
            avatarPath: store.accountAvatarPath,
            birthday: store.accountBirthday,
            gender: store.accountGender,
          );
        } on Object {
          // Preserve the local persistence error as the primary failure.
        }
        rethrow;
      }
      _saved = true;
      if (_newLocalAvatar != null) {
        await LocalImageStore.instance.delete(_newLocalAvatar!);
      }
      if (!mounted) return;
      Navigator.maybePop(context);
      showAppSnack(context, '个人资料已更新');
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.path, required this.fallback});

  final String path;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final clean = path.trim();
    return StoredImage(
      path: clean,
      fit: BoxFit.cover,
      fallback: _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ColoredBox(
      color: Color.lerp(primary, Colors.white, 0.88)!,
      child: Center(
        child: Text(
          fallback,
          style: TextStyle(
            color: primary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
