import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:harpy/api/twitter/data/user.dart';
import 'package:harpy/components/screens/following_followers_screen.dart';
import 'package:harpy/components/widgets/shared/buttons.dart';
import 'package:harpy/core/misc/harpy_navigator.dart';
import 'package:harpy/core/misc/harpy_theme.dart';
import 'package:harpy/core/utils/string_utils.dart';
import 'package:harpy/main_free.dart';

/// An [IconRow] to display an [Icon] next to some text.
class IconRow extends StatelessWidget {
  const IconRow({
    @required this.icon,
    @required this.child,
    this.iconPadding,
  });

  /// The [IconData] of the icon.
  final IconData icon;

  /// The [child] an either be a Widget or a String that will turn into a text
  /// widget and is displayed to the right of the [icon].
  final dynamic child;

  /// If [iconPadding] is not null the [icon] will be in the center of a
  /// [SizedBox] with a width of [iconPadding].
  final double iconPadding;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.body1;

    return Row(
      children: <Widget>[
        SizedBox(
          width: iconPadding,
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: child is Widget
              ? child
              : Text(
                  child,
                  style: textStyle.copyWith(
                    color: textStyle.color.withOpacity(0.8),
                  ),
                ),
        ),
      ],
    );
  }
}

/// A Widget to display the number of following users and followers for the
/// [User].
class FollowersCount extends StatelessWidget {
  const FollowersCount(this.user);

  final User user;

  void _showInScreen(FollowingFollowerType type) {
    HarpyNavigator.push(FollowingFollowerScreen(
      user: user,
      type: type,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        HarpyButton.flat(
          text: "${prettyPrintNumber(user.friendsCount)} Following",
          padding: EdgeInsets.zero,
          onTap: () => _showInScreen(FollowingFollowerType.following),
        ),
        HarpyButton.flat(
          text: "${prettyPrintNumber(user.followersCount)} Followers",
          padding: EdgeInsets.zero,
          onTap: () => _showInScreen(FollowingFollowerType.followers),
        ),
      ],
    );
  }
}

class TweetDivider extends StatelessWidget {
  const TweetDivider();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Divider(
      height: 0,
      color: brightness == Brightness.dark
          ? const Color(0x55FFFFFF)
          : const Color(0x35000000),
    );
  }
}

/// Builds space that is occupied by a banner ad in the free version of Harpy.
///
/// The banner ad act as an overlay that is anchored to the bottom of the
/// screen. The [BannerAdSpace] prevents the app from occupying the space
/// below the banner.
class BannerAdSpace extends StatefulWidget {
  @override
  _BannerAdSpaceState createState() => _BannerAdSpaceState();
}

class _BannerAdSpaceState extends State<BannerAdSpace> {
  double _height = 0;

  void _listener(MobileAdEvent event) {
    if (event == MobileAdEvent.loaded) {
      setState(() {
        _height = bannerAd.size.height.toDouble();
      });
    }

    // other events such as failedToLoad or closed dont imply that no banner
    // is showing anymore, therefore we can't set the height to 0 again after
    // the banner loaded once
  }

  @override
  void initState() {
    super.initState();

    bannerAd.listener = _listener;
  }

  @override
  Widget build(BuildContext context) {
    final harpyTheme = HarpyTheme.of(context);

    return AnimatedContainer(
      height: _height,
      color: harpyTheme.backgroundColors.last,
      duration: const Duration(milliseconds: 300),
    );
  }
}
