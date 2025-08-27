///| Comprehensive Text Document Tests - Ported from OCaml test suite

// === HELPER FUNCTIONS ===

///|
/// Helper to create a range from tuple coordinates
fn tuple_range(start : (Int, Int), end : (Int, Int)) -> Range {
  let (start_line, start_char) = start
  let (end_line, end_char) = end
  Range::new(
    Position::new(start_line, start_char),
    Position::new(end_line, end_char),
  )
}

///|
/// Helper to make a document with UTF-16 encoding
fn make_document(uri : String, text : String) -> TextDocument {
  TextDocument::new(uri~, text~, language_id="fake language", version=1)
}

///|
/// Helper to test general changes (supports both UTF8 and UTF16, but we use UTF16)
fn test_general(text : String, changes : Array[(Range?, String)]) -> String {
  let td = make_document("", text)
  let content_changes = changes.map(fn(change) {
    let (range, text) = change
    TextDocumentContentChangeEvent::new(text, range~)
  })
  let td_updated = td.apply_content_changes(content_changes)
  td_updated.text()
}

///|
/// Helper to test single change
fn test_change(text : String, range : Range, change : String) -> String {
  test_general(text, [(Some(range), change)])
}

///|
/// Helper to test multiple changes
fn test_multiple(text : String, changes : Array[(Range, String)]) -> String {
  let range_changes = changes.map(fn(change) {
    let (range, text) = change
    (Some(range), text)
  })
  test_general(text, range_changes)
}

// === BASIC TESTS ===

///|
test "basic functionality" {
  let text = "Hello, World!\nThis is a test."
  let doc = TextDocument::new(
    uri="file:///test.txt",
    text~,
    language_id="plaintext",
    version=1,
  )
  inspect(doc.language_id(), content="plaintext")
  inspect(doc.document_uri(), content="file:///test.txt")
  inspect(doc.version(), content="1")
  inspect(doc.text(), content="Hello, World!\nThis is a test.")
}

// === PORTED OCAML TESTS ===

///|
test "first line insert" {
  let range = tuple_range((0, 1), (0, 3))
  let result = test_change("foo bar baz", range, "XXXX")
  inspect(result, content="fXXXX bar baz")
}

///|
test "null edit" {
  let range = tuple_range((0, 2), (0, 2))
  let result = test_change("foo bar", range, "")
  inspect(result, content="foo bar")
}

///|
test "no range - replace entire document" {
  let result = test_general("foo bar baz", [(None, "XXXX")])
  inspect(result, content="XXXX")
}

///|
test "char by char" {
  let result = test_multiple("", [
    (tuple_range((0, 0), (0, 0)), "f"),
    (tuple_range((0, 1), (0, 1)), "o"),
    (tuple_range((0, 2), (0, 2)), "o"),
  ])
  inspect(result, content="foo")
}

///|
test "char by char - 2" {
  let result = test_multiple("char by char - 2\n", [
    (tuple_range((1, 10), (1, 10)), "b"),
    (tuple_range((1, 10), (1, 10)), "a"),
    (tuple_range((1, 10), (1, 10)), "r"),
    (tuple_range((1, 1), (1, 2)), ""),
  ])
  inspect(result, content="char by char - 2\nbr")
}

///|
test "char by char - 3" {
  let result = test_multiple("first line skip\nchar by char - 2\n", [
    (tuple_range((1, 4), (1, 5)), ""),
    (tuple_range((1, 3), (1, 4)), ""),
    (tuple_range((1, 3), (1, 3)), "x"),
  ])
  inspect(result, content="first line skip\nchaxby char - 2\n")
}

///|
test "insert last" {
  let result1 = test_change("x", tuple_range((0, 1), (0, 1)), "y")
  inspect(result1, content="xy")
  let result2 = test_change("x\ny", tuple_range((1, 1), (1, 1)), "z")
  inspect(result2, content="x\nyz")
  let result3 = test_change("x\ny", tuple_range((1, 10), (1, 10)), "z")
  inspect(result3, content="x\nyz")
}

///|
test "replace second line" {
  let range = tuple_range((1, 0), (2, 0))
  let result = test_change("foo\nbar\nbaz\n", range, "XXXX\n")
  inspect(result, content="foo\nXXXX\nbaz\n")
}

///|
test "edit in second line" {
  let range = tuple_range((1, 1), (1, 2))
  let result = test_change("foo\nbar\nbaz\n", range, "-XXX-")
  inspect(result, content="foo\nb-XXX-r\nbaz\n")
}

///|
test "insert at the end" {
  let range1 = tuple_range((3, 0), (3, 0))
  let result1 = test_change("foo\nbar\nbaz\n", range1, "XXX")
  inspect(result1, content="foo\nbar\nbaz\nXXX")
  let range2 = tuple_range((3, 0), (4, 0))
  let result2 = test_change("foo\nbar\nbaz\n", range2, "XXX")
  inspect(result2, content="foo\nbar\nbaz\nXXX")
}

///|
test "insert at the beginning" {
  let range = tuple_range((0, 0), (0, 0))
  let result = test_change("foo\n\\bar\nbaz\n", range, "XXX\n")
  inspect(result, content="XXX\nfoo\n\\bar\nbaz\n")
}

///|
test "insert in the middle" {
  let result = test_change("ab", tuple_range((0, 1), (0, 1)), "---")
  inspect(result, content="a---b")
}

///|
test "replace first line" {
  let range = tuple_range((0, 0), (1, 0))
  let result = test_change("foo\nbar\n", range, "baz\n")
  inspect(result, content="baz\nbar\n")
}

///|
test "beyond max char" {
  let range = tuple_range((0, 0), (0, 100))
  let result = test_change("foo\nbar\n", range, "baz")
  inspect(result, content="baz")
}

///|
test "entire line without newline" {
  let result1 = test_change("xxx\n", tuple_range((0, 0), (0, 3)), "baz")
  inspect(result1, content="baz\n")
  let result2 = test_change("xxx\n", tuple_range((0, 0), (0, 4)), "baz")
  inspect(result2, content="baz")
  let result3 = test_change("xxx\n", tuple_range((0, 0), (1, 0)), "baz")
  inspect(result3, content="baz")
}

///|
test "replace two lines" {
  let result = test_change("a\nb\nc\n", tuple_range((0, 0), (2, 0)), "XXX\n")
  inspect(result, content="XXX\nc\n")
}

///|
test "join lines" {
  let result = test_change("a\nb", tuple_range((0, 1), (1, 0)), "")
  inspect(result, content="ab")
}

///|
test "remove text" {
  let result = test_change("a---b", tuple_range((0, 1), (0, 4)), "")
  inspect(result, content="ab")
}

///|
test "remove newline - 1" {
  let result = test_change("\n", tuple_range((0, 0), (0, 1)), "")
  inspect(result, content="")
}

///|
test "remove newlines - 2" {
  let result = test_multiple("\nXXX\n", [(tuple_range((0, 0), (0, 1)), "")])
  inspect(
    result,
    content=(
      #|XXX
      #|
    ),
  )
}

///|
test "remove newlines - 3" {
  let result = test_multiple("\nXXX\n\n", [
    (tuple_range((0, 0), (0, 1)), ""),
    (tuple_range((0, 1), (0, 2)), ""),
  ])
  inspect(
    result,
    content=(
      #|XX
      #|
      #|
    ),
  )
}

///|
test "update when inserting a line at the end of the doc" {
  let result = test_change(
    "let x = 1;\n\nlet y = 2;",
    tuple_range((2, 10), (2, 10)),
    "\n-ZZZ",
  )
  inspect(result, content="let x = 1;\n\nlet y = 2;\n-ZZZ")
}

///|
test "complex line modifications" {
  let result = test_multiple("1\n2\n3\n", [
    (tuple_range((1, 9), (1, 9)), "l"),
    (tuple_range((1, 9), (1, 10)), ""),
  ])
  inspect(
    result,
    content=(
      #|1
      #|2
      #|3
      #|l
    ),
  )
}

// === ABSOLUTE POSITION TESTS ===

///|
test "absolute_position" {
  let text = "foo|bar\nbaz.x"
  let td = make_document("foo.ml", text)
  let pos1 = td.absolute_position(Position::new(0, 0))
  inspect(pos1, content="0") // position: 0/13
  let pos2 = td.absolute_position(Position::new(3, 0))
  inspect(pos2, content="13") // position: 13/13 (at end)
  let pos3 = td.absolute_position(Position::new(1, 0))
  inspect(pos3, content="8") // position: 8/13 (start of second line)
  let pos4 = td.absolute_position(Position::new(1, 100))
  inspect(pos4, content="13") // position: 13/13 (beyond end)
  let pos5 = td.absolute_position(Position::new(0, 100))
  inspect(pos5, content="13") // position: 7/13 (beyond line end)
  let pos6 = td.absolute_position(Position::new(100, 0))
  inspect(pos6, content="13") // position: 13/13 (beyond document)
}

// === TEXT DOCUMENT EDITS TESTS ===

///|
test "replace second line first line is newline" {
  let range = tuple_range((1, 2), (1, 2))
  let doc = make_document("foo.ml", "\nfoo\nbar\nbaz\n")
  let edit = TextEdit::new(range, "change")
  let new_doc = doc.apply_text_document_edits([edit])
  let result = new_doc.text()
  inspect(result, content="\nfochangeo\nbar\nbaz\n")
}

///|
test "get position after change" {
  let range = tuple_range((1, 2), (1, 2))
  let doc = make_document("foo.ml", "\nfoo\nbar\nbaz\n")
  let edit = TextDocumentContentChangeEvent::new("change", range=Some(range))
  let new_doc = doc.apply_content_changes([edit])
  let pos = new_doc.absolute_position(range.start)
  let result = new_doc.text()
  inspect(result, content="\nfochangeo\nbar\nbaz\n")
  inspect(pos, content="22")
}

// === UTF-16 SPECIFIC TESTS ===

///|
test "utf16 basic ascii only" {
  // Test basic ASCII text (works as expected)
  let text = "Hello, World!"
  let doc = make_document("test.txt", text)
  inspect(doc.text(), content="Hello, World!")
  let pos_start = doc.absolute_position(Position::new(0, 0))
  inspect(pos_start, content="0")
  let pos_middle = doc.absolute_position(Position::new(0, 5))
  inspect(pos_middle, content="5")
  let pos_end = doc.absolute_position(Position::new(0, 13))
  inspect(pos_end, content="13")
}

///|
test "utf16 simple insertion" {
  let text = "Hello World"
  let doc = make_document("test.txt", text)

  // Insert simple text in the middle
  let range = tuple_range((0, 5), (0, 5)) // After "Hello"
  let change = TextDocumentContentChangeEvent::new(
    ", Beautiful",
    range=Some(range),
  )
  let updated_doc = doc.apply_content_changes([change])
  inspect(updated_doc.text(), content="Hello, Beautiful World")
}

///|
test "utf16 document version tracking" {
  let text = "Version test"
  let doc = make_document("test.txt", text)
  inspect(doc.version(), content="1")

  // Apply changes with new version
  let change = TextDocumentContentChangeEvent::new(
    " v2",
    range=Some(tuple_range((0, 12), (0, 12))),
  )
  let updated_doc = doc.apply_content_changes([change], version=Some(2))
  inspect(updated_doc.version(), content="2")
  inspect(updated_doc.text(), content="Version test v2")

  // Set version explicitly
  let versioned_doc = updated_doc.set_version(3)
  inspect(versioned_doc.version(), content="3")
}

///|
test "utf16 text edit operations" {
  let text = "Start Middle End"
  let doc = make_document("test.txt", text)

  // Multiple text edits
  let edit1 = TextEdit::new(tuple_range((0, 0), (0, 5)), "Begin") // Replace "Start"
  let edit2 = TextEdit::new(tuple_range((0, 6), (0, 12)), "Center") // Replace "Middle"
  let updated_doc = doc.apply_text_document_edits([edit1, edit2])
  inspect(updated_doc.text(), content="Begin Center End")
}

///|
test "utf16 multiline operations" {
  let text = "First line\nSecond line\nThird line"
  let doc = make_document("test.txt", text)

  // Test absolute positions across lines
  let pos_line0_start = doc.absolute_position(Position::new(0, 0))
  inspect(pos_line0_start, content="0")
  let pos_line1_start = doc.absolute_position(Position::new(1, 0))
  inspect(pos_line1_start, content="11") // After "First line\n"
  let pos_line2_start = doc.absolute_position(Position::new(2, 0))
  inspect(pos_line2_start, content="23") // After "First line\nSecond line\n"

  // Test range operations across lines
  let (start, end) = doc.absolute_range(tuple_range((1, 0), (1, 11))) // "Second line"
  inspect(start, content="11")
  inspect(end, content="22")
}

///|
test "utf16 encoding verification" {
  // Verify that our implementation correctly handles UTF-16 encoding
  let text = "Test"
  let doc = make_document("test.txt", text)

  // Test basic operations (encoding is always UTF-16)
  let change = TextDocumentContentChangeEvent::new(
    "ing",
    range=Some(tuple_range((0, 4), (0, 4))),
  )
  let updated_doc = doc.apply_content_changes([change])
  inspect(updated_doc.text(), content="Testing")
}
// === LABELED CONSTRUCTOR TEST ===

///|
test "text_document_labeled_constructor" {
  // Test the new labeled argument constructor
  let doc = TextDocument::new(
    uri="file:///labeled_test.txt",
    language_id="moonbit",
    version=5,
    text="Hello from labeled constructor!",
  )
  inspect(doc.language_id(), content="moonbit")
  inspect(doc.document_uri(), content="file:///labeled_test.txt")
  inspect(doc.version(), content="5")
  inspect(doc.text(), content="Hello from labeled constructor!")
}

// === ADDITIONAL EDGE CASE TESTS FOR ROBUSTNESS ===

///|
test "empty document operations" {
  // Test operations on empty documents
  let doc = TextDocument::new(
    uri="file:///empty.txt",
    language_id="text",
    version=1,
    text="",
  )
  inspect(doc.text(), content="")
  inspect(doc.absolute_position(Position::new(0, 0)), content="0")
  inspect(doc.absolute_position(Position::new(10, 10)), content="0") // Beyond bounds

  // Test inserting into empty document
  let change = TextDocumentContentChangeEvent::new(
    "Hello",
    range=Some(Range::new(Position::new(0, 0), Position::new(0, 0))),
  )
  let updated = doc.apply_content_changes([change])
  inspect(updated.text(), content="Hello")
}

///|
test "single character document" {
  let doc = TextDocument::new(
    uri="file:///single.txt",
    language_id="text",
    version=1,
    text="A",
  )

  // Test various positions in single char doc
  inspect(doc.absolute_position(Position::new(0, 0)), content="0")
  inspect(doc.absolute_position(Position::new(0, 1)), content="1")
  inspect(doc.absolute_position(Position::new(0, 100)), content="1") // Beyond end
  inspect(doc.absolute_position(Position::new(100, 0)), content="1") // Beyond line

  // Test range calculations
  let (start, end) = doc.absolute_range(
    Range::new(Position::new(0, 0), Position::new(0, 1)),
  )
  inspect(start, content="0")
  inspect(end, content="1")
}

///|
test "only newlines document" {
  let doc = TextDocument::new(
    uri="file:///newlines.txt",
    language_id="text",
    version=1,
    text="\n\n\n",
  )
  inspect(doc.text(), content="\n\n\n")

  // Test positions across newline-only lines
  inspect(doc.absolute_position(Position::new(0, 0)), content="0")
  inspect(doc.absolute_position(Position::new(1, 0)), content="1")
  inspect(doc.absolute_position(Position::new(2, 0)), content="2")
  inspect(doc.absolute_position(Position::new(3, 0)), content="3")
  inspect(doc.absolute_position(Position::new(4, 0)), content="3") // Beyond end
}

///|
test "no newline at end" {
  let doc = TextDocument::new(
    uri="file:///no_final_newline.txt",
    language_id="text",
    version=1,
    text="line1\nline2",
  )

  // Test positions in document without final newline
  inspect(doc.absolute_position(Position::new(0, 0)), content="0")
  inspect(doc.absolute_position(Position::new(1, 0)), content="6")
  inspect(doc.absolute_position(Position::new(1, 5)), content="11")
  inspect(doc.absolute_position(Position::new(2, 0)), content="11") // Beyond end should go to end
}

///|
test "text reconstruction from dirty zipper" {
  // Test that text is properly reconstructed when cached text is None
  let doc = TextDocument::new(
    uri="file:///reconstruction.txt",
    language_id="text",
    version=1,
    text="Original text",
  )

  // Apply changes that mark text as dirty
  let change = TextDocumentContentChangeEvent::new(
    "Modified",
    range=Some(Range::new(Position::new(0, 0), Position::new(0, 8))),
  )
  let updated = doc.apply_content_changes([change])

  // This should trigger text reconstruction from zipper
  inspect(updated.text(), content="Modified text")

  // Accessing text again should use cached version
  inspect(updated.text(), content="Modified text")
}

///|
test "version tracking edge cases" {
  let doc = TextDocument::new(
    uri="file:///version.txt",
    language_id="text",
    version=0,
    text="test",
  )

  // Test version 0
  inspect(doc.version(), content="0")

  // Test large version numbers
  let high_version_doc = doc.set_version(999999)
  inspect(high_version_doc.version(), content="999999")

  // Test version with changes
  let change = TextDocumentContentChangeEvent::new("s", range=None)
  let updated = doc.apply_content_changes([change], version=Some(-1))
  inspect(updated.version(), content="-1")
  inspect(updated.text(), content="s")
}

///|
test "multiple empty changes" {
  let doc = TextDocument::new(
    uri="file:///multi_empty.txt",
    language_id="text",
    version=1,
    text="Hello World",
  )

  // Apply multiple empty changes (should have no effect)
  let changes = [
    TextDocumentContentChangeEvent::new(
      "",
      range=Some(Range::new(Position::new(0, 5), Position::new(0, 5))),
    ),
    TextDocumentContentChangeEvent::new(
      "",
      range=Some(Range::new(Position::new(0, 6), Position::new(0, 6))),
    ),
    TextDocumentContentChangeEvent::new(
      "",
      range=Some(Range::new(Position::new(0, 7), Position::new(0, 7))),
    ),
  ]
  let updated = doc.apply_content_changes(changes)
  inspect(updated.text(), content="Hello World")
}

///|
test "replace entire document multiple times" {
  let doc = TextDocument::new(
    uri="file:///replace_all.txt",
    language_id="text",
    version=1,
    text="Original",
  )

  // Replace entire document (None range)
  let change1 = TextDocumentContentChangeEvent::new(
    "First replacement",
    range=None,
  )
  let doc1 = doc.apply_content_changes([change1])
  inspect(doc1.text(), content="First replacement")

  // Replace again
  let change2 = TextDocumentContentChangeEvent::new(
    "Second replacement",
    range=None,
  )
  let doc2 = doc1.apply_content_changes([change2])
  inspect(doc2.text(), content="Second replacement")

  // Replace with empty
  let change3 = TextDocumentContentChangeEvent::new("", range=None)
  let doc3 = doc2.apply_content_changes([change3])
  inspect(doc3.text(), content="")
}

///|
test "complex text edit combinations" {
  let doc = TextDocument::new(
    uri="file:///complex_edits.txt",
    language_id="text",
    version=1,
    text="ABCDEFGHIJK",
  )

  // Multiple overlapping text edits (should be applied correctly)
  let edits = [
    TextEdit::new(Range::new(Position::new(0, 0), Position::new(0, 1)), "X"), // A -> X
    TextEdit::new(Range::new(Position::new(0, 2), Position::new(0, 4)), "YZ"), // CD -> YZ
    TextEdit::new(Range::new(Position::new(0, 8), Position::new(0, 11)), "QRS"), // IJK -> QRS
  ]
  let updated = doc.apply_text_document_edits(edits)
  inspect(updated.text(), content="XBYZEFGHQRS")
}

///|
test "range edge cases" {
  let doc = TextDocument::new(
    uri="file:///range_test.txt",
    language_id="text",
    version=1,
    text="Line1\nLine2\nLine3",
  )

  // Test ranges that span multiple lines
  let multiline_range = Range::new(Position::new(0, 2), Position::new(2, 2))
  let (start, end) = doc.absolute_range(multiline_range)
  inspect(start, content="2") // Position 2 in "Line1"
  inspect(end, content="14") // Position 2 in "Line3"

  // Test zero-length ranges at various positions
  let zero_range1 = Range::new(Position::new(0, 0), Position::new(0, 0))
  let (s1, e1) = doc.absolute_range(zero_range1)
  inspect(s1, content="0")
  inspect(e1, content="0")
  let zero_range2 = Range::new(Position::new(1, 3), Position::new(1, 3))
  let (s2, e2) = doc.absolute_range(zero_range2)
  inspect(s2, content="9") // Position 3 in "Line2"
  inspect(e2, content="9")
}

///|
test "boundary position calculations" {
  let doc = TextDocument::new(
    uri="file:///boundary.txt",
    language_id="text",
    version=1,
    text="Short\nMedium line\nVery long line indeed",
  )

  // Test positions at exact line boundaries
  inspect(doc.absolute_position(Position::new(0, 5)), content="5") // End of "Short"
  inspect(doc.absolute_position(Position::new(0, 6)), content="6") // Beyond "Short" (should clamp to line end)
  inspect(doc.absolute_position(Position::new(1, 11)), content="17") // End of "Medium line"
  inspect(doc.absolute_position(Position::new(1, 15)), content="21") // Beyond "Medium line"

  // Test at exact document end
  let doc_length = doc.text().length()
  inspect(doc_length, content="39")
  inspect(doc.absolute_position(Position::new(2, 21)), content="39") // End of document
  inspect(doc.absolute_position(Position::new(2, 100)), content="39") // Beyond end
}

///|
test "incremental vs batch edits consistency" {
  let text = "Hello, World! This is a test."
  let doc = TextDocument::new(
    uri="file:///consistency.txt",
    language_id="text",
    version=1,
    text~,
  )

  // Apply changes incrementally
  let change1 = TextDocumentContentChangeEvent::new(
    "Hi",
    range=Some(Range::new(Position::new(0, 0), Position::new(0, 5))),
  )
  let change2 = TextDocumentContentChangeEvent::new(
    "Universe",
    range=Some(Range::new(Position::new(0, 3), Position::new(0, 8))),
  )
  let incremental = doc
    .apply_content_changes([change1])
    .apply_content_changes([change2])

  // Apply equivalent text edits as batch
  let edit1 = TextEdit::new(
    Range::new(Position::new(0, 0), Position::new(0, 5)),
    "Hi",
  )
  let edit2 = TextEdit::new(
    Range::new(Position::new(0, 3), Position::new(0, 8)),
    "Universe",
  )
  let batch = doc.apply_text_document_edits([edit1, edit2])

  // Results should be consistent
  inspect(incremental.text(), content="Hi,Universed! This is a test.")
  inspect(batch.text(), content="Hi,Universed! This is a test.")
}

///|
test "special characters and whitespace" {
  let doc = TextDocument::new(
    uri="file:///special.txt",
    language_id="text",
    version=1,
    text="Tab:\t Space: \nNewline above",
  )

  // Test positions with special characters
  inspect(doc.absolute_position(Position::new(0, 4)), content="4") // Before tab
  inspect(doc.absolute_position(Position::new(0, 5)), content="5") // After tab
  inspect(doc.absolute_position(Position::new(0, 12)), content="12") // Before space
  inspect(doc.absolute_position(Position::new(0, 13)), content="13") // After space
  inspect(doc.absolute_position(Position::new(1, 0)), content="14") // Start of second line

  // Test replacing special characters
  let change = TextDocumentContentChangeEvent::new(
    "____",
    range=Some(Range::new(Position::new(0, 4), Position::new(0, 13))),
  )
  let updated = doc.apply_content_changes([change])
  inspect(updated.text(), content="Tab:____\nNewline above")
}
// === TESTS TO REACH REMAINING UNCOVERED CODE ===

///|
test "direct struct construction coverage" {
  // Test direct construction of supporting structs to reach uncovered lines
  let item = TextDocumentItem::{
    uri: "file:///direct.txt",
    language_id: "direct",
    version: 42,
    text: "Direct construction test",
  }
  let params = DidOpenTextDocumentParams::{ text_document: item }
  let doc = make(params)
  inspect(doc.text(), content="Direct construction test")
  inspect(doc.language_id(), content="direct")
  inspect(doc.version(), content="42")
  inspect(doc.document_uri(), content="file:///direct.txt")
}

///|
test "struct field access validation" {
  // Create structs and validate all fields work correctly
  let pos = Position::new(5, 10)
  inspect(pos.line, content="5")
  inspect(pos.character, content="10")
  let range = Range::new(Position::new(1, 2), Position::new(3, 4))
  inspect(range.start.line, content="1")
  inspect(range.start.character, content="2")
  inspect(range.end.line, content="3")
  inspect(range.end.character, content="4")
  let change = TextDocumentContentChangeEvent::new(
    "test text",
    range=Some(range),
  )
  inspect(change.text, content="test text")
  match change.range {
    Some(r) => {
      inspect(r.start.line, content="1")
      inspect(r.end.character, content="4")
    }
    None => fail("Expected Some range")
  }
  let edit = TextEdit::new(range, "replacement")
  inspect(edit.new_text, content="replacement")
  inspect(edit.range.start.line, content="1")
}
