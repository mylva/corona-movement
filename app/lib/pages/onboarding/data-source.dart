import 'dart:io';

import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:wfhmovement/models/onboarding_model.dart';
import 'package:wfhmovement/models/recoil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wfhmovement/models/user_model.dart';
import 'package:wfhmovement/style.dart';
import 'package:wfhmovement/widgets/button.dart';
import 'package:wfhmovement/widgets/garmin-login.dart';
import 'package:wfhmovement/widgets/main_scaffold.dart';

class DataSource extends HookWidget {
  @override
  Widget build(BuildContext context) {
    OnboardingModel onboarding = useModel(onboardingAtom);
    var getAvailableSteps = useAction(getAvailableStepsAction);

    useEffect(() {
      if (onboarding.authorized) {
        getAvailableSteps();
      }
      return;
    }, [onboarding.authorized]);

    return MainScaffold(
      appBar: AppWidgets.appBar(context, onboarding.dataSource, false),
      child: _body(context, onboarding),
    );
  }

  Widget _body(BuildContext context, OnboardingModel onboarding) {
    var consent = useState(false);
    var getHealthAuthorization = useAction(getHealthAuthorizationAction);
    var register = useAction(registerAction);
    var uploadSteps = useAction(uploadStepsAction);

    return Center(
      child: Container(
        child: ListView(
          padding: EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 50),
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(15),
              child: SvgPicture.asset(
                'assets/svg/access.svg',
                height: 100,
              ),
            ),
            Text(
              'This app is part of an exploratory research project at the University of Gothenburg investigating the impact of the pandemic on our physical movement. For this purpose, we will collect and store the following data:',
              style: TextStyle(fontSize: 12),
            ),
            _dataInformation(context, onboarding.dataSource),
            Text(
              'Any data stored will be removed upon opting out of the study by deleting your account.',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 20),
            if (onboarding.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Failed with Error: ${onboarding.error}',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            _widgetForUserData(context, onboarding, getHealthAuthorization,
                register, consent, uploadSteps),
          ],
        ),
      ),
    );
  }

  Widget _widgetForUserData(BuildContext context, OnboardingModel onboarding,
      getHealthAuthorization, register, consent, uploadSteps) {
    if (onboarding.fetching) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            if (onboarding.loadingMessage != null)
              Text(onboarding.loadingMessage),
            if (onboarding.displayDateWhileLoading != null)
              Text(
                  'So far we\'ve found data until ${onboarding.displayDateWhileLoading.toString().substring(0, 10)}'),
          ],
        ),
      );
    }
    if (!onboarding.authorized) {
      return _getAccess(context, onboarding, getHealthAuthorization);
    }
    if (onboarding.availableData.length > 500 ||
        (onboarding.dataSource == 'Garmin' &&
            onboarding.initialDataDate != null)) {
      return _hasData(context, onboarding, register, consent, uploadSteps);
    }
    if (onboarding.availableData.length <= 500) {
      return _noData(context, onboarding, getHealthAuthorization);
    }
    return null;
  }

  Widget _dataInformation(BuildContext context, String dataSource) {
    final List<String> entries = [
      'Step data',
      'Demographic data',
      'App interactions'
    ];
    final List<String> descriptions = [
      'Collected from $dataSource.\n\n- Historical data of number of steps taken with timestamps\n- Date selected for working from home. ( for comparisons before/after )',
      'The following points are collected by filling out the form in the next step:\n\n- Gender\n- Age range\n- Education\n- Profession\n- Company/organisation',
      'Automatically sent via app usage.\n\n- App open/close\n- Navigating through views\n- Sync steps button pressed\n- Change work from home date\n- Day selection in Before & after\n- Using share feature'
    ];

    return Container(
      height: 140,
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int i) {
          return GestureDetector(
            onTap: () => AppWidgets.showAlert(
              context,
              entries[i],
              descriptions[i],
            ),
            child: Container(
              height: 35,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '- ${entries[i]}',
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.info_outline,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getAccess(BuildContext context, OnboardingModel onboarding,
      Function getHealthAuthorization) {
    return Column(
      children: [
        Text(
          'To proceeed you must grant access for us to retrieve data from ${onboarding.dataSource}.',
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 25),
        if (onboarding.dataSource == 'Garmin') GarminLogin(),
        StyledButton(
          icon: Icons.check,
          title: 'Give access',
          onPressed: () async {
            if (onboarding.dataSource == 'Apple health') {
              if (Platform.operatingSystem == 'android') {
                return AppWidgets.showAlert(
                  context,
                  'Apple health',
                  'Apple health is not available on an Android device.',
                );
              }
              AppWidgets.showConfirmDialog(context, 'Apple health',
                  'You will now see a dialog for allowing access to Apple health\n\nTo give us access to your steps make sure check the box for steps before pressing allow.',
                  () {
                getHealthAuthorization();
              });
            } else {
              getHealthAuthorization();
            }
          },
        ),
      ],
    );
  }

  // void _authorizeFitbit() async {
  //   final result = await FlutterWebAuth.authenticate(
  //     url:
  //         'https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=22BSFZ&redirect_uri=https%3A%2F%2Fapi.mycoronamovement.com%2Ffitbit%2Fcallback&scope=activity&expires_in=604800',
  //     callbackUrlScheme: 'wfhmovement',
  //   );
  // }

  Widget _hasData(BuildContext context, OnboardingModel onboarding,
      Function register, ValueNotifier consent, Function uploadSteps) {
    if (onboarding.date.isBefore(onboarding.initialDataDate)) {
      return _onlyDataAfterCompareDate(context, onboarding);
    }
    return Column(
      children: [
        Container(
          child: Text(
            'Found data from ${onboarding.initialDataDate.toString().substring(0, 10)}',
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: consent.value,
              onChanged: (value) {
                consent.value = value;
              },
            ),
            Container(
              child: Text(
                'I agree to share my data with you.',
                maxLines: 2,
              ),
            )
          ],
        ),
        SizedBox(height: 20),
        Opacity(
          opacity: consent.value ? 1 : 0.5,
          child: StyledButton(
            icon: Icons.directions_run,
            title: 'Get started!',
            onPressed: () async {
              if (!consent.value) return;
              await register();
              uploadSteps();
              while (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _onlyDataAfterCompareDate(
      BuildContext context, OnboardingModel onboarding) {
    return Column(
      children: [
        Container(
          child: Text(
            'Found steps until ${onboarding.initialDataDate.toString().substring(0, 10)}',
          ),
        ),
        SizedBox(height: 20),
        Text(
          'You don\'t have any steps from before the date you selected, so we can\'t create a comparison for you. If you want to explore the app anyway, you can go back and pick the option "I don\'t have any steps saved."',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 25),
        StyledButton(
          icon: Icons.arrow_back,
          title: 'Go back',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _noData(BuildContext context, OnboardingModel onboarding,
      Function getHealthAuthorization) {
    String description =
        'You don\'t have any saved steps from ${onboarding.dataSource} or failed to give this app access to your health data. Try again after reviewing access to health data in your phone settings or go back and select another data source or proceed without steps.';
    if (onboarding.availableData.length > 0) {
      description =
          'You don\'t have enough steps saved to make any comparison, you need at least a couple of days before and after your set date for working from home. Go back and select another data source or proceed without steps.';
    }

    return Column(
      children: [
        Text(
          description,
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 25),
        StyledButton(
          icon: Icons.arrow_back,
          title: 'Go back',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        SizedBox(height: 25),
        if (onboarding.availableData.length == 0)
          StyledButton(
            icon: Icons.refresh,
            title: 'Try again',
            onPressed: () => getHealthAuthorization(),
          ),
      ],
    );
  }
}
