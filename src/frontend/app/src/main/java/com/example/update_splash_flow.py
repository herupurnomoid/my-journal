import re

# 1. Update MainActivity.kt
with open("MainActivity.kt", "r") as f:
    main_content = f.read()

# Add AppFlowState.WELCOME
main_content = main_content.replace(
    "enum class AppFlowState {\n    SPLASH,\n    LOGIN,",
    "enum class AppFlowState {\n    SPLASH,\n    WELCOME,\n    LOGIN,"
)

# Update AppFlow routing
router_logic = """    when (appState) {
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
        }"""

main_content = re.sub(r"\s*when \(appState\) \{.*AppFlowState\.SPLASH -> \{.*?onExploreClicked = \{.*?\n\s*\}\n\s*\)\n\s*\}", "\n" + router_logic, main_content, flags=re.DOTALL)

with open("MainActivity.kt", "w") as f:
    f.write(main_content)

# 2. Update SplashScreen.kt
with open("ui/screens/auth/SplashScreen.kt", "r") as f:
    splash_content = f.read()

# Rename existing SplashScreen to WelcomeScreen
splash_content = splash_content.replace(
    "@Composable\nfun SplashScreen(",
    "@Composable\nfun WelcomeScreen("
)

# Add true SplashScreen
true_splash = """@Composable
fun SplashScreen(
    onTimeout: () -> Unit,
    modifier: Modifier = Modifier
) {
    LaunchedEffect(Unit) {
        delay(2000) // 2 seconds splash
        onTimeout()
    }
    
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Image(
            painter = androidx.compose.ui.res.painterResource(id = com.example.R.drawable.splash),
            contentDescription = "Splash Illustration",
            modifier = Modifier.fillMaxWidth(0.6f),
            contentScale = androidx.compose.ui.layout.ContentScale.Fit
        )
    }
}

"""

splash_content = splash_content.replace(
    "import com.example.ui.viewmodel.JournalViewModel\n\n@Composable",
    "import com.example.ui.viewmodel.JournalViewModel\n\n" + true_splash + "@Composable"
)

# Remove splash from WelcomeScreen since it's now in the true splash
welcome_splash_box = """            // Calming Illustration
            Box(
                modifier = Modifier
                    .size(240.dp),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = androidx.compose.ui.res.painterResource(id = com.example.R.drawable.splash),
                    contentDescription = "Splash Illustration",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = androidx.compose.ui.layout.ContentScale.Fit
                )
            }

            Spacer(modifier = Modifier.height(48.dp))"""

splash_content = splash_content.replace(welcome_splash_box, "")

with open("ui/screens/auth/SplashScreen.kt", "w") as f:
    f.write(splash_content)

print("Files updated.")
