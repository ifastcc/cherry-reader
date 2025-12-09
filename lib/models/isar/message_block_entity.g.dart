// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_block_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageBlockEntityCollection on Isar {
  IsarCollection<MessageBlockEntity> get messageBlockEntitys =>
      this.collection();
}

const MessageBlockEntitySchema = CollectionSchema(
  name: r'MessageBlockEntity',
  id: -3276065960281747157,
  properties: {
    r'blockId': PropertySchema(id: 0, name: r'blockId', type: IsarType.string),
    r'content': PropertySchema(id: 1, name: r'content', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'errorJson': PropertySchema(
      id: 3,
      name: r'errorJson',
      type: IsarType.string,
    ),
    r'fileId': PropertySchema(id: 4, name: r'fileId', type: IsarType.string),
    r'fileJson': PropertySchema(
      id: 5,
      name: r'fileJson',
      type: IsarType.string,
    ),
    r'isError': PropertySchema(id: 6, name: r'isError', type: IsarType.bool),
    r'isFile': PropertySchema(id: 7, name: r'isFile', type: IsarType.bool),
    r'isImage': PropertySchema(id: 8, name: r'isImage', type: IsarType.bool),
    r'isMainText': PropertySchema(
      id: 9,
      name: r'isMainText',
      type: IsarType.bool,
    ),
    r'isThinking': PropertySchema(
      id: 10,
      name: r'isThinking',
      type: IsarType.bool,
    ),
    r'isTool': PropertySchema(id: 11, name: r'isTool', type: IsarType.bool),
    r'knowledgeJson': PropertySchema(
      id: 12,
      name: r'knowledgeJson',
      type: IsarType.string,
    ),
    r'messageId': PropertySchema(
      id: 13,
      name: r'messageId',
      type: IsarType.string,
    ),
    r'orderIndex': PropertySchema(
      id: 14,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'responseJson': PropertySchema(
      id: 15,
      name: r'responseJson',
      type: IsarType.string,
    ),
    r'targetLanguage': PropertySchema(
      id: 16,
      name: r'targetLanguage',
      type: IsarType.string,
    ),
    r'thinkingMillsec': PropertySchema(
      id: 17,
      name: r'thinkingMillsec',
      type: IsarType.double,
    ),
    r'toolJson': PropertySchema(
      id: 18,
      name: r'toolJson',
      type: IsarType.string,
    ),
    r'topicId': PropertySchema(id: 19, name: r'topicId', type: IsarType.string),
    r'type': PropertySchema(id: 20, name: r'type', type: IsarType.string),
    r'url': PropertySchema(id: 21, name: r'url', type: IsarType.string),
  },

  estimateSize: _messageBlockEntityEstimateSize,
  serialize: _messageBlockEntitySerialize,
  deserialize: _messageBlockEntityDeserialize,
  deserializeProp: _messageBlockEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'blockId': IndexSchema(
      id: -413886092950911832,
      name: r'blockId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'blockId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
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
    r'messageId_orderIndex': IndexSchema(
      id: 4795989850089223295,
      name: r'messageId_orderIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'messageId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'orderIndex',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _messageBlockEntityGetId,
  getLinks: _messageBlockEntityGetLinks,
  attach: _messageBlockEntityAttach,
  version: '3.3.0',
);

int _messageBlockEntityEstimateSize(
  MessageBlockEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blockId.length * 3;
  {
    final value = object.content;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.errorJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fileId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fileJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.knowledgeJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageId.length * 3;
  {
    final value = object.responseJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.targetLanguage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.toolJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.topicId.length * 3;
  bytesCount += 3 + object.type.length * 3;
  {
    final value = object.url;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _messageBlockEntitySerialize(
  MessageBlockEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.blockId);
  writer.writeString(offsets[1], object.content);
  writer.writeLong(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.errorJson);
  writer.writeString(offsets[4], object.fileId);
  writer.writeString(offsets[5], object.fileJson);
  writer.writeBool(offsets[6], object.isError);
  writer.writeBool(offsets[7], object.isFile);
  writer.writeBool(offsets[8], object.isImage);
  writer.writeBool(offsets[9], object.isMainText);
  writer.writeBool(offsets[10], object.isThinking);
  writer.writeBool(offsets[11], object.isTool);
  writer.writeString(offsets[12], object.knowledgeJson);
  writer.writeString(offsets[13], object.messageId);
  writer.writeLong(offsets[14], object.orderIndex);
  writer.writeString(offsets[15], object.responseJson);
  writer.writeString(offsets[16], object.targetLanguage);
  writer.writeDouble(offsets[17], object.thinkingMillsec);
  writer.writeString(offsets[18], object.toolJson);
  writer.writeString(offsets[19], object.topicId);
  writer.writeString(offsets[20], object.type);
  writer.writeString(offsets[21], object.url);
}

MessageBlockEntity _messageBlockEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageBlockEntity();
  object.blockId = reader.readString(offsets[0]);
  object.content = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readLong(offsets[2]);
  object.errorJson = reader.readStringOrNull(offsets[3]);
  object.fileId = reader.readStringOrNull(offsets[4]);
  object.fileJson = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.knowledgeJson = reader.readStringOrNull(offsets[12]);
  object.messageId = reader.readString(offsets[13]);
  object.orderIndex = reader.readLong(offsets[14]);
  object.responseJson = reader.readStringOrNull(offsets[15]);
  object.targetLanguage = reader.readStringOrNull(offsets[16]);
  object.thinkingMillsec = reader.readDoubleOrNull(offsets[17]);
  object.toolJson = reader.readStringOrNull(offsets[18]);
  object.topicId = reader.readString(offsets[19]);
  object.type = reader.readString(offsets[20]);
  object.url = reader.readStringOrNull(offsets[21]);
  return object;
}

P _messageBlockEntityDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messageBlockEntityGetId(MessageBlockEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messageBlockEntityGetLinks(
  MessageBlockEntity object,
) {
  return [];
}

void _messageBlockEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  MessageBlockEntity object,
) {
  object.id = id;
}

extension MessageBlockEntityByIndex on IsarCollection<MessageBlockEntity> {
  Future<MessageBlockEntity?> getByBlockId(String blockId) {
    return getByIndex(r'blockId', [blockId]);
  }

  MessageBlockEntity? getByBlockIdSync(String blockId) {
    return getByIndexSync(r'blockId', [blockId]);
  }

  Future<bool> deleteByBlockId(String blockId) {
    return deleteByIndex(r'blockId', [blockId]);
  }

  bool deleteByBlockIdSync(String blockId) {
    return deleteByIndexSync(r'blockId', [blockId]);
  }

  Future<List<MessageBlockEntity?>> getAllByBlockId(
    List<String> blockIdValues,
  ) {
    final values = blockIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'blockId', values);
  }

  List<MessageBlockEntity?> getAllByBlockIdSync(List<String> blockIdValues) {
    final values = blockIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'blockId', values);
  }

  Future<int> deleteAllByBlockId(List<String> blockIdValues) {
    final values = blockIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'blockId', values);
  }

  int deleteAllByBlockIdSync(List<String> blockIdValues) {
    final values = blockIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'blockId', values);
  }

  Future<Id> putByBlockId(MessageBlockEntity object) {
    return putByIndex(r'blockId', object);
  }

  Id putByBlockIdSync(MessageBlockEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'blockId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBlockId(List<MessageBlockEntity> objects) {
    return putAllByIndex(r'blockId', objects);
  }

  List<Id> putAllByBlockIdSync(
    List<MessageBlockEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'blockId', objects, saveLinks: saveLinks);
  }
}

extension MessageBlockEntityQueryWhereSort
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QWhere> {
  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MessageBlockEntityQueryWhere
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QWhereClause> {
  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  blockIdEqualTo(String blockId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'blockId', value: [blockId]),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  blockIdNotEqualTo(String blockId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [],
                upper: [blockId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [blockId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [blockId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [],
                upper: [blockId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  topicIdEqualTo(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'topicId', value: [topicId]),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdEqualToAnyOrderIndex(String messageId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'messageId_orderIndex',
          value: [messageId],
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdNotEqualToAnyOrderIndex(String messageId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [],
                upper: [messageId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [messageId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [messageId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [],
                upper: [messageId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdOrderIndexEqualTo(String messageId, int orderIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'messageId_orderIndex',
          value: [messageId, orderIndex],
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdEqualToOrderIndexNotEqualTo(String messageId, int orderIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [messageId],
                upper: [messageId, orderIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [messageId, orderIndex],
                includeLower: false,
                upper: [messageId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [messageId, orderIndex],
                includeLower: false,
                upper: [messageId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'messageId_orderIndex',
                lower: [messageId],
                upper: [messageId, orderIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdEqualToOrderIndexGreaterThan(
    String messageId,
    int orderIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'messageId_orderIndex',
          lower: [messageId, orderIndex],
          includeLower: include,
          upper: [messageId],
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdEqualToOrderIndexLessThan(
    String messageId,
    int orderIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'messageId_orderIndex',
          lower: [messageId],
          upper: [messageId, orderIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterWhereClause>
  messageIdEqualToOrderIndexBetween(
    String messageId,
    int lowerOrderIndex,
    int upperOrderIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'messageId_orderIndex',
          lower: [messageId, lowerOrderIndex],
          includeLower: includeLower,
          upper: [messageId, upperOrderIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MessageBlockEntityQueryFilter
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QFilterCondition> {
  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'blockId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'blockId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'blockId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  blockIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'blockId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'content'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'content'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentGreaterThan(
    String? value, {
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentLessThan(
    String? value, {
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'errorJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'errorJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'errorJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'errorJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'errorJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'errorJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'errorJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'errorJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'errorJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'errorJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'errorJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  errorJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'errorJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fileId'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fileId'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fileJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fileJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  fileJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  isErrorEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isError', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  isFileEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFile', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  isImageEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isImage', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  isMainTextEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMainText', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  isThinkingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isThinking', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  isToolEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isTool', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'knowledgeJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'knowledgeJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'knowledgeJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'knowledgeJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'knowledgeJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'knowledgeJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'knowledgeJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'knowledgeJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'knowledgeJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'knowledgeJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'knowledgeJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  knowledgeJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'knowledgeJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  messageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'messageId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  messageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'messageId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orderIndex', value: value),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  orderIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'orderIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  orderIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'orderIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  orderIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'orderIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'responseJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'responseJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'responseJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'responseJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'responseJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'responseJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'responseJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'responseJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'responseJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'responseJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'responseJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  responseJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'responseJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'targetLanguage'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'targetLanguage'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'targetLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'targetLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'targetLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'targetLanguage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'targetLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'targetLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'targetLanguage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'targetLanguage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'targetLanguage', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  targetLanguageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'targetLanguage', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  thinkingMillsecIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thinkingMillsec'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  thinkingMillsecIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thinkingMillsec'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  thinkingMillsecEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thinkingMillsec',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  thinkingMillsecGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thinkingMillsec',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  thinkingMillsecLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thinkingMillsec',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  thinkingMillsecBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thinkingMillsec',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'toolJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'toolJson'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'toolJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'toolJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'toolJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'toolJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'toolJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'toolJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'toolJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'toolJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'toolJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  toolJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'toolJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  topicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  topicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'url'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'url'),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'url',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'url',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterFilterCondition>
  urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }
}

extension MessageBlockEntityQueryObject
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QFilterCondition> {}

extension MessageBlockEntityQueryLinks
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QFilterCondition> {}

extension MessageBlockEntityQuerySortBy
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QSortBy> {
  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByBlockId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByBlockIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByErrorJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByErrorJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByFileJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByFileJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFile', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsFileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFile', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsMainText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainText', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsMainTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainText', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsThinking() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThinking', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsThinkingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThinking', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsTool() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTool', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByIsToolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTool', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByKnowledgeJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'knowledgeJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByKnowledgeJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'knowledgeJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByResponseJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByResponseJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByTargetLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByTargetLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByThinkingMillsec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thinkingMillsec', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByThinkingMillsecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thinkingMillsec', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByToolJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByToolJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension MessageBlockEntityQuerySortThenBy
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QSortThenBy> {
  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByBlockId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByBlockIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByErrorJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByErrorJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByFileJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByFileJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFile', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsFileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFile', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsMainText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainText', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsMainTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMainText', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsThinking() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThinking', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsThinkingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThinking', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsTool() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTool', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByIsToolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTool', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByKnowledgeJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'knowledgeJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByKnowledgeJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'knowledgeJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByResponseJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByResponseJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByTargetLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByTargetLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByThinkingMillsec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thinkingMillsec', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByThinkingMillsecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thinkingMillsec', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByToolJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolJson', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByToolJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolJson', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QAfterSortBy>
  thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension MessageBlockEntityQueryWhereDistinct
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct> {
  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByBlockId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByErrorJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByFileId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByFileJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByIsError() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isError');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByIsFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFile');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByIsImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isImage');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByIsMainText() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMainText');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByIsThinking() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isThinking');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByIsTool() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTool');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByKnowledgeJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'knowledgeJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByResponseJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'responseJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByTargetLanguage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'targetLanguage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByThinkingMillsec() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thinkingMillsec');
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByToolJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toolJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByTopicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageBlockEntity, MessageBlockEntity, QDistinct>
  distinctByUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension MessageBlockEntityQueryProperty
    on QueryBuilder<MessageBlockEntity, MessageBlockEntity, QQueryProperty> {
  QueryBuilder<MessageBlockEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MessageBlockEntity, String, QQueryOperations> blockIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockId');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<MessageBlockEntity, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  errorJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorJson');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations> fileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileId');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  fileJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileJson');
    });
  }

  QueryBuilder<MessageBlockEntity, bool, QQueryOperations> isErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isError');
    });
  }

  QueryBuilder<MessageBlockEntity, bool, QQueryOperations> isFileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFile');
    });
  }

  QueryBuilder<MessageBlockEntity, bool, QQueryOperations> isImageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isImage');
    });
  }

  QueryBuilder<MessageBlockEntity, bool, QQueryOperations>
  isMainTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMainText');
    });
  }

  QueryBuilder<MessageBlockEntity, bool, QQueryOperations>
  isThinkingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isThinking');
    });
  }

  QueryBuilder<MessageBlockEntity, bool, QQueryOperations> isToolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTool');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  knowledgeJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'knowledgeJson');
    });
  }

  QueryBuilder<MessageBlockEntity, String, QQueryOperations>
  messageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageId');
    });
  }

  QueryBuilder<MessageBlockEntity, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  responseJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'responseJson');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  targetLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetLanguage');
    });
  }

  QueryBuilder<MessageBlockEntity, double?, QQueryOperations>
  thinkingMillsecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thinkingMillsec');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations>
  toolJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toolJson');
    });
  }

  QueryBuilder<MessageBlockEntity, String, QQueryOperations> topicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicId');
    });
  }

  QueryBuilder<MessageBlockEntity, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<MessageBlockEntity, String?, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}
