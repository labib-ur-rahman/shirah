/// Post Author Model - Author info embedded in post/comment documents
class PostAuthorModel {
  final String uid;
  final String name;
  final String photo;

  const PostAuthorModel({
    required this.uid,
    required this.name,
    required this.photo,
  });

  factory PostAuthorModel.empty() {
    return const PostAuthorModel(uid: '', name: '', photo: '');
  }

  factory PostAuthorModel.fromMap(Map<String, dynamic> data) {
    return PostAuthorModel(
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      photo: data['photo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'photo': photo};
  }
}
