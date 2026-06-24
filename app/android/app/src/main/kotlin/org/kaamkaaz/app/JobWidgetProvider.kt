package org.kaamkaaz.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class JobWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.job_widget_layout)

            // Setup click intent for entire widget to open app
            val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("app://kaamkaaz")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntentWithData)

            // Job 1
            views.setTextViewText(R.id.job1_title, widgetData.getString("job1_title", "Loading..."))
            views.setTextViewText(R.id.job1_desc, widgetData.getString("job1_desc", ""))
            
            // Job 1 click
            val job1Id = widgetData.getString("job1_id", "")
            if (job1Id?.isNotEmpty() == true) {
                val pIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("app://kaamkaaz/job/$job1Id")
                )
                views.setOnClickPendingIntent(R.id.job1_layout, pIntent)
            }

            // Job 2
            views.setTextViewText(R.id.job2_title, widgetData.getString("job2_title", ""))
            views.setTextViewText(R.id.job2_desc, widgetData.getString("job2_desc", ""))
            
            val job2Id = widgetData.getString("job2_id", "")
            if (job2Id?.isNotEmpty() == true) {
                val pIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("app://kaamkaaz/job/$job2Id")
                )
                views.setOnClickPendingIntent(R.id.job2_layout, pIntent)
            }

            // Job 3
            views.setTextViewText(R.id.job3_title, widgetData.getString("job3_title", ""))
            views.setTextViewText(R.id.job3_desc, widgetData.getString("job3_desc", ""))

            val job3Id = widgetData.getString("job3_id", "")
            if (job3Id?.isNotEmpty() == true) {
                val pIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("app://kaamkaaz/job/$job3Id")
                )
                views.setOnClickPendingIntent(R.id.job3_layout, pIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
