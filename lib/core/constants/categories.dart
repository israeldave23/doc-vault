import 'package:shadcn_flutter/shadcn_flutter.dart';

class DocumentCategory {
  const DocumentCategory(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static const passport = DocumentCategory('passport', 'Passport', LucideIcons.plane);
  static const driversLicense = DocumentCategory('drivers_license', "Driver's License", LucideIcons.car);
  static const nationalId = DocumentCategory('national_id', 'National ID', LucideIcons.badge);
  static const philhealth = DocumentCategory('philhealth', 'PhilHealth', LucideIcons.hospital);
  static const sssUmid = DocumentCategory('sss_umid', 'SSS / UMID', LucideIcons.creditCard);
  static const prcLicense = DocumentCategory('prc_license', 'PRC License', LucideIcons.award);
  static const vehicleRegistration = DocumentCategory('vehicle_registration', 'Vehicle Registration', LucideIcons.bike);
  static const insurance = DocumentCategory('insurance', 'Insurance', LucideIcons.shield);
  static const visa = DocumentCategory('visa', 'Visa', LucideIcons.globe);
  static const workPermit = DocumentCategory('work_permit', 'Work Permit', LucideIcons.briefcaseBusiness);
  static const businessPermit = DocumentCategory('business_permit', 'Business Permit', LucideIcons.store);
  static const warranty = DocumentCategory('warranty', 'Warranty', LucideIcons.badgeCheck);
  static const bankCard = DocumentCategory('bank_card', 'Credit / Debit Card', LucideIcons.walletCards);
  static const other = DocumentCategory('other', 'Other', LucideIcons.fileText);

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
    return all.firstWhere((category) => category.key == key, orElse: () => other);
  }
}
