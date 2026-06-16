import re

with open("JournalViewModel.kt", "r") as f:
    content = f.read()

export_functions = """    // Export Functions
    fun exportJournalsToMarkdown(context: android.content.Context): Boolean {
        return try {
            val journals = allJournals.value
            val mdContent = StringBuilder().apply {
                append("# Rekap Jurnal Kelas Reflektif\\n\\n")
                journals.forEach { journal ->
                    append("## ${journal.title}\\n")
                    val dateStr = java.text.SimpleDateFormat("dd MMM yyyy, HH:mm", java.util.Locale.getDefault()).format(java.util.Date(journal.createdAt))
                    append("**Waktu:** $dateStr | **Mood:** ${journal.userMood}\\n\\n")
                    append("${journal.content.replace("<!--BLOCK_DELIMITER-->", "\\n")}\\n\\n")
                    append("---\\n\\n")
                }
            }.toString()

            val fileName = "MyJournal_Export_${System.currentTimeMillis()}.md"
            val contentValues = android.content.ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "text/markdown")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS + "/MyJurnal")
                }
            }

            val uri = context.contentResolver.insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri != null) {
                context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(mdContent.toByteArray())
                }
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun exportJournalsToPdf(context: android.content.Context): Boolean {
        return try {
            val journals = allJournals.value
            val pdfDocument = android.graphics.pdf.PdfDocument()
            val pageInfo = android.graphics.pdf.PdfDocument.PageInfo.Builder(595, 842, 1).create() // A4 size
            var page = pdfDocument.startPage(pageInfo)
            var canvas = page.canvas

            val titlePaint = android.graphics.Paint().apply {
                textSize = 24f
                isFakeBoldText = true
                color = android.graphics.Color.BLACK
            }
            val textPaint = android.graphics.Paint().apply {
                textSize = 14f
                color = android.graphics.Color.DKGRAY
            }

            var yPosition = 60f
            canvas.drawText("Rekap Jurnal Kelas Reflektif", 40f, yPosition, titlePaint)
            yPosition += 40f

            for (journal in journals) {
                if (yPosition > 780f) {
                    pdfDocument.finishPage(page)
                    page = pdfDocument.startPage(pageInfo)
                    canvas = page.canvas
                    yPosition = 60f
                }
                
                canvas.drawText(journal.title, 40f, yPosition, titlePaint)
                yPosition += 20f
                val dateStr = java.text.SimpleDateFormat("dd MMM yyyy", java.util.Locale.getDefault()).format(java.util.Date(journal.createdAt))
                canvas.drawText("Waktu: $dateStr | Mood: ${journal.userMood}", 40f, yPosition, textPaint)
                yPosition += 25f
                
                // Simple text rendering (no wrap for simplicity, just excerpt)
                val excerptText = android.text.TextUtils.ellipsize(journal.content.replace(Regex("<.*?>|<!--.*?-->|IMAGE:.*|DIVIDER:"), " ").take(100), textPaint, 500f, android.text.TextUtils.TruncateAt.END).toString()
                canvas.drawText(excerptText, 40f, yPosition, textPaint)
                yPosition += 50f
            }

            pdfDocument.finishPage(page)

            val fileName = "MyJournal_Export_${System.currentTimeMillis()}.pdf"
            val contentValues = android.content.ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS + "/MyJurnal")
                }
            }

            val uri = context.contentResolver.insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri != null) {
                context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                    pdfDocument.writeTo(outputStream)
                }
                pdfDocument.close()
                true
            } else {
                pdfDocument.close()
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
"""

content = re.sub(r"\}\s*$", export_functions, content)

with open("JournalViewModel.kt", "w") as f:
    f.write(content)
