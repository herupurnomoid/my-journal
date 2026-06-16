import re

with open("SettingsAndProfileScreen.kt", "r") as f:
    content = f.read()

# Replace TopAppBar with Custom Row in ProfileTab
topappbar_pattern = r"        TopAppBar\(\s+title = \{ Text\(\"Profil\", fontWeight = FontWeight\.Bold\) \},\s+actions = \{\s+IconButton\(onClick = onOpenSettings\) \{\s+Icon\(imageVector = Icons\.Default\.Settings, contentDescription = \"Pengaturan\"\)\s+\}\s+\},\s+colors = TopAppBarDefaults\.topAppBarColors\(containerColor = MaterialTheme\.colorScheme\.surface\)\s+\)"

custom_row = """        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Profil", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold))
            IconButton(onClick = onOpenSettings) {
                Icon(imageVector = Icons.Default.Settings, contentDescription = "Pengaturan")
            }
        }"""
content = re.sub(topappbar_pattern, custom_row, content)

# Remove @OptIn(ExperimentalMaterial3Api::class) from ProfileTab
content = content.replace("@OptIn(ExperimentalMaterial3Api::class)\n@Composable\nfun ProfileTab", "@Composable\nfun ProfileTab")

# Add LocalContext logic to ProfileTab for the export functions
content = content.replace("fun ProfileTab(viewModel: JournalViewModel, onOpenSettings: () -> Unit) {", "fun ProfileTab(viewModel: JournalViewModel, onOpenSettings: () -> Unit) {\n    val context = androidx.compose.ui.platform.LocalContext.current")

# Update Export Buttons
pdf_button = r"onClick = \{ exportToastText = \"Berhasil mengekspor catatan ke PDF\" \}"
pdf_button_new = """onClick = {
                            val success = viewModel.exportJournalsToPdf(context)
                            exportToastText = if (success) "Berhasil disimpan di folder Downloads/MyJurnal" else "Gagal mengekspor PDF"
                        }"""
content = content.replace(pdf_button, pdf_button_new)

md_button = r"onClick = \{ exportToastText = \"Berkas Markdown dibagikan!\" \}"
md_button_new = """onClick = {
                            val success = viewModel.exportJournalsToMarkdown(context)
                            exportToastText = if (success) "Berhasil disimpan di folder Downloads/MyJurnal" else "Gagal mengekspor Markdown"
                        }"""
content = content.replace(md_button, md_button_new)

with open("SettingsAndProfileScreen.kt", "w") as f:
    f.write(content)
