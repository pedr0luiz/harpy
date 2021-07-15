import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpy/components/components.dart';
import 'package:harpy/harpy_widgets/harpy_widgets.dart';

/// Builds an [icon] and [text] row with padding for the icon that matches the
/// size of a [TweetCard] avatar.
///
/// This is intended to build a label above or below a [TweetCard].
class TweetListInfoRow extends StatelessWidget {
  const TweetListInfoRow({
    required this.icon,
    required this.text,
    this.padding,
  });

  final Widget icon;
  final Widget text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeAnimation(
      duration: kShortAnimationDuration,
      curve: Curves.easeInOut,
      child: Padding(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: defaultPaddingValue * 2,
              vertical: defaultSmallPaddingValue,
            ),
        child: Row(
          children: [
            IconTheme(
              data: theme.iconTheme.copyWith(size: 18),
              child: SizedBox(
                width: TweetCardAvatar.defaultRadius * 2,
                child: icon,
              ),
            ),
            defaultHorizontalSpacer,
            Expanded(
              child: DefaultTextStyle(
                style: theme.textTheme.subtitle1!,
                child: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
