import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/firestore_service.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Section 1: Identification
  final _medicalIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedBirthDate;

  // Section 2: Socio-demographique
  String? _gender;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _insurance;
  String? _educationLevel;
  String? _maritalStatus;
  String? _mainCaregiver;

  // Section 3: Antecedents
  bool _hasDementiaHistory = false;
  final _relationshipController = TextEditingController();
  bool _dominantTransmission = false;
  bool _geneticTesting = false;

  bool _hta = false;
  bool _diabete = false;
  bool _dyslipemie = false;
  bool _otherSomatic = false;
  bool _psychiatric = false;

  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'), // Force Western/French calendar
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black, // Darker text for better visibility
            ),
            textTheme: GoogleFonts.cairoTextTheme(), // Ensure Cairo is used in picker
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une date de naissance")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.addPatient(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        patientIdentifier: _medicalIdController.text.trim(),
        birthDate: _selectedBirthDate!,
        gender: _gender,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        insurance: _insurance,
        educationLevel: _educationLevel,
        maritalStatus: _maritalStatus,
        mainCaregiver: _mainCaregiver,
        antecedents: {
          'familiaux': {
            'demence': _hasDementiaHistory,
            'lien_parente': _relationshipController.text.trim(),
            'transmission_dominante': _dominantTransmission,
            'genetique': _geneticTesting,
          },
          'personnels': {
            'hta': _hta,
            'diabete': _diabete,
            'dyslipemie': _dyslipemie,
            'somatique': _otherSomatic,
            'psychiatrique': _psychiatric,
          }
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient enregistré avec succès")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fiche Patient", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Center(
                child: Column(
                  children: [
                    Text(
                      "Hôpital Universitaire Habib Bourguiba de Sfax",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Service de Neurologie",
                      style: GoogleFonts.cairo(color: Colors.teal),
                    ),
                    const Divider(),
                  ],
                ),
              ),

              // Section 1: Identification
              _buildSectionHeader("Section 1 : Identification"),
              _buildCard([
                TextFormField(
                  controller: _medicalIdController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Identifiant Médical *",
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: "Prénom *",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: "Nom *",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date de naissance *",
                      prefixIcon: Icon(Icons.cake),
                    ),
                    child: Text(
                      _selectedBirthDate == null
                          ? "Sélectionner une date"
                          : "${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}",
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                ),
              ]),

              // Section 2: Socio-demographique
              _buildSectionHeader("Section 2 : Profil Socio-démographique"),
              _buildCard([
                Text("Sexe", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Masculin"),
                        value: "masculin",
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Féminin"),
                        value: "feminin",
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "Adresse",
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Numéro de téléphone",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Prise en charge"),
                  items: ["CNAM", "type I", "type II", "carte d'handicap"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _insurance = v),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Niveau scolaire"),
                  items: ["illettré", "primaire", "secondaire", "supérieur"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _educationLevel = v),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Statut matrimonial"),
                  items: ["célibataire", "mariée", "divorcé"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _maritalStatus = v),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Aidant principal"),
                  items: ["époux(e)", "fils", "fille", "mère", "père", "auxiliaire", "autre"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _mainCaregiver = v),
                ),
              ]),

              // Section 3: Antecedents
              _buildSectionHeader("Section 3 : Historique & Antécédents"),
              _buildCard([
                Text("Antécédents Familiaux", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.teal)),
                SwitchListTile(
                  title: const Text("Démence"),
                  value: _hasDementiaHistory,
                  onChanged: (v) => setState(() => _hasDementiaHistory = v),
                ),
                if (_hasDementiaHistory)
                  TextFormField(
                    controller: _relationshipController,
                    decoration: const InputDecoration(labelText: "Lien de parenté"),
                  ),
                SwitchListTile(
                  title: const Text("Transmission dominante"),
                  value: _dominantTransmission,
                  onChanged: (v) => setState(() => _dominantTransmission = v),
                ),
                SwitchListTile(
                  title: const Text("Prélèvement génétique"),
                  value: _geneticTesting,
                  onChanged: (v) => setState(() => _geneticTesting = v),
                ),
                const Divider(),
                Text("Antécédents Personnels", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                const Text("Facteurs de risque vasculaires :"),
                CheckboxListTile(
                  title: const Text("HTA"),
                  value: _hta,
                  onChanged: (v) => setState(() => _hta = v!),
                ),
                CheckboxListTile(
                  title: const Text("Diabète"),
                  value: _diabete,
                  onChanged: (v) => setState(() => _diabete = v!),
                ),
                CheckboxListTile(
                  title: const Text("Dyslipémie"),
                  value: _dyslipemie,
                  onChanged: (v) => setState(() => _dyslipemie = v!),
                ),
                SwitchListTile(
                  title: const Text("Autre maladie somatique"),
                  value: _otherSomatic,
                  onChanged: (v) => setState(() => _otherSomatic = v),
                ),
                SwitchListTile(
                  title: const Text("Maladie psychiatrique"),
                  value: _psychiatric,
                  onChanged: (v) => setState(() => _psychiatric = v),
                ),
              ]),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Enregistrer le Patient", style: GoogleFonts.cairo(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
