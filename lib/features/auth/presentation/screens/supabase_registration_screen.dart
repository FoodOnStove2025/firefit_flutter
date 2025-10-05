import 'package:firefit/features/auth/providers/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final registrationFormGroupProvider = StateProvider<FormGroup>((ref) {
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
      validators: [
        Validators.required,
        Validators.minLength(8),
        Validators.pattern(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$'),
      ],
    ),
    'confirmPassword': FormControl<String>(
      value: '',
      validators: [Validators.required],
    ),
    'stationCode': FormControl<String>(
      value: '',
      validators: [Validators.required],
    ),
  }, validators: [
    Validators.mustMatch('password', 'confirmPassword'),
  ]);
});

class SupabaseRegistrationScreen extends HookConsumerWidget {
  const SupabaseRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formGroup = ref.watch(registrationFormGroupProvider);
    final authNotifier = ref.watch(userNotifierProvider.notifier);
    final authState = ref.watch(userNotifierProvider);

    return authState.when(
      data: (state) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: ReactiveForm(
                formGroup: formGroup,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.15,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 100,
                              child: Image.asset(
                                'assets/images/fots-logo-color.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ReactiveTextField<String>(
                              formControlName: 'firstName',
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              validationMessages: {
                                'required': (error) => 'First name is required',
                              },
                            ),
                            const SizedBox(height: 16),
                            ReactiveTextField<String>(
                              formControlName: 'lastName',
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              validationMessages: {
                                'required': (error) => 'Last name is required',
                              },
                            ),
                            const SizedBox(height: 16),
                            ReactiveTextField<String>(
                              formControlName: 'email',
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              validationMessages: {
                                'required': (error) => 'Email is required',
                                'email': (error) => 'Enter a valid email',
                              },
                            ),
                            const SizedBox(height: 16),
                            ReactiveTextField<String>(
                              formControlName: 'password',
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              obscureText: true,
                              validationMessages: {
                                'required': (error) => 'Password is required',
                                'minLength': (error) =>
                                    'Password must be at least 8 characters',
                                'pattern': (error) =>
                                    'Password must contain letters and numbers',
                              },
                            ),
                            const SizedBox(height: 16),
                            ReactiveTextField<String>(
                              formControlName: 'confirmPassword',
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              obscureText: true,
                              validationMessages: {
                                'required': (error) =>
                                    'Please confirm your password',
                                'mustMatch': (error) => 'Passwords do not match',
                              },
                            ),
                            const SizedBox(height: 16),
                            ReactiveTextField<String>(
                              formControlName: 'stationCode',
                              decoration: InputDecoration(
                                labelText: 'Station Code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              validationMessages: {
                                'required': (error) => 'Station code is required',
                              },
                              onChanged: (control) async {
                                final code = control.value;
                                if (code != null && code.isNotEmpty) {
                                  await authNotifier.validateStationCode(code);
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            ReactiveFormConsumer(
                              builder: (context, form, child) {
                                return ShadButton(
                                  onPressed: form.valid && !state.isLoading
                                      ? () async {
                                          final firstName =
                                              form.control('firstName').value
                                                  as String;
                                          final lastName =
                                              form.control('lastName').value
                                                  as String;
                                          final email =
                                              form.control('email').value
                                                  as String;
                                          final password =
                                              form.control('password').value
                                                  as String;
                                          final stationCode =
                                              form.control('stationCode').value
                                                  as String;

                                          // First validate the station code
                                          final stationId = await authNotifier
                                              .validateStationCode(stationCode);

                                          if (stationId != null) {
                                            final result =
                                                await authNotifier.register(
                                              email: email,
                                              password: password,
                                              handle: email.split('@')[0],
                                              firstName: firstName,
                                              lastName: lastName,
                                            );

                                            if (result.isLoggedIn && context.mounted) {
                                              context.go('/home');
                                            }
                                          }
                                        }
                                      : null,
                                  child: state.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Sign Up'),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? '),
                                TextButton(
                                  onPressed: () {
                                    context.go('/login');
                                  },
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  state.error!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}