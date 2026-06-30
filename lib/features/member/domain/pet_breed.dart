class PetBreed {
  final String petBreedId;
  final String breedNameKor;
  final String breedNameEng;
  final String petTypeCode;
  final String mixedBreedCode;
  final String displayCode;

  PetBreed({
    required this.petBreedId,
    required this.breedNameKor,
    required this.breedNameEng,
    required this.petTypeCode,
    required this.mixedBreedCode,
    required this.displayCode,
  });

  factory PetBreed.fromJson(Map<String, dynamic> json) {
    return PetBreed(
      petBreedId: json['petBreedId']?.toString() ?? '',
      // Support both 'breedName' and 'breedNameKor' from API response variations
      breedNameKor: json['breedName']?.toString() ?? json['breedNameKor']?.toString() ?? '',
      // Support both 'breedNameEn' and 'breedNameEng' from API response variations
      breedNameEng: json['breedNameEn']?.toString() ?? json['breedNameEng']?.toString() ?? '',
      petTypeCode: json['petTypeCode']?.toString() ?? '',
      mixedBreedCode: json['mixedBreedCode']?.toString() ?? '',
      displayCode: json['displayCode']?.toString() ?? '',
    );
  }
}
