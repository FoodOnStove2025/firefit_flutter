import 'package:core/common/failures/failure.dart';
import 'package:core/common/repositories/graphql_repository.dart';
import 'package:core/config/env.dart';
import 'package:core/schema.graphql.dart';
import 'package:core/users/domain/models/user.dart';
import 'package:core/users/domain/repositories/user_repository_interface.dart';
import 'package:core/users/graphql/users.graphql.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

class UserRepository extends UserRepositoryInterface {
  UserRepository({required this.talker, required this.env}) {
    graphQLRepository = GraphQLRepository(talker: talker, env: env);
    graphqlClient = graphQLRepository.graphqlClient;
  }
  late GraphQLRepository graphQLRepository;
  late GraphQLClient graphqlClient;
  final EnvInterface env;
  final Talker talker;

  @override
  Future<Either<Failure, List<User>>> queryUsers({
    int? first,
    int? last,
    String? before,
    String? after,
    Input$UsersFilter? filter,
    List<Input$UsersOrderBy>? orderBy,
  }) async {
    try {
      final response = await graphqlClient.query$UserCollection(
        Options$Query$UserCollection(
          variables: Variables$Query$UserCollection(
            first: first,
            last: last,
            before: before,
            after: after,
            filter: filter,
            orderBy: orderBy,
          ),
        ),
      );

      if (response.hasException) {
        debugPrint('${response.exception}');
        return Left(Failure.unprocessableEntity(
            message: response.exception.toString()));
      }

      if (response.parsedData != null &&
          response.parsedData!.usersCollection != null) {
        return Right(List<User>.from(
            response.parsedData!.usersCollection!.edges.map((e) => e.node)));
      }
      return const Right([]);
    } catch (e) {
      debugPrint('$e');
      return Left(Failure.unprocessableEntity(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> createUser(
      {required Input$UsersInsertInput input}) async {
    try {
      final response =
          await graphqlClient.mutate$CreateUser(Options$Mutation$CreateUser(
        variables: Variables$Mutation$CreateUser(input: input),
      ));

      if (response.hasException) {
        debugPrint('${response.exception}');
        return Left(Failure.unprocessableEntity(
            message: response.exception.toString()));
      }

      if (response.parsedData != null &&
          response.parsedData!.insertIntoUsersCollection != null) {
        return Right(
            response.parsedData!.insertIntoUsersCollection!.records.first);
      }
      return const Left(Failure.empty());
    } catch (e) {
      debugPrint('$e');
      return Left(Failure.unprocessableEntity(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(
      {required String id, required Input$UsersUpdateInput input}) async {
    try {
      print('=== UpdateUser Debug Info ===');
      print('User ID: $id');
      print('Update Input: $input');
      print('Input primaryStationId: ${input.primaryStationId}');
      
      final response =
          await graphqlClient.mutate$UpdateUser(Options$Mutation$UpdateUser(
        variables: Variables$Mutation$UpdateUser(
          id: id,
          user: input,
        ),
      ));

      print('GraphQL Response received');
      print('Has Exception: ${response.hasException}');
      print('Response Data: ${response.data}');
      print('Parsed Data: ${response.parsedData}');

      if (response.hasException) {
        debugPrint('UpdateUser GraphQL Exception: ${response.exception}');
        print('UpdateUser failed - ID: $id, Input: $input');
        print('Exception details: ${response.exception.toString()}');
        return Left(Failure.unprocessableEntity(
            message: response.exception.toString()));
      }

      if (response.parsedData?.updateUsersCollection != null) {
        print('Update response records: ${response.parsedData!.updateUsersCollection!.records}');
        print('Affected count: ${response.parsedData!.updateUsersCollection!.affectedCount}');
      }

      print('UpdateUser mutation completed successfully');
      
      // After update, fetch the user to get the updated data
      // The mutation might not return records, so we fetch separately
      final userResult = await queryUsers(
        filter: Input$UsersFilter(
          id: Input$UUIDFilter(
            eq: id,
          ),
        ),
      );
      
      return userResult.fold(
        (l) => Left(Failure.unprocessableEntity(message: 'Failed to fetch updated user')),
        (users) {
          if (users.isNotEmpty) {
            return Right(users.first);
          }
          return const Left(Failure.empty());
        },
      );
    } catch (e) {
      debugPrint('$e');
      return Left(Failure.unprocessableEntity(message: e.toString()));
    }
  }
}
