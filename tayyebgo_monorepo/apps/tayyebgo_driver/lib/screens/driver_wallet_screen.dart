import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});
  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  final _amountCtrl = TextEditingController();
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    final user = AuthProvider.instance?.user;
    if (user != null) {
      context.read<DriverWalletProvider>().loadWallet(user.id);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;

    return AppScaffold(
      title: 'Wallet',
      body: walletProv.isLoading
          ? const ShimmerLoading(itemCount: 3)
          : wallet == null
              ? const Center(child: Text('No wallet data'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text('Available Balance', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('SYP ${wallet.availableBalance.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Level: ${wallet.level.displayName}',
                                style: TextStyle(color: _levelColor(wallet.level))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (wallet.availableBalance > 0) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _amountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount (SYP)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  suffixText: 'Max: ${wallet.availableBalance.toStringAsFixed(0)}',
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isRequesting
                                      ? null
                                      : () => _requestPayout(walletProv, wallet.availableBalance),
                                  icon: _isRequesting
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.send),
                                  label: Text(_isRequesting ? 'Requesting...' : 'Request Payout'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Color _levelColor(DriverLevel l) => switch (l) {
        DriverLevel.bronze => Colors.brown,
        DriverLevel.silver => Colors.grey,
        DriverLevel.gold => Colors.amber,
        DriverLevel.elite => Colors.cyan,
      };

  Future<void> _requestPayout(DriverWalletProvider prov, double maxAmount) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0 || amount > maxAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount')),
        );
      }
      return;
    }
    setState(() => _isRequesting = true);
    final uid = AuthProvider.instance?.user?.id;
    if (uid == null) return;
    final success = await prov.requestPayout(uid, amount);
    if (!mounted) return;
    setState(() => _isRequesting = false);
    if (mounted) {
      _amountCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Payout requested' : 'Request failed'),
      ));
    }
  }
}
