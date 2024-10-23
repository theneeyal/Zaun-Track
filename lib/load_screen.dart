import 'package:flutter/material.dart';
import 'despatch_screen.dart';  // Import DespatchScreen

class LoadScreen extends StatefulWidget {
  final String jobNumber;
  final List<Map<String, String>> scannedItems;
  final List<String> loadedItems;  // Passed from ScanScreen
  final bool isDespatched;  // Track if job is despatched

  const LoadScreen({
    super.key,
    required this.jobNumber,
    required this.scannedItems,
    required this.loadedItems,  // Initialize with passed loaded items
    this.isDespatched = false,  // Initialize with default false value
  });

  @override
  _LoadScreenState createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  final TextEditingController loadController = TextEditingController();
  late List<String> loadedItems;  // Store loaded items
  bool isDespatched = false;  // Track if job has been despatched
  bool isCompletelyLoaded = false;  // Track if all items are loaded

  @override
  void initState() {
    super.initState();
    loadedItems = List.from(widget.loadedItems);  // Initialize with the passed list
    isDespatched = widget.isDespatched;  // Initialize with the passed despatched status
    isCompletelyLoaded = loadedItems.length == widget.scannedItems.length;  // Check if all items are loaded
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? result =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (result != null) {
      setState(() {
        loadedItems = List<String>.from(result['loadedItems'] ?? []);
        isDespatched = result['isDespatched'] ?? false;
        isCompletelyLoaded = loadedItems.length == widget.scannedItems.length;
      });
    }
  }

  // Function to navigate to DespatchScreen
  void _navigateToDespatchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DespatchScreen(
          jobNumber: widget.jobNumber,
          scannedItems: widget.scannedItems,
          loadedItems: loadedItems,
        ),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          loadedItems = List<String>.from(result['loadedItems'] ?? []);
          isDespatched = result['isDespatched'] ?? false;
          isCompletelyLoaded = loadedItems.length == widget.scannedItems.length;
        });
      }
    });
  }

  // Function to mark the job as despatched when the check button is pressed
  void _markAsDespatched() {
    setState(() {
      isDespatched = true;
      isCompletelyLoaded = true;  // Mark as completely loaded when despatched
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Job has been marked as despatched and completely loaded!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allItemsLoaded = loadedItems.length == widget.scannedItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Load Items for Job ${widget.jobNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {
              'loadedItems': loadedItems,  // Pass back the updated loadedItems
              'isDespatched': isDespatched,  // Pass back the despatched status
              'isCompletelyLoaded': isCompletelyLoaded,  // Pass back the loaded status
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: loadController,
              decoration: InputDecoration(
                labelText: 'Enter Barcode to Load',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              enabled: !isDespatched,  // Disable input if already despatched
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isDespatched
                  ? null
                  : () {
                      String barcode = loadController.text.trim();
                      if (barcode.isNotEmpty) {
                        _loadItem(barcode);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDespatched ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Load Item', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loaded Items:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: loadedItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        'Loaded Barcode: ${loadedItems[index]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Show Check button only when all items are loaded and not despatched
            if (allItemsLoaded && !isDespatched)
              ElevatedButton(
                onPressed: isDespatched
                    ? null  // Disable the button when the job is already despatched
                    : _markAsDespatched,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDespatched ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '✔️ Mark as Despatched',
                  style: TextStyle(fontSize: 18),
                ),
              ),

            // Show message if already despatched
            if (isDespatched)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  '✅ Job has been marked as despatched!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Show message if all items are loaded but not yet despatched
            if (allItemsLoaded && !isDespatched)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  '⚠️ All items are loaded, but the job is not yet despatched!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Function to verify and load items
  void _loadItem(String barcode) {
    bool exists = widget.scannedItems.any((item) => item['barcode'] == barcode);

    if (exists) {
      if (!loadedItems.contains(barcode)) {
        setState(() {
          loadedItems.add(barcode);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Item $barcode loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Item $barcode is already loaded!'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: Item $barcode was not scanned for Job ${widget.jobNumber}!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    loadController.clear();  // Clear input after checking
  }
}
