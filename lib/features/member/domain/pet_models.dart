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
      myPetId: (json['myPetId'] ?? json['id'] ?? json['petId'])?.toString() ?? '',
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

class MyPetListItem {
  final String myPetId;
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

  MyPetListItem({
    required this.myPetId,
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
  });

  factory MyPetListItem.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weightKg'] ?? json['WEIGHT_KG'];
    double parsedWeight = 0.0;
    if (rawWeight != null) {
      if (rawWeight is num) {
        parsedWeight = rawWeight.toDouble();
      } else {
        parsedWeight = double.tryParse(rawWeight.toString()) ?? 0.0;
      }
    }

    final rawFileId = json['profileFileId'] ?? json['PROFILE_FILE_ID'];
    int? parsedFileId;
    if (rawFileId != null) {
      if (rawFileId is num) {
        parsedFileId = rawFileId.toInt();
      } else {
        parsedFileId = int.tryParse(rawFileId.toString());
      }
    }

    return MyPetListItem(
      myPetId: (json['myPetId'] ?? json['MY_PET_ID'] ?? json['id'] ?? json['petId'])?.toString() ?? '',
      petTypeCode: (json['petTypeCode'] ?? json['PET_TYPE_CODE'])?.toString() ?? '',
      petTypeCodeNm: (json['petTypeCodeNm'] ?? json['PET_TYPE_CODE_NM'])?.toString(),
      petBreedId: (json['petBreedId'] ?? json['PET_BREED_ID'])?.toString() ?? '',
      breedNameKor: (json['breedNameKor'] ?? json['breedName'] ?? json['BREED_NAME_KOR'] ?? json['BREED_NAME'])?.toString(),
      breedNameEng: (json['breedNameEng'] ?? json['breedNameEn'] ?? json['BREED_NAME_ENG'] ?? json['BREED_NAME_EN'])?.toString(),
      petName: (json['petName'] ?? json['PET_NAME'])?.toString() ?? '',
      profileFileId: parsedFileId,
      petAge: int.tryParse((json['petAge'] ?? json['PET_AGE'])?.toString() ?? '0') ?? 0,
      familyDt: (json['familyDt'] ?? json['FAMILY_DT'])?.toString() ?? '',
      genderCode: (json['genderCode'] ?? json['GENDER_CODE'])?.toString() ?? '',
      genderCodeNm: (json['genderCodeNm'] ?? json['GENDER_CODE_NM'])?.toString(),
      neuteredYn: (json['neuteredYn'] ?? json['NEUTERED_YN'])?.toString() ?? '',
      weightKg: parsedWeight,
      weightMeasureDt: (json['weightMeasureDt'] ?? json['WEIGHT_MEASURE_DT'])?.toString() ?? '',
      representYn: (json['representYn'] ?? json['REPRESENT_YN'])?.toString() ?? '',
      statusCode: (json['statusCode'] ?? json['STATUS_CODE'])?.toString() ?? '',
    );
  }
}
