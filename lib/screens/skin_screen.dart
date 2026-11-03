import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';

class SkinScreen extends StatelessWidget {
  const SkinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final data = appSkins;
        return PageFrame(
          title: '皮肤选择',
          child: Column(
            children: [
              SoftCard(
                onTap: () => runStoreAction(
                  context,
                  () => AppStore.instance.setSkin(-1),
                  successMessage: '已切换为跟随系统',
                ),
                borderColor: AppStore.instance.skinIndex == -1
                    ? appPrimary.withValues(alpha: 0.5)
                    : appBorder,
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C8792), Color(0xFF4B5960)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.brightness_auto_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '跟随系统',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '浅色系统使用山茶暖白，深色系统使用竹影墨绿。',
                            style: TextStyle(color: appMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (AppStore.instance.skinIndex == -1)
                      const Icon(Icons.check_circle_rounded, color: appPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < data.length; index++) ...[
                SoftCard(
                  onTap: () => runStoreAction(
                    context,
                    () => AppStore.instance.setSkin(index),
                    successMessage: '已切换为${data[index].name}',
                  ),
                  borderColor: AppStore.instance.skinIndex == index
                      ? data[index].primary.withValues(alpha: 0.5)
                      : appBorder,
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              data[index].heroStart,
                              data[index].heroEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data[index].name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              data[index].description,
                              style: const TextStyle(
                                color: appMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (AppStore.instance.skinIndex == index)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: appPrimary,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}
