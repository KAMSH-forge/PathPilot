import 'package:flutter/material.dart';

mixin StateSet<T extends StatefulWidget> on State<T> {
  static final Map<Type, State> _states = {};

  static T? of<T extends State>() => _states[T] as T?;

  @override
  void initState() {
    _states[runtimeType] = this;
    super.initState();
  }

  @override
  void dispose() {
    _states.remove(runtimeType);
    super.dispose();
  }
}