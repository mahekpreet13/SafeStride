import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_stride/bloc/navigation_bloc.dart';
import 'package:safe_stride/bloc/navigation_event.dart';
import 'package:safe_stride/bloc/navigation_state.dart';

/// Widget that provides an address input field with integrated route calculation.
/// Includes a text field for destination entry and a "Go" button to trigger routing.
/// Automatically updates suggestions as the user types in the address field.
class AddressInputRow extends StatelessWidget {
  /// Controller for the destination address text field.
  final TextEditingController addressController;

  const AddressInputRow({super.key, required this.addressController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Destination address',
                  border: OutlineInputBorder(),
                ),
                onChanged: (input) => context.read<NavigationBloc>().add(
                  UpdateSuggestions(input),
                ),
                onSubmitted: (_) {
                  context.read<NavigationBloc>().add(
                    SearchAddress(addressController.text),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.routeLoading
                  ? null
                  : () {
                      context.read<NavigationBloc>().add(
                        SearchAddress(addressController.text),
                      );
                    },
              child: state.routeLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Route'),
            ),
          ],
        );
      },
    );
  }
}
