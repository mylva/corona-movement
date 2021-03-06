import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PageWidget extends HookWidget {
  final Widget child;
  final bool greyscale;
  final double scale;
  final Function onTap;

  PageWidget({
    Key key,
    @required this.child,
    @required this.onTap,
    this.greyscale = false,
    this.scale = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _colorFilter(),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
    );
  }

  Widget _colorFilter() {
    if (!greyscale) return _body();
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: _body(),
    );
  }

  Widget _body() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        double multiplier =
            MediaQuery.of(context).size.width / constraints.maxWidth;

        return OverflowBox(
          maxWidth: constraints.maxWidth * multiplier,
          maxHeight: constraints.maxHeight * multiplier,
          child: Transform.scale(
            scale: (1 / multiplier / 1.1) * scale,
            child: AbsorbPointer(
              child: child,
            ),
          ),
        );
      }),
    );
  }
}
