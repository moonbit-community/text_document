///| Text Document Implementation for MoonBit
///
/// This module provides functionality for working with text documents,
/// applying edits, and tracking position changes. It's designed to be
/// compatible with Language Server Protocol (LSP) operations.

// Internal encoding is always UTF-16 for MoonBit strings

///|
/// Represents a position in a text document
pub struct Position {
  line : Int // 0-based line number
  character : Int // 0-based character offset within the line
}

///|
/// Creates a new Position
pub fn Position::new(line : Int, character : Int) -> Position {
  { line, character }
}

///|
/// Represents a range in a text document
pub struct Range {
  start : Position // The start position of the range
  end : Position // The end position of the range
}

///|
/// Creates a new Range
pub fn Range::new(start : Position, end : Position) -> Range {
  { start, end }
}

///|
/// Text document parameters for opening
pub(all) struct DidOpenTextDocumentParams {
  text_document : TextDocumentItem
}

///|
/// Text document item
pub(all) struct TextDocumentItem {
  uri : String // Document URI
  language_id : String // Programming language identifier
  version : Int // Document version number
  text : String // Document content
}

///|
/// Text content change event
pub struct TextDocumentContentChangeEvent {
  range : Range? // Range to change, None means replace entire document
  text : String // New text content
}

///|
/// Text edit operation
pub struct TextEdit {
  range : Range // Range to replace
  new_text : String // New text to insert
}

///|
/// Main text document structure (abstract - implementation details hidden)
pub struct TextDocument {
  priv language_id : String
  priv mut text : String? // Cached text content (None if dirty)
  priv uri : String // Document URI
  priv version : Int
  priv mut zipper : @string_zipper.StringZipper // Internal zipper for efficient edits
  // Position encoding is always UTF-16 for MoonBit strings
}

// === CONSTRUCTOR FUNCTIONS ===

///|
/// Creates a new TextDocumentContentChangeEvent
pub fn TextDocumentContentChangeEvent::new(
  text : String,
  range? : Range? = None,
) -> TextDocumentContentChangeEvent {
  { range, text }
}

///|
/// Creates a new TextEdit
pub fn TextEdit::new(range : Range, new_text : String) -> TextEdit {
  { range, new_text }
}

// === CORE API FUNCTIONS ===

///|
/// Creates a text document from DidOpenTextDocumentParams
/// Position encoding is always UTF-16 since MoonBit strings are UTF-16 encoded
pub fn make(params : DidOpenTextDocumentParams) -> TextDocument {
  let { text_document: { uri, language_id, version, text } } = params
  let zipper = @string_zipper.StringZipper::of_string(text)
  { language_id, text: Some(text), uri, version, zipper }
}

///|
/// Creates a text document using labeled arguments
/// Position encoding is always UTF-16 since MoonBit strings are UTF-16 encoded
pub fn TextDocument::new(
  uri~ : String,
  language_id~ : String,
  version~ : Int,
  text~ : String,
) -> TextDocument {
  let zipper = @string_zipper.StringZipper::of_string(text)
  { language_id, text: Some(text), uri, version, zipper }
}

///|
/// Gets the language ID of the document
pub fn TextDocument::language_id(self : TextDocument) -> String {
  self.language_id
}

///|
/// Gets the document URI
pub fn TextDocument::document_uri(self : TextDocument) -> String {
  self.uri
}

///|
/// Gets the document version
pub fn TextDocument::version(self : TextDocument) -> Int {
  self.version
}

///|
/// Gets the text content of the document
pub fn TextDocument::text(self : TextDocument) -> String {
  match self.text {
    Some(cached_text) => cached_text
    None => {
      // Need to reconstruct text from zipper
      let (new_zipper, reconstructed_text) = self.zipper.squash()
      self.text = Some(reconstructed_text)
      self.zipper = new_zipper
      reconstructed_text
    }
  }
}

///|
/// Sets the version of the document
pub fn TextDocument::set_version(
  self : TextDocument,
  version : Int,
) -> TextDocument {
  { ..self, version, }
}

// === INTERNAL HELPER FUNCTIONS ===

///|
/// Convert our public Position to string_zipper Position (internal helper)
fn to_sz_position(pos : Position) -> @string_zipper.Position {
  @string_zipper.Position::new(pos.line, pos.character)
}

///|
/// Convert our public Range to string_zipper Range (internal helper)
fn to_sz_range(range : Range) -> @string_zipper.Range {
  @string_zipper.Range::new(
    to_sz_position(range.start),
    to_sz_position(range.end),
  )
}

// === CONTENT CHANGE FUNCTIONS ===

///|
/// Apply a single content change to the zipper (internal helper)
fn apply_change(
  zipper : @string_zipper.StringZipper,
  change : TextDocumentContentChangeEvent,
) -> @string_zipper.StringZipper {
  match change.range {
    None =>
      // Replace entire document
      @string_zipper.StringZipper::of_string(change.text)
    Some(range) =>
      // Apply change to specific range
      zipper.apply_change(to_sz_range(range), replacement=change.text)
  }
}

///|
/// Apply a list of content changes to the document
pub fn TextDocument::apply_content_changes(
  self : TextDocument,
  changes : Array[TextDocumentContentChangeEvent],
  version? : Int? = None,
) -> TextDocument {
  // Apply changes sequentially to the zipper
  let mut new_zipper = self.zipper
  for change in changes {
    new_zipper = apply_change(new_zipper, change)
  }
  let new_version = match version {
    None => self.version
    Some(v) => v
  }
  {
    ..self,
    zipper: new_zipper,
    text: None, // Mark text as dirty since we've modified the zipper
    version: new_version,
  }
}

// === TEXT EDIT FUNCTIONS ===

///|
/// Apply a list of non-overlapping text edits to the document
/// The order of application matters when multiple inserts are done in the same position
/// All the offsets are interpreted relative to the original document
pub fn TextDocument::apply_text_document_edits(
  self : TextDocument,
  edits : Array[TextEdit],
) -> TextDocument {
  // Convert TextEdit list to content changes and apply them
  let changes = edits.map(fn(edit) {
    TextDocumentContentChangeEvent::{
      range: Some(edit.range),
      text: edit.new_text,
    }
  })
  let text_content = apply_changes_to_string(self.zipper, changes)
  let new_zipper = @string_zipper.StringZipper::of_string(text_content)
  { ..self, text: Some(text_content), zipper: new_zipper }
}

///|
/// Helper function to apply changes and get the resulting string (internal helper)
fn apply_changes_to_string(
  zipper : @string_zipper.StringZipper,
  changes : Array[TextDocumentContentChangeEvent],
) -> String {
  // Apply changes to a copy of the zipper
  let mut working_zipper = zipper
  for change in changes {
    working_zipper = apply_change(working_zipper, change)
  }

  // Get the final text
  let (_, text) = working_zipper.squash()
  text
}

// === POSITION FUNCTIONS ===

///|
/// Get the absolute position (offset) of a position in the document
/// If the position is outside the bounds of the document, 
/// the offset returned will be the length of the document
pub fn TextDocument::absolute_position(
  self : TextDocument,
  pos : Position,
) -> Int {
  let zipper = self.zipper.goto_position(to_sz_position(pos))
  zipper.offset()
}

///|
/// Get the absolute range (start_offset, end_offset) of a range in the document
/// Same as (absolute_position(range.start), absolute_position(range.end)) but possibly faster
pub fn TextDocument::absolute_range(
  self : TextDocument,
  range : Range,
) -> (Int, Int) {
  let start_zipper = self.zipper.goto_position(to_sz_position(range.start))
  let start_offset = start_zipper.offset()
  let end_zipper = start_zipper.goto_position(to_sz_position(range.end))
  let end_offset = end_zipper.offset()
  (start_offset, end_offset)
}
