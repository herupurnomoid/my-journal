package com.example.ui.screens.journal

import java.util.UUID

sealed class JournalBlock(val id: String = UUID.randomUUID().toString()) {
    data class TextBlock(val state: com.mohamedrejeb.richeditor.model.RichTextState) : JournalBlock()
    data class ImageBlock(val uri: String) : JournalBlock()
    data class DividerBlock(val dummy: Boolean = true) : JournalBlock()
    data class ChecklistBlock(var text: String = "", var isChecked: Boolean = false) : JournalBlock()
}
