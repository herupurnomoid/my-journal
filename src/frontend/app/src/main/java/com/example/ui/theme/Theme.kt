package com.example.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val DarkColorScheme =
  darkColorScheme(
    primary = SleekBluePrimaryDark,
    secondary = SleekPurpleSecondaryDark,
    tertiary = SleekOrangeTertiaryDark,
    background = SleekBackgroundDark,
    surface = SleekSurfaceDark,
    primaryContainer = SleekBlueContainerDark,
    secondaryContainer = SleekPurpleContainerDark,
    onPrimary = Color(0xFF0F172A),
    onSecondary = Color(0xFF0F172A),
    onBackground = SleekOnSurfaceDark,
    onSurface = SleekOnSurfaceDark
  )

private val LightColorScheme =
  lightColorScheme(
    primary = SleekBluePrimary,
    secondary = SleekPurpleSecondary,
    tertiary = SleekOrangeTertiary,
    background = SleekBackground,
    surface = SleekSurface,
    primaryContainer = SleekBlueContainer,
    secondaryContainer = SleekPurpleContainer,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = SleekOnSurface,
    onSurface = SleekOnSurface
  )

@Composable
fun MyApplicationTheme(
  darkTheme: Boolean = isSystemInDarkTheme(),
  // Turn off dynamicColor by default to prioritize our precise custom "Sleek Interface" brand colors
  dynamicColor: Boolean = false,
  content: @Composable () -> Unit,
) {
  val colorScheme =
    when {
      dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
        val context = LocalContext.current
        if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
      }

      darkTheme -> DarkColorScheme
      else -> LightColorScheme
    }

  MaterialTheme(colorScheme = colorScheme, typography = Typography, content = content)
}
