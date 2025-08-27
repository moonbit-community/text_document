[![check](https://github.com/moonbit-community/text_document/actions/workflows/ci.yml/badge.svg)](https://github.com/moonbit-community/text_document/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/moonbit-community/text_document/badge.svg?branch=main)](https://coveralls.io/github/moonbit-community/text_document?branch=main)

# Text Document Library for MoonBit

A high-performance text document library for MoonBit that provides LSP-compatible text editing operations. This library is a port of the OCaml LSP text document implementation and is designed for production use in language servers and text editors.

## Features

- **LSP-Compatible**: Implements the Language Server Protocol text document interface
- **UTF-16 Encoding**: Native support for UTF-16 encoded strings (MoonBit default)
- **Efficient Edits**: Uses string zipper data structure for O(log n) edit operations
- **Position Tracking**: Accurate position and range calculations
- **Comprehensive Testing**: Extensive test suite covering edge cases

## Installation

Add this package to your MoonBit project:

```bash
moon add bzy-debug/text_document
```

Then import it in your `moon.pkg.json`:

```json
{
  "import": ["bzy-debug/text_document"]
}
```

## Quick Example

```moonbit
test "readme example" {
  // Create a text document using labeled constructor
  let doc = TextDocument::new(
    uri="file:///example.txt",
    language_id="moonbit", 
    version=1,
    text="Hello, World!"
  )
  
  // Apply a content change
  let range = Range::new(
    Position::new(0, 7), 
    Position::new(0, 12)
  )
  let change = TextDocumentContentChangeEvent::new("MoonBit", range=Some(range))
  let updated_doc = doc.apply_content_changes([change])
  
  inspect(updated_doc.text(), content="Hello, MoonBit!")
}
```

## API Overview

### Core Types

- `TextDocument` - Abstract document structure (implementation details hidden)
- `Position` - Line and character position
- `Range` - Range between two positions
- `TextDocumentItem` - Document metadata and content
- `DidOpenTextDocumentParams` - Parameters for opening a document
- `TextDocumentContentChangeEvent` - Incremental content change
- `TextEdit` - Text edit operation

### Key Functions

#### Document Creation
- `make(params)` - Create document from parameters
- `TextDocument::new(uri~, language_id~, version~, text~)` - Create document with labeled arguments

#### Document Properties  
- `text()` - Get document content
- `version()` - Get document version
- `language_id()` - Get language identifier
- `document_uri()` - Get document URI

#### Document Modification
- `apply_content_changes(changes, version?)` - Apply content changes
- `apply_text_document_edits(edits)` - Apply text edits
- `set_version(version)` - Update version

#### Position Operations
- `absolute_position(pos)` - Get absolute offset
- `absolute_range(range)` - Get absolute range offsets

#### Constructors
- `Position::new(line, character)` - Create position
- `Range::new(start, end)` - Create range
- `TextDocumentContentChangeEvent::new(text, range?)` - Create content change
- `TextEdit::new(range, new_text)` - Create text edit

## Performance

- Document creation: O(1)
- Text retrieval: O(1) cached, O(n) reconstruction
- Content changes: O(log n) per edit
- Position calculations: O(log n)

## UTF-16 Support

Designed for MoonBit's native UTF-16 strings:
- Positions in UTF-16 code units
- LSP protocol compatible
- Efficient Unicode handling

## Testing

Comprehensive test suite with **100% code coverage** included. The test suite contains **50 tests** covering:
- All basic document operations
- Multi-line text handling
- Edge cases (empty documents, boundary conditions)
- Position and range calculations
- Content change scenarios
- Version tracking
- UTF-16 encoding scenarios
- Error conditions and robustness

Run with:

```bash
moon test
```

## License

Apache-2.0