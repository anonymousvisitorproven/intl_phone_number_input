import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/utils/util.dart';

/// [Item]
class Item extends StatelessWidget {
  final Country? country;
  final bool showFlag;
  final bool useEmoji;
  final TextStyle? textStyle;
  final bool withCountryNames;
  final double? leadingPadding;
  final bool trailingSpace;

  const Item({
    required this.showFlag,
    required this.useEmoji,
    this.country,
    this.textStyle,
    this.withCountryNames = false,
    this.leadingPadding = 12,
    this.trailingSpace = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String dialCode = (country?.dialCode ?? '');

    if (trailingSpace) {
      dialCode = dialCode.padRight(5, "   ");
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(width: leadingPadding),
        _Flag(
          country: country,
          showFlag: showFlag,
          useEmoji: useEmoji,
        ),
        SizedBox(width: 12.0),
        Text(
          '$dialCode',
          textDirection: TextDirection.ltr,
          style: textStyle,
        ),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  final Country? country;
  final bool showFlag;
  final bool useEmoji;

  const _Flag({
    required this.showFlag,
    required this.useEmoji,
    this.country,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localCountry = country;

    if (localCountry == null) {
      if (showFlag) {
        return Icon(
          Icons.language_rounded,
          size: 32,
        );
      }

      return SizedBox.shrink();
    }

    return showFlag
        ? useEmoji
            ? Text(
                Utils.generateFlagEmojiUnicode(localCountry.alpha2Code ?? ''),
                style: Theme.of(context).textTheme.headlineSmall,
              )
            : Image.asset(
                localCountry.flagUri,
                width: 32.0,
                package: 'intl_phone_number_input',
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox.shrink();
                },
              )
        : SizedBox.shrink();
  }
}
