class Interview {
  final int id;
  final String applyFor;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String interviewMode;
  final String? meetingLink;
  final String interviewDate;
  final String interviewTimeFrom;
  final String interviewTimeTo;
  final String status;
  final String? taskDescription;
  final List<String> taskFiles;
  final List<InterviewTaskFileUrl> taskFilesUrls;
  final String? taskUploadUrl;
  final AssignedUser? assignedUser;
  final List<FollowUp> followUps;

  Interview({
    required this.id,
    required this.applyFor,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.interviewMode,
    this.meetingLink,
    required this.interviewDate,
    required this.interviewTimeFrom,
    required this.interviewTimeTo,
    required this.status,
    this.taskDescription,
    this.taskFiles = const [],
    this.taskFilesUrls = const [],
    this.taskUploadUrl,
    this.assignedUser,
    this.followUps = const [],
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['id'] ?? 0,
      applyFor: json['apply_for'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'] ?? '',
      interviewMode: json['interview_mode'] ?? 'offline',
      meetingLink: json['meeting_link'],
      interviewDate: json['interview_date'] ?? '',
      interviewTimeFrom: json['interview_time_from'] ?? '',
      interviewTimeTo: json['interview_time_to'] ?? '',
      status: json['status'] ?? 'Pending',
      taskDescription: json['task_description'],
      taskFiles: json['task_files'] != null
          ? List<String>.from(json['task_files'])
          : [],
      taskFilesUrls: json['task_files_urls'] != null
          ? (json['task_files_urls'] as List)
              .map((e) => InterviewTaskFileUrl.fromJson(e))
              .toList()
          : [],
      taskUploadUrl: json['task_upload_url'],
      assignedUser: json['assigned_user'] != null
          ? AssignedUser.fromJson(json['assigned_user'])
          : null,
      followUps: json['follow_ups'] != null
          ? (json['follow_ups'] as List)
              .map((e) => FollowUp.fromJson(e))
              .toList()
          : [],
    );
  }
}

class InterviewTaskFileUrl {
  final String path;
  final String url;

  InterviewTaskFileUrl({required this.path, required this.url});

  factory InterviewTaskFileUrl.fromJson(Map<String, dynamic> json) {
    return InterviewTaskFileUrl(
      path: json['path'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class AssignedUser {
  final int id;
  final String name;

  AssignedUser({required this.id, required this.name});

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class FollowUp {
  final int id;
  final String followDate;
  final String title;
  final String? notes;

  FollowUp({
    required this.id,
    required this.followDate,
    required this.title,
    this.notes,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'] ?? 0,
      followDate: json['follow_date'] ?? '',
      title: json['title'] ?? '',
      notes: json['notes'],
    );
  }
}

class InterviewPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  InterviewPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory InterviewPagination.fromJson(Map<String, dynamic> json) {
    return InterviewPagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
    );
  }
}

class ReceivedTask {
  final int id;
  final String title;
  final String? message;
  final List<String> files;

  ReceivedTask({
    required this.id,
    required this.title,
    this.message,
    this.files = const [],
  });

  factory ReceivedTask.fromJson(Map<String, dynamic> json) {
    return ReceivedTask(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'],
      files: json['files'] != null ? List<String>.from(json['files']) : [],
    );
  }
}
