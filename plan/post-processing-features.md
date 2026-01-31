# TextHarvest Post-Processing Enhancement Plan

## Context

Based on experience building the PeerTalk book indexer, raw OCR output needs post-processing to be truly useful. The PeerTalk indexer achieved 100x speedup (O(1) lookup vs grepping 240K lines) by indexing 797 functions, 185 error codes, and 6 tables.

This plan outlines how to integrate similar capabilities into TextHarvest as generic, reusable features.

## Problem Statement

Current state:
- TextHarvest produces raw OCR text output
- Users must build custom tooling to make output searchable/navigable
- Common patterns (sections, tables, indexes) are rebuilt per-project

Desired state:
- TextHarvest produces structured, searchable output by default
- Generic post-processing handles common patterns
- Project-specific tools extend the base functionality

## Proposed Features

### 1. Section Markers (Phase 1 - Quick Win)
**Priority: HIGH** ⭐

Auto-detect and mark document structure during OCR:
- Chapter headers
- Section headers
- Table boundaries
- Appendix markers

**Implementation:**
- Add `post_processors/add_section_markers.sh`
- Configurable regex patterns in `textharvest.conf`
- Integrate with `pdf-ocr` command

**Benefit:** Makes documents navigable with simple grep commands

### 2. Quality Metrics (Phase 1 - Quick Win)
**Priority: MEDIUM** ⭐⭐

Detect and report OCR quality issues:
- Low confidence indicators (excessive ?)
- Formatting problems (broken tables)
- Truncation detection
- Language mismatches

**Implementation:**
- Add `post_processors/quality_check.sh`
- Integrate with existing validation patterns in `lib/common.sh`
- Show warnings in verbose mode (`-v`)

**Benefit:** Catch OCR problems early before wasting time on bad data

### 3. Generic Indexing (Phase 2 - Core Value)
**Priority: HIGHEST** ⭐⭐⭐

Build searchable indexes automatically:
- Line number mapping
- Term extraction (functions, error codes, etc.)
- Section/chapter index
- Document metadata

**Implementation:**
- Add `post_processors/build_index.py`
- Define standard JSON schema for indexes
- Auto-generate `*_index.json` alongside OCR output

**Benefit:** Every document becomes searchable by default, O(1) lookups

### 4. Table Extraction (Phase 3 - Advanced)
**Priority: MEDIUM-HIGH** ⭐⭐

Extract tables into structured format:
- Auto-detect table boundaries
- Extract content to JSON
- Handle common formatting issues

**Implementation:**
- Add `post_processors/extract_tables.py`
- Start simple: boundary detection + raw extraction
- Let domain-specific tools parse column structure

**Benefit:** Tables become queryable data instead of unstructured text

## Architecture

### Directory Structure
```
TextHarvest/
├── textharvest.sh
├── lib/
│   ├── common.sh
│   └── post_processing.sh         # NEW: Post-processing library
├── process_pdf_ocr.sh
├── post_processors/               # NEW: Modular post-processors
│   ├── add_section_markers.sh
│   ├── extract_tables.py
│   ├── build_index.py
│   └── quality_check.sh
└── config/
    └── default_patterns.conf      # NEW: Default detection patterns
```

### CLI Interface

**Integrated approach (recommended):**
```bash
./textharvest.sh pdf-ocr \
  --post-process sections,tables,index \
  --quality-check \
  -v
```

**Standalone post-processing:**
```bash
./textharvest.sh post-process \
  --input text_output/book.txt \
  --processors sections,tables,index
```

### Configuration Extension

Add to `textharvest.conf`:
```bash
# Post-processing settings
ENABLE_POST_PROCESSING=true
DEFAULT_PROCESSORS="sections,index"  # tables optional (slower)
BUILD_INDEX=true
QUALITY_CHECK=true

# Section marker patterns (customizable)
CHAPTER_PATTERN="^(Chapter|CHAPTER) [0-9]+"
TABLE_PATTERN="^Table [A-Z]-[0-9]+"
APPENDIX_PATTERN="^Appendix [A-Z]"

# Index settings
INDEX_MIN_TERM_LENGTH=3
INDEX_COMMON_WORDS="/usr/share/dict/stop-words"
```

### Output Structure

After OCR with post-processing:
```
text_output/
├── book.txt              # OCR output
├── book_sections.txt     # With section markers
├── book_index.json       # Searchable index
├── book_tables.json      # Extracted tables
└── book_metadata.json    # Quality metrics + stats
```

## Implementation Phases

### Phase 1: Quick Wins (Foundation)
**Goal:** Add immediate value with minimal complexity

1. Create `post_processors/` directory structure
2. Implement `add_section_markers.sh`
   - Configurable regex patterns
   - Dry-run support
   - Verbosity integration
3. Implement `quality_check.sh`
   - Common OCR issue detection
   - Integration with existing validation
4. Add `lib/post_processing.sh` library
   - Shared post-processing utilities
   - Pattern matching helpers
5. Update `textharvest.conf` with post-processing settings
6. Add tests for section markers and quality checks

**Deliverable:** Optional post-processing with `--post-process sections` flag

### Phase 2: Core Indexing (High Value)
**Goal:** Make all OCR output searchable by default

1. Implement `build_index.py`
   - Line number indexing
   - Term extraction
   - Section/structure mapping
2. Define JSON schema for indexes
3. Integrate with `pdf-ocr` command
4. Add `--build-index` flag
5. Update documentation with index usage examples
6. Add tests for index generation

**Deliverable:** Auto-generated indexes for all OCR output

### Phase 3: Advanced Features (Polish)
**Goal:** Handle complex structures

1. Implement `extract_tables.py`
   - Table boundary detection
   - Content extraction to JSON
   - Handle formatting edge cases
2. Add plugin architecture for custom processors
3. Performance optimization for large documents
4. Add parallel processing support
5. Add tests for table extraction

**Deliverable:** Full-featured post-processing pipeline

## Design Principles

1. **Modular & Optional**: All post-processors are optional and independently usable
2. **Configurable**: Patterns and settings customizable via config files
3. **Generic First**: Build generic features, let projects extend with domain logic
4. **Consistent**: Follow existing TextHarvest patterns (dry-run, verbosity, error handling)
5. **Cross-Platform**: Support both Linux and macOS
6. **Standards-Based**: Use standard formats (JSON) for indexes and metadata

## Integration with Existing Projects

### PeerTalk Example
```bash
# TextHarvest generates base indexes
./textharvest.sh pdf-ocr --post-process sections,index

# PeerTalk extends with domain-specific indexing
python3 tools/book_indexer/build_index.py \
  --base-index text_output/book_index.json \
  --add-interrupt-safety \
  --add-error-codes
```

### Benefits
- Generic infrastructure handled by TextHarvest
- Domain-specific knowledge in project tools
- No duplication across projects
- Standard index format enables reuse

## Open Questions

1. **Python Dependency**: Is adding Python acceptable for indexing features?
   - Alternative: Pure Bash (more complex, slower)

2. **Default Behavior**: Should post-processing be opt-in or opt-out?
   - Recommendation: Opt-in initially, consider default after validation

3. **Index Schema**: What should the standard JSON format look like?
   - Should it be compatible with existing tools (ripgrep JSON, etc.)?

4. **Performance**: How to handle very large documents (1000+ pages)?
   - Parallel processing?
   - Incremental indexing?

## Success Metrics

- **Usability**: Can find specific content 10x faster than grepping
- **Adoption**: Post-processing used on majority of OCR jobs
- **Reusability**: Index format works across multiple projects
- **Performance**: Post-processing adds <10% overhead to OCR time
- **Reliability**: Quality checks catch >80% of OCR issues

## Next Steps

1. Review and approve this plan
2. Implement Phase 1 (section markers + quality checks)
3. Validate with real OCR output
4. Gather feedback, iterate
5. Proceed to Phase 2 (indexing)

## References

- PeerTalk book indexer: Example of domain-specific implementation
- Original feedback: `peertalk_indexer_ideas.md` (captured insights)
- TextHarvest architecture: `CLAUDE.md` (consistency with existing patterns)
