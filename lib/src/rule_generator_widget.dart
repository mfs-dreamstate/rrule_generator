import 'package:flutter/material.dart';
import 'package:rrule_generator/localizations/english.dart';
import 'package:rrule_generator/localizations/text_delegate.dart';
import 'package:rrule_generator/src/periods/period.dart';
import 'package:rrule_generator/src/pickers/interval.dart';
import 'package:rrule_generator/src/periods/yearly.dart';
import 'package:rrule_generator/src/periods/monthly.dart';
import 'package:rrule_generator/src/periods/weekly.dart';
import 'package:rrule_generator/src/periods/daily.dart';
import 'package:rrule_generator/src/pickers/helpers.dart';
import 'package:intl/intl.dart';

class RRuleGenerator extends StatelessWidget {
  final RRuleTextDelegate textDelegate;
  final Function(String newValue)? onChange;
  final String initialRRule;
  final DateTime? initialDate;

  final frequencyNotifier = ValueNotifier(0);
  final countTypeNotifier = ValueNotifier(0);
  final pickedDateNotifier = ValueNotifier(DateTime.now());
  final instancesController = TextEditingController(text: '1');
  final List<Period> periodWidgets = [];

  RRuleGenerator(
      {Key? key,
      this.textDelegate = const EnglishRRuleTextDelegate(),
      this.onChange,
      this.initialRRule = '',
      this.initialDate})
      : super(key: key) {
    periodWidgets.addAll([
      Yearly(textDelegate, valueChanged, initialRRule,
          initialDate ?? DateTime.now()),
      Monthly(textDelegate, valueChanged, initialRRule,
          initialDate ?? DateTime.now()),
      Weekly(textDelegate, valueChanged, initialRRule,
          initialDate ?? DateTime.now()),
      Daily(textDelegate, valueChanged, initialRRule,
          initialDate ?? DateTime.now())
    ]);

    handleInitialRRule();
  }

  void handleInitialRRule() {
    if (initialRRule.contains('MONTHLY')) {
      frequencyNotifier.value = 1;
    } else if (initialRRule.contains('WEEKLY')) {
      frequencyNotifier.value = 2;
    } else if (initialRRule.contains('DAILY')) {
      frequencyNotifier.value = 3;
    } else if (initialRRule == '') {
      frequencyNotifier.value = 4;
    }

    if (initialRRule.contains('COUNT')) {
      countTypeNotifier.value = 1;
      instancesController.text = initialRRule.substring(
          initialRRule.indexOf('COUNT=') + 6, initialRRule.length);
    } else if (initialRRule.contains('UNTIL')) {
      countTypeNotifier.value = 2;
      int dateIndex = initialRRule.indexOf('UNTIL=') + 6;
      int year = int.parse(initialRRule.substring(dateIndex, dateIndex + 4));
      int month =
          int.parse(initialRRule.substring(dateIndex + 4, dateIndex + 6));
      int day =
          int.parse(initialRRule.substring(dateIndex + 6, initialRRule.length));

      pickedDateNotifier.value = DateTime(year, month, day);
    }
  }

  void valueChanged() {
    Function(String newValue)? fun = onChange;
    if (fun != null) fun(getRRule());
  }

  String getRRule() {
    if (frequencyNotifier.value == 4) {
      return '';
    }

    if (countTypeNotifier.value == 0) {
      return 'RRULE:${periodWidgets[frequencyNotifier.value].getRRule()}';
    } else if (countTypeNotifier.value == 1) {
      return 'RRULE:${periodWidgets[frequencyNotifier.value].getRRule()};COUNT=${instancesController.text}';
    }
    DateTime pickedDate = pickedDateNotifier.value;

    String day =
        pickedDate.day > 9 ? '${pickedDate.day}' : '0${pickedDate.day}';
    String month =
        pickedDate.month > 9 ? '${pickedDate.month}' : '0${pickedDate.month}';

    return 'RRULE:${periodWidgets[frequencyNotifier.value].getRRule()};UNTIL=${pickedDate.year}$month$day';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.maxFinite,
        child: ValueListenableBuilder(
          valueListenable: frequencyNotifier,
          builder: (BuildContext context, int period, Widget? child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildContainer(
                child: buildElement(
                  title: textDelegate.repeat,
                  child: buildDropdown(
                    child: DropdownButton(
                      isExpanded: true,
                      value: period,
                      onChanged: (int? newPeriod) {
                        frequencyNotifier.value = newPeriod!;
                        valueChanged();
                      },
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(
                            textDelegate.periods[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (period != 4) ...[
                const Divider(),
                periodWidgets[period],
                const Divider(),
                buildContainer(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: buildElement(
                              title: 'End',
                              child: buildDropdown(
                                child: ValueListenableBuilder(
                                  valueListenable: countTypeNotifier,
                                  builder: (BuildContext context, int countType,
                                          Widget? child) =>
                                      DropdownButton(
                                    isExpanded: true,
                                    value: countType,
                                    onChanged: (int? newCountType) {
                                      countTypeNotifier.value = newCountType!;
                                      valueChanged();
                                    },
                                    items: [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Text(textDelegate.neverEnds),
                                      ),
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text(textDelegate.endsAfter),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text(textDelegate.endsOnDate),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: countTypeNotifier,
                            builder: (BuildContext context, int countType,
                                    Widget? child) =>
                                SizedBox(
                              width: countType == 0 ? 0 : 8,
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: countTypeNotifier,
                            builder: (BuildContext context, int countType,
                                Widget? child) {
                              switch (countType) {
                                case 1:
                                  return Expanded(
                                    child: buildElement(
                                      title: textDelegate.instances,
                                      child: IntervalPicker(
                                          instancesController, valueChanged),
                                    ),
                                  );
                                case 2:
                                  return Expanded(
                                    child: buildElement(
                                      title: textDelegate.date,
                                      child: ValueListenableBuilder(
                                        valueListenable: pickedDateNotifier,
                                        builder: (BuildContext context,
                                                DateTime pickedDate,
                                                Widget? child) =>
                                            OutlinedButton(
                                          onPressed: () async {
                                            DateTime? picked =
                                                await showDatePicker(
                                              context: context,
                                              initialDate: pickedDate,
                                              firstDate:
                                                  DateTime.utc(2020, 10, 24),
                                              lastDate: DateTime(2100),
                                            );

                                            if (picked != null &&
                                                picked != pickedDate) {
                                              pickedDateNotifier.value = picked;
                                              valueChanged();
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.black,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 24,
                                            ),
                                          ),
                                          child: SizedBox(
                                            width: double.maxFinite,
                                            child: Text(
                                              DateFormat.yMd(
                                                      Intl.getCurrentLocale())
                                                  .format(
                                                pickedDate,
                                              ),
                                              style: const TextStyle(
                                                  color: Colors.black),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                default:
                                  return Container();
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      );
}
