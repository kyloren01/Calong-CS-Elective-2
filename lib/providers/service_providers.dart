import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/image_picker_service.dart';
import '../services/image_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/profile_service.dart';

// Pages watch providers, providers call these services, and only services
// talk to Supabase. Tests replace the services with in-memory fakes.

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider).auth),
);

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(ref.watch(supabaseClientProvider)),
);

final categoryServiceProvider = Provider<CategoryService>(
  (ref) => CategoryService(ref.watch(supabaseClientProvider)),
);

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.watch(supabaseClientProvider)),
);

final imageServiceProvider = Provider<ImageService>(
  (ref) => ImageService(ref.watch(supabaseClientProvider)),
);

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => ImagePickerService(),
);

final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(ref.watch(supabaseClientProvider)),
);
