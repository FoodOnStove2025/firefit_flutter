import 'package:firefit/features/auth/providers/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

final simpleRegistrationFormGroupProvider = StateProvider<FormGroup>((ref) {
  return FormGroup({
    'firstName': FormControl<String>(
      value: '',
      validators: [Validators.required],
    ),
    'lastName': FormControl<String>(
      value: '',
      validators: [Validators.required],
    ),
    'email': FormControl<String>(
      value: '',
      validators: [Validators.required, Validators.email],
    ),
    'password': FormControl<String>(
      value: '',
      validators: [Validators.required, Validators.minLength(8)],
    ),
    'stationCode': FormControl<String>(
      value: '',
      validators: [Validators.required],
    ),
  });
});

class SimpleSupabaseRegistrationScreen extends HookConsumerWidget {
  const SimpleSupabaseRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formGroup = ref.watch(simpleRegistrationFormGroupProvider);
    final authNotifier = ref.watch(userNotifierProvider.notifier);
    final authState = ref.watch(userNotifierProvider);

    return authState.when(
      data: (state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Supabase Registration')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ReactiveForm(
              formGroup: formGroup,
              child: Column(
                children: [
                  ReactiveTextField<String>(
                    formControlName: 'firstName',
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField<String>(
                    formControlName: 'lastName',
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField<String>(
                    formControlName: 'email',
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField<String>(
                    formControlName: 'password',
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField<String>(
                    formControlName: 'stationCode',
                    decoration: const InputDecoration(labelText: 'Station Code'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : () async {
                      if (formGroup.valid) {
                        final values = formGroup.value;
                        
                        // Test station validation (simplified)
                        final stationId = await authNotifier.validateStationCode(
                          values['stationCode'] as String
                        );
                        
                        if (stationId != null) {
                          final result = await authNotifier.register(
                            email: values['email'] as String,
                            password: values['password'] as String,
                            firstName: values['firstName'] as String?,
                            lastName: values['lastName'] as String?,
                            handle: '', // Not needed for Supabase
                          );
                          
                          if (result.error == null && result.user != null) {
                            // Registration successful
                            print('Registration successful! User: ${result.user!.user.email}');
                            print('Please check your email to verify your account before logging in.');
                            context.go('/login');
                          } else {
                            // Show error in debug console for now
                            print('Registration error: ${result.error ?? 'Unknown error'}');
                          }
                        } else {
                          print('Invalid station code: ENGINE13');
                        }
                      }
                    },
                    child: state.isLoading 
                      ? const CircularProgressIndicator() 
                      : const Text('Register'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}