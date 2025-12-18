// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_embedding_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTopicEmbeddingEntityCollection on Isar {
  IsarCollection<TopicEmbeddingEntity> get topicEmbeddingEntitys =>
      this.collection();
}

const TopicEmbeddingEntitySchema = CollectionSchema(
  name: r'TopicEmbeddingEntity',
  id: -8953149262123798963,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'embedding': PropertySchema(
      id: 1,
      name: r'embedding',
      type: IsarType.doubleList,
    ),
    r'firstQueryText': PropertySchema(
      id: 2,
      name: r'firstQueryText',
      type: IsarType.string,
    ),
    r'modelName': PropertySchema(
      id: 3,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'topicId': PropertySchema(id: 4, name: r'topicId', type: IsarType.string),
  },

  estimateSize: _topicEmbeddingEntityEstimateSize,
  serialize: _topicEmbeddingEntitySerialize,
  deserialize: _topicEmbeddingEntityDeserialize,
  deserializeProp: _topicEmbeddingEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'topicId': IndexSchema(
      id: 3718206658163357569,
      name: r'topicId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'topicId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _topicEmbeddingEntityGetId,
  getLinks: _topicEmbeddingEntityGetLinks,
  attach: _topicEmbeddingEntityAttach,
  version: '3.3.0',
);

int _topicEmbeddingEntityEstimateSize(
  TopicEmbeddingEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.embedding.length * 8;
  bytesCount += 3 + object.firstQueryText.length * 3;
  bytesCount += 3 + object.modelName.length * 3;
  bytesCount += 3 + object.topicId.length * 3;
  return bytesCount;
}

void _topicEmbeddingEntitySerialize(
  TopicEmbeddingEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAt);
  writer.writeDoubleList(offsets[1], object.embedding);
  writer.writeString(offsets[2], object.firstQueryText);
  writer.writeString(offsets[3], object.modelName);
  writer.writeString(offsets[4], object.topicId);
}

TopicEmbeddingEntity _topicEmbeddingEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TopicEmbeddingEntity();
  object.createdAt = reader.readLong(offsets[0]);
  object.embedding = reader.readDoubleList(offsets[1]) ?? [];
  object.firstQueryText = reader.readString(offsets[2]);
  object.id = id;
  object.modelName = reader.readString(offsets[3]);
  object.topicId = reader.readString(offsets[4]);
  return object;
}

P _topicEmbeddingEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _topicEmbeddingEntityGetId(TopicEmbeddingEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _topicEmbeddingEntityGetLinks(
  TopicEmbeddingEntity object,
) {
  return [];
}

void _topicEmbeddingEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  TopicEmbeddingEntity object,
) {
  object.id = id;
}

extension TopicEmbeddingEntityByIndex on IsarCollection<TopicEmbeddingEntity> {
  Future<TopicEmbeddingEntity?> getByTopicId(String topicId) {
    return getByIndex(r'topicId', [topicId]);
  }

  TopicEmbeddingEntity? getByTopicIdSync(String topicId) {
    return getByIndexSync(r'topicId', [topicId]);
  }

  Future<bool> deleteByTopicId(String topicId) {
    return deleteByIndex(r'topicId', [topicId]);
  }

  bool deleteByTopicIdSync(String topicId) {
    return deleteByIndexSync(r'topicId', [topicId]);
  }

  Future<List<TopicEmbeddingEntity?>> getAllByTopicId(
    List<String> topicIdValues,
  ) {
    final values = topicIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'topicId', values);
  }

  List<TopicEmbeddingEntity?> getAllByTopicIdSync(List<String> topicIdValues) {
    final values = topicIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'topicId', values);
  }

  Future<int> deleteAllByTopicId(List<String> topicIdValues) {
    final values = topicIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'topicId', values);
  }

  int deleteAllByTopicIdSync(List<String> topicIdValues) {
    final values = topicIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'topicId', values);
  }

  Future<Id> putByTopicId(TopicEmbeddingEntity object) {
    return putByIndex(r'topicId', object);
  }

  Id putByTopicIdSync(TopicEmbeddingEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'topicId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTopicId(List<TopicEmbeddingEntity> objects) {
    return putAllByIndex(r'topicId', objects);
  }

  List<Id> putAllByTopicIdSync(
    List<TopicEmbeddingEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'topicId', objects, saveLinks: saveLinks);
  }
}

extension TopicEmbeddingEntityQueryWhereSort
    on QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QWhere> {
  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TopicEmbeddingEntityQueryWhere
    on QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QWhereClause> {
  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  topicIdEqualTo(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'topicId', value: [topicId]),
      );
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterWhereClause>
  topicIdNotEqualTo(String topicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId',
                lower: [],
                upper: [topicId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId',
                lower: [topicId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId',
                lower: [topicId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId',
                lower: [],
                upper: [topicId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension TopicEmbeddingEntityQueryFilter
    on
        QueryBuilder<
          TopicEmbeddingEntity,
          TopicEmbeddingEntity,
          QFilterCondition
        > {
  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  createdAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  createdAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingElementEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'embedding',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'embedding',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'embedding',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'embedding',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', length, true, length, true);
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', 0, true, 0, true);
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', 0, true, length, include);
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', length, include, 999999, true);
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  embeddingLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'firstQueryText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'firstQueryText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'firstQueryText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'firstQueryText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'firstQueryText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'firstQueryText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'firstQueryText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'firstQueryText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'firstQueryText', value: ''),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  firstQueryTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'firstQueryText', value: ''),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'topicId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'topicId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<
    TopicEmbeddingEntity,
    TopicEmbeddingEntity,
    QAfterFilterCondition
  >
  topicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'topicId', value: ''),
      );
    });
  }
}

extension TopicEmbeddingEntityQueryObject
    on
        QueryBuilder<
          TopicEmbeddingEntity,
          TopicEmbeddingEntity,
          QFilterCondition
        > {}

extension TopicEmbeddingEntityQueryLinks
    on
        QueryBuilder<
          TopicEmbeddingEntity,
          TopicEmbeddingEntity,
          QFilterCondition
        > {}

extension TopicEmbeddingEntityQuerySortBy
    on QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QSortBy> {
  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByFirstQueryText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstQueryText', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByFirstQueryTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstQueryText', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }
}

extension TopicEmbeddingEntityQuerySortThenBy
    on QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QSortThenBy> {
  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByFirstQueryText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstQueryText', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByFirstQueryTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstQueryText', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QAfterSortBy>
  thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }
}

extension TopicEmbeddingEntityQueryWhereDistinct
    on QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QDistinct> {
  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QDistinct>
  distinctByEmbedding() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'embedding');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QDistinct>
  distinctByFirstQueryText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'firstQueryText',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QDistinct>
  distinctByModelName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TopicEmbeddingEntity, TopicEmbeddingEntity, QDistinct>
  distinctByTopicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId', caseSensitive: caseSensitive);
    });
  }
}

extension TopicEmbeddingEntityQueryProperty
    on
        QueryBuilder<
          TopicEmbeddingEntity,
          TopicEmbeddingEntity,
          QQueryProperty
        > {
  QueryBuilder<TopicEmbeddingEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, List<double>, QQueryOperations>
  embeddingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embedding');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, String, QQueryOperations>
  firstQueryTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstQueryText');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, String, QQueryOperations>
  modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<TopicEmbeddingEntity, String, QQueryOperations>
  topicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicId');
    });
  }
}
