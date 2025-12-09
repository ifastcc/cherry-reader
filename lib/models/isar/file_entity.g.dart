// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFileEntityCollection on Isar {
  IsarCollection<FileEntity> get fileEntitys => this.collection();
}

const FileEntitySchema = CollectionSchema(
  name: r'FileEntity',
  id: -8894801925475154393,
  properties: {
    r'canDelete': PropertySchema(
      id: 0,
      name: r'canDelete',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'fileId': PropertySchema(id: 2, name: r'fileId', type: IsarType.string),
    r'fileName': PropertySchema(
      id: 3,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'fileSize': PropertySchema(id: 4, name: r'fileSize', type: IsarType.long),
    r'hasLocalCache': PropertySchema(
      id: 5,
      name: r'hasLocalCache',
      type: IsarType.bool,
    ),
    r'isImage': PropertySchema(id: 6, name: r'isImage', type: IsarType.bool),
    r'localPath': PropertySchema(
      id: 7,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'mimeType': PropertySchema(
      id: 8,
      name: r'mimeType',
      type: IsarType.string,
    ),
    r'referenceCount': PropertySchema(
      id: 9,
      name: r'referenceCount',
      type: IsarType.long,
    ),
    r'sha256': PropertySchema(id: 10, name: r'sha256', type: IsarType.string),
    r'url': PropertySchema(id: 11, name: r'url', type: IsarType.string),
  },

  estimateSize: _fileEntityEstimateSize,
  serialize: _fileEntitySerialize,
  deserialize: _fileEntityDeserialize,
  deserializeProp: _fileEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'fileId': IndexSchema(
      id: -2092632783237962250,
      name: r'fileId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fileId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'sha256': IndexSchema(
      id: 5834825609754713283,
      name: r'sha256',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sha256',
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

  getId: _fileEntityGetId,
  getLinks: _fileEntityGetLinks,
  attach: _fileEntityAttach,
  version: '3.3.0',
);

int _fileEntityEstimateSize(
  FileEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileId.length * 3;
  {
    final value = object.fileName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mimeType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sha256;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.url;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _fileEntitySerialize(
  FileEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.canDelete);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.fileId);
  writer.writeString(offsets[3], object.fileName);
  writer.writeLong(offsets[4], object.fileSize);
  writer.writeBool(offsets[5], object.hasLocalCache);
  writer.writeBool(offsets[6], object.isImage);
  writer.writeString(offsets[7], object.localPath);
  writer.writeString(offsets[8], object.mimeType);
  writer.writeLong(offsets[9], object.referenceCount);
  writer.writeString(offsets[10], object.sha256);
  writer.writeString(offsets[11], object.url);
}

FileEntity _fileEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FileEntity();
  object.createdAt = reader.readLong(offsets[1]);
  object.fileId = reader.readString(offsets[2]);
  object.fileName = reader.readStringOrNull(offsets[3]);
  object.fileSize = reader.readLongOrNull(offsets[4]);
  object.id = id;
  object.localPath = reader.readStringOrNull(offsets[7]);
  object.mimeType = reader.readStringOrNull(offsets[8]);
  object.referenceCount = reader.readLong(offsets[9]);
  object.sha256 = reader.readStringOrNull(offsets[10]);
  object.url = reader.readStringOrNull(offsets[11]);
  return object;
}

P _fileEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _fileEntityGetId(FileEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _fileEntityGetLinks(FileEntity object) {
  return [];
}

void _fileEntityAttach(IsarCollection<dynamic> col, Id id, FileEntity object) {
  object.id = id;
}

extension FileEntityByIndex on IsarCollection<FileEntity> {
  Future<FileEntity?> getByFileId(String fileId) {
    return getByIndex(r'fileId', [fileId]);
  }

  FileEntity? getByFileIdSync(String fileId) {
    return getByIndexSync(r'fileId', [fileId]);
  }

  Future<bool> deleteByFileId(String fileId) {
    return deleteByIndex(r'fileId', [fileId]);
  }

  bool deleteByFileIdSync(String fileId) {
    return deleteByIndexSync(r'fileId', [fileId]);
  }

  Future<List<FileEntity?>> getAllByFileId(List<String> fileIdValues) {
    final values = fileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'fileId', values);
  }

  List<FileEntity?> getAllByFileIdSync(List<String> fileIdValues) {
    final values = fileIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'fileId', values);
  }

  Future<int> deleteAllByFileId(List<String> fileIdValues) {
    final values = fileIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'fileId', values);
  }

  int deleteAllByFileIdSync(List<String> fileIdValues) {
    final values = fileIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'fileId', values);
  }

  Future<Id> putByFileId(FileEntity object) {
    return putByIndex(r'fileId', object);
  }

  Id putByFileIdSync(FileEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'fileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFileId(List<FileEntity> objects) {
    return putAllByIndex(r'fileId', objects);
  }

  List<Id> putAllByFileIdSync(
    List<FileEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'fileId', objects, saveLinks: saveLinks);
  }
}

extension FileEntityQueryWhereSort
    on QueryBuilder<FileEntity, FileEntity, QWhere> {
  QueryBuilder<FileEntity, FileEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension FileEntityQueryWhere
    on QueryBuilder<FileEntity, FileEntity, QWhereClause> {
  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> fileIdEqualTo(
    String fileId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'fileId', value: [fileId]),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> fileIdNotEqualTo(
    String fileId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'fileId',
                lower: [],
                upper: [fileId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'fileId',
                lower: [fileId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'fileId',
                lower: [fileId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'fileId',
                lower: [],
                upper: [fileId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> sha256IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'sha256', value: [null]),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> sha256IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'sha256',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> sha256EqualTo(
    String? sha256,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'sha256', value: [sha256]),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> sha256NotEqualTo(
    String? sha256,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [],
                upper: [sha256],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [sha256],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [sha256],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [],
                upper: [sha256],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> createdAtEqualTo(
    int createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> createdAtNotEqualTo(
    int createdAt,
  ) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> createdAtGreaterThan(
    int createdAt, {
    bool include = false,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> createdAtLessThan(
    int createdAt, {
    bool include = false,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterWhereClause> createdAtBetween(
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

extension FileEntityQueryFilter
    on QueryBuilder<FileEntity, FileEntity, QFilterCondition> {
  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> canDeleteEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'canDelete', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> createdAtEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> createdAtLessThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdGreaterThan(
    String value, {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdLessThan(
    String value, {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileId', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileId', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fileName'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fileName'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fileSize'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fileSize'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileSizeEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileSize', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  fileSizeGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileSizeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> fileSizeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  hasLocalCacheEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasLocalCache', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> isImageEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isImage', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  localPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localPath'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  localPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localPath'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> localPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  localPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> localPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> localPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  localPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> localPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> localPathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> localPathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localPath', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localPath', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'mimeType'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  mimeTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'mimeType'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  mimeTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mimeType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  mimeTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> mimeTypeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mimeType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  mimeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mimeType', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  mimeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mimeType', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  referenceCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceCount', value: value),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  referenceCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'referenceCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  referenceCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'referenceCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  referenceCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'referenceCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sha256'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  sha256IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sha256'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sha256',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256Contains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256Matches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sha256',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> sha256IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sha256', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition>
  sha256IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sha256', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'url'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'url'),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlGreaterThan(
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlLessThan(
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlBetween(
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }
}

extension FileEntityQueryObject
    on QueryBuilder<FileEntity, FileEntity, QFilterCondition> {}

extension FileEntityQueryLinks
    on QueryBuilder<FileEntity, FileEntity, QFilterCondition> {}

extension FileEntityQuerySortBy
    on QueryBuilder<FileEntity, FileEntity, QSortBy> {
  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByCanDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByCanDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByHasLocalCache() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasLocalCache', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByHasLocalCacheDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasLocalCache', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByIsImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByIsImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByMimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByMimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByReferenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCount', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy>
  sortByReferenceCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCount', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortBySha256() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortBySha256Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension FileEntityQuerySortThenBy
    on QueryBuilder<FileEntity, FileEntity, QSortThenBy> {
  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByCanDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByCanDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileId', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByHasLocalCache() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasLocalCache', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByHasLocalCacheDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasLocalCache', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByIsImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByIsImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImage', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByMimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByMimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByReferenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCount', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy>
  thenByReferenceCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCount', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenBySha256() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenBySha256Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.desc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension FileEntityQueryWhereDistinct
    on QueryBuilder<FileEntity, FileEntity, QDistinct> {
  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByCanDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canDelete');
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByFileId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByFileName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSize');
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByHasLocalCache() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasLocalCache');
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByIsImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isImage');
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByLocalPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByMimeType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mimeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByReferenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceCount');
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctBySha256({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sha256', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FileEntity, FileEntity, QDistinct> distinctByUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension FileEntityQueryProperty
    on QueryBuilder<FileEntity, FileEntity, QQueryProperty> {
  QueryBuilder<FileEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FileEntity, bool, QQueryOperations> canDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canDelete');
    });
  }

  QueryBuilder<FileEntity, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FileEntity, String, QQueryOperations> fileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileId');
    });
  }

  QueryBuilder<FileEntity, String?, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<FileEntity, int?, QQueryOperations> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSize');
    });
  }

  QueryBuilder<FileEntity, bool, QQueryOperations> hasLocalCacheProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasLocalCache');
    });
  }

  QueryBuilder<FileEntity, bool, QQueryOperations> isImageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isImage');
    });
  }

  QueryBuilder<FileEntity, String?, QQueryOperations> localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<FileEntity, String?, QQueryOperations> mimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mimeType');
    });
  }

  QueryBuilder<FileEntity, int, QQueryOperations> referenceCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceCount');
    });
  }

  QueryBuilder<FileEntity, String?, QQueryOperations> sha256Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sha256');
    });
  }

  QueryBuilder<FileEntity, String?, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}
