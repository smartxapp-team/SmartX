class Profile {
  final String fullName;
  final String rollNo;
  final String branch;
  final String yearSem;
  final String section;
  final String gender;
  final String email;
  final String batch;
  final String profilePicUrl;

  Profile({
    required this.fullName,
    required this.rollNo,
    required this.branch,
    required this.yearSem,
    required this.section,
    required this.gender,
    required this.email,
    required this.batch,
    required this.profilePicUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      fullName: json['full_name'] ?? 'N/A',
      rollNo: json['roll_no'] ?? 'N/A',
      branch: json['branch'] ?? 'N/A',
      yearSem: json['year_sem'] ?? 'N/A',
      section: json['section'] ?? 'N/A',
      gender: json['gender'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      batch: json['batch'] ?? 'N/A',
      profilePicUrl: json['profile_pic_url'] ?? '',
    );
  }
}
