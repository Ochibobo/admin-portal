import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class AppDropdownButton<T> extends StatelessWidget {
  const AppDropdownButton({
    Key key,
    @required this.value,
    @required this.onChanged,
    @required this.items,
    this.selectedItemBuilder,
    this.labelText,
    this.showBlank,
    this.blankValue = '',
    this.enabled = true,
  }) : super(key: key);

  final String labelText;
  final dynamic value;
  final Function(dynamic) onChanged;
  final List<DropdownMenuItem<T>> items;
  final bool showBlank;
  final bool enabled;
  final dynamic blankValue;
  final DropdownButtonBuilder selectedItemBuilder;

  @override
  Widget build(BuildContext context) {
    final state = StoreProvider.of<AppState>(context).state;
    final _showBlank = showBlank ?? state.settingsUIState.isFiltered;

    dynamic checkedValue = value;
    final values = items.toList().map((option) => option.value).toList();
    if (!values.contains(value)) {
      checkedValue = blankValue;
    }
    final bool isEmpty = checkedValue == null || checkedValue == '';

    Widget dropDownButton = DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: checkedValue,
        isExpanded: true,
        isDense: labelText != null,
        onChanged: enabled ? onChanged : null,
        selectedItemBuilder: selectedItemBuilder,
        items: [
          if (_showBlank || isEmpty)
            DropdownMenuItem<T>(
              value: blankValue,
              child: SizedBox(),
            ),
          ...items
        ],
      ),
    );

    if (labelText != null) {
      dropDownButton = InputDecorator(
          decoration: InputDecoration(
            labelText: labelText,
          ),
          isEmpty: isEmpty,
          child: dropDownButton);
    }

    return dropDownButton;
  }
}
