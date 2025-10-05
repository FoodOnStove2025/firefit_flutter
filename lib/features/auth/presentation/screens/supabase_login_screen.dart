import 'package:firefit/features/auth/providers/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final loginFormGroupProvider = StateProvider<FormGroup>((ref) {
  return FormGroup({
    'email': FormControl<String>(
      value: '',
      validators: [Validators.required, Validators.email],
    ),
    'password': FormControl<String>(
      value: '',
      validators: [Validators.required],
    ),
  });
});

class SupabaseLoginScreen extends HookConsumerWidget {
  const SupabaseLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formGroup = ref.watch(loginFormGroupProvider);
    final authNotifier = ref.watch(userNotifierProvider.notifier);
    final authState = ref.watch(userNotifierProvider);

    return authState.when(
      data: (state) {
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
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
                              'Sign In',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
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
                              },
                            ),
                            const SizedBox(height: 24),
                            ReactiveFormConsumer(
                              builder: (context, form, child) {
                                return ShadButton(
                                  onPressed: form.valid && !state.isLoading
                                      ? () async {
                                          final email =
                                              form.control('email').value
                                                  as String;
                                          final password =
                                              form.control('password').value
                                                  as String;

                                          final result =
                                              await authNotifier.login(
                                            email: email,
                                            password: password,
                                          );

                                          result.fold(
                                            (failure) {
                                              // Login failed - error is shown in UI via state.error
                                            },
                                            (user) {
                                              context.go('/home');
                                            },
                                          );
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
                                      : const Text('Login'),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? "),
                                TextButton(
                                  onPressed: () {
                                    context.go('/register');
                                  },
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                context.push('/request-password-reset');
                              },
                              child: const Text('Forgot your password?'),
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