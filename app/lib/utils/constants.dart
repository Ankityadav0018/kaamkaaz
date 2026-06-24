import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../l10n/locale_keys.g.dart';

class SkillInfo {
  final String id;
  final String name;
  final IconData icon;

  const SkillInfo(this.id, this.name, this.icon);
}

class JobCategoryInfo {
  final String id;
  final String name;
  final String emoji;
  const JobCategoryInfo(this.id, this.name, this.emoji);
}

List<JobCategoryInfo> get JOB_CATEGORIES => [
  JobCategoryInfo('Plumbing', LocaleKeys.skillPlumbing.tr(), '🔧'),
  JobCategoryInfo('Electrical', LocaleKeys.skillElectrical.tr(), '⚡'),
  JobCategoryInfo('Carpentry', LocaleKeys.skillCarpentry.tr(), '🪚'),
  JobCategoryInfo('Painting', LocaleKeys.skillPainting.tr(), '🎨'),
  JobCategoryInfo('Welding', LocaleKeys.skillWelding.tr(), '🔥'),
  JobCategoryInfo('Masonry', LocaleKeys.skillMasonry.tr(), '🧱'),
  JobCategoryInfo('Driving', LocaleKeys.skillDriving.tr(), '🚚'),
  JobCategoryInfo('Cooking', LocaleKeys.skillCooking.tr(), '🍳'),
  JobCategoryInfo('AC Repair', LocaleKeys.skillACRepair.tr(), '❄️'),
  JobCategoryInfo('Security Guard', LocaleKeys.skillSecurity.tr(), '🛡️'),
  JobCategoryInfo('Cleaning', LocaleKeys.skillCleaning.tr(), '🧹'),
  JobCategoryInfo('Construction', LocaleKeys.skillConstruction.tr(), '🏗️'),
];

List<SkillInfo> get kSkillsList => [
      SkillInfo(
          'Plumbing', LocaleKeys.skillPlumbing.tr(), Icons.plumbing_rounded),
      SkillInfo('Electrical', LocaleKeys.skillElectrical.tr(),
          Icons.electrical_services_rounded),
      SkillInfo(
          'Carpentry', LocaleKeys.skillCarpentry.tr(), Icons.carpenter_rounded),
      SkillInfo('Painting', LocaleKeys.skillPainting.tr(),
          Icons.format_paint_rounded),
      SkillInfo('Welding', LocaleKeys.skillWelding.tr(),
          Icons.precision_manufacturing_rounded),
      SkillInfo(
          'Masonry', LocaleKeys.skillMasonry.tr(), Icons.foundation_rounded),
      SkillInfo(
          'Driving', LocaleKeys.skillDriving.tr(), Icons.drive_eta_rounded),
      SkillInfo(
          'Cooking', LocaleKeys.skillCooking.tr(), Icons.restaurant_rounded),
      SkillInfo(
          'AC Repair', LocaleKeys.skillACRepair.tr(), Icons.ac_unit_rounded),
      SkillInfo('Security Guard', LocaleKeys.skillSecurity.tr(),
          Icons.security_rounded),
      SkillInfo('Cleaning', LocaleKeys.skillCleaning.tr(),
          Icons.cleaning_services_rounded),
      SkillInfo('Construction', LocaleKeys.skillConstruction.tr(),
          Icons.handyman_rounded),
    ];
