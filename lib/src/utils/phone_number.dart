import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:equatable/equatable.dart';
import 'package:intl_phone_number_input/src/models/country_list.dart';
import 'package:intl_phone_number_input/src/utils/phone_number/phone_number_util.dart';

/// Type of phone numbers.
enum PhoneNumberType {
  FIXED_LINE, // : 0,
  MOBILE, //: 1,
  FIXED_LINE_OR_MOBILE, //: 2,
  TOLL_FREE, //: 3,
  PREMIUM_RATE, //: 4,
  SHARED_COST, //: 5,
  VOIP, //: 6,
  PERSONAL_NUMBER, //: 7,
  PAGER, //: 8,
  UAN, //: 9,
  VOICEMAIL, //: 10,
  UNKNOWN, //: -1
}

/// [PhoneNumber] contains detailed information about a phone number
class PhoneNumber extends Equatable {
  /// Either formatted or unformatted String of the phone number
  final String? phoneNumber;

  /// The Country [dialCode] of the phone number
  final String? dialCode;

  /// Country [isoCode] of the phone number
  final String? isoCode;

  @override
  List<Object?> get props => [phoneNumber, isoCode, dialCode];

  PhoneNumber({
    this.phoneNumber,
    this.dialCode,
    this.isoCode,
  });

  @override
  String toString() {
    return 'PhoneNumber(phoneNumber: $phoneNumber, dialCode: $dialCode, isoCode: $isoCode)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PhoneNumber &&
          runtimeType == other.runtimeType &&
          phoneNumber == other.phoneNumber &&
          dialCode == other.dialCode &&
          isoCode == other.isoCode;

  @override
  int get hashCode => super.hashCode ^ phoneNumber.hashCode ^ dialCode.hashCode ^ isoCode.hashCode;

  /// Returns [PhoneNumber] which contains region information about
  /// the [phoneNumber] and [isoCode] passed.
  static PhoneNumber getRegionInfoFromPhoneNumber(
    String phoneNumber, [
    String isoCode = '',
  ]) {
    RegionInfo regionInfo =
        PhoneNumberUtil.getRegionInfo(phoneNumber: phoneNumber, isoCode: isoCode);

    String? internationalPhoneNumber = PhoneNumberUtil.normalizePhoneNumber(
      phoneNumber: phoneNumber,
      isoCode: regionInfo.isoCode ?? isoCode,
    );

    return PhoneNumber(
      phoneNumber: internationalPhoneNumber,
      dialCode: regionInfo.regionPrefix,
      isoCode: regionInfo.isoCode,
    );
  }

  /// Accepts a [PhoneNumber] object and returns a formatted phone number String
  static String getParsableNumber(PhoneNumber phoneNumber) {
    if (phoneNumber.isoCode != null) {
      PhoneNumber number = getRegionInfoFromPhoneNumber(
        phoneNumber.phoneNumber!,
        phoneNumber.isoCode!,
      );
      String? formattedNumber = PhoneNumberUtil.formatAsYouType(
        phoneNumber: number.phoneNumber!,
        isoCode: number.isoCode!,
      );

      return formattedNumber!.replaceAll(
        RegExp('^([\\+]?${number.dialCode}[\\s]?)'),
        '',
      );
    } else {
      throw new Exception('ISO Code is "${phoneNumber.isoCode}"');
    }
  }

  /// Returns a String of [phoneNumber] without [dialCode]
  String parseNumber() {
    return this.phoneNumber!.replaceAll("${this.dialCode}", '');
  }

  /// For predefined phone number returns Country's [isoCode] from the dial code,
  /// Returns null if not found.
  static String? getISO2CodeByPrefix(String prefix) {
    if (prefix.isNotEmpty) {
      prefix = prefix.startsWith('+') ? prefix : '+$prefix';
      var country =
          Countries.countryList.firstWhereOrNull((country) => country['dial_code'] == prefix);
      if (country != null && country['alpha_2_code'] != null) {
        return country['alpha_2_code'];
      }
    }
    return null;
  }

  /// Returns [PhoneNumberType] which is the type of phone number
  /// Accepts [phoneNumber] and [isoCode] and r
  static Future<PhoneNumberType> getPhoneNumberType(String phoneNumber, String isoCode) async {
    PhoneNumberType type =
        await PhoneNumberUtil.getNumberType(phoneNumber: phoneNumber, isoCode: isoCode);

    return type;
  }
}
