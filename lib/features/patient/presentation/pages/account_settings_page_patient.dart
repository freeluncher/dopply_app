import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/account_view_model_patient.dart';

final accountViewModelPatientProvider = ChangeNotifierProvider(
  (ref) => AccountViewModelPatient(),
);

class AccountSettingsPagePatient extends ConsumerWidget {
  const AccountSettingsPagePatient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(accountViewModelPatientProvider);
    final emailController = TextEditingController();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Akun Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Ganti Email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(hintText: 'Email baru'),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      vm.isLoading
                          ? null
                          : () => ref
                              .read(accountViewModelPatientProvider)
                              .changeEmail(emailController.text),
                  child: const Text('Ganti Email'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Ganti Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(hintText: 'Password lama'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(hintText: 'Password baru'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed:
                  vm.isLoading
                      ? null
                      : () => ref
                          .read(accountViewModelPatientProvider)
                          .changePassword(
                            oldPasswordController.text,
                            newPasswordController.text,
                          ),
              child: const Text('Ganti Password'),
            ),
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  vm.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (vm.success != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  vm.success!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
