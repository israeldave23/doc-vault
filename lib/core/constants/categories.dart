import 'package:flutter/material.dart';

/// Preset categories. The [key] is what gets stored in the database so labels
/// can be renamed or localized later without migrating data.
class DocumentCategory {
  const DocumentCategory(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static const passport = DocumentCategory('passport', 'Passport', Icons.flight_takeoff);
  static const driversLicense = DocumentCategory('drivers_license', "Driver's License", Icons.directions_car);
  static const nationalId = DocumentCategory('national_id', 'National ID', Icons.badge);
  static const philhealth = DocumentCategory('philhealth', 'PhilHealth', Icons.local_hospital);
  static const sssUmid = DocumentCategory('sss_umid', 'SSS / UMID', Icons.credit_card);
  static const prcLicense = DocumentCategory('prc_license', 'PRC License', Icons.workspace_premium);
  static const vehicleRegistration = DocumentCategory('vehicle_registration', 'Vehicle Registration', Icons.two_wheeler);
  static const insurance = DocumentCategory('insurance', 'Insurance', Icons.shield);
  static const visa = DocumentCategory('visa', 'Visa', Icons.public);
  static const workPermit = DocumentCategory('work_permit', 'Work Permit', Icons.work);
  static const businessPermit = DocumentCategory('business_permit', 'Business Permit', Icons.storefront);
  static const warranty = DocumentCategory('warranty', 'Warranty', Icons.verified);
  static const bankCard = DocumentCategory('bank_card', 'Credit / Debit Card', Icons.payment);
  static const other = DocumentCategory('other', 'Other', Icons.description);

  static const all = <DocumentCategory>[
    passport,
    driversLicense,
    nationalId,
    philhealth,
    sssUmid,
    prcLicense,
    vehicleRegistration,
    insurance,
    visa,
    workPermit,
    businessPermit,
    warranty,
    bankCard,
    other,
  ];

  static DocumentCategory byKey(String key) {
    return all.firstWhere((c) => c.key == key, orElse: () => other);
  }
}
