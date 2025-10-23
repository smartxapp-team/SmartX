class UserProfile {
  final String fullName;
  final String rollNo;
  final String branch;
  final String yearSem;
  final String section;
  final String email;
  final String profilePicUrl;
  final String gender;
  final String batch;

  UserProfile({
    required this.fullName,
    required this.rollNo,
    required this.branch,
    required this.yearSem,
    required this.section,
    required this.email,
    required this.profilePicUrl,
    required this.gender,
    required this.batch,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] ?? 'N/A',
      rollNo: json['roll_no'] ?? 'N/A',
      branch: json['branch'] ?? 'N/A',
      yearSem: json['year_sem'] ?? 'N/A',
      section: json['section'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      profilePicUrl: json['profile_pic_url'] ?? '',
      gender: json['gender'] ?? 'N/A',
      batch: json['batch'] ?? 'N/A',
    );
  }
}

class AcademicInfo {
  final double classAttendance;
  final double bioAttendance;
  final double sgpa;
  final double cgpa;
  final List<SemesterGPA> semesterGpa;

  AcademicInfo({
    required this.classAttendance,
    required this.bioAttendance,
    required this.sgpa,
    required this.cgpa,
    required this.semesterGpa,
  });

  factory AcademicInfo.fromJson(Map<String, dynamic> json) {
    var gpaList = json['semester_gpa'] as List? ?? [];
    List<SemesterGPA> semesterGpaData = gpaList.map((i) => SemesterGPA.fromJson(i)).toList();

    return AcademicInfo(
      classAttendance: (json['class_attendance'] as num?)?.toDouble() ?? 0.0,
      bioAttendance: (json['bio_attendance'] as num?)?.toDouble() ?? 0.0,
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0.0,
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      semesterGpa: semesterGpaData,
    );
  }
}

class SemesterGPA {
  final int semester;
  final double gpa;

  SemesterGPA({required this.semester, required this.gpa});

  factory SemesterGPA.fromJson(Map<String, dynamic> json) {
    return SemesterGPA(
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
