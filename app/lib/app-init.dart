import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:wfhmovement/app.dart';
import 'package:wfhmovement/widgets/main_scaffold.dart';

import 'models/recoil.dart';
import 'models/user_model.dart';

class LanguageSetter extends StatefulWidget {
  final User user;

  const LanguageSetter({Key key, this.user}) : super(key: key);

  @override
  _LanguageSetterState createState() => _LanguageSetterState();
}

class _LanguageSetterState extends State<LanguageSetter>
    with AfterLayoutMixin<LanguageSetter> {
  @override
  void afterFirstLayout(BuildContext context) async {
    String language = widget.user.languageOverride != null
        ? widget.user.languageOverride
        : Localizations.localeOf(context).languageCode;
    I18n.of(context).locale = Locale(language);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => App(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class UserInit extends HookWidget {
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
      return MainScaffold(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'),
        Locale('sv'),
      ],
      title: 'Work from home movement',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.amber,
      ),
      debugShowCheckedModeBanner: false,
      home: LanguageSetter(user: user),
    );
  }
}

class AppInit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'),
        Locale('sv'),
      ],
      title: 'Work from home movement',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.amber,
      ),
      debugShowCheckedModeBanner: false,
      home: UserInit(),
    );
  }
}
