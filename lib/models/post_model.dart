class PostModel {
  final String id;
  final String content;
  final PostAuthor author;
  final List<PostMedia> media;
  final String visibility;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.content,
    required this.author,
    required this.media,
    required this.visibility,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? '',
      author: PostAuthor.fromJson(json['author'] ?? {}),
      media:
          (json['media'] as List<dynamic>?)
              ?.map((m) => PostMedia.fromJson(m))
              .toList() ??
          [],
      visibility: json['visibility'] ?? 'public',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author.toJson(),
      'media': media.map((m) => m.toJson()).toList(),
      'visibility': visibility,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? content,
    PostAuthor? author,
    List<PostMedia>? media,
    String? visibility,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      media: media ?? this.media,
      visibility: visibility ?? this.visibility,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}

// ✅ UPDATED: Added bio, experienceYears, degrees
class PostAuthor {
  final String id;
  final String fullName;
  final String? avatar;
  final String role;
  final String? specialty;
  final String? bio; // ✅ NEW
  final int? experienceYears; // ✅ NEW
  final List<Map<String, dynamic>>? degrees; // ✅ NEW

  PostAuthor({
    required this.id,
    required this.fullName,
    this.avatar,
    required this.role,
    this.specialty,
    this.bio, // ✅ NEW
    this.experienceYears, // ✅ NEW
    this.degrees, // ✅ NEW
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    String? avatarUrl;

    if (json['avatar'] != null) {
      if (json['avatar'] is Map) {
        avatarUrl = json['avatar']['url'];
      } else if (json['avatar'] is String) {
        avatarUrl = json['avatar'];
      }
    }

    avatarUrl ??=
        json['avatar_url'] ?? json['profile_image'] ?? json['profileImage'];

    // ✅ Parse degrees list
    List<Map<String, dynamic>>? degreesList;
    if (json['degrees'] != null && json['degrees'] is List) {
      degreesList = (json['degrees'] as List)
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    }

    return PostAuthor(
      id: json['_id'] ?? json['id'] ?? '',
      fullName:
          json['fullName'] ?? json['full_name'] ?? json['name'] ?? 'Unknown',
      avatar: avatarUrl,
      role: json['role'] ?? 'user',
      specialty: json['specialty'],
      bio: json['bio'], // ✅ NEW
      experienceYears: json['experienceYears'], // ✅ NEW
      degrees: degreesList, // ✅ NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'avatar': avatar,
      'role': role,
      'specialty': specialty,
      if (bio != null) 'bio': bio,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (degrees != null) 'degrees': degrees,
    };
  }
}

class PostMedia {
  final String publicId;
  final String url;
  final String resourceType;
  final String? format;
  final String? originalName;
  final String? mimeType;
  final int? size;
  final String? thumbnail;

  PostMedia({
    required this.publicId,
    required this.url,
    required this.resourceType,
    this.format,
    this.originalName,
    this.mimeType,
    this.size,
    this.thumbnail,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    String? thumbnailUrl;
    if (json['thumbnail'] != null) {
      if (json['thumbnail'] is Map) {
        thumbnailUrl = json['thumbnail']['url'];
      } else if (json['thumbnail'] is String) {
        thumbnailUrl = json['thumbnail'];
      }
    }

    return PostMedia(
      publicId: json['public_id'] ?? '',
      url: json['url'] ?? '',
      resourceType: json['resourceType'] ?? 'image',
      format: json['format'],
      originalName: json['originalName'],
      mimeType: json['mimeType'],
      size: json['size'],
      thumbnail: thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'url': url,
      'resourceType': resourceType,
      'format': format,
      'originalName': originalName,
      'mimeType': mimeType,
      'size': size,
      if (thumbnail != null) 'thumbnail': thumbnail,
    };
  }

  bool get isVideo =>
      resourceType == 'video' || mimeType?.contains('video') == true;
  bool get isImage =>
      resourceType == 'image' || mimeType?.contains('image') == true;
}

class PostComment {
  final String id;
  final String postId;
  final PostAuthor author;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['_id'] ?? json['id'] ?? '',
      postId: json['post'] ?? '',
      author: PostAuthor.fromJson(json['author'] ?? {}),
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['created_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}
