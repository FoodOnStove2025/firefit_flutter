// ignore_for_file: avoid_unused_constructor_parameters

import 'package:core/config/env.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:talker_flutter/talker_flutter.dart';

class GraphQLRepository {
  HiveStore? hiveStore;

  GraphQLRepository({
    required this.talker,
    required this.env,
    this.hiveStore,
  }) {
    final AuthLink authLink = AuthLink(
      getToken: () async {
        // Use the current user's session token for RLS policies to work
        final session = sb.Supabase.instance.client.auth.currentSession;
        if (session != null && session.accessToken.isNotEmpty) {
          print('GraphQL using user session token for authentication');
          return 'Bearer ${session.accessToken}';
        } else {
          // Fallback to API key for unauthenticated requests
          print('GraphQL using API key for authentication (no user session)');
          return env.supabaseKey;
        }
      },
    );

    HttpLink httpLink = HttpLink('${env.supabaseBaseUrl}/graphql/v1',
        defaultHeaders: {
          'apiKey': env.supabaseKey,
          'Content-Type': 'application/json; charset=utf-8'
        });

    Link link = authLink.concat(httpLink);

    graphqlClient =
        GraphQLClient(link: link, cache: GraphQLCache(store: InMemoryStore()));
  }

  late final GraphQLClient graphqlClient;
  final Talker talker;
  final EnvInterface env;
}
