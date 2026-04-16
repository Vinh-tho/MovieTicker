import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> signIn(
    String emailOrPhone,
    String password,
  ) async {
    try {
      final responseData = await remoteDataSource.signIn(
        emailOrPhone,
        password,
      );
      final token = _readToken(responseData);
      if (token != null) {
        await localDataSource.cacheToken(token);
      }

      final UserModel userModel = UserModel.fromJson(responseData);
      await localDataSource.cacheUserProfile(
        id: userModel.id,
        fullName: userModel.fullName,
        email: userModel.email,
        phone: userModel.phone,
      );
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signUp({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? address,
  }) async {
    try {
      await remoteDataSource.signUp(
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp(String email, String otpCode) async {
    try {
      await remoteDataSource.verifyOtp(email, otpCode);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String? _readToken(Map<String, dynamic> payload) {
    const tokenKeys = [
      'token',
      'Token',
      'accessToken',
      'AccessToken',
      'jwtToken',
      'JwtToken',
    ];

    for (final key in tokenKeys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
