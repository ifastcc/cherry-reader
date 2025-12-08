// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_conversation_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUnifiedConversationEntityCollection on Isar {
  IsarCollection<UnifiedConversationEntity> get unifiedConversationEntitys =>
      this.collection();
}

const UnifiedConversationEntitySchema = CollectionSchema(
  name: r'UnifiedConversationEntity',
  id: 2588592938251752014,
  properties: {
    r'contextId': PropertySchema(
      id: 0,
      name: r'contextId',
      type: IsarType.string,
    ),
    r'contextSnapshot': PropertySchema(
      id: 1,
      name: r'contextSnapshot',
      type: IsarType.string,
    ),
    r'contextType': PropertySchema(
      id: 2,
      name: r'contextType',
      type: IsarType.string,
      enumMap: _UnifiedConversationEntitycontextTypeEnumValueMap,
    ),
    r'conversationId': PropertySchema(
      id: 3,
      name: r'conversationId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'isArchived': PropertySchema(
      id: 5,
      name: r'isArchived',
      type: IsarType.bool,
    ),
    r'isPinned': PropertySchema(id: 6, name: r'isPinned', type: IsarType.bool),
    r'messageCount': PropertySchema(
      id: 7,
      name: r'messageCount',
      type: IsarType.long,
    ),
    r'modelId': PropertySchema(id: 8, name: r'modelId', type: IsarType.string),
    r'providerId': PropertySchema(
      id: 9,
      name: r'providerId',
      type: IsarType.string,
    ),
    r'roundCount': PropertySchema(
      id: 10,
      name: r'roundCount',
      type: IsarType.long,
    ),
    r'title': PropertySchema(id: 11, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.long,
    ),
  },

  estimateSize: _unifiedConversationEntityEstimateSize,
  serialize: _unifiedConversationEntitySerialize,
  deserialize: _unifiedConversationEntityDeserialize,
  deserializeProp: _unifiedConversationEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'conversationId': IndexSchema(
      id: 2945908346256754300,
      name: r'conversationId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'conversationId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'contextId': IndexSchema(
      id: 3310582078593788176,
      name: r'contextId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'contextId',
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

  getId: _unifiedConversationEntityGetId,
  getLinks: _unifiedConversationEntityGetLinks,
  attach: _unifiedConversationEntityAttach,
  version: '3.3.0',
);

int _unifiedConversationEntityEstimateSize(
  UnifiedConversationEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contextId.length * 3;
  {
    final value = object.contextSnapshot;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.contextType.name.length * 3;
  bytesCount += 3 + object.conversationId.length * 3;
  {
    final value = object.modelId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.providerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _unifiedConversationEntitySerialize(
  UnifiedConversationEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contextId);
  writer.writeString(offsets[1], object.contextSnapshot);
  writer.writeString(offsets[2], object.contextType.name);
  writer.writeString(offsets[3], object.conversationId);
  writer.writeLong(offsets[4], object.createdAt);
  writer.writeBool(offsets[5], object.isArchived);
  writer.writeBool(offsets[6], object.isPinned);
  writer.writeLong(offsets[7], object.messageCount);
  writer.writeString(offsets[8], object.modelId);
  writer.writeString(offsets[9], object.providerId);
  writer.writeLong(offsets[10], object.roundCount);
  writer.writeString(offsets[11], object.title);
  writer.writeLong(offsets[12], object.updatedAt);
}

UnifiedConversationEntity _unifiedConversationEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UnifiedConversationEntity();
  object.contextId = reader.readString(offsets[0]);
  object.contextSnapshot = reader.readStringOrNull(offsets[1]);
  object.contextType =
      _UnifiedConversationEntitycontextTypeValueEnumMap[reader.readStringOrNull(
        offsets[2],
      )] ??
      ConversationContextType.topic;
  object.conversationId = reader.readString(offsets[3]);
  object.createdAt = reader.readLong(offsets[4]);
  object.id = id;
  object.isArchived = reader.readBool(offsets[5]);
  object.isPinned = reader.readBool(offsets[6]);
  object.messageCount = reader.readLong(offsets[7]);
  object.modelId = reader.readStringOrNull(offsets[8]);
  object.providerId = reader.readStringOrNull(offsets[9]);
  object.roundCount = reader.readLong(offsets[10]);
  object.title = reader.readString(offsets[11]);
  object.updatedAt = reader.readLong(offsets[12]);
  return object;
}

P _unifiedConversationEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (_UnifiedConversationEntitycontextTypeValueEnumMap[reader
                  .readStringOrNull(offset)] ??
              ConversationContextType.topic)
          as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UnifiedConversationEntitycontextTypeEnumValueMap = {
  r'topic': r'topic',
  r'messageGroup': r'messageGroup',
  r'singleMessage': r'singleMessage',
};
const _UnifiedConversationEntitycontextTypeValueEnumMap = {
  r'topic': ConversationContextType.topic,
  r'messageGroup': ConversationContextType.messageGroup,
  r'singleMessage': ConversationContextType.singleMessage,
};

Id _unifiedConversationEntityGetId(UnifiedConversationEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _unifiedConversationEntityGetLinks(
  UnifiedConversationEntity object,
) {
  return [];
}

void _unifiedConversationEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  UnifiedConversationEntity object,
) {
  object.id = id;
}

extension UnifiedConversationEntityByIndex
    on IsarCollection<UnifiedConversationEntity> {
  Future<UnifiedConversationEntity?> getByConversationId(
    String conversationId,
  ) {
    return getByIndex(r'conversationId', [conversationId]);
  }

  UnifiedConversationEntity? getByConversationIdSync(String conversationId) {
    return getByIndexSync(r'conversationId', [conversationId]);
  }

  Future<bool> deleteByConversationId(String conversationId) {
    return deleteByIndex(r'conversationId', [conversationId]);
  }

  bool deleteByConversationIdSync(String conversationId) {
    return deleteByIndexSync(r'conversationId', [conversationId]);
  }

  Future<List<UnifiedConversationEntity?>> getAllByConversationId(
    List<String> conversationIdValues,
  ) {
    final values = conversationIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'conversationId', values);
  }

  List<UnifiedConversationEntity?> getAllByConversationIdSync(
    List<String> conversationIdValues,
  ) {
    final values = conversationIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'conversationId', values);
  }

  Future<int> deleteAllByConversationId(List<String> conversationIdValues) {
    final values = conversationIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'conversationId', values);
  }

  int deleteAllByConversationIdSync(List<String> conversationIdValues) {
    final values = conversationIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'conversationId', values);
  }

  Future<Id> putByConversationId(UnifiedConversationEntity object) {
    return putByIndex(r'conversationId', object);
  }

  Id putByConversationIdSync(
    UnifiedConversationEntity object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'conversationId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByConversationId(
    List<UnifiedConversationEntity> objects,
  ) {
    return putAllByIndex(r'conversationId', objects);
  }

  List<Id> putAllByConversationIdSync(
    List<UnifiedConversationEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'conversationId', objects, saveLinks: saveLinks);
  }
}

extension UnifiedConversationEntityQueryWhereSort
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QWhere
        > {
  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhere
  >
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension UnifiedConversationEntityQueryWhere
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QWhereClause
        > {
  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  conversationIdEqualTo(String conversationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'conversationId',
          value: [conversationId],
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  conversationIdNotEqualTo(String conversationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [],
                upper: [conversationId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [conversationId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [conversationId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [],
                upper: [conversationId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  contextIdEqualTo(String contextId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'contextId', value: [contextId]),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  contextIdNotEqualTo(String contextId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contextId',
                lower: [],
                upper: [contextId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contextId',
                lower: [contextId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contextId',
                lower: [contextId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contextId',
                lower: [],
                upper: [contextId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
  createdAtEqualTo(int createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
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

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterWhereClause
  >
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

extension UnifiedConversationEntityQueryFilter
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QFilterCondition
        > {
  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextId',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contextSnapshot'),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contextSnapshot'),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextSnapshot',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextSnapshot',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextSnapshotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeEqualTo(
    ConversationContextType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeGreaterThan(
    ConversationContextType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeLessThan(
    ConversationContextType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeBetween(
    ConversationContextType lower,
    ConversationContextType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextType',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextType', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  contextTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextType', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conversationId',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conversationId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conversationId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  conversationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conversationId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  isArchivedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isArchived', value: value),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isPinned', value: value),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  messageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'messageCount', value: value),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  messageCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'messageCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  messageCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'messageCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  messageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'messageCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'modelId'),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'modelId'),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelId',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'providerId',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'providerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  providerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  roundCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'roundCount', value: value),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  roundCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'roundCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  roundCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'roundCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  roundCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'roundCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
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
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  updatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterFilterCondition
  >
  updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension UnifiedConversationEntityQueryObject
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QFilterCondition
        > {}

extension UnifiedConversationEntityQueryLinks
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QFilterCondition
        > {}

extension UnifiedConversationEntityQuerySortBy
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QSortBy
        > {
  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByContextId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByContextIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByContextSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByContextSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByContextType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextType', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByContextTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextType', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByConversationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByConversationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByRoundCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundCount', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByRoundCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundCount', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UnifiedConversationEntityQuerySortThenBy
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QSortThenBy
        > {
  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByContextId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByContextIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByContextSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByContextSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByContextType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextType', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByContextTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextType', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByConversationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByConversationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByRoundCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundCount', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByRoundCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundCount', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    UnifiedConversationEntity,
    QAfterSortBy
  >
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UnifiedConversationEntityQueryWhereDistinct
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QDistinct
        > {
  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByContextId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contextId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByContextSnapshot({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'contextSnapshot',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByContextType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contextType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'conversationId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isArchived');
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageCount');
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByModelId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByProviderId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'providerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByRoundCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roundCount');
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedConversationEntity, UnifiedConversationEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension UnifiedConversationEntityQueryProperty
    on
        QueryBuilder<
          UnifiedConversationEntity,
          UnifiedConversationEntity,
          QQueryProperty
        > {
  QueryBuilder<UnifiedConversationEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UnifiedConversationEntity, String, QQueryOperations>
  contextIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextId');
    });
  }

  QueryBuilder<UnifiedConversationEntity, String?, QQueryOperations>
  contextSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextSnapshot');
    });
  }

  QueryBuilder<
    UnifiedConversationEntity,
    ConversationContextType,
    QQueryOperations
  >
  contextTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextType');
    });
  }

  QueryBuilder<UnifiedConversationEntity, String, QQueryOperations>
  conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conversationId');
    });
  }

  QueryBuilder<UnifiedConversationEntity, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<UnifiedConversationEntity, bool, QQueryOperations>
  isArchivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isArchived');
    });
  }

  QueryBuilder<UnifiedConversationEntity, bool, QQueryOperations>
  isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<UnifiedConversationEntity, int, QQueryOperations>
  messageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageCount');
    });
  }

  QueryBuilder<UnifiedConversationEntity, String?, QQueryOperations>
  modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelId');
    });
  }

  QueryBuilder<UnifiedConversationEntity, String?, QQueryOperations>
  providerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'providerId');
    });
  }

  QueryBuilder<UnifiedConversationEntity, int, QQueryOperations>
  roundCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roundCount');
    });
  }

  QueryBuilder<UnifiedConversationEntity, String, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<UnifiedConversationEntity, int, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUnifiedMessageEntityCollection on Isar {
  IsarCollection<UnifiedMessageEntity> get unifiedMessageEntitys =>
      this.collection();
}

const UnifiedMessageEntitySchema = CollectionSchema(
  name: r'UnifiedMessageEntity',
  id: -8591540344551846727,
  properties: {
    r'askId': PropertySchema(id: 0, name: r'askId', type: IsarType.string),
    r'content': PropertySchema(id: 1, name: r'content', type: IsarType.string),
    r'contextContent': PropertySchema(
      id: 2,
      name: r'contextContent',
      type: IsarType.string,
    ),
    r'contextDataJson': PropertySchema(
      id: 3,
      name: r'contextDataJson',
      type: IsarType.string,
    ),
    r'contextSummary': PropertySchema(
      id: 4,
      name: r'contextSummary',
      type: IsarType.string,
    ),
    r'conversationId': PropertySchema(
      id: 5,
      name: r'conversationId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'errorMessage': PropertySchema(
      id: 7,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'isMainline': PropertySchema(
      id: 8,
      name: r'isMainline',
      type: IsarType.bool,
    ),
    r'messageId': PropertySchema(
      id: 9,
      name: r'messageId',
      type: IsarType.string,
    ),
    r'modelId': PropertySchema(id: 10, name: r'modelId', type: IsarType.string),
    r'modelName': PropertySchema(
      id: 11,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'role': PropertySchema(id: 12, name: r'role', type: IsarType.string),
    r'status': PropertySchema(id: 13, name: r'status', type: IsarType.string),
    r'templateId': PropertySchema(
      id: 14,
      name: r'templateId',
      type: IsarType.string,
    ),
    r'templateName': PropertySchema(
      id: 15,
      name: r'templateName',
      type: IsarType.string,
    ),
    r'templateSnapshot': PropertySchema(
      id: 16,
      name: r'templateSnapshot',
      type: IsarType.string,
    ),
    r'usageJson': PropertySchema(
      id: 17,
      name: r'usageJson',
      type: IsarType.string,
    ),
    r'userQuery': PropertySchema(
      id: 18,
      name: r'userQuery',
      type: IsarType.string,
    ),
  },

  estimateSize: _unifiedMessageEntityEstimateSize,
  serialize: _unifiedMessageEntitySerialize,
  deserialize: _unifiedMessageEntityDeserialize,
  deserializeProp: _unifiedMessageEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'messageId': IndexSchema(
      id: -635287409172016016,
      name: r'messageId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'messageId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'conversationId': IndexSchema(
      id: 2945908346256754300,
      name: r'conversationId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'conversationId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'askId': IndexSchema(
      id: 4335625400576112076,
      name: r'askId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'askId',
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

  getId: _unifiedMessageEntityGetId,
  getLinks: _unifiedMessageEntityGetLinks,
  attach: _unifiedMessageEntityAttach,
  version: '3.3.0',
);

int _unifiedMessageEntityEstimateSize(
  UnifiedMessageEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.askId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.content.length * 3;
  {
    final value = object.contextContent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contextDataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contextSummary;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.conversationId.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageId.length * 3;
  {
    final value = object.modelId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.modelName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.role.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.templateId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.templateName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.templateSnapshot;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.usageJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userQuery;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _unifiedMessageEntitySerialize(
  UnifiedMessageEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.askId);
  writer.writeString(offsets[1], object.content);
  writer.writeString(offsets[2], object.contextContent);
  writer.writeString(offsets[3], object.contextDataJson);
  writer.writeString(offsets[4], object.contextSummary);
  writer.writeString(offsets[5], object.conversationId);
  writer.writeLong(offsets[6], object.createdAt);
  writer.writeString(offsets[7], object.errorMessage);
  writer.writeBool(offsets[8], object.isMainline);
  writer.writeString(offsets[9], object.messageId);
  writer.writeString(offsets[10], object.modelId);
  writer.writeString(offsets[11], object.modelName);
  writer.writeString(offsets[12], object.role);
  writer.writeString(offsets[13], object.status);
  writer.writeString(offsets[14], object.templateId);
  writer.writeString(offsets[15], object.templateName);
  writer.writeString(offsets[16], object.templateSnapshot);
  writer.writeString(offsets[17], object.usageJson);
  writer.writeString(offsets[18], object.userQuery);
}

UnifiedMessageEntity _unifiedMessageEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UnifiedMessageEntity();
  object.askId = reader.readStringOrNull(offsets[0]);
  object.content = reader.readString(offsets[1]);
  object.contextContent = reader.readStringOrNull(offsets[2]);
  object.contextDataJson = reader.readStringOrNull(offsets[3]);
  object.contextSummary = reader.readStringOrNull(offsets[4]);
  object.conversationId = reader.readString(offsets[5]);
  object.createdAt = reader.readLong(offsets[6]);
  object.errorMessage = reader.readStringOrNull(offsets[7]);
  object.id = id;
  object.isMainline = reader.readBool(offsets[8]);
  object.messageId = reader.readString(offsets[9]);
  object.modelId = reader.readStringOrNull(offsets[10]);
  object.modelName = reader.readStringOrNull(offsets[11]);
  object.role = reader.readString(offsets[12]);
  object.status = reader.readString(offsets[13]);
  object.templateId = reader.readStringOrNull(offsets[14]);
  object.templateName = reader.readStringOrNull(offsets[15]);
  object.templateSnapshot = reader.readStringOrNull(offsets[16]);
  object.usageJson = reader.readStringOrNull(offsets[17]);
  object.userQuery = reader.readStringOrNull(offsets[18]);
  return object;
}

P _unifiedMessageEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _unifiedMessageEntityGetId(UnifiedMessageEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _unifiedMessageEntityGetLinks(
  UnifiedMessageEntity object,
) {
  return [];
}

void _unifiedMessageEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  UnifiedMessageEntity object,
) {
  object.id = id;
}

extension UnifiedMessageEntityByIndex on IsarCollection<UnifiedMessageEntity> {
  Future<UnifiedMessageEntity?> getByMessageId(String messageId) {
    return getByIndex(r'messageId', [messageId]);
  }

  UnifiedMessageEntity? getByMessageIdSync(String messageId) {
    return getByIndexSync(r'messageId', [messageId]);
  }

  Future<bool> deleteByMessageId(String messageId) {
    return deleteByIndex(r'messageId', [messageId]);
  }

  bool deleteByMessageIdSync(String messageId) {
    return deleteByIndexSync(r'messageId', [messageId]);
  }

  Future<List<UnifiedMessageEntity?>> getAllByMessageId(
    List<String> messageIdValues,
  ) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'messageId', values);
  }

  List<UnifiedMessageEntity?> getAllByMessageIdSync(
    List<String> messageIdValues,
  ) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'messageId', values);
  }

  Future<int> deleteAllByMessageId(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'messageId', values);
  }

  int deleteAllByMessageIdSync(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'messageId', values);
  }

  Future<Id> putByMessageId(UnifiedMessageEntity object) {
    return putByIndex(r'messageId', object);
  }

  Id putByMessageIdSync(UnifiedMessageEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'messageId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMessageId(List<UnifiedMessageEntity> objects) {
    return putAllByIndex(r'messageId', objects);
  }

  List<Id> putAllByMessageIdSync(
    List<UnifiedMessageEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'messageId', objects, saveLinks: saveLinks);
  }
}

extension UnifiedMessageEntityQueryWhereSort
    on QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QWhere> {
  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension UnifiedMessageEntityQueryWhere
    on QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QWhereClause> {
  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
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

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
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

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  messageIdEqualTo(String messageId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'messageId', value: [messageId]),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  messageIdNotEqualTo(String messageId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId',
                lower: [],
                upper: [messageId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId',
                lower: [messageId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId',
                lower: [messageId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId',
                lower: [],
                upper: [messageId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  conversationIdEqualTo(String conversationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'conversationId',
          value: [conversationId],
        ),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  conversationIdNotEqualTo(String conversationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [],
                upper: [conversationId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [conversationId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [conversationId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationId',
                lower: [],
                upper: [conversationId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  askIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'askId', value: [null]),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  askIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'askId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  askIdEqualTo(String? askId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'askId', value: [askId]),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  askIdNotEqualTo(String? askId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'askId',
                lower: [],
                upper: [askId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'askId',
                lower: [askId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'askId',
                lower: [askId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'askId',
                lower: [],
                upper: [askId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
  createdAtEqualTo(int createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
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

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
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

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
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

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterWhereClause>
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

extension UnifiedMessageEntityQueryFilter
    on
        QueryBuilder<
          UnifiedMessageEntity,
          UnifiedMessageEntity,
          QFilterCondition
        > {
  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'askId'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'askId'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'askId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'askId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'askId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'askId',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'askId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'askId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'askId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'askId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'askId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  askIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'askId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contextContent'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contextContent'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextContent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextContent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextContent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextContent',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextContent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextContent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextContent',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextContent',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextContent', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextContent', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contextDataJson'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contextDataJson'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextDataJson',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextDataJson', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextDataJson', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contextSummary'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contextSummary'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextSummary',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextSummary',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextSummary',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextSummary',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextSummary',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextSummary',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextSummary',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextSummary',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextSummary', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  contextSummaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextSummary', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conversationId',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conversationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conversationId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conversationId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  conversationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conversationId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'errorMessage'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'errorMessage'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'errorMessage',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'errorMessage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'errorMessage', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'errorMessage', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  isMainlineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMainline', value: value),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'messageId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'messageId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'messageId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'messageId',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'messageId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'messageId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'messageId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'messageId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'messageId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  messageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'messageId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'modelId'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'modelId'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modelId',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modelId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modelId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'modelName'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'modelName'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelNameEqualTo(String? value, {bool caseSensitive = true}) {
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelNameGreaterThan(
    String? value, {
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelNameLessThan(
    String? value, {
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  modelNameBetween(
    String? lower,
    String? upper, {
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'role',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'role',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'templateId'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'templateId'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'templateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'templateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'templateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'templateId',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'templateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'templateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'templateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'templateId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'templateId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'templateId', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'templateName'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'templateName'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'templateName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'templateName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'templateName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'templateName',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'templateName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'templateName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'templateName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'templateName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'templateName', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'templateName', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'templateSnapshot'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'templateSnapshot'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'templateSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'templateSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'templateSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'templateSnapshot',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'templateSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'templateSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'templateSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'templateSnapshot',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'templateSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  templateSnapshotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'templateSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'usageJson'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'usageJson'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'usageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'usageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'usageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'usageJson',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'usageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'usageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'usageJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'usageJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'usageJson', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  usageJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'usageJson', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userQuery'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userQuery'),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userQuery',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userQuery',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userQuery',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userQuery',
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
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userQuery',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userQuery',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userQuery',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userQuery',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userQuery', value: ''),
      );
    });
  }

  QueryBuilder<
    UnifiedMessageEntity,
    UnifiedMessageEntity,
    QAfterFilterCondition
  >
  userQueryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userQuery', value: ''),
      );
    });
  }
}

extension UnifiedMessageEntityQueryObject
    on
        QueryBuilder<
          UnifiedMessageEntity,
          UnifiedMessageEntity,
          QFilterCondition
        > {}

extension UnifiedMessageEntityQueryLinks
    on
        QueryBuilder<
          UnifiedMessageEntity,
          UnifiedMessageEntity,
          QFilterCondition
        > {}

extension UnifiedMessageEntityQuerySortBy
    on QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QSortBy> {
  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByAskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByAskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContextContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextContent', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContextContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextContent', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContextDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextDataJson', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContextDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextDataJson', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContextSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSummary', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByContextSummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSummary', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByConversationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByConversationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByIsMainline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainline', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByIsMainlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainline', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByTemplateName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateName', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByTemplateNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateName', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByTemplateSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshot', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByTemplateSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshot', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByUsageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByUsageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByUserQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  sortByUserQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.desc);
    });
  }
}

extension UnifiedMessageEntityQuerySortThenBy
    on QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QSortThenBy> {
  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByAskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByAskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContextContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextContent', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContextContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextContent', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContextDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextDataJson', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContextDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextDataJson', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContextSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSummary', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByContextSummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSummary', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByConversationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByConversationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByIsMainline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainline', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByIsMainlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainline', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByTemplateName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateName', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByTemplateNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateName', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByTemplateSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshot', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByTemplateSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshot', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByUsageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByUsageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.desc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByUserQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.asc);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QAfterSortBy>
  thenByUserQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.desc);
    });
  }
}

extension UnifiedMessageEntityQueryWhereDistinct
    on QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct> {
  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByAskId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'askId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByContextContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'contextContent',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByContextDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'contextDataJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByContextSummary({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'contextSummary',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'conversationId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByIsMainline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMainline');
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByModelId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByModelName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByRole({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByTemplateId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByTemplateName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByTemplateSnapshot({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'templateSnapshot',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByUsageJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usageJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnifiedMessageEntity, UnifiedMessageEntity, QDistinct>
  distinctByUserQuery({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userQuery', caseSensitive: caseSensitive);
    });
  }
}

extension UnifiedMessageEntityQueryProperty
    on
        QueryBuilder<
          UnifiedMessageEntity,
          UnifiedMessageEntity,
          QQueryProperty
        > {
  QueryBuilder<UnifiedMessageEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  askIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'askId');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String, QQueryOperations>
  contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  contextContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextContent');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  contextDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextDataJson');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  contextSummaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextSummary');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String, QQueryOperations>
  conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conversationId');
    });
  }

  QueryBuilder<UnifiedMessageEntity, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<UnifiedMessageEntity, bool, QQueryOperations>
  isMainlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMainline');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String, QQueryOperations>
  messageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageId');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelId');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  templateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateId');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  templateNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateName');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  templateSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateSnapshot');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  usageJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usageJson');
    });
  }

  QueryBuilder<UnifiedMessageEntity, String?, QQueryOperations>
  userQueryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userQuery');
    });
  }
}
