package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ui.screens.auth.*
import com.example.ui.screens.dashboard.*
import com.example.ui.screens.journal.*
import com.example.ui.screens.mood.*
import com.example.ui.theme.MyApplicationTheme
import com.example.ui.viewmodel.JournalViewModel

import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import com.example.workers.DailyReminderWorker
import com.example.workers.InactivityWorker
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {
    private val journalViewModel: JournalViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
        }
        
        setupWorkManager()

        enableEdgeToEdge()
        setContent {
            MyApplicationTheme {
                MainAppNavigator(viewModel = journalViewModel)
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Reset the 48h inactivity timer every time the app comes to the foreground
        val inactivityRequest = OneTimeWorkRequestBuilder<InactivityWorker>()
            .setInitialDelay(48, TimeUnit.HOURS)
            .build()
            
        WorkManager.getInstance(this).enqueueUniqueWork(
            "inactivity_reminder",
            ExistingWorkPolicy.REPLACE,
            inactivityRequest
        )
        
        // Update Firestore lastActiveAt
        journalViewModel.updateLastActive()
    }

    override fun onStop() {
        super.onStop()
        // Reset PIN verification when user leaves the app so PIN is required on return
        if (journalViewModel.isPinEnabled.value) {
            android.util.Log.d("MainActivity", "onStop: isPinEnabled=true, calling resetPinVerification")
            journalViewModel.resetPinVerification()
        }
    }

    private fun setupWorkManager() {
        val dailyRequest = PeriodicWorkRequestBuilder<DailyReminderWorker>(24, TimeUnit.HOURS)
            .build()
            
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "daily_reminder",
            ExistingPeriodicWorkPolicy.KEEP,
            dailyRequest
        )
    }
}

// Global Navigation State Router
enum class AppFlowState {
    SPLASH,
    WELCOME,
    LOGIN,
    LOADING,
    PIN,
    MAIN_SHELL
}

enum class NavigationTab {
    HOME,
    JOURNAL_LIST,
    MOOD_CALENDAR,
    INSIGHTS,
    PROFILE_SETTINGS
}

enum class JournalSubState {
    LIST,
    CREATE,
    EDIT,
    DETAIL,
    MOOD_ANALYSIS
}

@Composable
fun MainAppNavigator(
    viewModel: JournalViewModel,
    modifier: Modifier = Modifier
) {
    // Top-level Navigation router
    var appState by remember { mutableStateOf(AppFlowState.SPLASH) }
    
    // Auth observation triggers automatically
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    val isProfileLoaded by viewModel.isProfileLoaded.collectAsState()
    val isPinVerified by viewModel.isPinVerified.collectAsState()
    val isPinEnabled by viewModel.isPinEnabled.collectAsState()
    val userPin by viewModel.userPin.collectAsState()

    // Screen sub-states
    var activeTab by remember { mutableStateOf(NavigationTab.HOME) }
    var journalSubState by remember { mutableStateOf(JournalSubState.LIST) }

    // On State transitions check
    LaunchedEffect(isLoggedIn, isProfileLoaded, isPinVerified, isPinEnabled) {
        if (!isLoggedIn) {
            appState = AppFlowState.SPLASH
        } else if (!isProfileLoaded) {
            // Profile is still loading from Firestore - show loading screen
            appState = AppFlowState.LOADING
        } else if (isPinEnabled && !isPinVerified) {
            appState = AppFlowState.PIN
        } else {
            appState = AppFlowState.MAIN_SHELL
        }
    }
    when (appState) {
        AppFlowState.SPLASH -> {
            SplashScreen(
                onTimeout = {
                    appState = AppFlowState.WELCOME
                }
            )
        }
        AppFlowState.WELCOME -> {
            WelcomeScreen(
                onExploreClicked = {
                    appState = AppFlowState.LOGIN
                }
            )
        }
        AppFlowState.LOGIN -> {
            LoginScreen(
                onLoginSuccess = {
                    viewModel.logInWithGoogle()
                }
            )
        }
        AppFlowState.LOADING -> {
            // Simple loading screen while waiting for Firestore profile
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.primary
                    )
                    androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Memuat profil...",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                    )
                }
            }
        }
        AppFlowState.PIN -> {
            PinSecurityScreen(
                viewModel = viewModel,
                correctPin = userPin,
                onPinVerified = {
                    // PinSecurityScreen already called viewModel.verifyPin() with the raw PIN
                    // so isPinVerified is already true. Just navigate.
                    appState = AppFlowState.MAIN_SHELL
                },
                onNewPinSet = { newPin ->
                    viewModel.updatePin(newPin)
                    appState = AppFlowState.MAIN_SHELL
                }
            )
        }
        AppFlowState.MAIN_SHELL -> {
            Scaffold(
                modifier = Modifier.fillMaxSize(),
                bottomBar = {
                    NavigationBar(
                        modifier = Modifier
                            .windowInsetsPadding(WindowInsets.navigationBars)
                            .testTag("bottom_nav_bar"),
                        containerColor = MaterialTheme.colorScheme.surface,
                        tonalElevation = 8.dp
                    ) {
                        // Home
                        NavigationBarItem(
                            selected = activeTab == NavigationTab.HOME,
                            onClick = { 
                                activeTab = NavigationTab.HOME 
                            },
                            icon = { Icon(imageVector = Icons.Default.Home, contentDescription = "Home") },
                            label = { Text("Home") },
                            modifier = Modifier.testTag("nav_home_tab")
                        )

                        // Journal list
                        NavigationBarItem(
                            selected = activeTab == NavigationTab.JOURNAL_LIST,
                            onClick = { 
                                activeTab = NavigationTab.JOURNAL_LIST
                                journalSubState = JournalSubState.LIST
                            },
                            icon = { Icon(imageVector = Icons.Default.Book, contentDescription = "Journal") },
                            label = { Text("Journal") },
                            modifier = Modifier.testTag("nav_journal_tab")
                        )

                        // Mood Calendar
                        NavigationBarItem(
                            selected = activeTab == NavigationTab.MOOD_CALENDAR,
                            onClick = { activeTab = NavigationTab.MOOD_CALENDAR },
                            icon = { Icon(imageVector = Icons.Default.CalendarMonth, contentDescription = "Mood") },
                            label = { Text("Mood") },
                            modifier = Modifier.testTag("nav_mood_tab")
                        )

                        // Insights
                        NavigationBarItem(
                            selected = activeTab == NavigationTab.INSIGHTS,
                            onClick = { activeTab = NavigationTab.INSIGHTS },
                            icon = { Icon(imageVector = Icons.Default.TrendingUp, contentDescription = "Insights") },
                            label = { Text("Insights") },
                            modifier = Modifier.testTag("nav_insights_tab")
                        )

                        // Profile / Settings
                        NavigationBarItem(
                            selected = activeTab == NavigationTab.PROFILE_SETTINGS,
                            onClick = { activeTab = NavigationTab.PROFILE_SETTINGS },
                            icon = { Icon(imageVector = Icons.Default.Person, contentDescription = "Profile") },
                            label = { Text("Profil") },
                            modifier = Modifier.testTag("nav_profile_tab")
                        )
                    }
                },
                floatingActionButton = {
                    // Show Floating Action Button on Home or List screens for Quick journaling!
                    val showFab = (activeTab == NavigationTab.HOME || (activeTab == NavigationTab.JOURNAL_LIST && journalSubState == JournalSubState.LIST))
                    if (showFab) {
                        FloatingActionButton(
                            onClick = {
                                activeTab = NavigationTab.JOURNAL_LIST
                                journalSubState = JournalSubState.CREATE
                            },
                            modifier = Modifier
                                .navigationBarsPadding()
                                .padding(bottom = 16.dp)
                                .testTag("fab_write_journal"),
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = MaterialTheme.colorScheme.onPrimary
                        ) {
                            Icon(imageVector = Icons.Default.Add, contentDescription = "Tulis Jurnal Baru")
                        }
                    }
                }
            ) { innerPadding ->
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(innerPadding)
                ) {
                    when (activeTab) {
                        NavigationTab.HOME -> {
                            HomeDashboardScreen(
                                viewModel = viewModel,
                                onWriteQuickJournal = {
                                    activeTab = NavigationTab.JOURNAL_LIST
                                    journalSubState = JournalSubState.CREATE
                                },
                                onNavigateToMoodCalendar = {
                                    activeTab = NavigationTab.MOOD_CALENDAR
                                },
                                onNavigateToRecommendations = {
                                    activeTab = NavigationTab.MOOD_CALENDAR // recommendations nested inside mood tab as a sub-segment
                                },
                                onJournalSelected = { journal ->
                                    viewModel.selectJournal(journal)
                                    activeTab = NavigationTab.JOURNAL_LIST
                                    journalSubState = JournalSubState.DETAIL
                                }
                            )
                        }
                        NavigationTab.JOURNAL_LIST -> {
                            when (journalSubState) {
                                JournalSubState.LIST -> {
                                    JournalListScreen(
                                        viewModel = viewModel,
                                        onJournalSelected = { journal ->
                                            viewModel.selectJournal(journal)
                                            journalSubState = JournalSubState.DETAIL
                                        },
                                        onWriteNewClicked = {
                                            journalSubState = JournalSubState.CREATE
                                        }
                                    )
                                }
                                JournalSubState.CREATE -> {
                                    CreateJournalScreen(
                                        viewModel = viewModel,
                                        journalToEdit = null,
                                        onSaveSuccess = {
                                            journalSubState = JournalSubState.LIST
                                        },
                                        onCancel = {
                                            journalSubState = JournalSubState.LIST
                                        }
                                    )
                                }
                                JournalSubState.EDIT -> {
                                    CreateJournalScreen(
                                        viewModel = viewModel,
                                        journalToEdit = viewModel.selectedJournal.value,
                                        onSaveSuccess = {
                                            journalSubState = JournalSubState.DETAIL
                                        },
                                        onCancel = {
                                            journalSubState = JournalSubState.DETAIL
                                        }
                                    )
                                }
                                JournalSubState.DETAIL -> {
                                    JournalDetailScreen(
                                        viewModel = viewModel,
                                        onEditClicked = {
                                            journalSubState = JournalSubState.EDIT
                                        },
                                        onDeleteClicked = {
                                            val journal = viewModel.selectedJournal.value
                                            if (journal != null && journal.firestoreId.isNotEmpty()) {
                                                viewModel.deleteJournal(journal.firestoreId)
                                            }
                                            journalSubState = JournalSubState.LIST
                                        },
                                        onNavigateBack = {
                                            journalSubState = JournalSubState.LIST
                                        },
                                        onNavigateToMoodAnalysis = {
                                            journalSubState = JournalSubState.MOOD_ANALYSIS
                                        }
                                    )
                                }
                                JournalSubState.MOOD_ANALYSIS -> {
                                    MoodAnalysisScreen(
                                        viewModel = viewModel,
                                        onNavigateBack = {
                                            journalSubState = JournalSubState.DETAIL
                                        }
                                    )
                                }
                            }
                        }
                        NavigationTab.MOOD_CALENDAR -> {
                            // Sub-screens of tracker: Column holds calendar, then recommendation tray below!
                            Column(modifier = Modifier.fillMaxSize()) {
                                TabRow(selectedTabIndex = 0) {
                                    Tab(selected = true, onClick = {}, text = { Text("Kalender Bulanan") })
                                }
                                MoodCalendarScreen(viewModel = viewModel, modifier = Modifier.weight(1f))
                            }
                        }
                        NavigationTab.INSIGHTS -> {
                            MoodInsightDashboardScreen(viewModel = viewModel)
                        }
                        NavigationTab.PROFILE_SETTINGS -> {
                            SettingsAndProfileScreen(viewModel = viewModel)
                        }
                    }
                }
            }
        }
    }
}
