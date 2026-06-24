import 'package:home_widget/home_widget.dart';
import '../models/job_model.dart';

class WidgetService {
  static const String appGroupId = 'group.kaamkaaz.widget';
  static const String androidWidgetName = 'JobWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> updateWidgetWithJobs(List<JobModel> jobs) async {
    try {
      final topJobs = jobs.take(3).toList();
      
      for (int i = 0; i < 3; i++) {
        final job = i < topJobs.length ? topJobs[i] : null;
        final prefix = 'job${i + 1}_';
        
        if (job != null) {
          await HomeWidget.saveWidgetData('${prefix}id', job.id);
          await HomeWidget.saveWidgetData('${prefix}title', job.title);
          
          final wageStr = job.formattedWage;
          final distStr = job.formattedDistance.isNotEmpty ? ' • ${job.formattedDistance}' : '';
          await HomeWidget.saveWidgetData('${prefix}desc', '$wageStr$distStr');
        } else {
          await HomeWidget.saveWidgetData('${prefix}id', '');
          await HomeWidget.saveWidgetData('${prefix}title', '');
          await HomeWidget.saveWidgetData('${prefix}desc', '');
        }
      }
      
      await HomeWidget.updateWidget(
        name: androidWidgetName,
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
