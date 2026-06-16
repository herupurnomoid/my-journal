import re

with open("CreateJournalScreen.kt", "r") as f:
    content = f.read()

# 1. Replace the old Formatting Toolbar
old_toolbar_regex = r"// Formatting Toolbar\s+Card\(.*?elevation = CardDefaults\.cardElevation\(0\.dp\)\n\s+\)\s+\{.*?\}\n\s+\}"

new_toolbar = """// Formatting Toolbar
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)),
                elevation = CardDefaults.cardElevation(0.dp)
            ) {
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val rState = activeTextBlock?.state

                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontWeight = FontWeight.Bold)) }) { Icon(Icons.Default.FormatBold, "Bold", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontStyle = androidx.compose.ui.text.font.FontStyle.Italic)) }) { Icon(Icons.Default.FormatItalic, "Italic", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(textDecoration = TextDecoration.Underline)) }) { Icon(Icons.Default.FormatUnderlined, "Underline", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(textDecoration = TextDecoration.LineThrough)) }) { Icon(Icons.Default.FormatStrikethrough, "Strikethrough", tint = Color.DarkGray) } }
                    
                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }

                    item { IconButton(onClick = { rState?.toggleParagraphStyle(androidx.compose.ui.text.ParagraphStyle(textAlign = TextAlign.Left)) }) { Icon(Icons.Default.FormatAlignLeft, "Align Left", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleParagraphStyle(androidx.compose.ui.text.ParagraphStyle(textAlign = TextAlign.Center)) }) { Icon(Icons.Default.FormatAlignCenter, "Align Center", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleParagraphStyle(androidx.compose.ui.text.ParagraphStyle(textAlign = TextAlign.Right)) }) { Icon(Icons.Default.FormatAlignRight, "Align Right", tint = Color.DarkGray) } }

                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }

                    item { IconButton(onClick = { rState?.toggleUnorderedList() }) { Icon(Icons.Default.FormatListBulleted, "Bullets", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleOrderedList() }) { Icon(Icons.Default.FormatListNumbered, "Numbers", tint = Color.DarkGray) } }

                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontSize = 24.sp, fontWeight = FontWeight.Bold)) }) { Text("H1", fontWeight = FontWeight.Bold, color = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontSize = 20.sp, fontWeight = FontWeight.Bold)) }) { Text("H2", fontWeight = FontWeight.Bold, color = Color.DarkGray) } }
                    
                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }

                    item { 
                        IconButton(onClick = { 
                            val insertIdx = activeBlockIndex + 1
                            blocks.add(insertIdx, JournalBlock.ImageBlock("mock_taman"))
                            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
                            activeBlockIndex = insertIdx + 1
                        }) { Icon(Icons.Default.Image, "Insert Image", tint = MaterialTheme.colorScheme.primary) } 
                    }
                    item { 
                        IconButton(onClick = { 
                            val insertIdx = activeBlockIndex + 1
                            blocks.add(insertIdx, JournalBlock.ChecklistBlock())
                            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
                            activeBlockIndex = insertIdx + 1
                        }) { Icon(Icons.Default.CheckBox, "Insert Checklist", tint = MaterialTheme.colorScheme.primary) } 
                    }
                    item { 
                        IconButton(onClick = { 
                            val insertIdx = activeBlockIndex + 1
                            blocks.add(insertIdx, JournalBlock.DividerBlock())
                            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
                            activeBlockIndex = insertIdx + 1
                        }) { Icon(Icons.Default.HorizontalRule, "Insert Divider", tint = MaterialTheme.colorScheme.primary) } 
                    }
                }
            }"""

content = re.sub(old_toolbar_regex, new_toolbar, content, flags=re.DOTALL)

# 2. Add block rendering for Checklist and Divider
old_blocks_regex = r"(is JournalBlock\.ImageBlock -> \{.*?\n\s+\})\n(\s+)\}"
new_blocks = r"""\1
\2is JournalBlock.DividerBlock -> {
\2    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
\2        Divider(color = MaterialTheme.colorScheme.outlineVariant)
\2        IconButton(
\2            onClick = { blocks.removeAt(index) },
\2            modifier = Modifier.align(Alignment.TopEnd).size(24.dp)
\2        ) {
\2            Icon(Icons.Default.Clear, "Remove", tint = Color.Gray)
\2        }
\2    }
\2}
\2is JournalBlock.ChecklistBlock -> {
\2    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
\2        Checkbox(checked = block.isChecked, onCheckedChange = { 
\2            blocks[index] = block.copy(isChecked = it)
\2        })
\2        OutlinedTextField(
\2            value = block.text,
\2            onValueChange = { 
\2                blocks[index] = block.copy(text = it)
\2            },
\2            modifier = Modifier.fillMaxWidth().weight(1f),
\2            colors = OutlinedTextFieldDefaults.colors(
\2                focusedBorderColor = Color.Transparent,
\2                unfocusedBorderColor = Color.Transparent
\2            ),
\2            textStyle = MaterialTheme.typography.bodyLarge.copy(
\2                textDecoration = if (block.isChecked) TextDecoration.LineThrough else TextDecoration.None
\2            ),
\2            placeholder = { Text("Tugas...") },
\2            trailingIcon = {
\2                IconButton(onClick = { blocks.removeAt(index) }) {
\2                    Icon(Icons.Default.Clear, "Remove", tint = Color.Gray)
\2                }
\2            }
\2        )
\2    }
\2}
\2}"""
content = re.sub(old_blocks_regex, new_blocks, content, flags=re.DOTALL)

# 3. Remove Floating Toolbar and Photo Tray
remove_regex = r"// Floating Vertical Toolbar.*?Spacer\(modifier = Modifier\.height\(24\.dp\)\)"
content = re.sub(remove_regex, "Spacer(modifier = Modifier.height(24.dp))", content, flags=re.DOTALL)

with open("CreateJournalScreen.kt", "w") as f:
    f.write(content)
