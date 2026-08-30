import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';

/// App-bar action that lets admin-capable users toggle client vs admin view.
class PortalSwitchAction extends StatelessWidget {
  const PortalSwitchAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated || !state.canSwitchPortal) {
          return const SizedBox.shrink();
        }
        final switchToClient = state.role.isAdmin;
        return IconButton(
          icon: Icon(
            switchToClient
                ? Icons.person_outline
                : Icons.admin_panel_settings_outlined,
          ),
          tooltip: switchToClient
              ? 'Switch to client view'
              : 'Switch to admin view',
          onPressed: () => context.read<AuthCubit>().togglePortal(),
        );
      },
    );
  }
}
