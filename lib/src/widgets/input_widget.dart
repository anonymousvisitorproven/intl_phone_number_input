import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/src/models/country_list.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/providers/country_provider.dart';
import 'package:intl_phone_number_input/src/utils/formatter/as_you_type_formatter.dart';
import 'package:intl_phone_number_input/src/utils/phone_number.dart';
import 'package:intl_phone_number_input/src/utils/phone_number/phone_number_util.dart';
import 'package:intl_phone_number_input/src/utils/selector_config.dart';
import 'package:intl_phone_number_input/src/utils/test/test_helper.dart';
import 'package:intl_phone_number_input/src/utils/util.dart';
import 'package:intl_phone_number_input/src/utils/widget_view.dart';
import 'package:intl_phone_number_input/src/widgets/selector_button.dart';

/// Enum for [SelectorButton] types.
///
/// Available type includes:
///   * [PhoneInputSelectorType.DROPDOWN]
///   * [PhoneInputSelectorType.BOTTOM_SHEET]
///   * [PhoneInputSelectorType.DIALOG]
enum PhoneInputSelectorType { DROPDOWN, BOTTOM_SHEET, DIALOG }

/// A [TextFormField] for [InternationalPhoneNumberInput].
///
/// [initialValue] accepts a [PhoneNumber] this is used to set initial values
/// for phone the input field and the selector button
///
/// [selectorButtonOnErrorPadding] is a double which is used to align the selector
/// button with the input field when an error occurs
///
/// [locale] accepts a country locale which will be used to translation, if the
/// translation exist
///
/// [countries] accepts list of string on Country isoCode, if specified filters
/// available countries to match the [countries] specified.
class InputValidation {
  final isValid;
  final isSetStateAllowed;

  InputValidation({
    required this.isValid,
    required this.isSetStateAllowed,
  });
}

class InternationalPhoneNumberInput extends StatefulWidget {
  final SelectorConfig selectorConfig;

  final ValueChanged<PhoneNumber>? onInputChanged;
  final ValueChanged<InputValidation>? onInputValidated;

  final VoidCallback? onSubmit;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final ValueChanged<PhoneNumber>? onSaved;

  final Key? fieldKey;
  final TextEditingController? textFieldController;
  final TextInputType keyboardType;
  final TextInputAction? keyboardAction;

  final PhoneNumber? initialValue;
  final String? hintText;
  final String? errorMessage;

  final double selectorButtonOnErrorPadding;

  /// Ignored if [setSelectorButtonAsPrefixIcon = true]
  final double spaceBetweenSelectorAndTextField;
  final int maxLength;

  final bool isEnabled;
  final bool formatInput;
  final bool autoFocus;
  final bool autoFocusSearch;
  final AutovalidateMode autoValidateMode;
  final bool ignoreBlank;
  final bool countrySelectorScrollControlled;

  final String? locale;

  final TextStyle? textStyle;
  final TextStyle? selectorTextStyle;
  final InputBorder? inputBorder;
  final InputDecoration? inputDecoration;
  final InputDecoration? searchBoxDecoration;
  final Color? cursorColor;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final EdgeInsets scrollPadding;

  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  final List<String>? countries;

  InternationalPhoneNumberInput({
    required this.onInputChanged,
    this.selectorConfig = const SelectorConfig(),
    this.onInputValidated,
    this.onSubmit,
    this.onFieldSubmitted,
    this.validator,
    this.onSaved,
    this.fieldKey,
    this.textFieldController,
    this.keyboardAction,
    this.keyboardType = TextInputType.phone,
    this.initialValue,
    this.hintText = 'Phone number',
    this.errorMessage = 'Invalid phone number',
    this.selectorButtonOnErrorPadding = 24,
    this.spaceBetweenSelectorAndTextField = 12,
    this.maxLength = 15,
    this.isEnabled = true,
    this.formatInput = true,
    this.autoFocus = false,
    this.autoFocusSearch = false,
    this.autoValidateMode = AutovalidateMode.disabled,
    this.ignoreBlank = false,
    this.countrySelectorScrollControlled = true,
    this.locale,
    this.textStyle,
    this.selectorTextStyle,
    this.inputBorder,
    this.inputDecoration,
    this.searchBoxDecoration,
    this.textAlign = TextAlign.start,
    this.textAlignVertical = TextAlignVertical.center,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.focusNode,
    this.cursorColor,
    this.autofillHints,
    this.countries,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InternationalPhoneNumberInput> {
  TextEditingController? _innerController;
  late final controller =
      widget.textFieldController ?? (_innerController = TextEditingController());
  double selectorButtonBottomPadding = 0;

  Country? country;
  List<Country> countries = [];
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    loadCountries();
    initialiseWidget(isSetStateNeeded: false);
  }

  void dispose() {
    _innerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InputWidgetView(
      state: this,
    );
  }

  @override
  void didUpdateWidget(InternationalPhoneNumberInput oldWidget) {
    if (oldWidget.initialValue != widget.initialValue) {
      if (country?.alpha2Code != widget.initialValue?.isoCode) {
        loadCountries();
      }
      initialiseWidget(isSetStateNeeded: false);
    }
    super.didUpdateWidget(oldWidget);
  }

  /// [initialiseWidget] sets initial values of the widget
  void initialiseWidget({required bool isSetStateNeeded}) {
    var localInitialValue = widget.initialValue;

    if (localInitialValue == null) {
      return;
    }

    var localIsoCode = localInitialValue.isoCode;
    var localPhoneNumber = localInitialValue.phoneNumber;

    if (localPhoneNumber == null ||
        localPhoneNumber.isEmpty ||
        localIsoCode == null ||
        localIsoCode.isEmpty) {
      return;
    }

    if (PhoneNumberUtil.isValidNumber(phoneNumber: localPhoneNumber, isoCode: localIsoCode)) {
      String phoneNumber = PhoneNumber.getParsableNumber(localInitialValue);

      controller.text =
          widget.formatInput ? phoneNumber : phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      phoneNumberControllerListener(isSetStateAllowed: isSetStateNeeded);
    }
  }

  /// loads countries from [Countries.countryList] and selected Country
  void loadCountries({Country? previouslySelectedCountry}) {
    List<Country> countries = CountryProvider.getCountriesData(countries: widget.countries);

    final country = previouslySelectedCountry ??
        Utils.getInitialSelectedCountry(
          countries,
          widget.initialValue?.isoCode ?? '',
        );

    countries = countries.toSet().toList();

    final CountryComparator? countryComparator = widget.selectorConfig.countryComparator;

    if (countryComparator != null) {
      countries.sort(countryComparator);
    }

    this.countries = countries;
    this.country = country;
  }

  /// Listener that validates changes from the widget, returns a bool to
  /// the `ValueCallback` [widget.onInputValidated]
  void phoneNumberControllerListener({required bool isSetStateAllowed}) {
    if (!mounted) {
      return;
    }

    String parsedPhoneNumberString = controller.text.replaceAll(RegExp(r'[^\d+]'), '');

    var localOnInputChanged = widget.onInputChanged;
    var phoneNumber = getParsedPhoneNumber(parsedPhoneNumberString, this.country?.alpha2Code);

    if (phoneNumber == null) {
      String phoneNumber = '${this.country?.dialCode}$parsedPhoneNumberString';

      if (localOnInputChanged != null) {
        localOnInputChanged(
          PhoneNumber(
            phoneNumber: phoneNumber,
            isoCode: this.country?.alpha2Code,
            dialCode: this.country?.dialCode,
          ),
        );
      }

      _isValid = false;
      widget.onInputValidated?.call(
        InputValidation(
          isValid: _isValid,
          isSetStateAllowed: isSetStateAllowed,
        ),
      );
    } else {
      if (localOnInputChanged != null) {
        localOnInputChanged(
          PhoneNumber(
            phoneNumber: phoneNumber,
            isoCode: this.country?.alpha2Code,
            dialCode: this.country?.dialCode,
          ),
        );
      }

      _isValid = true;
      widget.onInputValidated?.call(
        InputValidation(
          isValid: _isValid,
          isSetStateAllowed: isSetStateAllowed,
        ),
      );
    }
  }

  /// Returns a formatted String of [phoneNumber] with [isoCode], returns `null`
  /// if [phoneNumber] is not valid or if an [Exception] is caught.
  String? getParsedPhoneNumber(String phoneNumber, String? isoCode) {
    if (phoneNumber.isNotEmpty && isoCode != null) {
      try {
        final isValidPhoneNumber =
            PhoneNumberUtil.isValidNumber(phoneNumber: phoneNumber, isoCode: isoCode);

        if (isValidPhoneNumber) {
          return PhoneNumberUtil.normalizePhoneNumber(phoneNumber: phoneNumber, isoCode: isoCode);
        }
      } on Exception {
        return null;
      }
    }

    return null;
  }

  /// Creates or Select [InputDecoration]
  InputDecoration getInputDecoration(InputDecoration? decoration) {
    InputDecoration value = decoration ??
        InputDecoration(
          border: widget.inputBorder ?? UnderlineInputBorder(),
          hintText: widget.hintText,
        );

    return value.copyWith(
      prefixIcon: SelectorButton(
        country: country,
        countries: countries,
        onCountryChanged: onCountryChanged,
        selectorConfig: widget.selectorConfig,
        selectorTextStyle: widget.selectorTextStyle,
        searchBoxDecoration: widget.searchBoxDecoration,
        locale: locale,
        isEnabled: widget.isEnabled,
        autoFocusSearchField: widget.autoFocusSearch,
        isScrollControlled: widget.countrySelectorScrollControlled,
      ),
    );
  }

  /// Validate the phone number when a change occurs
  void onChanged(String value) {
    phoneNumberControllerListener(isSetStateAllowed: true);
  }

  /// Validate and returns a validation error when [FormState] validate is called.
  ///
  /// Also updates [selectorButtonBottomPadding]
  String? validator(String? value) {
    if (_isValid) {
      return null;
    }

    if ((value == null || value.isEmpty) && widget.ignoreBlank) {
      return null;
    } else {
      return widget.errorMessage;
    }
  }

  /// Changes Selector Button Country and Validate Change.
  void onCountryChanged(Country? country) {
    setState(() {
      this.country = country;
    });
    phoneNumberControllerListener(isSetStateAllowed: true);
  }

  void _phoneNumberSaved() {
    if (this.mounted) {
      String parsedPhoneNumberString = controller.text.replaceAll(RegExp(r'[^\d+]'), '');

      String phoneNumber = '${this.country?.dialCode ?? ''}' + parsedPhoneNumberString;

      widget.onSaved?.call(
        PhoneNumber(
          phoneNumber: phoneNumber,
          isoCode: country?.alpha2Code,
          dialCode: country?.dialCode,
        ),
      );
    }
  }

  /// Saved the phone number when form is saved
  void onSaved(String? value) {
    _phoneNumberSaved();
  }

  /// Corrects duplicate locale
  String? get locale {
    var localLocale = widget.locale;

    if (localLocale == null) return null;

    if (localLocale.toLowerCase() == 'nb' || localLocale.toLowerCase() == 'nn') {
      return 'no';
    }

    return localLocale;
  }
}

class _InputWidgetView extends WidgetView<InternationalPhoneNumberInput, _InputWidgetState> {
  final _InputWidgetState state;

  _InputWidgetView({Key? key, required this.state}) : super(key: key, state: state);

  @override
  Widget build(BuildContext context) {
    final countryCode = state.country?.alpha2Code ?? '';
    final dialCode = state.country?.dialCode ?? '';

    return TextFormField(
      key: widget.fieldKey ?? Key(TestHelper.TextInputKeyValue),
      textDirection: TextDirection.ltr,
      controller: state.controller,
      cursorColor: widget.cursorColor,
      focusNode: widget.focusNode,
      enabled: widget.isEnabled,
      autofocus: widget.autoFocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.keyboardAction,
      style: widget.textStyle,
      decoration: state.getInputDecoration(widget.inputDecoration),
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      onEditingComplete: widget.onSubmit,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: widget.autoValidateMode,
      autofillHints: widget.autofillHints,
      validator: widget.validator ?? state.validator,
      onSaved: state.onSaved,
      scrollPadding: widget.scrollPadding,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLength),
        widget.formatInput
            ? AsYouTypeFormatter(
                isoCode: countryCode,
                dialCode: dialCode,
                onInputFormatted: (TextEditingValue value) {
                  state.controller.value = value;
                },
              )
            : FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: state.onChanged,
    );
  }
}
