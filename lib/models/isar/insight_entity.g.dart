// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInsightEntityCollection on Isar {
  IsarCollection<InsightEntity> get insightEntitys => this.collection();
}

const InsightEntitySchema = CollectionSchema(
  name: r'InsightEntity',
  id: -6539662085930653395,
  properties: {
    r'assistantFilter': PropertySchema(
      id: 0,
      name: r'assistantFilter',
      type: IsarType.string,
    ),
    r'charCount': PropertySchema(
      id: 1,
      name: r'charCount',
      type: IsarType.long,
    ),
    r'content': PropertySchema(id: 2, name: r'content', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'insightId': PropertySchema(
      id: 4,
      name: r'insightId',
      type: IsarType.string,
    ),
    r'perspectiveIcon': PropertySchema(
      id: 5,
      name: r'perspectiveIcon',
      type: IsarType.string,
    ),
    r'perspectiveId': PropertySchema(
      id: 6,
      name: r'perspectiveId',
      type: IsarType.string,
    ),
    r'perspectiveName': PropertySchema(
      id: 7,
      name: r'perspectiveName',
      type: IsarType.string,
    ),
    r'queryCount': PropertySchema(
      id: 8,
      name: r'queryCount',
      type: IsarType.long,
    ),
    r'timeRangeLabel': PropertySchema(
      id: 9,
      name: r'timeRangeLabel',
      type: IsarType.string,
    ),
  },

  estimateSize: _insightEntityEstimateSize,
  serialize: _insightEntitySerialize,
  deserialize: _insightEntityDeserialize,
  deserializeProp: _insightEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'insightId': IndexSchema(
      id: 5818887354909674719,
      name: r'insightId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'insightId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _insightEntityGetId,
  getLinks: _insightEntityGetLinks,
  attach: _insightEntityAttach,
  version: '3.3.0',
);

int _insightEntityEstimateSize(
  InsightEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assistantFilter.length * 3;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.insightId.length * 3;
  bytesCount += 3 + object.perspectiveIcon.length * 3;
  bytesCount += 3 + object.perspectiveId.length * 3;
  bytesCount += 3 + object.perspectiveName.length * 3;
  bytesCount += 3 + object.timeRangeLabel.length * 3;
  return bytesCount;
}

void _insightEntitySerialize(
  InsightEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assistantFilter);
  writer.writeLong(offsets[1], object.charCount);
  writer.writeString(offsets[2], object.content);
  writer.writeLong(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.insightId);
  writer.writeString(offsets[5], object.perspectiveIcon);
  writer.writeString(offsets[6], object.perspectiveId);
  writer.writeString(offsets[7], object.perspectiveName);
  writer.writeLong(offsets[8], object.queryCount);
  writer.writeString(offsets[9], object.timeRangeLabel);
}

InsightEntity _insightEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InsightEntity();
  object.assistantFilter = reader.readString(offsets[0]);
  object.charCount = reader.readLong(offsets[1]);
  object.content = reader.readString(offsets[2]);
  object.createdAt = reader.readLong(offsets[3]);
  object.id = id;
  object.insightId = reader.readString(offsets[4]);
  object.perspectiveIcon = reader.readString(offsets[5]);
  object.perspectiveId = reader.readString(offsets[6]);
  object.perspectiveName = reader.readString(offsets[7]);
  object.queryCount = reader.readLong(offsets[8]);
  object.timeRangeLabel = reader.readString(offsets[9]);
  return object;
}

P _insightEntityDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _insightEntityGetId(InsightEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _insightEntityGetLinks(InsightEntity object) {
  return [];
}

void _insightEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  InsightEntity object,
) {
  object.id = id;
}

extension InsightEntityByIndex on IsarCollection<InsightEntity> {
  Future<InsightEntity?> getByInsightId(String insightId) {
    return getByIndex(r'insightId', [insightId]);
  }

  InsightEntity? getByInsightIdSync(String insightId) {
    return getByIndexSync(r'insightId', [insightId]);
  }

  Future<bool> deleteByInsightId(String insightId) {
    return deleteByIndex(r'insightId', [insightId]);
  }

  bool deleteByInsightIdSync(String insightId) {
    return deleteByIndexSync(r'insightId', [insightId]);
  }

  Future<List<InsightEntity?>> getAllByInsightId(List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'insightId', values);
  }

  List<InsightEntity?> getAllByInsightIdSync(List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'insightId', values);
  }

  Future<int> deleteAllByInsightId(List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'insightId', values);
  }

  int deleteAllByInsightIdSync(List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'insightId', values);
  }

  Future<Id> putByInsightId(InsightEntity object) {
    return putByIndex(r'insightId', object);
  }

  Id putByInsightIdSync(InsightEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'insightId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInsightId(List<InsightEntity> objects) {
    return putAllByIndex(r'insightId', objects);
  }

  List<Id> putAllByInsightIdSync(
    List<InsightEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'insightId', objects, saveLinks: saveLinks);
  }
}

extension InsightEntityQueryWhereSort
    on QueryBuilder<InsightEntity, InsightEntity, QWhere> {
  QueryBuilder<InsightEntity, InsightEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension InsightEntityQueryWhere
    on QueryBuilder<InsightEntity, InsightEntity, QWhereClause> {
  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  insightIdEqualTo(String insightId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'insightId', value: [insightId]),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  insightIdNotEqualTo(String insightId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [],
                upper: [insightId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [insightId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [insightId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [],
                upper: [insightId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  createdAtEqualTo(int createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  createdAtNotEqualTo(int createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  createdAtGreaterThan(int createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  createdAtLessThan(int createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterWhereClause>
  createdAtBetween(
    int lowerCreatedAt,
    int upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension InsightEntityQueryFilter
    on QueryBuilder<InsightEntity, InsightEntity, QFilterCondition> {
  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'assistantFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'assistantFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'assistantFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'assistantFilter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'assistantFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'assistantFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'assistantFilter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'assistantFilter',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'assistantFilter', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  assistantFilterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'assistantFilter', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  charCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'charCount', value: value),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  charCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'charCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  charCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'charCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  charCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'charCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'insightId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'insightId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'insightId', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  insightIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'insightId', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'perspectiveIcon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'perspectiveIcon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'perspectiveIcon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'perspectiveIcon',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'perspectiveIcon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'perspectiveIcon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'perspectiveIcon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'perspectiveIcon',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'perspectiveIcon', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'perspectiveIcon', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'perspectiveId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'perspectiveId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'perspectiveId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'perspectiveId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'perspectiveId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'perspectiveId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'perspectiveId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'perspectiveId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'perspectiveId', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'perspectiveId', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'perspectiveName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'perspectiveName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'perspectiveName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'perspectiveName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'perspectiveName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'perspectiveName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'perspectiveName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'perspectiveName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'perspectiveName', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  perspectiveNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'perspectiveName', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  queryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'queryCount', value: value),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  queryCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'queryCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  queryCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'queryCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  queryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'queryCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'timeRangeLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timeRangeLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timeRangeLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timeRangeLabel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'timeRangeLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'timeRangeLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'timeRangeLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'timeRangeLabel',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timeRangeLabel', value: ''),
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterFilterCondition>
  timeRangeLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'timeRangeLabel', value: ''),
      );
    });
  }
}

extension InsightEntityQueryObject
    on QueryBuilder<InsightEntity, InsightEntity, QFilterCondition> {}

extension InsightEntityQueryLinks
    on QueryBuilder<InsightEntity, InsightEntity, QFilterCondition> {}

extension InsightEntityQuerySortBy
    on QueryBuilder<InsightEntity, InsightEntity, QSortBy> {
  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByAssistantFilter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantFilter', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByAssistantFilterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantFilter', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> sortByCharCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charCount', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByCharCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charCount', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> sortByInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByPerspectiveIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveIcon', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByPerspectiveIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveIcon', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByPerspectiveId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByPerspectiveIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByPerspectiveName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveName', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByPerspectiveNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveName', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> sortByQueryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryCount', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByQueryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryCount', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByTimeRangeLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeRangeLabel', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  sortByTimeRangeLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeRangeLabel', Sort.desc);
    });
  }
}

extension InsightEntityQuerySortThenBy
    on QueryBuilder<InsightEntity, InsightEntity, QSortThenBy> {
  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByAssistantFilter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantFilter', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByAssistantFilterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantFilter', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByCharCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charCount', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByCharCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charCount', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByPerspectiveIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveIcon', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByPerspectiveIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveIcon', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByPerspectiveId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByPerspectiveIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByPerspectiveName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveName', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByPerspectiveNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveName', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy> thenByQueryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryCount', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByQueryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryCount', Sort.desc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByTimeRangeLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeRangeLabel', Sort.asc);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QAfterSortBy>
  thenByTimeRangeLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeRangeLabel', Sort.desc);
    });
  }
}

extension InsightEntityQueryWhereDistinct
    on QueryBuilder<InsightEntity, InsightEntity, QDistinct> {
  QueryBuilder<InsightEntity, InsightEntity, QDistinct>
  distinctByAssistantFilter({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'assistantFilter',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct> distinctByCharCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'charCount');
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct> distinctByInsightId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'insightId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct>
  distinctByPerspectiveIcon({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'perspectiveIcon',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct>
  distinctByPerspectiveId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'perspectiveId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct>
  distinctByPerspectiveName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'perspectiveName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct> distinctByQueryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queryCount');
    });
  }

  QueryBuilder<InsightEntity, InsightEntity, QDistinct>
  distinctByTimeRangeLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'timeRangeLabel',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension InsightEntityQueryProperty
    on QueryBuilder<InsightEntity, InsightEntity, QQueryProperty> {
  QueryBuilder<InsightEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations>
  assistantFilterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assistantFilter');
    });
  }

  QueryBuilder<InsightEntity, int, QQueryOperations> charCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'charCount');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<InsightEntity, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations> insightIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'insightId');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations>
  perspectiveIconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perspectiveIcon');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations>
  perspectiveIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perspectiveId');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations>
  perspectiveNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perspectiveName');
    });
  }

  QueryBuilder<InsightEntity, int, QQueryOperations> queryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queryCount');
    });
  }

  QueryBuilder<InsightEntity, String, QQueryOperations>
  timeRangeLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeRangeLabel');
    });
  }
}
