import 'package:wfhmovement/i18n.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wfhmovement/models/recoil.dart';
import 'package:wfhmovement/models/user_model.dart';

import 'package:wfhmovement/style.dart';
import 'package:wfhmovement/widgets/day-select.dart';
import 'package:wfhmovement/widgets/main_scaffold.dart';
import 'package:wfhmovement/widgets/share.dart';
import 'package:wfhmovement/widgets/steps-chart.dart';
import 'package:wfhmovement/widgets/steps-difference.dart';

class DetailedSteps extends HookWidget {
  GlobalKey _globalKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    User user = useModel(userAtom);
    String shareSubject = user.id == 'all' ? 'people\'s'.i18n : 'my'.i18n;
    String shareText =
        'This is how how %s movement has changed after working from home.'
            .i18n
            .fill([shareSubject]);

    return MainScaffold(
      appBar: AppWidgets.appBar(context, 'Before & after'.i18n, true),
      child: ListView(
        padding: EdgeInsets.only(top: 15),
        children: [
          StepsDifference(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Hero(
              tag: 'steps-chart',
              child: StepsChart(),
              flightShuttleBuilder: AppWidgets.flightShuttleBuilder,
            ),
          ),
          AppWidgets.chartDescription(
            user.id == 'all'
                ? 'Above you can see how working from home has affected how people move throughout the day.'
                    .i18n
                : 'Above you can see how your activity has changed over a typical day before and after working from home.'
                    .i18n,
          ),
          DaySelect(),
          ShareButton(
            widgets: [
              StepsDifference(share: true),
              StepsChart(share: true),
            ],
            text: shareText +
                '\nTry yourself by downloading the app https://hci-gu.github.io/#/wfh-movement'
                    .i18n
                    .fill([shareSubject]),
            subject: shareText,
            screen: 'Before & after',
          ),
        ],
      ),
    );
  }
}
