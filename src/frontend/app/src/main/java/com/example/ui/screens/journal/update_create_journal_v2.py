import re

with open("CreateJournalScreen.kt", "r") as f:
    content = f.read()

# 1. Add imports
imports = """
import android.Manifest
import android.content.Context
import android.location.Geocoder
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.google.android.gms.location.LocationServices
import java.io.File
import java.util.Locale
"""
content = re.sub(r"(import androidx.compose.animation.\*)", r"\1" + "\n" + imports, content, count=1)

# 2. Add Geolocation fetching and permission state inside CreateJournalScreen
func_start = r"fun CreateJournalScreen\([^\{]+\{\n"
new_states = """    val context = androidx.compose.ui.platform.LocalContext.current
    var currentLocationName by remember { mutableStateOf(journalToEdit?.location ?: "Mencari lokasi...") }
    
    // Media Attachments
    var cameraTempUri by remember { mutableStateOf<Uri?>(null) }
    val galleryLauncher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            val insertIdx = (activeBlockIndex + 1).coerceIn(0, blocks.size)
            blocks.add(insertIdx, JournalBlock.ImageBlock(uri.toString()))
            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
            activeBlockIndex = insertIdx + 1
        }
    }
    
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && cameraTempUri != null) {
            val insertIdx = (activeBlockIndex + 1).coerceIn(0, blocks.size)
            blocks.add(insertIdx, JournalBlock.ImageBlock(cameraTempUri.toString()))
            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
            activeBlockIndex = insertIdx + 1
        }
    }

    var showMediaDropdown by remember { mutableStateOf(false) }

    // Location Permission & Fetch
    @OptIn(ExperimentalPermissionsApi::class)
    val locationPermissions = rememberMultiplePermissionsState(
        permissions = listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
    )

    LaunchedEffect(Unit) {
        if (!locationPermissions.allPermissionsGranted) {
            locationPermissions.launchMultiplePermissionRequest()
        }
    }

    LaunchedEffect(locationPermissions.allPermissionsGranted) {
        if (locationPermissions.allPermissionsGranted && journalToEdit == null) {
            try {
                val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
                fusedLocationClient.lastLocation.addOnSuccessListener { loc ->
                    if (loc != null) {
                        try {
                            val geocoder = Geocoder(context, Locale.getDefault())
                            val addresses = geocoder.getFromLocation(loc.latitude, loc.longitude, 1)
                            if (!addresses.isNullOrEmpty()) {
                                currentLocationName = "${addresses[0].subAdminArea ?: addresses[0].locality}, ${addresses[0].countryCode}"
                            } else {
                                currentLocationName = "Lokasi tidak diketahui"
                            }
                        } catch (e: Exception) {
                            currentLocationName = "GPS Aktif (${loc.latitude}, ${loc.longitude})"
                        }
                    } else {
                        currentLocationName = "Gagal membaca GPS"
                    }
                }
            } catch (e: SecurityException) {
                currentLocationName = "Akses lokasi ditolak"
            }
        }
    }
"""
content = re.sub(func_start, lambda m: m.group(0) + new_states, content)

# 3. Update hardcoded "Jakarta Selatan, ID" to currentLocationName
content = content.replace('location = "Jakarta Selatan, ID"', 'location = currentLocationName')
content = content.replace('text = "Jakarta Selatan, ID (GPS Akurat)"', 'text = currentLocationName')

# 4. Update the "Insert Image" icon in toolbar to open a Dropdown
old_image_icon = r"""                    item \{ \n\s+IconButton\(onClick = \{ \n\s+val insertIdx = \(activeBlockIndex \+ 1\).coerceIn\(0, blocks\.size\)\n\s+blocks\.add\(insertIdx, JournalBlock\.ImageBlock\("mock_taman"\)\)\n\s+blocks\.add\(insertIdx \+ 1, JournalBlock\.TextBlock\(com\.mohamedrejeb\.richeditor\.model\.RichTextState\(\)\)\)\n\s+activeBlockIndex = insertIdx \+ 1\n\s+\}\) \{ Icon\(Icons\.Default\.Image, "Insert Image", tint = MaterialTheme\.colorScheme\.primary\) \} \n\s+\}"""

new_image_icon = """                    item { 
                        Box {
                            IconButton(onClick = { showMediaDropdown = true }) { 
                                Icon(Icons.Default.Image, "Insert Image", tint = MaterialTheme.colorScheme.primary) 
                            }
                            DropdownMenu(
                                expanded = showMediaDropdown,
                                onDismissRequest = { showMediaDropdown = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text("Pilih dari Galeri") },
                                    leadingIcon = { Icon(Icons.Default.PhotoLibrary, "Gallery") },
                                    onClick = {
                                        showMediaDropdown = false
                                        galleryLauncher.launch(androidx.activity.result.PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                                    }
                                )
                                DropdownMenuItem(
                                    text = { Text("Buka Kamera") },
                                    leadingIcon = { Icon(Icons.Default.CameraAlt, "Camera") },
                                    onClick = {
                                        showMediaDropdown = false
                                        val imagePath = File(context.cacheDir, "images")
                                        imagePath.mkdirs()
                                        val tempFile = File.createTempFile("journal_cam_", ".jpg", imagePath)
                                        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", tempFile)
                                        cameraTempUri = uri
                                        cameraLauncher.launch(uri)
                                    }
                                )
                            }
                        }
                    }"""
content = re.sub(old_image_icon, new_image_icon, content)

with open("CreateJournalScreen.kt", "w") as f:
    f.write(content)
