import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/setup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/checklists/checklists_screen.dart';
import '../screens/checklists/checklist_detail_screen.dart';
import '../screens/checklists/checklist_history_screen.dart';
import '../screens/recipes/recipes_screen.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import '../screens/recipes/recipe_new_screen.dart';
import '../screens/recipes/recipe_edit_screen.dart';
import '../screens/checklists/checklist_manage_screen.dart';
import '../screens/menu/allergen_matrix_screen.dart';
import '../screens/diary/diary_screen.dart';
import '../screens/incidents/incidents_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/documents/documents_screen.dart';
import '../screens/documents/document_upload_screen.dart';
import '../screens/documents/document_detail_screen.dart';
import '../screens/ai_import/ai_import_screen.dart';
import '../widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(profileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.whenOrNull(
            data: (s) => s.session != null,
          ) ??
          false;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/setup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        // Check if user has a profile — if not, send to setup
        final hasProfile = profile.whenOrNull(data: (p) => p != null) ?? false;
        if (!hasProfile) return '/setup';
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/checklists',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChecklistsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ChecklistManageScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ChecklistDetailScreen(
                  templateId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => ChecklistHistoryScreen(
                      templateId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/recipes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RecipesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const RecipeNewScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => RecipeEditScreen(
                  recipeId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => RecipeDetailScreen(
                  recipeId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AllergenMatrixScreen(),
            ),
          ),
          GoRoute(
            path: '/diary',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiaryScreen(),
            ),
          ),
          GoRoute(
            path: '/incidents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: IncidentsScreen(),
            ),
          ),
          GoRoute(
            path: '/suppliers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SuppliersScreen(),
            ),
          ),
          GoRoute(
            path: '/team',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeamScreen(),
            ),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DocumentsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) => const DocumentUploadScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => DocumentDetailScreen(
                  documentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/ai-import',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AiImportScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
