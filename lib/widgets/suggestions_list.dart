import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_stride/bloc/navigation_bloc.dart';
import 'package:safe_stride/bloc/navigation_event.dart';
import 'package:safe_stride/bloc/navigation_state.dart';

class SuggestionsList extends StatelessWidget {
  final TextEditingController addressController;
  const SuggestionsList({super.key, required this.addressController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        if (!state.showSuggestions || state.suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 180),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.suggestions.length,
            itemBuilder: (context, index) {
              final s = state.suggestions[index];
              return ListTile(
                title: Text(
                  s,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  addressController.text = s;
                  context.read<NavigationBloc>().add(SelectSuggestion(s));
                },
              );
            },
          ),
        );
      },
    );
  }
}
