import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_manager/features/posts/application/posts_provider.dart';

void main() {
  test('filter and page-size changes reset pagination', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(postsFilterProvider.notifier);

    controller.setPage(3);
    expect(container.read(postsFilterProvider).page, 3);

    controller.setQuery('offline');
    expect(container.read(postsFilterProvider).page, 0);

    controller.setPage(2);
    controller.setSearchField(PostSearchField.titleAndBody);
    expect(container.read(postsFilterProvider).page, 0);

    controller.setPage(1);
    controller.setPageSize(-1);
    expect(container.read(postsFilterProvider).page, 0);
    expect(container.read(postsFilterProvider).pageSize, -1);
  });
}
