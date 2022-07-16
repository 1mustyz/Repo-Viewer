import 'package:auto_route/annotations.dart';
import 'package:repo_viewer/auth/presentation/authorization_page.dart';
import 'package:repo_viewer/auth/presentation/sign_in_page.dart';
import 'package:repo_viewer/splash/pressentation/splash_page.dart';
import 'package:repo_viewer/starred_repos/presentation/starred_repos_page.dart';

@MaterialAutoRouter(routes: [
  MaterialRoute(page: SplashPage, initial: true),
  MaterialRoute(page: SignInPage, path: '/sign-in'),
  MaterialRoute(page: AuthorizationPage, path: '/auth'),
  MaterialRoute(page: StarredRepoPage, path: '/starred'),
], replaceInRouteName: 'Page,Route')
class $AppRouter {}
