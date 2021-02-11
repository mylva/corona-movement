import 'package:i18n_extension/i18n_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/physics.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uni_links/uni_links.dart';
import 'package:wfhmovement/models/form_model.dart';
import 'package:wfhmovement/models/onboarding_model.dart';
import 'package:wfhmovement/models/user_model.dart';
import 'package:wfhmovement/pages/home.dart';
import 'package:wfhmovement/pages/onboarding/introduction.dart';
import 'package:wfhmovement/models/recoil.dart';
import 'package:wfhmovement/pages/onboarding/sync-data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:wfhmovement/widgets/main_scaffold.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => StateStore(),
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
        child: InitUser(),
      ),
    );
  }
}

class InitUser extends HookWidget {
  @override
  Widget build(BuildContext context) {
    User user = useModel(userAtom);
    var init = useAction(initAction);
    useEffect(() {
      try {
        init();
      } catch (e) {}
      return;
    }, []);

    if (!user.inited) {
      return MaterialApp(
        theme: ThemeData(
          fontFamily: 'Poppins',
          primarySwatch: Colors.amber,
        ),
        debugShowCheckedModeBanner: false,
        home: MainScaffold(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    String language = user.languageOverride != null
        ? user.languageOverride
        : Localizations.localeOf(context).languageCode;

    return I18n(
      initialLocale: Locale(language),
      child: MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', 'GB'),
          Locale('sv', 'SE'),
        ],
        title: 'Work from home movement',
        theme: ThemeData(
          fontFamily: 'Poppins',
          primarySwatch: Colors.amber,
        ),
        debugShowCheckedModeBanner: false,
        home: ScreenSelector(),
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
    var joinGroup = useAction(joinGroupAction);

    useEffect(() {
      var handleUri = (Uri uri) {
        if (uri != null) {
          String code = uri.queryParameters['code'];
          user.setGroupCode(code);
          if (user.id != null && user.group == null) {
            joinGroup();
            user.setDeeplinkOpen(true);
          } else if (user.id == null) {
            user.setDeeplinkOpen(true);
          }
        }
      };

      var asyncFunc = () async {
        try {
          Uri initialUri = await getInitialUri();
          handleUri(initialUri);
        } catch (e) {
          print('Failed to get initial uri.');
          print(e);
        }
        getUriLinksStream().listen((Uri uri) {
          handleUri(uri);
        }, onError: (err) {
          print('uri stream err ${err}');
        });
      };

      asyncFunc();
      return;
    }, []);

    if ((user.id == null || !onboarding.done) && !onboarding.uploading) {
      return Introduction();
    }
    if (onboarding.uploading || !user.gaveEstimate || !form.uploaded) {
      return SyncData();
    }
    return Home();
  }
}
