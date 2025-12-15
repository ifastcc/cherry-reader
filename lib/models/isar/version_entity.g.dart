// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVersionEntityCollection on Isar {
  IsarCollection<VersionEntity> get versionEntitys => this.collection();
}

const VersionEntitySchema = CollectionSchema(
  name: r'VersionEntity',
  id: 1741822393060962916,
  properties: {
    r'fileSizeBytes': PropertySchema(
      id: 0,
      name: r'fileSizeBytes',
      type: IsarType.long,
    ),
    r'importedAtMs': PropertySchema(
      id: 1,
      name: r'importedAtMs',
      type: IsarType.long,
    ),
    r'isLocked': PropertySchema(id: 2, name: r'isLocked', type: IsarType.bool),
    r'isarPath': PropertySchema(
      id: 3,
      name: r'isarPath',
      type: IsarType.string,
    ),
    r'messageCount': PropertySchema(
      id: 4,
      name: r'messageCount',
      type: IsarType.long,
    ),
    r'sourceFileName': PropertySchema(
      id: 5,
      name: r'sourceFileName',
      type: IsarType.string,
    ),
    r'sourceModifiedAtMs': PropertySchema(
      id: 6,
      name: r'sourceModifiedAtMs',
      type: IsarType.long,
    ),
    r'statusIndex': PropertySchema(
      id: 7,
      name: r'statusIndex',
      type: IsarType.long,
    ),
    r'topicCount': PropertySchema(
      id: 8,
      name: r'topicCount',
      type: IsarType.long,
    ),
    r'versionId': PropertySchema(
      id: 9,
      name: r'versionId',
      type: IsarType.string,
    ),
  },

  estimateSize: _versionEntityEstimateSize,
  serialize: _versionEntitySerialize,
  deserialize: _versionEntityDeserialize,
  deserializeProp: _versionEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'versionId': IndexSchema(
      id: -4747984966447694449,
      name: r'versionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'versionId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'importedAtMs': IndexSchema(
      id: 7913378031396809861,
      name: r'importedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'importedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'statusIndex': IndexSchema(
      id: -3068638669929638322,
      name: r'statusIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'statusIndex',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _versionEntityGetId,
  getLinks: _versionEntityGetLinks,
  attach: _versionEntityAttach,
  version: '3.3.0',
);

int _versionEntityEstimateSize(
  VersionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.isarPath.length * 3;
  bytesCount += 3 + object.sourceFileName.length * 3;
  bytesCount += 3 + object.versionId.length * 3;
  return bytesCount;
}

void _versionEntitySerialize(
  VersionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.fileSizeBytes);
  writer.writeLong(offsets[1], object.importedAtMs);
  writer.writeBool(offsets[2], object.isLocked);
  writer.writeString(offsets[3], object.isarPath);
  writer.writeLong(offsets[4], object.messageCount);
  writer.writeString(offsets[5], object.sourceFileName);
  writer.writeLong(offsets[6], object.sourceModifiedAtMs);
  writer.writeLong(offsets[7], object.statusIndex);
  writer.writeLong(offsets[8], object.topicCount);
  writer.writeString(offsets[9], object.versionId);
}

VersionEntity _versionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VersionEntity();
  object.fileSizeBytes = reader.readLong(offsets[0]);
  object.id = id;
  object.importedAtMs = reader.readLong(offsets[1]);
  object.isLocked = reader.readBool(offsets[2]);
  object.isarPath = reader.readString(offsets[3]);
  object.messageCount = reader.readLong(offsets[4]);
  object.sourceFileName = reader.readString(offsets[5]);
  object.sourceModifiedAtMs = reader.readLong(offsets[6]);
  object.statusIndex = reader.readLong(offsets[7]);
  object.topicCount = reader.readLong(offsets[8]);
  object.versionId = reader.readString(offsets[9]);
  return object;
}

P _versionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _versionEntityGetId(VersionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _versionEntityGetLinks(VersionEntity object) {
  return [];
}

void _versionEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  VersionEntity object,
) {
  object.id = id;
}

extension VersionEntityByIndex on IsarCollection<VersionEntity> {
  Future<VersionEntity?> getByVersionId(String versionId) {
    return getByIndex(r'versionId', [versionId]);
  }

  VersionEntity? getByVersionIdSync(String versionId) {
    return getByIndexSync(r'versionId', [versionId]);
  }

  Future<bool> deleteByVersionId(String versionId) {
    return deleteByIndex(r'versionId', [versionId]);
  }

  bool deleteByVersionIdSync(String versionId) {
    return deleteByIndexSync(r'versionId', [versionId]);
  }

  Future<List<VersionEntity?>> getAllByVersionId(List<String> versionIdValues) {
    final values = versionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'versionId', values);
  }

  List<VersionEntity?> getAllByVersionIdSync(List<String> versionIdValues) {
    final values = versionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'versionId', values);
  }

  Future<int> deleteAllByVersionId(List<String> versionIdValues) {
    final values = versionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'versionId', values);
  }

  int deleteAllByVersionIdSync(List<String> versionIdValues) {
    final values = versionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'versionId', values);
  }

  Future<Id> putByVersionId(VersionEntity object) {
    return putByIndex(r'versionId', object);
  }

  Id putByVersionIdSync(VersionEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'versionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVersionId(List<VersionEntity> objects) {
    return putAllByIndex(r'versionId', objects);
  }

  List<Id> putAllByVersionIdSync(
    List<VersionEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'versionId', objects, saveLinks: saveLinks);
  }
}

extension VersionEntityQueryWhereSort
    on QueryBuilder<VersionEntity, VersionEntity, QWhere> {
  QueryBuilder<VersionEntity, VersionEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhere> anyImportedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'importedAtMs'),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhere> anyStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'statusIndex'),
      );
    });
  }
}

extension VersionEntityQueryWhere
    on QueryBuilder<VersionEntity, VersionEntity, QWhereClause> {
  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  versionIdEqualTo(String versionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'versionId', value: [versionId]),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  versionIdNotEqualTo(String versionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'versionId',
                lower: [],
                upper: [versionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'versionId',
                lower: [versionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'versionId',
                lower: [versionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'versionId',
                lower: [],
                upper: [versionId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  importedAtMsEqualTo(int importedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'importedAtMs',
          value: [importedAtMs],
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  importedAtMsNotEqualTo(int importedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAtMs',
                lower: [],
                upper: [importedAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAtMs',
                lower: [importedAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAtMs',
                lower: [importedAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAtMs',
                lower: [],
                upper: [importedAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  importedAtMsGreaterThan(int importedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAtMs',
          lower: [importedAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  importedAtMsLessThan(int importedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAtMs',
          lower: [],
          upper: [importedAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  importedAtMsBetween(
    int lowerImportedAtMs,
    int upperImportedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAtMs',
          lower: [lowerImportedAtMs],
          includeLower: includeLower,
          upper: [upperImportedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  statusIndexEqualTo(int statusIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'statusIndex',
          value: [statusIndex],
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  statusIndexNotEqualTo(int statusIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusIndex',
                lower: [],
                upper: [statusIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusIndex',
                lower: [statusIndex],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusIndex',
                lower: [statusIndex],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusIndex',
                lower: [],
                upper: [statusIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  statusIndexGreaterThan(int statusIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'statusIndex',
          lower: [statusIndex],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  statusIndexLessThan(int statusIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'statusIndex',
          lower: [],
          upper: [statusIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterWhereClause>
  statusIndexBetween(
    int lowerStatusIndex,
    int upperStatusIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'statusIndex',
          lower: [lowerStatusIndex],
          includeLower: includeLower,
          upper: [upperStatusIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension VersionEntityQueryFilter
    on QueryBuilder<VersionEntity, VersionEntity, QFilterCondition> {
  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  fileSizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileSizeBytes', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  fileSizeBytesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileSizeBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  fileSizeBytesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileSizeBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  fileSizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileSizeBytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  importedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importedAtMs', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  importedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  importedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  importedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isLockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isLocked', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'isarPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'isarPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'isarPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'isarPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'isarPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarPath', value: ''),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  isarPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'isarPath', value: ''),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  messageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'messageCount', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
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

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceFileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceFileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceFileName', value: ''),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceFileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceFileName', value: ''),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceModifiedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceModifiedAtMs', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceModifiedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceModifiedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceModifiedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceModifiedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  sourceModifiedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceModifiedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  statusIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'statusIndex', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  statusIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'statusIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  statusIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'statusIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  statusIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'statusIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  topicCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topicCount', value: value),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  topicCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'topicCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  topicCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'topicCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  topicCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'topicCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'versionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'versionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'versionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'versionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'versionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'versionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'versionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'versionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'versionId', value: ''),
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterFilterCondition>
  versionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'versionId', value: ''),
      );
    });
  }
}

extension VersionEntityQueryObject
    on QueryBuilder<VersionEntity, VersionEntity, QFilterCondition> {}

extension VersionEntityQueryLinks
    on QueryBuilder<VersionEntity, VersionEntity, QFilterCondition> {}

extension VersionEntityQuerySortBy
    on QueryBuilder<VersionEntity, VersionEntity, QSortBy> {
  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByFileSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByImportedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAtMs', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByImportedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAtMs', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> sortByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> sortByIsarPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarPath', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByIsarPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarPath', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortBySourceFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceFileName', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortBySourceFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceFileName', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortBySourceModifiedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceModifiedAtMs', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortBySourceModifiedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceModifiedAtMs', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> sortByStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByStatusIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> sortByTopicCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicCount', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByTopicCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicCount', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> sortByVersionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionId', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  sortByVersionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionId', Sort.desc);
    });
  }
}

extension VersionEntityQuerySortThenBy
    on QueryBuilder<VersionEntity, VersionEntity, QSortThenBy> {
  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByFileSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByImportedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAtMs', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByImportedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAtMs', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenByIsarPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarPath', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByIsarPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarPath', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenBySourceFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceFileName', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenBySourceFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceFileName', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenBySourceModifiedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceModifiedAtMs', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenBySourceModifiedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceModifiedAtMs', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenByStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByStatusIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenByTopicCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicCount', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByTopicCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicCount', Sort.desc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy> thenByVersionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionId', Sort.asc);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QAfterSortBy>
  thenByVersionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionId', Sort.desc);
    });
  }
}

extension VersionEntityQueryWhereDistinct
    on QueryBuilder<VersionEntity, VersionEntity, QDistinct> {
  QueryBuilder<VersionEntity, VersionEntity, QDistinct>
  distinctByFileSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSizeBytes');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct>
  distinctByImportedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importedAtMs');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct> distinctByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLocked');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct> distinctByIsarPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isarPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct>
  distinctByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageCount');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct>
  distinctBySourceFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceFileName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct>
  distinctBySourceModifiedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceModifiedAtMs');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct>
  distinctByStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusIndex');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct> distinctByTopicCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicCount');
    });
  }

  QueryBuilder<VersionEntity, VersionEntity, QDistinct> distinctByVersionId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'versionId', caseSensitive: caseSensitive);
    });
  }
}

extension VersionEntityQueryProperty
    on QueryBuilder<VersionEntity, VersionEntity, QQueryProperty> {
  QueryBuilder<VersionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VersionEntity, int, QQueryOperations> fileSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSizeBytes');
    });
  }

  QueryBuilder<VersionEntity, int, QQueryOperations> importedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importedAtMs');
    });
  }

  QueryBuilder<VersionEntity, bool, QQueryOperations> isLockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLocked');
    });
  }

  QueryBuilder<VersionEntity, String, QQueryOperations> isarPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarPath');
    });
  }

  QueryBuilder<VersionEntity, int, QQueryOperations> messageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageCount');
    });
  }

  QueryBuilder<VersionEntity, String, QQueryOperations>
  sourceFileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceFileName');
    });
  }

  QueryBuilder<VersionEntity, int, QQueryOperations>
  sourceModifiedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceModifiedAtMs');
    });
  }

  QueryBuilder<VersionEntity, int, QQueryOperations> statusIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusIndex');
    });
  }

  QueryBuilder<VersionEntity, int, QQueryOperations> topicCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicCount');
    });
  }

  QueryBuilder<VersionEntity, String, QQueryOperations> versionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'versionId');
    });
  }
}
