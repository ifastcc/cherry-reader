// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perspective_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPerspectiveEntityCollection on Isar {
  IsarCollection<PerspectiveEntity> get perspectiveEntitys => this.collection();
}

const PerspectiveEntitySchema = CollectionSchema(
  name: r'PerspectiveEntity',
  id: -7206895427389277192,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'icon': PropertySchema(id: 3, name: r'icon', type: IsarType.string),
    r'isBuiltin': PropertySchema(
      id: 4,
      name: r'isBuiltin',
      type: IsarType.bool,
    ),
    r'isEnabled': PropertySchema(
      id: 5,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(id: 6, name: r'name', type: IsarType.string),
    r'perspectiveId': PropertySchema(
      id: 7,
      name: r'perspectiveId',
      type: IsarType.string,
    ),
    r'promptTemplate': PropertySchema(
      id: 8,
      name: r'promptTemplate',
      type: IsarType.string,
    ),
    r'sortOrder': PropertySchema(
      id: 9,
      name: r'sortOrder',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.long,
    ),
  },

  estimateSize: _perspectiveEntityEstimateSize,
  serialize: _perspectiveEntitySerialize,
  deserialize: _perspectiveEntityDeserialize,
  deserializeProp: _perspectiveEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'perspectiveId': IndexSchema(
      id: 2580632355324919489,
      name: r'perspectiveId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'perspectiveId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _perspectiveEntityGetId,
  getLinks: _perspectiveEntityGetLinks,
  attach: _perspectiveEntityAttach,
  version: '3.3.0',
);

int _perspectiveEntityEstimateSize(
  PerspectiveEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.icon.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.perspectiveId.length * 3;
  bytesCount += 3 + object.promptTemplate.length * 3;
  return bytesCount;
}

void _perspectiveEntitySerialize(
  PerspectiveEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.description);
  writer.writeString(offsets[3], object.icon);
  writer.writeBool(offsets[4], object.isBuiltin);
  writer.writeBool(offsets[5], object.isEnabled);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.perspectiveId);
  writer.writeString(offsets[8], object.promptTemplate);
  writer.writeLong(offsets[9], object.sortOrder);
  writer.writeLong(offsets[10], object.updatedAt);
}

PerspectiveEntity _perspectiveEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PerspectiveEntity();
  object.category = reader.readString(offsets[0]);
  object.createdAt = reader.readLong(offsets[1]);
  object.description = reader.readString(offsets[2]);
  object.icon = reader.readString(offsets[3]);
  object.id = id;
  object.isBuiltin = reader.readBool(offsets[4]);
  object.isEnabled = reader.readBool(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.perspectiveId = reader.readString(offsets[7]);
  object.promptTemplate = reader.readString(offsets[8]);
  object.sortOrder = reader.readLong(offsets[9]);
  object.updatedAt = reader.readLong(offsets[10]);
  return object;
}

P _perspectiveEntityDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _perspectiveEntityGetId(PerspectiveEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _perspectiveEntityGetLinks(
  PerspectiveEntity object,
) {
  return [];
}

void _perspectiveEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  PerspectiveEntity object,
) {
  object.id = id;
}

extension PerspectiveEntityByIndex on IsarCollection<PerspectiveEntity> {
  Future<PerspectiveEntity?> getByPerspectiveId(String perspectiveId) {
    return getByIndex(r'perspectiveId', [perspectiveId]);
  }

  PerspectiveEntity? getByPerspectiveIdSync(String perspectiveId) {
    return getByIndexSync(r'perspectiveId', [perspectiveId]);
  }

  Future<bool> deleteByPerspectiveId(String perspectiveId) {
    return deleteByIndex(r'perspectiveId', [perspectiveId]);
  }

  bool deleteByPerspectiveIdSync(String perspectiveId) {
    return deleteByIndexSync(r'perspectiveId', [perspectiveId]);
  }

  Future<List<PerspectiveEntity?>> getAllByPerspectiveId(
    List<String> perspectiveIdValues,
  ) {
    final values = perspectiveIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'perspectiveId', values);
  }

  List<PerspectiveEntity?> getAllByPerspectiveIdSync(
    List<String> perspectiveIdValues,
  ) {
    final values = perspectiveIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'perspectiveId', values);
  }

  Future<int> deleteAllByPerspectiveId(List<String> perspectiveIdValues) {
    final values = perspectiveIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'perspectiveId', values);
  }

  int deleteAllByPerspectiveIdSync(List<String> perspectiveIdValues) {
    final values = perspectiveIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'perspectiveId', values);
  }

  Future<Id> putByPerspectiveId(PerspectiveEntity object) {
    return putByIndex(r'perspectiveId', object);
  }

  Id putByPerspectiveIdSync(PerspectiveEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'perspectiveId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPerspectiveId(List<PerspectiveEntity> objects) {
    return putAllByIndex(r'perspectiveId', objects);
  }

  List<Id> putAllByPerspectiveIdSync(
    List<PerspectiveEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'perspectiveId', objects, saveLinks: saveLinks);
  }
}

extension PerspectiveEntityQueryWhereSort
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QWhere> {
  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PerspectiveEntityQueryWhere
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QWhereClause> {
  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
  perspectiveIdEqualTo(String perspectiveId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'perspectiveId',
          value: [perspectiveId],
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterWhereClause>
  perspectiveIdNotEqualTo(String perspectiveId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'perspectiveId',
                lower: [],
                upper: [perspectiveId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'perspectiveId',
                lower: [perspectiveId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'perspectiveId',
                lower: [perspectiveId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'perspectiveId',
                lower: [],
                upper: [perspectiveId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension PerspectiveEntityQueryFilter
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QFilterCondition> {
  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'icon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'icon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'icon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'icon',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'icon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'icon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'icon',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'icon',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'icon', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  iconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'icon', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  isBuiltinEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isBuiltin', value: value),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isEnabled', value: value),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  perspectiveIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'perspectiveId', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  perspectiveIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'perspectiveId', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'promptTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'promptTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'promptTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'promptTemplate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'promptTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'promptTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'promptTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'promptTemplate',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'promptTemplate', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  promptTemplateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'promptTemplate', value: ''),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  sortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sortOrder', value: value),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  sortOrderGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sortOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  sortOrderLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sortOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  sortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sortOrder',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
  updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterFilterCondition>
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

extension PerspectiveEntityQueryObject
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QFilterCondition> {}

extension PerspectiveEntityQueryLinks
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QFilterCondition> {}

extension PerspectiveEntityQuerySortBy
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QSortBy> {
  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByIsBuiltin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBuiltin', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByIsBuiltinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBuiltin', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByPerspectiveId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByPerspectiveIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByPromptTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTemplate', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByPromptTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTemplate', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PerspectiveEntityQuerySortThenBy
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QSortThenBy> {
  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIsBuiltin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBuiltin', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIsBuiltinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBuiltin', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByPerspectiveId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByPerspectiveIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perspectiveId', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByPromptTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTemplate', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByPromptTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTemplate', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PerspectiveEntityQueryWhereDistinct
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct> {
  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct> distinctByIcon({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icon', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByIsBuiltin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBuiltin');
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByPerspectiveId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'perspectiveId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByPromptTemplate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'promptTemplate',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<PerspectiveEntity, PerspectiveEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension PerspectiveEntityQueryProperty
    on QueryBuilder<PerspectiveEntity, PerspectiveEntity, QQueryProperty> {
  QueryBuilder<PerspectiveEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PerspectiveEntity, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<PerspectiveEntity, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PerspectiveEntity, String, QQueryOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<PerspectiveEntity, String, QQueryOperations> iconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icon');
    });
  }

  QueryBuilder<PerspectiveEntity, bool, QQueryOperations> isBuiltinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBuiltin');
    });
  }

  QueryBuilder<PerspectiveEntity, bool, QQueryOperations> isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<PerspectiveEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<PerspectiveEntity, String, QQueryOperations>
  perspectiveIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perspectiveId');
    });
  }

  QueryBuilder<PerspectiveEntity, String, QQueryOperations>
  promptTemplateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptTemplate');
    });
  }

  QueryBuilder<PerspectiveEntity, int, QQueryOperations> sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<PerspectiveEntity, int, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
