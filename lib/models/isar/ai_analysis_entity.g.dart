// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_analysis_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAIAnalysisEntityCollection on Isar {
  IsarCollection<AIAnalysisEntity> get aIAnalysisEntitys => this.collection();
}

const AIAnalysisEntitySchema = CollectionSchema(
  name: r'AIAnalysisEntity',
  id: -5070261836944158169,
  properties: {
    r'content': PropertySchema(id: 0, name: r'content', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'groupIndex': PropertySchema(
      id: 2,
      name: r'groupIndex',
      type: IsarType.long,
    ),
    r'topicId': PropertySchema(id: 3, name: r'topicId', type: IsarType.string),
  },

  estimateSize: _aIAnalysisEntityEstimateSize,
  serialize: _aIAnalysisEntitySerialize,
  deserialize: _aIAnalysisEntityDeserialize,
  deserializeProp: _aIAnalysisEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'topicId': IndexSchema(
      id: 3718206658163357569,
      name: r'topicId',
      unique: false,
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

  getId: _aIAnalysisEntityGetId,
  getLinks: _aIAnalysisEntityGetLinks,
  attach: _aIAnalysisEntityAttach,
  version: '3.3.0',
);

int _aIAnalysisEntityEstimateSize(
  AIAnalysisEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.topicId.length * 3;
  return bytesCount;
}

void _aIAnalysisEntitySerialize(
  AIAnalysisEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.groupIndex);
  writer.writeString(offsets[3], object.topicId);
}

AIAnalysisEntity _aIAnalysisEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AIAnalysisEntity();
  object.content = reader.readString(offsets[0]);
  object.createdAt = reader.readLong(offsets[1]);
  object.groupIndex = reader.readLong(offsets[2]);
  object.id = id;
  object.topicId = reader.readString(offsets[3]);
  return object;
}

P _aIAnalysisEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _aIAnalysisEntityGetId(AIAnalysisEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aIAnalysisEntityGetLinks(AIAnalysisEntity object) {
  return [];
}

void _aIAnalysisEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  AIAnalysisEntity object,
) {
  object.id = id;
}

extension AIAnalysisEntityQueryWhereSort
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QWhere> {
  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AIAnalysisEntityQueryWhere
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QWhereClause> {
  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause>
  topicIdEqualTo(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'topicId', value: [topicId]),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterWhereClause>
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

extension AIAnalysisEntityQueryFilter
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QFilterCondition> {
  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  groupIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groupIndex', value: value),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  groupIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'groupIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  groupIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'groupIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  groupIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'groupIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
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

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  topicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterFilterCondition>
  topicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'topicId', value: ''),
      );
    });
  }
}

extension AIAnalysisEntityQueryObject
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QFilterCondition> {}

extension AIAnalysisEntityQueryLinks
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QFilterCondition> {}

extension AIAnalysisEntityQuerySortBy
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QSortBy> {
  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByGroupIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByGroupIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }
}

extension AIAnalysisEntityQuerySortThenBy
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QSortThenBy> {
  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByGroupIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByGroupIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QAfterSortBy>
  thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }
}

extension AIAnalysisEntityQueryWhereDistinct
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QDistinct> {
  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QDistinct>
  distinctByContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QDistinct>
  distinctByGroupIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupIndex');
    });
  }

  QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QDistinct>
  distinctByTopicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId', caseSensitive: caseSensitive);
    });
  }
}

extension AIAnalysisEntityQueryProperty
    on QueryBuilder<AIAnalysisEntity, AIAnalysisEntity, QQueryProperty> {
  QueryBuilder<AIAnalysisEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AIAnalysisEntity, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<AIAnalysisEntity, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AIAnalysisEntity, int, QQueryOperations> groupIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupIndex');
    });
  }

  QueryBuilder<AIAnalysisEntity, String, QQueryOperations> topicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicId');
    });
  }
}
