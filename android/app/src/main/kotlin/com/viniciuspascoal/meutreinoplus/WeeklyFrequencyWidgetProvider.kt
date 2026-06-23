package com.viniciuspascoal.meutreinoplus

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class WeeklyFrequencyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val weeklyDone = widgetData.getInt("weekly_done", 0)
        val weeklyExpected = widgetData.getInt("weekly_expected", 0)
        val weeklyRemaining = widgetData.getInt("weekly_remaining", 0)
        val weeklyStatusText = widgetData.getString(
            "weekly_status_text",
            "0/0 treinos na semana"
        )
        val completionRate = widgetData.getInt("weekly_completion_rate", 0)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(
                context.packageName,
                R.layout.weekly_frequency_widget
            )

            views.setTextViewText(R.id.widget_title, "Frequencia semanal")
            views.setTextViewText(R.id.widget_done_value, weeklyDone.toString())
            views.setTextViewText(R.id.widget_expected_value, weeklyExpected.toString())
            views.setTextViewText(R.id.widget_remaining_value, weeklyRemaining.toString())
            views.setTextViewText(R.id.widget_status, weeklyStatusText)
            views.setProgressBar(R.id.widget_progress, 100, completionRate, false)

            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_container, launchIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
