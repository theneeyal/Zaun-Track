import 'package:flutter/material.dart';

class DespatchScreen extends StatelessWidget {
  final String jobNumber;
  final List<Map<String, String>> scannedItems;
  final List<String> loadedItems;

  const DespatchScreen({super.key, 
    required this.jobNumber,
    required this.scannedItems,
    required this.loadedItems,
  });

  @override
  Widget build(BuildContext context) {
    // Check if all scanned items have been loaded
    bool allItemsLoaded = scannedItems.every((item) => loadedItems.contains(item['barcode']));
    return Scaffold(
      appBar: AppBar(
        title: Text('Despatch Check for Job $jobNumber'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Despatch Status:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Check if despatch is safe
            if (allItemsLoaded)
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.greenAccent,
                child: Text(
                  'ALL ITEMS LOADED. SAFE TO DESPATCH!',
                  style: TextStyle(fontSize: 18, color: Colors.green[900]),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.redAccent,
                child: Text(
                  'NOT SAFE TO DESPATCH: Some scanned items are not loaded!',
                  style: TextStyle(fontSize: 18, color: Colors.red[900]),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Scanned Items:',
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: scannedItems.length,
                itemBuilder: (context, index) {
                  bool isLoaded = loadedItems.contains(scannedItems[index]['barcode']);
                  return ListTile(
                    title: Text('Barcode: ${scannedItems[index]['barcode']}'),
                    subtitle: Text('Category: ${scannedItems[index]['category']}'),
                    trailing: isLoaded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
