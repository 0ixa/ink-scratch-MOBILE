// lib/core/utils/navigation_utils.dart
//
// Central place for all Navigator.push calls so routes stay consistent.

import 'package:flutter/material.dart';
import '../../features/manga/presentation/pages/manga_detail_page.dart';
import '../../features/manga/presentation/pages/manga_reader_page.dart';

class AppNavigator {
  AppNavigator._();

  static void toMangaDetail(BuildContext context, String mangaId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MangaDetailPage(mangaId: mangaId)),
    );
  }

  static void toReader(
    BuildContext context, {
    required String mangaId,
    required String chapterId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MangaReaderPage(mangaId: mangaId, chapterId: chapterId),
      ),
    );
  }
}
