import 'package:equatable/equatable.dart';

class KtpModel extends Equatable {
  final String? nik;
  final String? name;
  final String? gender;
  final String? address;
  final String? rt;
  final String? rw;
  final String? subDistrict;
  final String? district;
  final String? religion;
  final String? marital;
  final String? occupation;
  final String? nationality;
  final String? validUntil;

  const KtpModel({
    this.nik,
    this.name,
    this.gender,
    this.address,
    this.rt,
    this.rw,
    this.subDistrict,
    this.district,
    this.religion,
    this.marital,
    this.occupation,
    this.nationality,
    this.validUntil,
  });

  @override
  List<Object?> get props => [
        this.nik,
        this.name,
        this.gender,
        this.address,
        this.rt,
        this.rw,
        this.subDistrict,
        this.district,
        this.religion,
        this.marital,
        this.occupation,
        this.nationality,
        this.validUntil,
      ];
}
