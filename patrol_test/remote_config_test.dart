import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Firebase Remote Config trên màn Profile.
void main() {
  /// Test Case 10 — Remote Config.
  /// Login → tab Profile → verify 2 dòng giá trị Remote Config hiển thị →
  /// tap `remote_config_refresh` → verify không lỗi, giá trị vẫn hiển thị.
  patrolTest('TC10 - Remote Config', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    // Card Remote Config nằm giữa ListView của Profile ⇒ cuộn tới.
    await $(const Key(WidgetKeys.remoteConfigJournalsValue)).scrollTo();

    // 2 dòng giá trị: maxJournals và maxKeywords.
    await $(const Key(WidgetKeys.remoteConfigJournalsValue)).waitUntilVisible(
      timeout: uiTimeout,
    );
    await $(const Key(WidgetKeys.remoteConfigKeywordsValue)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.remoteConfigJournalsValue)).visible, true);
    expect($(const Key(WidgetKeys.remoteConfigKeywordsValue)).visible, true);

    // Fetch lại config từ Firebase.
    await $(const Key(WidgetKeys.remoteConfigRefresh)).scrollTo();
    await $(const Key(WidgetKeys.remoteConfigRefresh)).tap();

    // Sau refresh: không crash, 2 dòng giá trị vẫn còn hiển thị.
    // (`tap` đã pump & settle nên setState sau `await rc.refresh()` đã áp dụng.)
    await $(const Key(WidgetKeys.remoteConfigJournalsValue)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.remoteConfigJournalsValue)).visible, true);
    expect($(const Key(WidgetKeys.remoteConfigKeywordsValue)).visible, true);
  });
}
