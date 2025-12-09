// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageEntityCollection on Isar {
  IsarCollection<MessageEntity> get messageEntitys => this.collection();
}

const MessageEntitySchema = CollectionSchema(
  name: r'MessageEntity',
  id: 2569526783852321106,
  properties: {
    r'askId': PropertySchema(id: 0, name: r'askId', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'isAssistant': PropertySchema(
      id: 2,
      name: r'isAssistant',
      type: IsarType.bool,
    ),
    r'isUser': PropertySchema(id: 3, name: r'isUser', type: IsarType.bool),
    r'mentionsJson': PropertySchema(
      id: 4,
      name: r'mentionsJson',
      type: IsarType.string,
    ),
    r'messageId': PropertySchema(
      id: 5,
      name: r'messageId',
      type: IsarType.string,
    ),
    r'metricsJson': PropertySchema(
      id: 6,
      name: r'metricsJson',
      type: IsarType.string,
    ),
    r'modelId': PropertySchema(id: 7, name: r'modelId', type: IsarType.string),
    r'modelName': PropertySchema(
      id: 8,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'orderIndex': PropertySchema(
      id: 9,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'role': PropertySchema(id: 10, name: r'role', type: IsarType.string),
    r'roundIndex': PropertySchema(
      id: 11,
      name: r'roundIndex',
      type: IsarType.long,
    ),
    r'status': PropertySchema(id: 12, name: r'status', type: IsarType.string),
    r'topicId': PropertySchema(id: 13, name: r'topicId', type: IsarType.string),
    r'usageJson': PropertySchema(
      id: 14,
      name: r'usageJson',
      type: IsarType.string,
    ),
    r'useful': PropertySchema(id: 15, name: r'useful', type: IsarType.bool),
  },

  estimateSize: _messageEntityEstimateSize,
  serialize: _messageEntitySerialize,
  deserialize: _messageEntityDeserialize,
  deserializeProp: _messageEntityDeserializeProp,
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
    r'topicId_orderIndex': IndexSchema(
      id: 7749318808457378320,
      name: r'topicId_orderIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'topicId',
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
    r'roundIndex': IndexSchema(
      id: 4841269634881066912,
      name: r'roundIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'roundIndex',
          type: IndexType.value,
          caseSensitive: false,
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

  getId: _messageEntityGetId,
  getLinks: _messageEntityGetLinks,
  attach: _messageEntityAttach,
  version: '3.3.0',
);

int _messageEntityEstimateSize(
  MessageEntity object,
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
  {
    final value = object.mentionsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageId.length * 3;
  {
    final value = object.metricsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  bytesCount += 3 + object.topicId.length * 3;
  {
    final value = object.usageJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _messageEntitySerialize(
  MessageEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.askId);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.isAssistant);
  writer.writeBool(offsets[3], object.isUser);
  writer.writeString(offsets[4], object.mentionsJson);
  writer.writeString(offsets[5], object.messageId);
  writer.writeString(offsets[6], object.metricsJson);
  writer.writeString(offsets[7], object.modelId);
  writer.writeString(offsets[8], object.modelName);
  writer.writeLong(offsets[9], object.orderIndex);
  writer.writeString(offsets[10], object.role);
  writer.writeLong(offsets[11], object.roundIndex);
  writer.writeString(offsets[12], object.status);
  writer.writeString(offsets[13], object.topicId);
  writer.writeString(offsets[14], object.usageJson);
  writer.writeBool(offsets[15], object.useful);
}

MessageEntity _messageEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageEntity();
  object.askId = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readLong(offsets[1]);
  object.id = id;
  object.mentionsJson = reader.readStringOrNull(offsets[4]);
  object.messageId = reader.readString(offsets[5]);
  object.metricsJson = reader.readStringOrNull(offsets[6]);
  object.modelId = reader.readStringOrNull(offsets[7]);
  object.modelName = reader.readStringOrNull(offsets[8]);
  object.orderIndex = reader.readLong(offsets[9]);
  object.role = reader.readString(offsets[10]);
  object.roundIndex = reader.readLong(offsets[11]);
  object.status = reader.readString(offsets[12]);
  object.topicId = reader.readString(offsets[13]);
  object.usageJson = reader.readStringOrNull(offsets[14]);
  object.useful = reader.readBool(offsets[15]);
  return object;
}

P _messageEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messageEntityGetId(MessageEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messageEntityGetLinks(MessageEntity object) {
  return [];
}

void _messageEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  MessageEntity object,
) {
  object.id = id;
}

extension MessageEntityByIndex on IsarCollection<MessageEntity> {
  Future<MessageEntity?> getByMessageId(String messageId) {
    return getByIndex(r'messageId', [messageId]);
  }

  MessageEntity? getByMessageIdSync(String messageId) {
    return getByIndexSync(r'messageId', [messageId]);
  }

  Future<bool> deleteByMessageId(String messageId) {
    return deleteByIndex(r'messageId', [messageId]);
  }

  bool deleteByMessageIdSync(String messageId) {
    return deleteByIndexSync(r'messageId', [messageId]);
  }

  Future<List<MessageEntity?>> getAllByMessageId(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'messageId', values);
  }

  List<MessageEntity?> getAllByMessageIdSync(List<String> messageIdValues) {
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

  Future<Id> putByMessageId(MessageEntity object) {
    return putByIndex(r'messageId', object);
  }

  Id putByMessageIdSync(MessageEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'messageId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMessageId(List<MessageEntity> objects) {
    return putAllByIndex(r'messageId', objects);
  }

  List<Id> putAllByMessageIdSync(
    List<MessageEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'messageId', objects, saveLinks: saveLinks);
  }
}

extension MessageEntityQueryWhereSort
    on QueryBuilder<MessageEntity, MessageEntity, QWhere> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhere> anyRoundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'roundIndex'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension MessageEntityQueryWhere
    on QueryBuilder<MessageEntity, MessageEntity, QWhereClause> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  messageIdEqualTo(String messageId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'messageId', value: [messageId]),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdEqualToAnyOrderIndex(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'topicId_orderIndex',
          value: [topicId],
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdNotEqualToAnyOrderIndex(String topicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [],
                upper: [topicId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [topicId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [topicId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [],
                upper: [topicId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdOrderIndexEqualTo(String topicId, int orderIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'topicId_orderIndex',
          value: [topicId, orderIndex],
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdEqualToOrderIndexNotEqualTo(String topicId, int orderIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [topicId],
                upper: [topicId, orderIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [topicId, orderIndex],
                includeLower: false,
                upper: [topicId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [topicId, orderIndex],
                includeLower: false,
                upper: [topicId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_orderIndex',
                lower: [topicId],
                upper: [topicId, orderIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdEqualToOrderIndexGreaterThan(
    String topicId,
    int orderIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_orderIndex',
          lower: [topicId, orderIndex],
          includeLower: include,
          upper: [topicId],
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdEqualToOrderIndexLessThan(
    String topicId,
    int orderIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_orderIndex',
          lower: [topicId],
          upper: [topicId, orderIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  topicIdEqualToOrderIndexBetween(
    String topicId,
    int lowerOrderIndex,
    int upperOrderIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_orderIndex',
          lower: [topicId, lowerOrderIndex],
          includeLower: includeLower,
          upper: [topicId, upperOrderIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  roundIndexEqualTo(int roundIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'roundIndex', value: [roundIndex]),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  roundIndexNotEqualTo(int roundIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'roundIndex',
                lower: [],
                upper: [roundIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'roundIndex',
                lower: [roundIndex],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'roundIndex',
                lower: [roundIndex],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'roundIndex',
                lower: [],
                upper: [roundIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  roundIndexGreaterThan(int roundIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'roundIndex',
          lower: [roundIndex],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  roundIndexLessThan(int roundIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'roundIndex',
          lower: [],
          upper: [roundIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  roundIndexBetween(
    int lowerRoundIndex,
    int upperRoundIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'roundIndex',
          lower: [lowerRoundIndex],
          includeLower: includeLower,
          upper: [upperRoundIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> askIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'askId', value: [null]),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> askIdEqualTo(
    String? askId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'askId', value: [askId]),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> askIdNotEqualTo(
    String? askId,
  ) {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
  createdAtEqualTo(int createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
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

extension MessageEntityQueryFilter
    on QueryBuilder<MessageEntity, MessageEntity, QFilterCondition> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  askIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'askId'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  askIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'askId'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  askIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'askId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  askIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'askId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  isAssistantEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isAssistant', value: value),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  isUserEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isUser', value: value),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'mentionsJson'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'mentionsJson'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mentionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mentionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mentionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mentionsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mentionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mentionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mentionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mentionsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mentionsJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  mentionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mentionsJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  messageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'messageId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  messageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'messageId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'metricsJson'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'metricsJson'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'metricsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'metricsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'metricsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'metricsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'metricsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'metricsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'metricsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'metricsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metricsJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  metricsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'metricsJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'modelId'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'modelId'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'modelName'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'modelName'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modelName', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orderIndex', value: value),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> roleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> roleBetween(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> roleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  roundIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'roundIndex', value: value),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  roundIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'roundIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  roundIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'roundIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  roundIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'roundIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  topicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  topicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  usageJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'usageJson'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  usageJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'usageJson'),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  usageJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'usageJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  usageJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'usageJson', value: ''),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
  usefulEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'useful', value: value),
      );
    });
  }
}

extension MessageEntityQueryObject
    on QueryBuilder<MessageEntity, MessageEntity, QFilterCondition> {}

extension MessageEntityQueryLinks
    on QueryBuilder<MessageEntity, MessageEntity, QFilterCondition> {}

extension MessageEntityQuerySortBy
    on QueryBuilder<MessageEntity, MessageEntity, QSortBy> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByAskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByAskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByIsAssistant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAssistant', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByIsAssistantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAssistant', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByMentionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mentionsJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByMentionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mentionsJson', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByMetricsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metricsJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByMetricsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metricsJson', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByRoundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundIndex', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByRoundIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundIndex', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByUsageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  sortByUsageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByUseful() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useful', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByUsefulDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useful', Sort.desc);
    });
  }
}

extension MessageEntityQuerySortThenBy
    on QueryBuilder<MessageEntity, MessageEntity, QSortThenBy> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByAskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByAskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'askId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIsAssistant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAssistant', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByIsAssistantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAssistant', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByMentionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mentionsJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByMentionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mentionsJson', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByMetricsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metricsJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByMetricsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metricsJson', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByModelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByModelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByRoundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundIndex', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByRoundIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roundIndex', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByUsageJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
  thenByUsageJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageJson', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByUseful() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useful', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByUsefulDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useful', Sort.desc);
    });
  }
}

extension MessageEntityQueryWhereDistinct
    on QueryBuilder<MessageEntity, MessageEntity, QDistinct> {
  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByAskId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'askId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
  distinctByIsAssistant() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAssistant');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUser');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByMentionsJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mentionsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByMessageId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByMetricsJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metricsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByModelId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByModelName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByRole({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByRoundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roundIndex');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByTopicId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByUsageJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usageJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByUseful() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useful');
    });
  }
}

extension MessageEntityQueryProperty
    on QueryBuilder<MessageEntity, MessageEntity, QQueryProperty> {
  QueryBuilder<MessageEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> askIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'askId');
    });
  }

  QueryBuilder<MessageEntity, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MessageEntity, bool, QQueryOperations> isAssistantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAssistant');
    });
  }

  QueryBuilder<MessageEntity, bool, QQueryOperations> isUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUser');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations>
  mentionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mentionsJson');
    });
  }

  QueryBuilder<MessageEntity, String, QQueryOperations> messageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageId');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> metricsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metricsJson');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> modelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelId');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<MessageEntity, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<MessageEntity, String, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<MessageEntity, int, QQueryOperations> roundIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roundIndex');
    });
  }

  QueryBuilder<MessageEntity, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<MessageEntity, String, QQueryOperations> topicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicId');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> usageJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usageJson');
    });
  }

  QueryBuilder<MessageEntity, bool, QQueryOperations> usefulProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useful');
    });
  }
}
