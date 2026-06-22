package com.viniciuspascoal.meutreinoplus

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class TodayWorkoutWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val workoutName = widgetData.getString(
            "today_workout_name",
            "Nenhum treino configurado"
        )

        val workoutDescription = widgetData.getString(
            "today_workout_description",
            "Abra o app para configurar sua sequencia ABC"
        )

        val trainedToday = widgetData.getBoolean("trained_today", false)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(
                context.packageName,
                R.layout.today_workout_widget
            )

            views.setTextViewText(R.id.widget_title, "MeuTreino+")
            views.setTextViewText(R.id.widget_workout_name, "Hoje: $workoutName")
            views.setTextViewText(R.id.widget_workout_description, workoutDescription)
            views.setTextViewText(
                R.id.widget_status,
                if (trainedToday) "Concluido hoje" else "Pendente"
            )

            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_container, launchIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
