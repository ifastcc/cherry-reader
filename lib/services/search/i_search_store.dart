import '../../models/domain/search_hits.dart';

abstract class ISearchStore {
  Future<List<TopicNameHit>> searchTopicNames(
    String keyword, {
    int limit = 50,
  });

  Future<List<MessageContentHit>> searchMessageContent(
    String keyword, {
    int limit = 100,
  });
}
