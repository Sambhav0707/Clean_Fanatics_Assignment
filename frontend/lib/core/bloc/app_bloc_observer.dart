import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);

    print(
      '[BLoC EVENT] '
      'Bloc: ${bloc.runtimeType}, '
      'Event: ${event.runtimeType}, '
      'Details: $event',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);

    print(
      '[BLoC TRANSITION] '
      'Bloc: ${bloc.runtimeType}, '
      'From: ${transition.currentState.runtimeType} '
      '→ To: ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print(
      '[BLoC ERROR] '
      'Bloc: ${bloc.runtimeType}, '
      'Error: $error',
    );

    super.onError(bloc, error, stackTrace);
  }
}
