import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/physics.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wfhmovement/global-analytics.dart';
import 'package:wfhmovement/models/form_model.dart';
import 'package:wfhmovement/models/onboarding_model.dart';
import 'package:wfhmovement/models/user_model.dart';
import 'package:wfhmovement/pages/home.dart';
import 'package:wfhmovement/pages/onboarding/introduction.dart';
import 'package:wfhmovement/models/recoil.dart';
import 'package:wfhmovement/pages/sync-data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:wfhmovement/api.dart' as api;
import 'package:image/image.dart' as img;
import 'package:wfhmovement/widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  FirebaseAnalytics analytics = FirebaseAnalytics();
  globalAnalytics.init(analytics);

  runApp(App(analytics));
}

class App extends StatelessWidget {
  final FirebaseAnalytics analytics;

  App(this.analytics);
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => StateStore(),
      child: BetterFeedback(
        backgroundColor: Colors.grey,
        drawColors: [Colors.red, Colors.green, Colors.blue, Colors.yellow],
        child: RefreshConfiguration(
          headerBuilder: () => WaterDropHeader(),
          headerTriggerDistance: 80.0,
          springDescription: SpringDescription(
            stiffness: 170,
            damping: 16,
            mass: 1.9,
          ),
          maxOverScrollExtent: 100,
          maxUnderScrollExtent: 0,
          enableScrollWhenRefreshCompleted: true,
          enableLoadingWhenFailed: true,
          enableBallisticLoad: true,
          child: MaterialApp(
            title: 'Work from home movement',
            theme: ThemeData(
              fontFamily: 'Poppins',
              primarySwatch: Colors.amber,
            ),
            debugShowCheckedModeBanner: false,
            home: ScreenSelector(),
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: analytics),
            ],
          ),
        ),
        onFeedback: (
          BuildContext context,
          String feedbackText, // the feedback from the user
          Uint8List feedbackScreenshot, // raw png encoded image data
        ) async {
          BuildContext dialogContext;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              dialogContext = context;
              return Dialog(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Sending feedback'),
                    ],
                  ),
                ),
              );
            },
          );
          await api.feedback(feedbackText, feedbackScreenshot);
          Navigator.pop(dialogContext);
          BetterFeedback.of(context).hide();
          feedbackText = '';
        },
      ),
    );
  }
}

class ScreenSelector extends HookWidget {
  @override
  Widget build(BuildContext context) {
    OnboardingModel onboarding = useModel(onboardingAtom);
    FormModel form = useModel(formAtom);
    User user = useModel(userAtom);
    var init = useAction(initAction);
    useEffect(() {
      init();
      return;
    }, []);

    if (!user.inited) {
      return MainScaffold(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if ((user.id == null || !onboarding.done) && !onboarding.uploading) {
      return Introduction();
    }
    if (onboarding.uploading || !user.gaveEstimate || !form.uploaded) {
      return SyncData();
    }
    return Home();
  }
}
