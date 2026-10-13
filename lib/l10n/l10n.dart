import 'package:base_app/core/result/result.dart';
import 'package:base_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:base_app/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// UI text for a [Failure]. Lives here, not in core, so core stays UI-free.
extension FailureL10n on Failure {
  String localized(AppLocalizations l10n) =>
      message ??
      switch (type) {
        FailureType.network => l10n.errorNetwork,
        FailureType.unauthorized => l10n.errorUnauthorized,
        FailureType.badRequest => l10n.errorBadRequest,
        FailureType.server => l10n.errorServer,
        FailureType.unknown => l10n.errorUnknown,
      };
}
