import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class SignUp implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUp(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    print('🟢 [SIGN UP USECASE] Parámetros recibidos:');
    print('   - email: ${params.email}');
    print('   - displayName: ${params.displayName}');
    print('   - accountType: ${params.accountType}');
    
    return await repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      accountType: params.accountType,
    );
  }
}

class SignUpParams {
  final String email;
  final String password;
  final String? displayName;
  final String? accountType;

  SignUpParams({
    required this.email,
    required this.password,
    this.displayName,
    this.accountType,
  });
}
