import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_mapper.dart';
import 'firestore_paths.dart';

class NoteRepositoryImpl implements NoteRepository {
  final FirestorePaths _paths;

  NoteRepositoryImpl(this._paths);

  @override
  Stream<List<Note>> watchNotes(String studentId) {
    return _paths
        .notes(studentId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(NoteMapper.fromDoc).toList());
  }

  @override
  Future<List<Note>> getNotes(String studentId, {int limit = 200}) async {
    final snap = await _paths
        .notes(studentId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(NoteMapper.fromDoc).toList();
  }

  @override
  Future<void> addNote(Note note) async {
    await _paths.notes(note.studentId).add(NoteMapper.toMap(note));
  }

  @override
  Future<void> deleteNote(String studentId, String noteId) async {
    await _paths.notes(studentId).doc(noteId).delete();
  }

  @override
  Future<void> setVisibility(
      String studentId, String noteId, bool visible) async {
    await _paths
        .notes(studentId)
        .doc(noteId)
        .update({'visibleToParent': visible});
  }
}
