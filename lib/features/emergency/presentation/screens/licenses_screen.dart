import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _licenses = [
    {
      'name': 'Flutter SDK & Engine',
      'type': 'BSD 3-Clause License',
      'desc': 'Google UI toolkit for crafting beautiful, natively compiled mobile applications.',
      'license': '''
Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Google Inc. nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.
''',
    },
    {
      'name': 'Google Maps Flutter',
      'type': 'BSD 3-Clause License',
      'desc': 'Flutter plugin for integrating native Google Maps views and satellite overlays.',
      'license': '''
Copyright 2017 The Chromium Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
''',
    },
    {
      'name': 'Riverpod State Manager',
      'type': 'MIT License',
      'desc': 'A reactive caching and state-management framework for Dart and Flutter.',
      'license': '''
MIT License

Copyright (c) 2020 Remi Rousselet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
''',
    },
    {
      'name': 'Firebase Core & Auth',
      'type': 'Apache 2.0 License',
      'desc': 'Flutter plugins connecting the application to Google Firebase backend core APIs.',
      'license': '''
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
''',
    },
    {
      'name': 'Flutter Animate',
      'type': 'MIT License',
      'desc': 'A library for adding beautiful, performance-optimized micro-animations.',
      'license': '''
MIT License

Copyright (c) 2022 gskinner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
''',
    },
    {
      'name': 'Shared Preferences',
      'type': 'BSD 3-Clause License',
      'desc': 'Plugin for caching user profile medical data locally on the device.',
      'license': '''
Copyright 2017 The Chromium Authors. All rights reserved.
Redistribution and use in source and binary forms, with or without modification...
''',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _licenses.where((l) {
      final name = l['name']!.toLowerCase();
      final type = l['type']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search packages...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Licenses List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No package license found matching your search.'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final lic = filtered[index];
                          return _buildLicenseCard(theme, lic);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseCard(ThemeData theme, Map<String, String> lic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        title: Text(
          lic['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lic['type']!,
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              lic['desc']!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              lic['license']!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
