import 'package:flutter/material.dart';

class DestinationSearchBar extends StatelessWidget {
  final TextEditingController addressController;
  final bool routeLoading;
  final VoidCallback onSearchAndRoute;
  final Function(String) onUpdateSuggestions;
  final List<String> suggestions;
  final bool showSuggestions;
  final Function(String) onSelectSuggestion;

  const DestinationSearchBar({
    super.key,
    required this.addressController,
    required this.routeLoading,
    required this.onSearchAndRoute,
    required this.onUpdateSuggestions,
    required this.suggestions,
    required this.showSuggestions,
    required this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Destination address',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onUpdateSuggestions,
                  onSubmitted: (_) => onSearchAndRoute(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: routeLoading ? null : onSearchAndRoute,
                child: routeLoading
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
          ),
          if (showSuggestions)
            Container(
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
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  return ListTile(
                    title: Text(
                      s,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelectSuggestion(s),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
