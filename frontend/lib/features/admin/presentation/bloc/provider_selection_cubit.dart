import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_provider.dart';
import '../../domain/usecases/get_admin_providers.dart';

abstract class ProviderSelectionState {}

class ProviderSelectionInitial extends ProviderSelectionState {}

class ProviderSelectionLoading extends ProviderSelectionState {}

class ProviderSelectionLoaded extends ProviderSelectionState {
  final List<AdminProvider> providers;
  ProviderSelectionLoaded(this.providers);
}

class ProviderSelectionError extends ProviderSelectionState {
  final String message;
  ProviderSelectionError(this.message);
}

class ProviderSelectionCubit extends Cubit<ProviderSelectionState> {
  final GetAdminProviders getAdminProviders;
  final int adminId;

  ProviderSelectionCubit({
    required this.getAdminProviders,
    required this.adminId,
  }) : super(ProviderSelectionInitial());

  Future<void> loadProviders() async {
    emit(ProviderSelectionLoading());
    final result = await getAdminProviders(adminId);
    result.fold(
      (failure) => emit(ProviderSelectionError(failure.message)),
      (providers) => emit(ProviderSelectionLoaded(providers)),
    );
  }
}
