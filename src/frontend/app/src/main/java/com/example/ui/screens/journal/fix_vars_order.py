import re

with open("CreateJournalScreen.kt", "r") as f:
    content = f.read()

# Remove the existing initialization of `blocks` and `activeBlockIndex`
blocks_pattern = re.compile(r"\s+// Block-based Editor State\n\s+val blocks = remember \{[\s\S]*?(?=\s+val currentBlocks by rememberUpdatedState\(blocks\.toList\(\)\))", re.MULTILINE)
blocks_match = blocks_pattern.search(content)

if blocks_match:
    blocks_code = blocks_match.group(0)
    content = content.replace(blocks_code, "")
    
    # We need to insert it back right after `val context = androidx.compose.ui.platform.LocalContext.current`
    context_pattern = r"(val context = androidx.compose.ui.platform.LocalContext.current\n)"
    content = re.sub(context_pattern, r"\1" + blocks_code, content)

with open("CreateJournalScreen.kt", "w") as f:
    f.write(content)
