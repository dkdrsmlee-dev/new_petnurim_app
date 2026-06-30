class CreateMyPetResponse {
  final String myPetId;
  final String nextStep;

  CreateMyPetResponse({
    required this.myPetId,
    required this.nextStep,
  });

  factory CreateMyPetResponse.fromJson(Map<String, dynamic> json) {
    return CreateMyPetResponse(
      myPetId: json['myPetId']?.toString() ?? '',
      nextStep: json['nextStep']?.toString() ?? '',
    );
  }
}

class MyPetDetailResponse {
  final String myPetId;
  final String accountMasterId;
  final String petTypeCode;
  final String? petTypeCodeNm;
  final String petBreedId;
  final String? breedNameKor;
  final String? breedNameEng;
  final String petName;
  final int? profileFileId;
  final int petAge;
  final String familyDt;
  final String genderCode;
  final String? genderCodeNm;
  final String neuteredYn;
  final double weightKg;
  final String weightMeasureDt;
  final String representYn;
  final String statusCode;
  final String regDt;

  MyPetDetailResponse({
    required this.myPetId,
    required this.accountMasterId,
    required this.petTypeCode,
    this.petTypeCodeNm,
    required this.petBreedId,
    this.breedNameKor,
    this.breedNameEng,
    required this.petName,
    this.profileFileId,
    required this.petAge,
    required this.familyDt,
    required this.genderCode,
    this.genderCodeNm,
    required this.neuteredYn,
    required this.weightKg,
    required this.weightMeasureDt,
    required this.representYn,
    required this.statusCode,
    required this.regDt,
  });

  factory MyPetDetailResponse.fromJson(Map<String, dynamic> json) {
    // Parse weightKg safely as double
    final rawWeight = json['weightKg'];
    double parsedWeight = 0.0;
    if (rawWeight != null) {
      if (rawWeight is num) {
        parsedWeight = rawWeight.toDouble();
      } else {
        parsedWeight = double.tryParse(rawWeight.toString()) ?? 0.0;
      }
    }

    // Parse profileFileId safely as int
    final rawFileId = json['profileFileId'];
    int? parsedFileId;
    if (rawFileId != null) {
      if (rawFileId is num) {
        parsedFileId = rawFileId.toInt();
      } else {
        parsedFileId = int.tryParse(rawFileId.toString());
      }
    }

    return MyPetDetailResponse(
      myPetId: json['myPetId']?.toString() ?? '',
      accountMasterId: json['accountMasterId']?.toString() ?? '',
      petTypeCode: json['petTypeCode']?.toString() ?? '',
      petTypeCodeNm: json['petTypeCodeNm']?.toString(),
      petBreedId: json['petBreedId']?.toString() ?? '',
      breedNameKor: json['breedName']?.toString() ?? json['breedNameKor']?.toString(),
      breedNameEng: json['breedNameEn']?.toString() ?? json['breedNameEng']?.toString(),
      petName: json['petName']?.toString() ?? '',
      profileFileId: parsedFileId,
      petAge: int.tryParse(json['petAge']?.toString() ?? '0') ?? 0,
      familyDt: json['familyDt']?.toString() ?? '',
      genderCode: json['genderCode']?.toString() ?? '',
      genderCodeNm: json['genderCodeNm']?.toString(),
      neuteredYn: json['neuteredYn']?.toString() ?? '',
      weightKg: parsedWeight,
      weightMeasureDt: json['weightMeasureDt']?.toString() ?? '',
      representYn: json['representYn']?.toString() ?? '',
      statusCode: json['statusCode']?.toString() ?? '',
      regDt: json['regDt']?.toString() ?? '',
    );
  }
}
