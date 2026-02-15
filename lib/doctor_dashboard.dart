import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: Import Firebase packages when ready
// import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  // Mock Data as requested
  final List<Map<String, dynamic>> fakeResults = const [
    {
      "name": "Patient A",
      "id": "P001",
      "score": 15,
      "temps": "2:30",
      "date": "12/02/2026",
    },
    {
      "name": "Patient B",
      "id": "P002",
      "score": 12,
      "temps": "3:15",
      "date": "13/02/2026",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "لوحة تحكم الطبيب",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "النتائج الأخيرة",
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // TODO: Replace with StreamBuilder<QuerySnapshot> using FirebaseFirestore.instance
            Expanded(
              child: ListView.builder(
                itemCount: fakeResults.length,
                itemBuilder: (context, index) {
                  final result = fakeResults[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text(
                          result['id'].toString().substring(0, 1), // Initial
                          style: GoogleFonts.cairo(color: Colors.teal),
                        ),
                      ),
                      title: Text(
                        result['name'],
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "المعرف: ${result['id']}",
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          Text(
                            "النتيجة: ${result['score']}  |  الوقت: ${result['temps']}  |  التاريخ: ${result['date']}",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.grey,
                          size: 32,
                        ),
                        onPressed: null, // Audio button inactive as requested
                        // TODO: Implement audio playback from Firebase Storage URL
                      ),
                    ),
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
