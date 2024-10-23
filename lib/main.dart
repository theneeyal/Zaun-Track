import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for database
import 'firebase_options.dart'; // Generated Firebase options
import 'load_screen.dart';
import 'scan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZaunTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const JobScreen(),
    );
  }
}

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  _JobScreenState createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final TextEditingController jobController = TextEditingController();
  List<Map<String, dynamic>> jobList = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJobsFromFirestore();
  }

  @override
  void dispose() {
    jobController.dispose();
    super.dispose();
  }

  // Load jobs from Firestore with error handling
  Future<void> _loadJobsFromFirestore() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _fetchJobs();
      setState(() {
        jobList = snapshot.docs.map((doc) => doc.data()).toList();
      });
      print('Jobs loaded successfully');
    } catch (e) {
      print('Error loading jobs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading jobs: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch jobs from Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> _fetchJobs() async {
    return await firestore.collection('jobs').get();
  }

  // Save a new job to Firestore
  Future<void> _saveJobToFirestore(Map<String, dynamic> job) async {
    try {
      print('Saving job with jobNumber: ${job['jobNumber']}');
      await firestore.collection('jobs').doc(job['jobNumber']).set(job);
      print('Job ${job['jobNumber']} saved successfully');
    } catch (e) {
      print('Error saving job: $e');
    }
  }

  // Delete a job from Firestore
  Future<void> _deleteJobFromFirestore(String jobNumber) async {
    try {
      await firestore.collection('jobs').doc(jobNumber).delete();
      print('Job $jobNumber deleted successfully');
    } catch (e) {
      print('Error deleting job: $e');
    }
  }

  // Handle job creation or opening an existing job
  void _createOrOpenJob() {
    String jobNumber = jobController.text.trim();
    print('Job Number: $jobNumber');  // Log to verify job number

    if (jobNumber.isNotEmpty) {
      // Check if the job already exists in the jobList
      bool jobExists = jobList.any((job) => job['jobNumber'] == jobNumber);
      if (jobExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening existing Job: $jobNumber')),
        );
        _openLoadScreen(jobNumber);
      } else {
        // Create a new job with proper array initialization for loadedItems and scannedItems
        Map<String, dynamic> newJob = {
          'jobNumber': jobNumber,  // Ensure job number is set
          'isCompleted': false,
          'isLoaded': false,
          'isDespatched': false,
          'loadedItems': <String>[],  // Initialize as an empty list
          'scannedItems': <Map<String, String>>[],  // Initialize as an empty list of maps
        };
        setState(() {
          jobList.add(newJob);  // Add the new job to the job list
        });
        _saveJobToFirestore(newJob);  // Save the job to Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created new Job: $jobNumber')),
        );
        _openScanScreen(jobNumber);
      }
      jobController.clear();  // Clear the input field
    } else {
      print('Error: Job number is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job number cannot be empty')),
      );
    }
  }

  // Confirm job deletion
  void _confirmDeleteJob(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this job?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteJobFromFirestore(jobList[index]['jobNumber']);
                setState(() {
                  jobList.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job deleted successfully.')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Open Scan Screen for the job
  void _openScanScreen(String jobNumber) async {
    int jobIndex = jobList.indexWhere((job) => job['jobNumber'] == jobNumber);
    if (jobIndex != -1) {
      var result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanScreen(
            jobNumber: jobNumber,
            isCompleted: jobList[jobIndex]['isCompleted'],
            scannedItems: List<Map<String, String>>.from(jobList[jobIndex]['scannedItems']),
            loadedItems: List<String>.from(jobList[jobIndex]['loadedItems']),
          ),
        ),
      );

      if (result != null) {
        setState(() {
          jobList[jobIndex]['isCompleted'] = result['isCompleted'];
          jobList[jobIndex]['scannedItems'] = List<Map<String, String>>.from(result['scannedItems']);
          jobList[jobIndex]['loadedItems'] = List<String>.from(result['loadedItems']);
          _saveJobToFirestore(jobList[jobIndex]); // Update Firestore with changes
        });
      }
    }
  }

  // Open Load Screen for the job
  void _openLoadScreen(String jobNumber) async {
    int jobIndex = jobList.indexWhere((job) => job['jobNumber'] == jobNumber);
    if (jobIndex != -1) {
      var result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoadScreen(
            jobNumber: jobNumber,
            scannedItems: List<Map<String, String>>.from(jobList[jobIndex]['scannedItems']),
            loadedItems: List<String>.from(jobList[jobIndex]['loadedItems']),
            isDespatched: jobList[jobIndex]['isDespatched'],
          ),
        ),
      );

      if (result != null && result['loadedItems'] != null) {
        setState(() {
          jobList[jobIndex]['isLoaded'] = true;
          jobList[jobIndex]['loadedItems'] = List<String>.from(result['loadedItems']);
          jobList[jobIndex]['isDespatched'] = result['isDespatched'] ?? false;
          _saveJobToFirestore(jobList[jobIndex]); // Save updated job to Firestore
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZaunTrack Job Management'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app_icon.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'ZaunTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: jobController,
                decoration: InputDecoration(
                  labelText: 'Scan Barcode or Enter Job Number',
                  labelStyle: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.blue[50],
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createOrOpenJob,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Create or Open Job', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Active Jobs:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : jobList.isEmpty
                        ? const Center(child: Text('No active jobs, please add a job.'))
                        : ListView.builder(
                            itemCount: jobList.length,
                            itemBuilder: (context, index) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 4.0,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                                  title: Text(
                                    'Job: ${jobList[index]['jobNumber']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jobList[index]['isCompleted']
                                            ? 'Scanning Status: Completed'
                                            : 'Scanning Status: Active',
                                        style: TextStyle(
                                            color: jobList[index]['isCompleted'] ? Colors.green : Colors.orange),
                                      ),
                                      Text(
                                        jobList[index]['isLoaded']
                                            ? 'Loading Status: Completed'
                                            : 'Loading Status: Not Loaded/Partially Loaded',
                                        style: TextStyle(
                                            color: jobList[index]['isLoaded'] ? Colors.green : Colors.orange),
                                      ),
                                      if (jobList[index]['isDespatched'])
                                        const Text(
                                          'Despatch Status: Despatched',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _openScanScreen(jobList[index]['jobNumber']);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _confirmDeleteJob(index);
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    _openLoadScreen(jobList[index]['jobNumber']);
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
