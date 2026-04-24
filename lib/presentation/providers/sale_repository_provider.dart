// lib/presentation/providers/repositories/sale_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/sale_repository.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});
