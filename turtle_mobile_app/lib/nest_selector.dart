import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard_page.dart';
import 'onboarding_sceen.dart';

class NestSelectorPage extends StatefulWidget {
  const NestSelectorPage({super.key});

  @override
  State<NestSelectorPage> createState() => _NestSelectorPageState();
}

class _NestSelectorPageState extends State<NestSelectorPage> {
  bool isDarkMode = false;
  Map<String, dynamic>? selectedNest;

  List<Map<String, dynamic>> nests = [];

  String selectedFilter = "All Smart Shells";

  List<String> get filters {
    final names = nests.map((n) => n['name'] as String).toSet().toList();
    return ["All Smart Shells", ...names];
  }

  double get averageTemp =>
      nests.isEmpty ? 0.0 : nests.map((n) => n['temp'] as double).reduce((a, b) => a + b) / nests.length;

  double get averageHumidity =>
      nests.isEmpty ? 0.0 : nests.map((n) => n['humidity'] as double).reduce((a, b) => a + b) / nests.length;

  @override
  void initState() {
    super.initState();
    _listenToNests();
  }

  void _listenToNests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseDatabase.instance.ref('nests/$uid').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final List<Map<String, dynamic>> loadedNests = [];
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value);
          loadedNests.add({
            'id': key,
            'name': map['name'] ?? key,
            'location': map['location'] ?? '',
            'temp': (map['temperature'] ?? 0).toDouble(),
            'humidity': (map['humidity'] ?? 0).toDouble(),
            'gif': 'assets/turtle1.gif'
          });
        });

        setState(() {
          nests = loadedNests;
        });
      } else {
        setState(() {
          nests = [];
        });
      }
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _showPairingForm() {
    final pairingCodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter Pairing Code",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 12),
            TextField(
              controller: pairingCodeController,
              decoration: const InputDecoration(labelText: "Pairing Code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _submitPairingCode(pairingCodeController.text.trim()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.teal : Colors.tealAccent),
              child: const Text("Pair Nest"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPairingCode(String code) async {
    if (code.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseDatabase.instance.ref();
    final pairReqPath = 'pairRequests/$uid';

    await ref.child(pairReqPath).set({
      'pendingCode': code,
    });

    if (context.mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pairing request sent. Waiting for device...")),
    );
  }

  Widget _nestCard(Map<String, dynamic> nest) {
    final isSelected = selectedNest == nest;
    final tileColor = isSelected
        ? (isDarkMode ? Colors.teal.shade700 : Colors.tealAccent.shade100)
        : (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white);

    final textColor = isSelected || !isDarkMode ? Colors.black : Colors.white;
    final subTextColor =
        isSelected || !isDarkMode ? Colors.black54 : Colors.white70;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartHubTemperaturePage(
                temperature: nest['temp'],
                humidity: nest['humidity'],
                nestName: nest['name'],
                isDarkMode: isDarkMode,
              ),
            ),
          );
        } else {
          setState(() => selectedNest = nest);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.wifi, color: subTextColor),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: subTextColor, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(nest['gif'], fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(nest['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            Text(nest['location'], style: TextStyle(fontSize: 11, color: subTextColor)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${nest['temp']}°C",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                Icon(Icons.arrow_forward_ios, size: 13, color: subTextColor),
              ],
            ),
            if (isSelected) const SizedBox(height: 4),
            if (isSelected)
              Text("Tap again to open", style: TextStyle(fontSize: 10, color: subTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _showPairingForm,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, size: 36, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double currentTemp = selectedNest?['temp'] ?? averageTemp;
    final double currentHumidity = selectedNest?['humidity'] ?? averageHumidity;
    final filteredNests = selectedFilter == "All Smart Shells"
        ? nests
        : nests.where((n) => n['name'] == selectedFilter).toList();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Manage Home",
                            style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("Hey, Syusyi",
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87)),
                            const SizedBox(width: 6),
                            const Text("👋", style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.logout, color: isDarkMode ? Colors.white : Colors.black54),
                          onPressed: _logout,
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: (value) => setState(() => isDarkMode = value),
                          activeColor: const Color.fromARGB(255, 57, 204, 169),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.thermostat, color: Colors.teal, size: 24),
                              const SizedBox(width: 6),
                              Text("${currentTemp.toStringAsFixed(1)}°C",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.blue, size: 24),
                              const SizedBox(width: 6),
                              Text("${currentHumidity.toStringAsFixed(0)}%",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Smart Shell Status Overview",
                          style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[300] : Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final isSelected = filter == selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : (isDarkMode ? Colors.grey.shade800 : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(filter,
                              style: TextStyle(
                                  color: isSelected
                                      ? (isDarkMode ? Colors.black : Colors.white)
                                      : (isDarkMode ? Colors.white70 : Colors.black87),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Your Smart Shells", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75,
                    children: [
                      ...filteredNests.map((nest) => _nestCard(nest)).toList(),
                      _buildAddTile(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
