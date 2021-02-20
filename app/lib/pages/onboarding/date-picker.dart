import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:wfhmovement/style.dart';
import 'package:wfhmovement/widgets/button.dart';

class Period {
  final DateTime from;
  final DateTime to;
  Period({this.from, this.to});

  String toString() {
    var ts =
        this.to == null ? 'pågående' : DateFormat('yyyy-MM-dd').format(this.to);
    var fs = DateFormat('yyyy-MM-dd').format(this.from);
    return '$fs - $ts';
  }
}

final specialDeletePeriod = Period();

class DatePicker extends HookWidget {
  Widget build(BuildContext context) {
    var periods = useState([Period(from: DateTime(2020, 3, 11))]);

    return Scaffold(
      appBar: AppWidgets.appBar(context: context, title: 'WFH Perioder'),
      body: _body(context, periods),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          var period = await showDialog(
            context: context,
            builder: (context) => AddPeriodDialog(
              from: DateTime(2020, 03, 11),
            ),
          );
          if (period != null) {
            periods.value = [...periods.value, period];
          }
        },
      ),
    );
  }

  final dayColor = Color.fromARGB(50, 0, 0, 0);

  Widget _body(BuildContext context, ValueNotifier<List<Period>> periods) {
    double width = MediaQuery.of(context).size.width;
    double dayWidth = width * 0.5 / 7;
    DateTime startDay = DateTime(2019, 12, 30);
    int numWeeks = (DateTime.now().difference(startDay).inDays / 7).ceil();

    return SingleChildScrollView(
      child: Stack(
        children: [
          Container(width: width, height: numWeeks * dayWidth),
          _months(context),
          Positioned(
            left: width * 0.13,
            child: _days(context),
          ),
          Positioned(
            left: width * 0.13,
            child: _periods(context, periods),
          ),
          _events(context),
        ],
      ),
    );
  }

  Widget _months(context) {
    double dayWidth = MediaQuery.of(context).size.width * 0.52 / 7;
    double width = MediaQuery.of(context).size.width * 0.13;
    DateTime startDay = DateTime(2019, 12, 30);
    int numWeeks = (DateTime.now().difference(startDay).inDays / 7).ceil();

    List<Widget> children = [];

    for (var i = 0; i < numWeeks; i++) {
      var weekday = startDay.add(Duration(days: i * 7));
      var d = int.parse(DateFormat('d').format(weekday));
      if (d <= 16 && d + 7 > 16) {
        children.add(
          Positioned(
            top: i * dayWidth,
            child: Container(
              width: width,
              height: dayWidth,
              child: Center(
                child: Text(
                  DateFormat('MMM').format(weekday),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        );
      }
      var year = DateFormat('yyyy').format(weekday);
      var yearNextWeek =
          DateFormat('yyyy').format(weekday.add(Duration(days: 7)));
      if (year != yearNextWeek) {
        children.add(
          Positioned(
            top: i * dayWidth,
            child: Container(
              width: width,
              height: dayWidth,
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: dayColor))),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  year,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        );
        children.add(
          Positioned(
            top: (i + 1) * dayWidth,
            child: Container(
              width: width,
              height: dayWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  yearNextWeek,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      width: width,
      height: dayWidth * numWeeks,
      child: Stack(
        children: children,
      ),
    );
  }

  Widget _days(context) {
    double width = MediaQuery.of(context).size.width * 0.52;
    DateTime startDay = DateTime(2019, 12, 30);
    double dayWidth = width / 7;
    int numWeeks = (DateTime.now().difference(startDay).inDays / 7).ceil();

    List<Widget> children = [];

    for (var i = 0; i < 7 * numWeeks; i++) {
      children.add(Positioned(
        left: (i % 7) * dayWidth,
        top: (i / 7).floor() * dayWidth,
        child: Container(
          width: dayWidth,
          height: dayWidth,
          decoration: BoxDecoration(
              border: _numBorder(startDay.add(Duration(days: i)), i % 7)),
          child: Center(
            child: Text(
                DateFormat('d').format(
                  startDay.add(Duration(days: i)),
                ),
                style: TextStyle(color: dayColor, fontSize: 12)),
          ),
        ),
      ));
    }

    return Container(
      width: width,
      height: dayWidth * numWeeks,
      child: Stack(
        children: children,
      ),
    );
  }

  BoxBorder _numBorder(DateTime day, int dow) {
    String month = DateFormat('M').format(day);
    String monthBelow = DateFormat('M').format(day.add(Duration(days: 7)));
    String monthRight = DateFormat('M').format(day.add(Duration(days: 1)));
    BorderSide bottom =
        month == monthBelow ? BorderSide.none : BorderSide(color: dayColor);
    BorderSide right = month == monthRight || dow == 6
        ? BorderSide.none
        : BorderSide(color: dayColor);
    return Border(bottom: bottom, right: right);
  }

  Widget _periods(context, ValueNotifier<List<Period>> periods) {
    double width = MediaQuery.of(context).size.width * 0.52;
    DateTime startDay = DateTime(2019, 12, 30);
    double dayWidth = width / 7;
    int numWeeks = (DateTime.now().difference(startDay).inDays / 7).ceil();

    List<Widget> children = [];

    for (Period period in periods.value) {
      var beginning = period.from.difference(startDay).inDays;
      var start = beginning;
      var end = (period.to ?? DateTime.now()).difference(startDay).inDays;

      var eow;
      do {
        var weekIndex = (start / 7).floor();
        eow = start + (6 - (start % 7));
        if (eow > end) eow = end;

        var radius = Radius.circular(dayWidth / 2);

        children.add(Positioned(
          left: (start % 7) * dayWidth,
          top: weekIndex * dayWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              var newPeriod = await showDialog(
                context: context,
                builder: (context) => EditPeriodDialog(
                  from: period.from,
                  to: period.to,
                ),
              );
              if (newPeriod == specialDeletePeriod) {
                periods.value = periods.value
                    .where((element) => element != period)
                    .toList();
              } else if (newPeriod != null) {
                periods.value = periods.value
                    .map<Period>((p) => p == period ? newPeriod : p)
                    .toList();
              }
            },
            child: Container(
              width: (eow - start + 1) * dayWidth,
              height: dayWidth,
              padding: EdgeInsets.only(top: dayWidth / 4, bottom: dayWidth / 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(102, 245, 195, 68),
                  borderRadius: BorderRadius.only(
                    topLeft: start == beginning ? radius : Radius.zero,
                    bottomLeft: start == beginning ? radius : Radius.zero,
                    topRight:
                        eow == end && period.to != null ? radius : Radius.zero,
                    bottomRight:
                        eow == end && period.to != null ? radius : Radius.zero,
                  ),
                ),
              ),
            ),
          ),
        ));
        start = eow + 1;
      } while (eow < end);
    }

    return Container(
      width: width,
      height: dayWidth * numWeeks,
      child: Stack(
        children: children,
      ),
    );
  }

  Widget _events(context) {
    double width = MediaQuery.of(context).size.width * 0.37;
    return Container(
      width: width,
    );
  }

  // Widget _body(BuildContext context, ValueNotifier<List<Period>> periods) {
  //   return ListView(
  //     children: periods.value
  //         .map<Widget>(
  //           (period) => ListTile(
  //             title: Text(period.toString()),
  //             trailing: IconButton(
  //               icon: Icon(Icons.delete),
  //               onPressed: () {
  //                 periods.value = periods.value
  //                     .where((element) => element != period)
  //                     .toList();
  //               },
  //             ),
  //             onTap: () async {
  //               var newPeriod = await showDialog(
  //                 context: context,
  //                 builder: (context) => EditPeriodDialog(
  //                   from: period.from,
  //                   to: period.to,
  //                 ),
  //               );
  //               if (newPeriod == specialDeletePeriod) {
  //                 periods.value = periods.value
  //                     .where((element) => element != period)
  //                     .toList();
  //               } else if (newPeriod != null) {
  //                 periods.value = periods.value
  //                     .map<Period>((p) => p == period ? newPeriod : p)
  //                     .toList();
  //               }
  //             },
  //           ),
  //         )
  //         .toList(),
  //   );
  // }
}

class AddPeriodDialog extends PeriodDialog {
  AddPeriodDialog({from, to})
      : super(
          from: from,
          to: to,
          title: 'Lägg till period',
          leftButtonText: 'Ångra',
          rightButtonText: 'Lägg till',
          leftButtonDanger: false,
        );
}

class EditPeriodDialog extends PeriodDialog {
  EditPeriodDialog({from, to})
      : super(
          from: from,
          to: to,
          title: 'Ändra period',
          leftButtonText: 'Ta bort',
          rightButtonText: 'Spara',
          leftButtonDanger: true,
        );
}

//
//  Make a AddPeriodDialog and a ChangePeriodDialog
//
//  make sure you get the value of the dialog to a button
//

class PeriodDialog extends HookWidget {
  final DateTime from;
  final DateTime to;
  final String title;
  final String leftButtonText;
  final String rightButtonText;
  final bool leftButtonDanger;

  PeriodDialog(
      {this.from,
      this.to,
      @required this.title,
      @required this.leftButtonText,
      @required this.rightButtonText,
      @required this.leftButtonDanger});

  Widget build(BuildContext context) {
    var dialogFrom = useState(from);
    var dialogTo = useState<DateTime>(to);

    return SimpleDialog(
      contentPadding: EdgeInsets.all(10),
      children: [
        _dialogTitle(title),
        SizedBox(height: 22),
        _dialogLabel('Från'),
        _dialogDate(context, dialogFrom.value, (date) {
          dialogFrom.value = date;
        }),
        SizedBox(height: 32),
        _dialogLabel('Till'),
        _dialogDate(context, dialogTo.value, (date) {
          dialogTo.value = date;
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StyledButton(
                onPressed: () {
                  Navigator.pop(
                      context, leftButtonDanger ? specialDeletePeriod : null);
                },
                title: leftButtonText,
                small: true,
                secondary: !leftButtonDanger,
                danger: leftButtonDanger,
              ),
              SizedBox(width: 20),
              StyledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    Period(from: dialogFrom.value, to: dialogTo.value),
                  );
                },
                title: rightButtonText,
                small: true,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _dialogTitle(text) {
    return Text(text, style: TextStyle(fontSize: 24));
  }

  Widget _dialogLabel(text) {
    return Text(text, style: TextStyle(fontSize: 12));
  }

  Widget _dialogDate(context, DateTime date, onChanged) {
    return GestureDetector(
      onTap: () async {
        var newDate = await showDatePicker(
            context: context,
            initialDate: date != null ? date : DateTime.now(),
            firstDate: DateTime(2020, 1, 1),
            lastDate: DateTime.now());
        if (newDate != null) {
          onChanged(newDate);
        }
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            border: Border.all(
          color: Colors.black,
          width: 1,
        )),
        child: Center(
          child: Text(date != null
              ? DateFormat('yyyy-MM-dd').format(date)
              : 'pågående'),
        ),
      ),
    );
  }
}
