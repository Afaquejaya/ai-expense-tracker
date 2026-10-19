import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const ExpenseTrackerScreen(),
    );
  }
}

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _extractedExpenses = [];
  String _errorMessage = "";

  // CHANGE THIS IP: Use "10.0.2.2" for Android Emulator, "localhost" for iOS Simulator, or your system IP for real device
  // final String _backendUrl = "http://10.0.2.2:8000/process-expense";
  final String _backendUrl = "http://your WiFi IPv4:8000/process-expense";

  Future<void> sendTextToAI() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true; // Triggering Shimmer/Loader
      _errorMessage = "";
      _extractedExpenses = [];
    });

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": _controller.text}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          setState(() {
            _extractedExpenses = jsonResponse['data'];
            _isLoading = false;
          });
        } else if (jsonResponse['action'] == 'save_local') {
          // Handled by on_chain_error hook
          setState(() {
            _errorMessage = "Hook Error: ${jsonResponse['message']}\n[Action Taken: Saved to Local Database (Offline)]";
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to connect to backend AI pipeline.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Hook Expense Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Type like: 'Yaar aaj dosto ke sath Dubai Mall mein 120 AED ka dinner kiya aur 15 AED taxi mein kharch hue.'",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : sendTextToAI,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Process via AI Hooks"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 24),

            // --- THE MOBILE UI STATE HANDLING ---
            Expanded(
              child: _isLoading
                  ? _buildShimmerPlaceholder() // Shimmer activated by on_llm_start
                  : _errorMessage.isNotEmpty
                  ? _buildErrorUI() // Error handled by on_chain_error
                  : _buildExpenseList(), // Strict JSON structured via on_llm_end
            )
          ],
        ),
      ),
    );
  }

  // Hook 1 UI: Simulated Shimmer Effect
  Widget _buildShimmerPlaceholder() {
    return ListView.builder(
      itemCount: 2,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.black12),
          title: Container(height: 15, color: Colors.black12),
          subtitle: Container(height: 10, color: Colors.black12, margin: const EdgeInsets.only(top: 5)),
        ),
      ),
    );
  }

  // Hook 3 UI: Parsing the perfect Structured JSON Output
  Widget _buildExpenseList() {
    if (_extractedExpenses.isEmpty) {
      return const Center(child: Text("No expenses added yet. Enter text above."));
    }
    return ListView.builder(
      itemCount: _extractedExpenses.length,
      itemBuilder: (context, index) {
        final item = _extractedExpenses[index];
        final isFood = item['category'] == 'Food';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(
              isFood ? Icons.fastfood : Icons.directions_car,
              color: isFood ? Colors.green : Colors.blue,
            ),
            title: Text(item['item'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Category: ${item['category']}"),
            trailing: Text(
              "${item['amount']} ${item['currency']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  // Hook 4 UI: Error/Offline Fallback state
  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}