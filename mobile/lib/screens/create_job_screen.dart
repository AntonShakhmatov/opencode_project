import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedServiceType = 'plumbing';

  final List<String> _serviceTypes = [
    'plumbing',
    'electrical',
    'carpentry',
    'painting',
    'cleaning',
    'landscaping',
    'appliance_repair',
    'general_repair',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                ),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the issue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      const Text('Current Location'),
                      const Text(
                        'Location will be detected automatically',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Consumer<JobProvider>(
                builder: (context, jobProvider, _) {
                  return ElevatedButton(
                    onPressed: jobProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              // TODO: Get actual location
                              await jobProvider.createJob(
                                serviceType: _selectedServiceType,
                                description: _descriptionController.text,
                                latitude: 40.7128,
                                longitude: -74.0060,
                                token: context.read<AuthProvider>().token,
                              );
                              
                              if (jobProvider.error == null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Job created! Searching for handymen...'),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                    child: jobProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Request Service'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
