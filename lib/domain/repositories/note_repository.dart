import '../entities/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchNotes(String studentId);
  Future<List<Note>> getNotes(String studentId, {int limit});
  Future<void> addNote(Note note);
  Future<void> deleteNote(String studentId, String noteId);
  Future<void> setVisibility(String studentId, String noteId, bool visible);
}
