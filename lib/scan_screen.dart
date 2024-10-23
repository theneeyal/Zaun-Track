import 'package:flutter/material.dart';
import 'load_screen.dart';  // Import the LoadScreen

class ScanScreen extends StatefulWidget {
  final String jobNumber;
  final bool isCompleted;  // Job completion status
  final List<Map<String, String>> scannedItems;  // List of scanned items passed from JobScreen
  final List<String> loadedItems;  // <-- Add loadedItems to constructor

  const ScanScreen({super.key, 
    required this.jobNumber,
    this.isCompleted = false,
    required this.scannedItems,
    required this.loadedItems,  // <-- Initialize with passed loaded items
  });

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController barcodeController = TextEditingController();
  String? selectedCategory; // Category selected by user
  late List<Map<String, String>> scannedItems;  // List of scanned items
  late List<String> loadedItems;  // Loaded items list
  bool isScanningCompleted = false;  // Track if scanning is completed

  @override
  void initState() {
    super.initState();
    isScanningCompleted = widget.isCompleted;  // Set initial status from passed value
    scannedItems = List.from(widget.scannedItems);  // Initialize scannedItems from the passed list
    loadedItems = List.from(widget.loadedItems);  // Initialize loadedItems from the passed list
  }

  // Function to handle category selection
  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  // Function to toggle scanning status
  void _toggleScanningStatus(bool value) {
    setState(() {
      isScanningCompleted = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Items for Job ${widget.jobNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {
              'isCompleted': isScanningCompleted,
              'scannedItems': scannedItems,  // Pass updated scannedItems back to JobScreen
              'loadedItems': loadedItems,    // <-- Pass loadedItems back to JobScreen
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input field for barcode with rounded corners and background color
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Enter or Scan Barcode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              enabled: !isScanningCompleted, // Disable if scanning is completed
            ),
            const SizedBox(height: 16),

            // Message to choose type of item
            const Text(
              "Please choose the type of item to be scanned:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 2x2 Grid of buttons using Wrap widget
            Wrap(
              spacing: 8.0, // Horizontal space between buttons
              runSpacing: 8.0, // Vertical space between buttons
              alignment: WrapAlignment.center, // Center-align the buttons
              children: [
                _buildCategoryButton('Mesh'),
                _buildCategoryButton('Posts'),
                _buildCategoryButton('Gates'),
                _buildCategoryButton('Fixings'),
              ],
            ),
            const SizedBox(height: 16),

            // Button to add the item, only enabled if a category is selected and scanning is not completed
            ElevatedButton(
              onPressed: selectedCategory == null || isScanningCompleted
                  ? null // Disable button if no category is selected or scanning is completed
                  : () {
                      String barcode = barcodeController.text.trim();
                      if (barcode.isNotEmpty && selectedCategory != null) {
                        setState(() {
                          scannedItems.add({
                            'barcode': barcode,
                            'category': selectedCategory!, // Add selected category
                          });
                          barcodeController.clear();  // Clear after adding
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black, // Set text color to white
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle button to mark scanning status
            SwitchListTile(
              title: Text(
                isScanningCompleted ? 'Scanning Completed.' : 'Scanning in Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isScanningCompleted ? Colors.green : Colors.red,
                ),
              ),
              value: isScanningCompleted,
              onChanged: (bool value) {
                _toggleScanningStatus(value);
              },
              activeColor: Colors.green,
              inactiveThumbColor: Colors.redAccent,
              inactiveTrackColor: Colors.red[200],
            ),
            const SizedBox(height: 24),

            // Scanned Items List Title
            const Text(
              'Scanned Items:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Display scanned items with improved styling
            Expanded(
              child: ListView.builder(
                itemCount: scannedItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        'Barcode: ${scannedItems[index]['barcode']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        'Category: ${scannedItems[index]['category']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Button to navigate to the LoadScreen
            ElevatedButton(
              onPressed: isScanningCompleted
                  ? () async {
                      var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoadScreen(
                            jobNumber: widget.jobNumber,
                            scannedItems: scannedItems,  // Pass scanned items to LoadScreen
                            loadedItems: loadedItems,    // <-- Pass the existing loadedItems to LoadScreen
                          ),
                        ),
                      );

                      // Update the loadedItems after returning from LoadScreen
                      if (result != null) {
                        setState(() {
                          loadedItems = List<String>.from(result['loadedItems']);  // Update loadedItems from LoadScreen result
                        });
                      }
                    }
                  : null, // Disable button if scanning is not completed
              style: ElevatedButton.styleFrom(
                backgroundColor: isScanningCompleted ? Colors.blue : Colors.grey, // Change button color based on scanning status
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Loading',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // Set text color to white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build each category button
  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: isScanningCompleted ? null : () => _selectCategory(category),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        backgroundColor: selectedCategory == category ? Colors.blue : Colors.grey[300],  // Highlight selected category
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: selectedCategory == category ? Colors.white : Colors.black,  // Change text color when selected
          fontSize: 14,
        ),
      ),
    );
  }
}
