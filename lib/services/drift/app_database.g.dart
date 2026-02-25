// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AssistantsTable extends Assistants
    with TableInfo<$AssistantsTable, Assistant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssistantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assistantIdMeta = const VerificationMeta(
    'assistantId',
  );
  @override
  late final GeneratedColumn<String> assistantId = GeneratedColumn<String>(
    'assistant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicCountMeta = const VerificationMeta(
    'topicCount',
  );
  @override
  late final GeneratedColumn<int> topicCount = GeneratedColumn<int>(
    'topic_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    assistantId,
    name,
    description,
    avatar,
    prompt,
    topicCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assistants';
  @override
  VerificationContext validateIntegrity(
    Insertable<Assistant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('assistant_id')) {
      context.handle(
        _assistantIdMeta,
        assistantId.isAcceptableOrUnknown(
          data['assistant_id']!,
          _assistantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assistantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    }
    if (data.containsKey('topic_count')) {
      context.handle(
        _topicCountMeta,
        topicCount.isAcceptableOrUnknown(data['topic_count']!, _topicCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assistantId};
  @override
  Assistant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Assistant(
      assistantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assistant_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      ),
      topicCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AssistantsTable createAlias(String alias) {
    return $AssistantsTable(attachedDatabase, alias);
  }
}

class Assistant extends DataClass implements Insertable<Assistant> {
  final String assistantId;
  final String name;
  final String? description;
  final String? avatar;
  final String? prompt;
  final int topicCount;
  final int createdAt;
  final int updatedAt;
  const Assistant({
    required this.assistantId,
    required this.name,
    this.description,
    this.avatar,
    this.prompt,
    required this.topicCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['assistant_id'] = Variable<String>(assistantId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || prompt != null) {
      map['prompt'] = Variable<String>(prompt);
    }
    map['topic_count'] = Variable<int>(topicCount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AssistantsCompanion toCompanion(bool nullToAbsent) {
    return AssistantsCompanion(
      assistantId: Value(assistantId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      prompt: prompt == null && nullToAbsent
          ? const Value.absent()
          : Value(prompt),
      topicCount: Value(topicCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Assistant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Assistant(
      assistantId: serializer.fromJson<String>(json['assistantId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      prompt: serializer.fromJson<String?>(json['prompt']),
      topicCount: serializer.fromJson<int>(json['topicCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assistantId': serializer.toJson<String>(assistantId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'avatar': serializer.toJson<String?>(avatar),
      'prompt': serializer.toJson<String?>(prompt),
      'topicCount': serializer.toJson<int>(topicCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Assistant copyWith({
    String? assistantId,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<String?> prompt = const Value.absent(),
    int? topicCount,
    int? createdAt,
    int? updatedAt,
  }) => Assistant(
    assistantId: assistantId ?? this.assistantId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    avatar: avatar.present ? avatar.value : this.avatar,
    prompt: prompt.present ? prompt.value : this.prompt,
    topicCount: topicCount ?? this.topicCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Assistant copyWithCompanion(AssistantsCompanion data) {
    return Assistant(
      assistantId: data.assistantId.present
          ? data.assistantId.value
          : this.assistantId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      topicCount: data.topicCount.present
          ? data.topicCount.value
          : this.topicCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Assistant(')
          ..write('assistantId: $assistantId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('avatar: $avatar, ')
          ..write('prompt: $prompt, ')
          ..write('topicCount: $topicCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assistantId,
    name,
    description,
    avatar,
    prompt,
    topicCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Assistant &&
          other.assistantId == this.assistantId &&
          other.name == this.name &&
          other.description == this.description &&
          other.avatar == this.avatar &&
          other.prompt == this.prompt &&
          other.topicCount == this.topicCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AssistantsCompanion extends UpdateCompanion<Assistant> {
  final Value<String> assistantId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> avatar;
  final Value<String?> prompt;
  final Value<int> topicCount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AssistantsCompanion({
    this.assistantId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.avatar = const Value.absent(),
    this.prompt = const Value.absent(),
    this.topicCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssistantsCompanion.insert({
    required String assistantId,
    required String name,
    this.description = const Value.absent(),
    this.avatar = const Value.absent(),
    this.prompt = const Value.absent(),
    this.topicCount = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : assistantId = Value(assistantId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Assistant> custom({
    Expression<String>? assistantId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? avatar,
    Expression<String>? prompt,
    Expression<int>? topicCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assistantId != null) 'assistant_id': assistantId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (avatar != null) 'avatar': avatar,
      if (prompt != null) 'prompt': prompt,
      if (topicCount != null) 'topic_count': topicCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssistantsCompanion copyWith({
    Value<String>? assistantId,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? avatar,
    Value<String?>? prompt,
    Value<int>? topicCount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AssistantsCompanion(
      assistantId: assistantId ?? this.assistantId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      prompt: prompt ?? this.prompt,
      topicCount: topicCount ?? this.topicCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assistantId.present) {
      map['assistant_id'] = Variable<String>(assistantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (topicCount.present) {
      map['topic_count'] = Variable<int>(topicCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssistantsCompanion(')
          ..write('assistantId: $assistantId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('avatar: $avatar, ')
          ..write('prompt: $prompt, ')
          ..write('topicCount: $topicCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopicsTable extends Topics with TableInfo<$TopicsTable, Topic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundCountMeta = const VerificationMeta(
    'roundCount',
  );
  @override
  late final GeneratedColumn<int> roundCount = GeneratedColumn<int>(
    'round_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    topicId,
    name,
    messageCount,
    roundCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<Topic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageCountMeta);
    }
    if (data.containsKey('round_count')) {
      context.handle(
        _roundCountMeta,
        roundCount.isAcceptableOrUnknown(data['round_count']!, _roundCountMeta),
      );
    } else if (isInserting) {
      context.missing(_roundCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topicId};
  @override
  Topic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Topic(
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      roundCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TopicsTable createAlias(String alias) {
    return $TopicsTable(attachedDatabase, alias);
  }
}

class Topic extends DataClass implements Insertable<Topic> {
  final String topicId;
  final String name;
  final int messageCount;
  final int roundCount;
  final int createdAt;
  final int updatedAt;
  const Topic({
    required this.topicId,
    required this.name,
    required this.messageCount,
    required this.roundCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic_id'] = Variable<String>(topicId);
    map['name'] = Variable<String>(name);
    map['message_count'] = Variable<int>(messageCount);
    map['round_count'] = Variable<int>(roundCount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TopicsCompanion toCompanion(bool nullToAbsent) {
    return TopicsCompanion(
      topicId: Value(topicId),
      name: Value(name),
      messageCount: Value(messageCount),
      roundCount: Value(roundCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Topic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Topic(
      topicId: serializer.fromJson<String>(json['topicId']),
      name: serializer.fromJson<String>(json['name']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      roundCount: serializer.fromJson<int>(json['roundCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topicId': serializer.toJson<String>(topicId),
      'name': serializer.toJson<String>(name),
      'messageCount': serializer.toJson<int>(messageCount),
      'roundCount': serializer.toJson<int>(roundCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Topic copyWith({
    String? topicId,
    String? name,
    int? messageCount,
    int? roundCount,
    int? createdAt,
    int? updatedAt,
  }) => Topic(
    topicId: topicId ?? this.topicId,
    name: name ?? this.name,
    messageCount: messageCount ?? this.messageCount,
    roundCount: roundCount ?? this.roundCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Topic copyWithCompanion(TopicsCompanion data) {
    return Topic(
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      name: data.name.present ? data.name.value : this.name,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      roundCount: data.roundCount.present
          ? data.roundCount.value
          : this.roundCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Topic(')
          ..write('topicId: $topicId, ')
          ..write('name: $name, ')
          ..write('messageCount: $messageCount, ')
          ..write('roundCount: $roundCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    topicId,
    name,
    messageCount,
    roundCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Topic &&
          other.topicId == this.topicId &&
          other.name == this.name &&
          other.messageCount == this.messageCount &&
          other.roundCount == this.roundCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TopicsCompanion extends UpdateCompanion<Topic> {
  final Value<String> topicId;
  final Value<String> name;
  final Value<int> messageCount;
  final Value<int> roundCount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TopicsCompanion({
    this.topicId = const Value.absent(),
    this.name = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.roundCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicsCompanion.insert({
    required String topicId,
    required String name,
    required int messageCount,
    required int roundCount,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : topicId = Value(topicId),
       name = Value(name),
       messageCount = Value(messageCount),
       roundCount = Value(roundCount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Topic> custom({
    Expression<String>? topicId,
    Expression<String>? name,
    Expression<int>? messageCount,
    Expression<int>? roundCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topicId != null) 'topic_id': topicId,
      if (name != null) 'name': name,
      if (messageCount != null) 'message_count': messageCount,
      if (roundCount != null) 'round_count': roundCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicsCompanion copyWith({
    Value<String>? topicId,
    Value<String>? name,
    Value<int>? messageCount,
    Value<int>? roundCount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TopicsCompanion(
      topicId: topicId ?? this.topicId,
      name: name ?? this.name,
      messageCount: messageCount ?? this.messageCount,
      roundCount: roundCount ?? this.roundCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (roundCount.present) {
      map['round_count'] = Variable<int>(roundCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicsCompanion(')
          ..write('topicId: $topicId, ')
          ..write('name: $name, ')
          ..write('messageCount: $messageCount, ')
          ..write('roundCount: $roundCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopicAssistantsTable extends TopicAssistants
    with TableInfo<$TopicAssistantsTable, TopicAssistant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicAssistantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES topics (topic_id)',
    ),
  );
  static const VerificationMeta _assistantIdMeta = const VerificationMeta(
    'assistantId',
  );
  @override
  late final GeneratedColumn<String> assistantId = GeneratedColumn<String>(
    'assistant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assistants (assistant_id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [topicId, assistantId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_assistants';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicAssistant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('assistant_id')) {
      context.handle(
        _assistantIdMeta,
        assistantId.isAcceptableOrUnknown(
          data['assistant_id']!,
          _assistantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assistantIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topicId, assistantId};
  @override
  TopicAssistant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicAssistant(
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      assistantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assistant_id'],
      )!,
    );
  }

  @override
  $TopicAssistantsTable createAlias(String alias) {
    return $TopicAssistantsTable(attachedDatabase, alias);
  }
}

class TopicAssistant extends DataClass implements Insertable<TopicAssistant> {
  final String topicId;
  final String assistantId;
  const TopicAssistant({required this.topicId, required this.assistantId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic_id'] = Variable<String>(topicId);
    map['assistant_id'] = Variable<String>(assistantId);
    return map;
  }

  TopicAssistantsCompanion toCompanion(bool nullToAbsent) {
    return TopicAssistantsCompanion(
      topicId: Value(topicId),
      assistantId: Value(assistantId),
    );
  }

  factory TopicAssistant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicAssistant(
      topicId: serializer.fromJson<String>(json['topicId']),
      assistantId: serializer.fromJson<String>(json['assistantId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topicId': serializer.toJson<String>(topicId),
      'assistantId': serializer.toJson<String>(assistantId),
    };
  }

  TopicAssistant copyWith({String? topicId, String? assistantId}) =>
      TopicAssistant(
        topicId: topicId ?? this.topicId,
        assistantId: assistantId ?? this.assistantId,
      );
  TopicAssistant copyWithCompanion(TopicAssistantsCompanion data) {
    return TopicAssistant(
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      assistantId: data.assistantId.present
          ? data.assistantId.value
          : this.assistantId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicAssistant(')
          ..write('topicId: $topicId, ')
          ..write('assistantId: $assistantId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topicId, assistantId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicAssistant &&
          other.topicId == this.topicId &&
          other.assistantId == this.assistantId);
}

class TopicAssistantsCompanion extends UpdateCompanion<TopicAssistant> {
  final Value<String> topicId;
  final Value<String> assistantId;
  final Value<int> rowid;
  const TopicAssistantsCompanion({
    this.topicId = const Value.absent(),
    this.assistantId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicAssistantsCompanion.insert({
    required String topicId,
    required String assistantId,
    this.rowid = const Value.absent(),
  }) : topicId = Value(topicId),
       assistantId = Value(assistantId);
  static Insertable<TopicAssistant> custom({
    Expression<String>? topicId,
    Expression<String>? assistantId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topicId != null) 'topic_id': topicId,
      if (assistantId != null) 'assistant_id': assistantId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicAssistantsCompanion copyWith({
    Value<String>? topicId,
    Value<String>? assistantId,
    Value<int>? rowid,
  }) {
    return TopicAssistantsCompanion(
      topicId: topicId ?? this.topicId,
      assistantId: assistantId ?? this.assistantId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (assistantId.present) {
      map['assistant_id'] = Variable<String>(assistantId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicAssistantsCompanion(')
          ..write('topicId: $topicId, ')
          ..write('assistantId: $assistantId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES topics (topic_id)',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundIndexMeta = const VerificationMeta(
    'roundIndex',
  );
  @override
  late final GeneratedColumn<int> roundIndex = GeneratedColumn<int>(
    'round_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _askIdMeta = const VerificationMeta('askId');
  @override
  late final GeneratedColumn<String> askId = GeneratedColumn<String>(
    'ask_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usefulMeta = const VerificationMeta('useful');
  @override
  late final GeneratedColumn<bool> useful = GeneratedColumn<bool>(
    'useful',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("useful" IN (0, 1))',
    ),
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usageJsonMeta = const VerificationMeta(
    'usageJson',
  );
  @override
  late final GeneratedColumn<String> usageJson = GeneratedColumn<String>(
    'usage_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metricsJsonMeta = const VerificationMeta(
    'metricsJson',
  );
  @override
  late final GeneratedColumn<String> metricsJson = GeneratedColumn<String>(
    'metrics_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mentionsJsonMeta = const VerificationMeta(
    'mentionsJson',
  );
  @override
  late final GeneratedColumn<String> mentionsJson = GeneratedColumn<String>(
    'mentions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    topicId,
    orderIndex,
    roundIndex,
    role,
    askId,
    useful,
    modelId,
    modelName,
    usageJson,
    metricsJson,
    mentionsJson,
    createdAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('round_index')) {
      context.handle(
        _roundIndexMeta,
        roundIndex.isAcceptableOrUnknown(data['round_index']!, _roundIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_roundIndexMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('ask_id')) {
      context.handle(
        _askIdMeta,
        askId.isAcceptableOrUnknown(data['ask_id']!, _askIdMeta),
      );
    }
    if (data.containsKey('useful')) {
      context.handle(
        _usefulMeta,
        useful.isAcceptableOrUnknown(data['useful']!, _usefulMeta),
      );
    } else if (isInserting) {
      context.missing(_usefulMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('usage_json')) {
      context.handle(
        _usageJsonMeta,
        usageJson.isAcceptableOrUnknown(data['usage_json']!, _usageJsonMeta),
      );
    }
    if (data.containsKey('metrics_json')) {
      context.handle(
        _metricsJsonMeta,
        metricsJson.isAcceptableOrUnknown(
          data['metrics_json']!,
          _metricsJsonMeta,
        ),
      );
    }
    if (data.containsKey('mentions_json')) {
      context.handle(
        _mentionsJsonMeta,
        mentionsJson.isAcceptableOrUnknown(
          data['mentions_json']!,
          _mentionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      roundIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_index'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      askId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ask_id'],
      ),
      useful: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}useful'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      usageJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage_json'],
      ),
      metricsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metrics_json'],
      ),
      mentionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mentions_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String messageId;
  final String topicId;
  final int orderIndex;
  final int roundIndex;
  final String role;
  final String? askId;
  final bool useful;
  final String? modelId;
  final String? modelName;
  final String? usageJson;
  final String? metricsJson;
  final String? mentionsJson;
  final int createdAt;
  final String status;
  const Message({
    required this.messageId,
    required this.topicId,
    required this.orderIndex,
    required this.roundIndex,
    required this.role,
    this.askId,
    required this.useful,
    this.modelId,
    this.modelName,
    this.usageJson,
    this.metricsJson,
    this.mentionsJson,
    required this.createdAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['topic_id'] = Variable<String>(topicId);
    map['order_index'] = Variable<int>(orderIndex);
    map['round_index'] = Variable<int>(roundIndex);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || askId != null) {
      map['ask_id'] = Variable<String>(askId);
    }
    map['useful'] = Variable<bool>(useful);
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || usageJson != null) {
      map['usage_json'] = Variable<String>(usageJson);
    }
    if (!nullToAbsent || metricsJson != null) {
      map['metrics_json'] = Variable<String>(metricsJson);
    }
    if (!nullToAbsent || mentionsJson != null) {
      map['mentions_json'] = Variable<String>(mentionsJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      topicId: Value(topicId),
      orderIndex: Value(orderIndex),
      roundIndex: Value(roundIndex),
      role: Value(role),
      askId: askId == null && nullToAbsent
          ? const Value.absent()
          : Value(askId),
      useful: Value(useful),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      usageJson: usageJson == null && nullToAbsent
          ? const Value.absent()
          : Value(usageJson),
      metricsJson: metricsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metricsJson),
      mentionsJson: mentionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(mentionsJson),
      createdAt: Value(createdAt),
      status: Value(status),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['messageId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      roundIndex: serializer.fromJson<int>(json['roundIndex']),
      role: serializer.fromJson<String>(json['role']),
      askId: serializer.fromJson<String?>(json['askId']),
      useful: serializer.fromJson<bool>(json['useful']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      usageJson: serializer.fromJson<String?>(json['usageJson']),
      metricsJson: serializer.fromJson<String?>(json['metricsJson']),
      mentionsJson: serializer.fromJson<String?>(json['mentionsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'topicId': serializer.toJson<String>(topicId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'roundIndex': serializer.toJson<int>(roundIndex),
      'role': serializer.toJson<String>(role),
      'askId': serializer.toJson<String?>(askId),
      'useful': serializer.toJson<bool>(useful),
      'modelId': serializer.toJson<String?>(modelId),
      'modelName': serializer.toJson<String?>(modelName),
      'usageJson': serializer.toJson<String?>(usageJson),
      'metricsJson': serializer.toJson<String?>(metricsJson),
      'mentionsJson': serializer.toJson<String?>(mentionsJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'status': serializer.toJson<String>(status),
    };
  }

  Message copyWith({
    String? messageId,
    String? topicId,
    int? orderIndex,
    int? roundIndex,
    String? role,
    Value<String?> askId = const Value.absent(),
    bool? useful,
    Value<String?> modelId = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> usageJson = const Value.absent(),
    Value<String?> metricsJson = const Value.absent(),
    Value<String?> mentionsJson = const Value.absent(),
    int? createdAt,
    String? status,
  }) => Message(
    messageId: messageId ?? this.messageId,
    topicId: topicId ?? this.topicId,
    orderIndex: orderIndex ?? this.orderIndex,
    roundIndex: roundIndex ?? this.roundIndex,
    role: role ?? this.role,
    askId: askId.present ? askId.value : this.askId,
    useful: useful ?? this.useful,
    modelId: modelId.present ? modelId.value : this.modelId,
    modelName: modelName.present ? modelName.value : this.modelName,
    usageJson: usageJson.present ? usageJson.value : this.usageJson,
    metricsJson: metricsJson.present ? metricsJson.value : this.metricsJson,
    mentionsJson: mentionsJson.present ? mentionsJson.value : this.mentionsJson,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      roundIndex: data.roundIndex.present
          ? data.roundIndex.value
          : this.roundIndex,
      role: data.role.present ? data.role.value : this.role,
      askId: data.askId.present ? data.askId.value : this.askId,
      useful: data.useful.present ? data.useful.value : this.useful,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      usageJson: data.usageJson.present ? data.usageJson.value : this.usageJson,
      metricsJson: data.metricsJson.present
          ? data.metricsJson.value
          : this.metricsJson,
      mentionsJson: data.mentionsJson.present
          ? data.mentionsJson.value
          : this.mentionsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('messageId: $messageId, ')
          ..write('topicId: $topicId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('roundIndex: $roundIndex, ')
          ..write('role: $role, ')
          ..write('askId: $askId, ')
          ..write('useful: $useful, ')
          ..write('modelId: $modelId, ')
          ..write('modelName: $modelName, ')
          ..write('usageJson: $usageJson, ')
          ..write('metricsJson: $metricsJson, ')
          ..write('mentionsJson: $mentionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    topicId,
    orderIndex,
    roundIndex,
    role,
    askId,
    useful,
    modelId,
    modelName,
    usageJson,
    metricsJson,
    mentionsJson,
    createdAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.messageId == this.messageId &&
          other.topicId == this.topicId &&
          other.orderIndex == this.orderIndex &&
          other.roundIndex == this.roundIndex &&
          other.role == this.role &&
          other.askId == this.askId &&
          other.useful == this.useful &&
          other.modelId == this.modelId &&
          other.modelName == this.modelName &&
          other.usageJson == this.usageJson &&
          other.metricsJson == this.metricsJson &&
          other.mentionsJson == this.mentionsJson &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> messageId;
  final Value<String> topicId;
  final Value<int> orderIndex;
  final Value<int> roundIndex;
  final Value<String> role;
  final Value<String?> askId;
  final Value<bool> useful;
  final Value<String?> modelId;
  final Value<String?> modelName;
  final Value<String?> usageJson;
  final Value<String?> metricsJson;
  final Value<String?> mentionsJson;
  final Value<int> createdAt;
  final Value<String> status;
  final Value<int> rowid;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.roundIndex = const Value.absent(),
    this.role = const Value.absent(),
    this.askId = const Value.absent(),
    this.useful = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.usageJson = const Value.absent(),
    this.metricsJson = const Value.absent(),
    this.mentionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String topicId,
    required int orderIndex,
    required int roundIndex,
    required String role,
    this.askId = const Value.absent(),
    required bool useful,
    this.modelId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.usageJson = const Value.absent(),
    this.metricsJson = const Value.absent(),
    this.mentionsJson = const Value.absent(),
    required int createdAt,
    required String status,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       topicId = Value(topicId),
       orderIndex = Value(orderIndex),
       roundIndex = Value(roundIndex),
       role = Value(role),
       useful = Value(useful),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<Message> custom({
    Expression<String>? messageId,
    Expression<String>? topicId,
    Expression<int>? orderIndex,
    Expression<int>? roundIndex,
    Expression<String>? role,
    Expression<String>? askId,
    Expression<bool>? useful,
    Expression<String>? modelId,
    Expression<String>? modelName,
    Expression<String>? usageJson,
    Expression<String>? metricsJson,
    Expression<String>? mentionsJson,
    Expression<int>? createdAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (topicId != null) 'topic_id': topicId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (roundIndex != null) 'round_index': roundIndex,
      if (role != null) 'role': role,
      if (askId != null) 'ask_id': askId,
      if (useful != null) 'useful': useful,
      if (modelId != null) 'model_id': modelId,
      if (modelName != null) 'model_name': modelName,
      if (usageJson != null) 'usage_json': usageJson,
      if (metricsJson != null) 'metrics_json': metricsJson,
      if (mentionsJson != null) 'mentions_json': mentionsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? topicId,
    Value<int>? orderIndex,
    Value<int>? roundIndex,
    Value<String>? role,
    Value<String?>? askId,
    Value<bool>? useful,
    Value<String?>? modelId,
    Value<String?>? modelName,
    Value<String?>? usageJson,
    Value<String?>? metricsJson,
    Value<String?>? mentionsJson,
    Value<int>? createdAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      topicId: topicId ?? this.topicId,
      orderIndex: orderIndex ?? this.orderIndex,
      roundIndex: roundIndex ?? this.roundIndex,
      role: role ?? this.role,
      askId: askId ?? this.askId,
      useful: useful ?? this.useful,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      usageJson: usageJson ?? this.usageJson,
      metricsJson: metricsJson ?? this.metricsJson,
      mentionsJson: mentionsJson ?? this.mentionsJson,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (roundIndex.present) {
      map['round_index'] = Variable<int>(roundIndex.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (askId.present) {
      map['ask_id'] = Variable<String>(askId.value);
    }
    if (useful.present) {
      map['useful'] = Variable<bool>(useful.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (usageJson.present) {
      map['usage_json'] = Variable<String>(usageJson.value);
    }
    if (metricsJson.present) {
      map['metrics_json'] = Variable<String>(metricsJson.value);
    }
    if (mentionsJson.present) {
      map['mentions_json'] = Variable<String>(mentionsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('topicId: $topicId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('roundIndex: $roundIndex, ')
          ..write('role: $role, ')
          ..write('askId: $askId, ')
          ..write('useful: $useful, ')
          ..write('modelId: $modelId, ')
          ..write('modelName: $modelName, ')
          ..write('usageJson: $usageJson, ')
          ..write('metricsJson: $metricsJson, ')
          ..write('mentionsJson: $mentionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageBlocksTable extends MessageBlocks
    with TableInfo<$MessageBlocksTable, MessageBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES topics (topic_id)',
    ),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES messages (message_id)',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thinkingMillsecMeta = const VerificationMeta(
    'thinkingMillsec',
  );
  @override
  late final GeneratedColumn<double> thinkingMillsec = GeneratedColumn<double>(
    'thinking_millsec',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileJsonMeta = const VerificationMeta(
    'fileJson',
  );
  @override
  late final GeneratedColumn<String> fileJson = GeneratedColumn<String>(
    'file_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolJsonMeta = const VerificationMeta(
    'toolJson',
  );
  @override
  late final GeneratedColumn<String> toolJson = GeneratedColumn<String>(
    'tool_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorJsonMeta = const VerificationMeta(
    'errorJson',
  );
  @override
  late final GeneratedColumn<String> errorJson = GeneratedColumn<String>(
    'error_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetLanguageMeta = const VerificationMeta(
    'targetLanguage',
  );
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
    'target_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knowledgeJsonMeta = const VerificationMeta(
    'knowledgeJson',
  );
  @override
  late final GeneratedColumn<String> knowledgeJson = GeneratedColumn<String>(
    'knowledge_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    blockId,
    topicId,
    messageId,
    orderIndex,
    type,
    content,
    thinkingMillsec,
    url,
    fileJson,
    toolJson,
    errorJson,
    targetLanguage,
    responseJson,
    knowledgeJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('thinking_millsec')) {
      context.handle(
        _thinkingMillsecMeta,
        thinkingMillsec.isAcceptableOrUnknown(
          data['thinking_millsec']!,
          _thinkingMillsecMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('file_json')) {
      context.handle(
        _fileJsonMeta,
        fileJson.isAcceptableOrUnknown(data['file_json']!, _fileJsonMeta),
      );
    }
    if (data.containsKey('tool_json')) {
      context.handle(
        _toolJsonMeta,
        toolJson.isAcceptableOrUnknown(data['tool_json']!, _toolJsonMeta),
      );
    }
    if (data.containsKey('error_json')) {
      context.handle(
        _errorJsonMeta,
        errorJson.isAcceptableOrUnknown(data['error_json']!, _errorJsonMeta),
      );
    }
    if (data.containsKey('target_language')) {
      context.handle(
        _targetLanguageMeta,
        targetLanguage.isAcceptableOrUnknown(
          data['target_language']!,
          _targetLanguageMeta,
        ),
      );
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    }
    if (data.containsKey('knowledge_json')) {
      context.handle(
        _knowledgeJsonMeta,
        knowledgeJson.isAcceptableOrUnknown(
          data['knowledge_json']!,
          _knowledgeJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {blockId};
  @override
  MessageBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageBlock(
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      thinkingMillsec: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thinking_millsec'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      fileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_json'],
      ),
      toolJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_json'],
      ),
      errorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_json'],
      ),
      targetLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_language'],
      ),
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      ),
      knowledgeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knowledge_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessageBlocksTable createAlias(String alias) {
    return $MessageBlocksTable(attachedDatabase, alias);
  }
}

class MessageBlock extends DataClass implements Insertable<MessageBlock> {
  final String blockId;
  final String topicId;
  final String messageId;
  final int orderIndex;
  final String type;
  final String? content;
  final double? thinkingMillsec;
  final String? url;
  final String? fileJson;
  final String? toolJson;
  final String? errorJson;
  final String? targetLanguage;
  final String? responseJson;
  final String? knowledgeJson;
  final int createdAt;
  const MessageBlock({
    required this.blockId,
    required this.topicId,
    required this.messageId,
    required this.orderIndex,
    required this.type,
    this.content,
    this.thinkingMillsec,
    this.url,
    this.fileJson,
    this.toolJson,
    this.errorJson,
    this.targetLanguage,
    this.responseJson,
    this.knowledgeJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['block_id'] = Variable<String>(blockId);
    map['topic_id'] = Variable<String>(topicId);
    map['message_id'] = Variable<String>(messageId);
    map['order_index'] = Variable<int>(orderIndex);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || thinkingMillsec != null) {
      map['thinking_millsec'] = Variable<double>(thinkingMillsec);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || fileJson != null) {
      map['file_json'] = Variable<String>(fileJson);
    }
    if (!nullToAbsent || toolJson != null) {
      map['tool_json'] = Variable<String>(toolJson);
    }
    if (!nullToAbsent || errorJson != null) {
      map['error_json'] = Variable<String>(errorJson);
    }
    if (!nullToAbsent || targetLanguage != null) {
      map['target_language'] = Variable<String>(targetLanguage);
    }
    if (!nullToAbsent || responseJson != null) {
      map['response_json'] = Variable<String>(responseJson);
    }
    if (!nullToAbsent || knowledgeJson != null) {
      map['knowledge_json'] = Variable<String>(knowledgeJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MessageBlocksCompanion toCompanion(bool nullToAbsent) {
    return MessageBlocksCompanion(
      blockId: Value(blockId),
      topicId: Value(topicId),
      messageId: Value(messageId),
      orderIndex: Value(orderIndex),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      thinkingMillsec: thinkingMillsec == null && nullToAbsent
          ? const Value.absent()
          : Value(thinkingMillsec),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      fileJson: fileJson == null && nullToAbsent
          ? const Value.absent()
          : Value(fileJson),
      toolJson: toolJson == null && nullToAbsent
          ? const Value.absent()
          : Value(toolJson),
      errorJson: errorJson == null && nullToAbsent
          ? const Value.absent()
          : Value(errorJson),
      targetLanguage: targetLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(targetLanguage),
      responseJson: responseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(responseJson),
      knowledgeJson: knowledgeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(knowledgeJson),
      createdAt: Value(createdAt),
    );
  }

  factory MessageBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageBlock(
      blockId: serializer.fromJson<String>(json['blockId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      thinkingMillsec: serializer.fromJson<double?>(json['thinkingMillsec']),
      url: serializer.fromJson<String?>(json['url']),
      fileJson: serializer.fromJson<String?>(json['fileJson']),
      toolJson: serializer.fromJson<String?>(json['toolJson']),
      errorJson: serializer.fromJson<String?>(json['errorJson']),
      targetLanguage: serializer.fromJson<String?>(json['targetLanguage']),
      responseJson: serializer.fromJson<String?>(json['responseJson']),
      knowledgeJson: serializer.fromJson<String?>(json['knowledgeJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'blockId': serializer.toJson<String>(blockId),
      'topicId': serializer.toJson<String>(topicId),
      'messageId': serializer.toJson<String>(messageId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'thinkingMillsec': serializer.toJson<double?>(thinkingMillsec),
      'url': serializer.toJson<String?>(url),
      'fileJson': serializer.toJson<String?>(fileJson),
      'toolJson': serializer.toJson<String?>(toolJson),
      'errorJson': serializer.toJson<String?>(errorJson),
      'targetLanguage': serializer.toJson<String?>(targetLanguage),
      'responseJson': serializer.toJson<String?>(responseJson),
      'knowledgeJson': serializer.toJson<String?>(knowledgeJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MessageBlock copyWith({
    String? blockId,
    String? topicId,
    String? messageId,
    int? orderIndex,
    String? type,
    Value<String?> content = const Value.absent(),
    Value<double?> thinkingMillsec = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> fileJson = const Value.absent(),
    Value<String?> toolJson = const Value.absent(),
    Value<String?> errorJson = const Value.absent(),
    Value<String?> targetLanguage = const Value.absent(),
    Value<String?> responseJson = const Value.absent(),
    Value<String?> knowledgeJson = const Value.absent(),
    int? createdAt,
  }) => MessageBlock(
    blockId: blockId ?? this.blockId,
    topicId: topicId ?? this.topicId,
    messageId: messageId ?? this.messageId,
    orderIndex: orderIndex ?? this.orderIndex,
    type: type ?? this.type,
    content: content.present ? content.value : this.content,
    thinkingMillsec: thinkingMillsec.present
        ? thinkingMillsec.value
        : this.thinkingMillsec,
    url: url.present ? url.value : this.url,
    fileJson: fileJson.present ? fileJson.value : this.fileJson,
    toolJson: toolJson.present ? toolJson.value : this.toolJson,
    errorJson: errorJson.present ? errorJson.value : this.errorJson,
    targetLanguage: targetLanguage.present
        ? targetLanguage.value
        : this.targetLanguage,
    responseJson: responseJson.present ? responseJson.value : this.responseJson,
    knowledgeJson: knowledgeJson.present
        ? knowledgeJson.value
        : this.knowledgeJson,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageBlock copyWithCompanion(MessageBlocksCompanion data) {
    return MessageBlock(
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      thinkingMillsec: data.thinkingMillsec.present
          ? data.thinkingMillsec.value
          : this.thinkingMillsec,
      url: data.url.present ? data.url.value : this.url,
      fileJson: data.fileJson.present ? data.fileJson.value : this.fileJson,
      toolJson: data.toolJson.present ? data.toolJson.value : this.toolJson,
      errorJson: data.errorJson.present ? data.errorJson.value : this.errorJson,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      knowledgeJson: data.knowledgeJson.present
          ? data.knowledgeJson.value
          : this.knowledgeJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageBlock(')
          ..write('blockId: $blockId, ')
          ..write('topicId: $topicId, ')
          ..write('messageId: $messageId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('thinkingMillsec: $thinkingMillsec, ')
          ..write('url: $url, ')
          ..write('fileJson: $fileJson, ')
          ..write('toolJson: $toolJson, ')
          ..write('errorJson: $errorJson, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('responseJson: $responseJson, ')
          ..write('knowledgeJson: $knowledgeJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    blockId,
    topicId,
    messageId,
    orderIndex,
    type,
    content,
    thinkingMillsec,
    url,
    fileJson,
    toolJson,
    errorJson,
    targetLanguage,
    responseJson,
    knowledgeJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageBlock &&
          other.blockId == this.blockId &&
          other.topicId == this.topicId &&
          other.messageId == this.messageId &&
          other.orderIndex == this.orderIndex &&
          other.type == this.type &&
          other.content == this.content &&
          other.thinkingMillsec == this.thinkingMillsec &&
          other.url == this.url &&
          other.fileJson == this.fileJson &&
          other.toolJson == this.toolJson &&
          other.errorJson == this.errorJson &&
          other.targetLanguage == this.targetLanguage &&
          other.responseJson == this.responseJson &&
          other.knowledgeJson == this.knowledgeJson &&
          other.createdAt == this.createdAt);
}

class MessageBlocksCompanion extends UpdateCompanion<MessageBlock> {
  final Value<String> blockId;
  final Value<String> topicId;
  final Value<String> messageId;
  final Value<int> orderIndex;
  final Value<String> type;
  final Value<String?> content;
  final Value<double?> thinkingMillsec;
  final Value<String?> url;
  final Value<String?> fileJson;
  final Value<String?> toolJson;
  final Value<String?> errorJson;
  final Value<String?> targetLanguage;
  final Value<String?> responseJson;
  final Value<String?> knowledgeJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MessageBlocksCompanion({
    this.blockId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.thinkingMillsec = const Value.absent(),
    this.url = const Value.absent(),
    this.fileJson = const Value.absent(),
    this.toolJson = const Value.absent(),
    this.errorJson = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.knowledgeJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageBlocksCompanion.insert({
    required String blockId,
    required String topicId,
    required String messageId,
    required int orderIndex,
    required String type,
    this.content = const Value.absent(),
    this.thinkingMillsec = const Value.absent(),
    this.url = const Value.absent(),
    this.fileJson = const Value.absent(),
    this.toolJson = const Value.absent(),
    this.errorJson = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.knowledgeJson = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : blockId = Value(blockId),
       topicId = Value(topicId),
       messageId = Value(messageId),
       orderIndex = Value(orderIndex),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<MessageBlock> custom({
    Expression<String>? blockId,
    Expression<String>? topicId,
    Expression<String>? messageId,
    Expression<int>? orderIndex,
    Expression<String>? type,
    Expression<String>? content,
    Expression<double>? thinkingMillsec,
    Expression<String>? url,
    Expression<String>? fileJson,
    Expression<String>? toolJson,
    Expression<String>? errorJson,
    Expression<String>? targetLanguage,
    Expression<String>? responseJson,
    Expression<String>? knowledgeJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (blockId != null) 'block_id': blockId,
      if (topicId != null) 'topic_id': topicId,
      if (messageId != null) 'message_id': messageId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (thinkingMillsec != null) 'thinking_millsec': thinkingMillsec,
      if (url != null) 'url': url,
      if (fileJson != null) 'file_json': fileJson,
      if (toolJson != null) 'tool_json': toolJson,
      if (errorJson != null) 'error_json': errorJson,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (responseJson != null) 'response_json': responseJson,
      if (knowledgeJson != null) 'knowledge_json': knowledgeJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageBlocksCompanion copyWith({
    Value<String>? blockId,
    Value<String>? topicId,
    Value<String>? messageId,
    Value<int>? orderIndex,
    Value<String>? type,
    Value<String?>? content,
    Value<double?>? thinkingMillsec,
    Value<String?>? url,
    Value<String?>? fileJson,
    Value<String?>? toolJson,
    Value<String?>? errorJson,
    Value<String?>? targetLanguage,
    Value<String?>? responseJson,
    Value<String?>? knowledgeJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return MessageBlocksCompanion(
      blockId: blockId ?? this.blockId,
      topicId: topicId ?? this.topicId,
      messageId: messageId ?? this.messageId,
      orderIndex: orderIndex ?? this.orderIndex,
      type: type ?? this.type,
      content: content ?? this.content,
      thinkingMillsec: thinkingMillsec ?? this.thinkingMillsec,
      url: url ?? this.url,
      fileJson: fileJson ?? this.fileJson,
      toolJson: toolJson ?? this.toolJson,
      errorJson: errorJson ?? this.errorJson,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      responseJson: responseJson ?? this.responseJson,
      knowledgeJson: knowledgeJson ?? this.knowledgeJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (thinkingMillsec.present) {
      map['thinking_millsec'] = Variable<double>(thinkingMillsec.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (fileJson.present) {
      map['file_json'] = Variable<String>(fileJson.value);
    }
    if (toolJson.present) {
      map['tool_json'] = Variable<String>(toolJson.value);
    }
    if (errorJson.present) {
      map['error_json'] = Variable<String>(errorJson.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (knowledgeJson.present) {
      map['knowledge_json'] = Variable<String>(knowledgeJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageBlocksCompanion(')
          ..write('blockId: $blockId, ')
          ..write('topicId: $topicId, ')
          ..write('messageId: $messageId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('thinkingMillsec: $thinkingMillsec, ')
          ..write('url: $url, ')
          ..write('fileJson: $fileJson, ')
          ..write('toolJson: $toolJson, ')
          ..write('errorJson: $errorJson, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('responseJson: $responseJson, ')
          ..write('knowledgeJson: $knowledgeJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilesTable extends Files with TableInfo<$FilesTable, File> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceCountMeta = const VerificationMeta(
    'referenceCount',
  );
  @override
  late final GeneratedColumn<int> referenceCount = GeneratedColumn<int>(
    'reference_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fileId,
    fileName,
    localPath,
    fileSize,
    mimeType,
    sha256,
    referenceCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'files';
  @override
  VerificationContext validateIntegrity(
    Insertable<File> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('reference_count')) {
      context.handle(
        _referenceCountMeta,
        referenceCount.isAcceptableOrUnknown(
          data['reference_count']!,
          _referenceCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  File map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return File(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      referenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FilesTable createAlias(String alias) {
    return $FilesTable(attachedDatabase, alias);
  }
}

class File extends DataClass implements Insertable<File> {
  final String fileId;
  final String? fileName;
  final String? localPath;
  final int? fileSize;
  final String? mimeType;
  final String? sha256;
  final int referenceCount;
  final int createdAt;
  final int updatedAt;
  const File({
    required this.fileId,
    this.fileName,
    this.localPath,
    this.fileSize,
    this.mimeType,
    this.sha256,
    required this.referenceCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['reference_count'] = Variable<int>(referenceCount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FilesCompanion toCompanion(bool nullToAbsent) {
    return FilesCompanion(
      fileId: Value(fileId),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      referenceCount: Value(referenceCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory File.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return File(
      fileId: serializer.fromJson<String>(json['fileId']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      referenceCount: serializer.fromJson<int>(json['referenceCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'fileName': serializer.toJson<String?>(fileName),
      'localPath': serializer.toJson<String?>(localPath),
      'fileSize': serializer.toJson<int?>(fileSize),
      'mimeType': serializer.toJson<String?>(mimeType),
      'sha256': serializer.toJson<String?>(sha256),
      'referenceCount': serializer.toJson<int>(referenceCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  File copyWith({
    String? fileId,
    Value<String?> fileName = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    int? referenceCount,
    int? createdAt,
    int? updatedAt,
  }) => File(
    fileId: fileId ?? this.fileId,
    fileName: fileName.present ? fileName.value : this.fileName,
    localPath: localPath.present ? localPath.value : this.localPath,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    sha256: sha256.present ? sha256.value : this.sha256,
    referenceCount: referenceCount ?? this.referenceCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  File copyWithCompanion(FilesCompanion data) {
    return File(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      referenceCount: data.referenceCount.present
          ? data.referenceCount.value
          : this.referenceCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('File(')
          ..write('fileId: $fileId, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256: $sha256, ')
          ..write('referenceCount: $referenceCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fileId,
    fileName,
    localPath,
    fileSize,
    mimeType,
    sha256,
    referenceCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is File &&
          other.fileId == this.fileId &&
          other.fileName == this.fileName &&
          other.localPath == this.localPath &&
          other.fileSize == this.fileSize &&
          other.mimeType == this.mimeType &&
          other.sha256 == this.sha256 &&
          other.referenceCount == this.referenceCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FilesCompanion extends UpdateCompanion<File> {
  final Value<String> fileId;
  final Value<String?> fileName;
  final Value<String?> localPath;
  final Value<int?> fileSize;
  final Value<String?> mimeType;
  final Value<String?> sha256;
  final Value<int> referenceCount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FilesCompanion({
    this.fileId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.referenceCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilesCompanion.insert({
    required String fileId,
    this.fileName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.referenceCount = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<File> custom({
    Expression<String>? fileId,
    Expression<String>? fileName,
    Expression<String>? localPath,
    Expression<int>? fileSize,
    Expression<String>? mimeType,
    Expression<String>? sha256,
    Expression<int>? referenceCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (fileName != null) 'file_name': fileName,
      if (localPath != null) 'local_path': localPath,
      if (fileSize != null) 'file_size': fileSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (sha256 != null) 'sha256': sha256,
      if (referenceCount != null) 'reference_count': referenceCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilesCompanion copyWith({
    Value<String>? fileId,
    Value<String?>? fileName,
    Value<String?>? localPath,
    Value<int?>? fileSize,
    Value<String?>? mimeType,
    Value<String?>? sha256,
    Value<int>? referenceCount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FilesCompanion(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
      referenceCount: referenceCount ?? this.referenceCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (referenceCount.present) {
      map['reference_count'] = Variable<int>(referenceCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilesCompanion(')
          ..write('fileId: $fileId, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256: $sha256, ')
          ..write('referenceCount: $referenceCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportArtifactsTable extends ImportArtifacts
    with TableInfo<$ImportArtifactsTable, ImportArtifact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportArtifactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _artifactIdMeta = const VerificationMeta(
    'artifactId',
  );
  @override
  late final GeneratedColumn<String> artifactId = GeneratedColumn<String>(
    'artifact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    artifactId,
    sourceType,
    fileName,
    sourcePath,
    fileSize,
    sha256,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_artifacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportArtifact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('artifact_id')) {
      context.handle(
        _artifactIdMeta,
        artifactId.isAcceptableOrUnknown(data['artifact_id']!, _artifactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artifactIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {artifactId};
  @override
  ImportArtifact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportArtifact(
      artifactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artifact_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ImportArtifactsTable createAlias(String alias) {
    return $ImportArtifactsTable(attachedDatabase, alias);
  }
}

class ImportArtifact extends DataClass implements Insertable<ImportArtifact> {
  final String artifactId;
  final String sourceType;
  final String? fileName;
  final String? sourcePath;
  final int? fileSize;
  final String? sha256;
  final int createdAt;
  const ImportArtifact({
    required this.artifactId,
    required this.sourceType,
    this.fileName,
    this.sourcePath,
    this.fileSize,
    this.sha256,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['artifact_id'] = Variable<String>(artifactId);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || sourcePath != null) {
      map['source_path'] = Variable<String>(sourcePath);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ImportArtifactsCompanion toCompanion(bool nullToAbsent) {
    return ImportArtifactsCompanion(
      artifactId: Value(artifactId),
      sourceType: Value(sourceType),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      sourcePath: sourcePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePath),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      createdAt: Value(createdAt),
    );
  }

  factory ImportArtifact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportArtifact(
      artifactId: serializer.fromJson<String>(json['artifactId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      sourcePath: serializer.fromJson<String?>(json['sourcePath']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'artifactId': serializer.toJson<String>(artifactId),
      'sourceType': serializer.toJson<String>(sourceType),
      'fileName': serializer.toJson<String?>(fileName),
      'sourcePath': serializer.toJson<String?>(sourcePath),
      'fileSize': serializer.toJson<int?>(fileSize),
      'sha256': serializer.toJson<String?>(sha256),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ImportArtifact copyWith({
    String? artifactId,
    String? sourceType,
    Value<String?> fileName = const Value.absent(),
    Value<String?> sourcePath = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    int? createdAt,
  }) => ImportArtifact(
    artifactId: artifactId ?? this.artifactId,
    sourceType: sourceType ?? this.sourceType,
    fileName: fileName.present ? fileName.value : this.fileName,
    sourcePath: sourcePath.present ? sourcePath.value : this.sourcePath,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    sha256: sha256.present ? sha256.value : this.sha256,
    createdAt: createdAt ?? this.createdAt,
  );
  ImportArtifact copyWithCompanion(ImportArtifactsCompanion data) {
    return ImportArtifact(
      artifactId: data.artifactId.present
          ? data.artifactId.value
          : this.artifactId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportArtifact(')
          ..write('artifactId: $artifactId, ')
          ..write('sourceType: $sourceType, ')
          ..write('fileName: $fileName, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    artifactId,
    sourceType,
    fileName,
    sourcePath,
    fileSize,
    sha256,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportArtifact &&
          other.artifactId == this.artifactId &&
          other.sourceType == this.sourceType &&
          other.fileName == this.fileName &&
          other.sourcePath == this.sourcePath &&
          other.fileSize == this.fileSize &&
          other.sha256 == this.sha256 &&
          other.createdAt == this.createdAt);
}

class ImportArtifactsCompanion extends UpdateCompanion<ImportArtifact> {
  final Value<String> artifactId;
  final Value<String> sourceType;
  final Value<String?> fileName;
  final Value<String?> sourcePath;
  final Value<int?> fileSize;
  final Value<String?> sha256;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ImportArtifactsCompanion({
    this.artifactId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportArtifactsCompanion.insert({
    required String artifactId,
    required String sourceType,
    this.fileName = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : artifactId = Value(artifactId),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt);
  static Insertable<ImportArtifact> custom({
    Expression<String>? artifactId,
    Expression<String>? sourceType,
    Expression<String>? fileName,
    Expression<String>? sourcePath,
    Expression<int>? fileSize,
    Expression<String>? sha256,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (artifactId != null) 'artifact_id': artifactId,
      if (sourceType != null) 'source_type': sourceType,
      if (fileName != null) 'file_name': fileName,
      if (sourcePath != null) 'source_path': sourcePath,
      if (fileSize != null) 'file_size': fileSize,
      if (sha256 != null) 'sha256': sha256,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportArtifactsCompanion copyWith({
    Value<String>? artifactId,
    Value<String>? sourceType,
    Value<String?>? fileName,
    Value<String?>? sourcePath,
    Value<int?>? fileSize,
    Value<String?>? sha256,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ImportArtifactsCompanion(
      artifactId: artifactId ?? this.artifactId,
      sourceType: sourceType ?? this.sourceType,
      fileName: fileName ?? this.fileName,
      sourcePath: sourcePath ?? this.sourcePath,
      fileSize: fileSize ?? this.fileSize,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (artifactId.present) {
      map['artifact_id'] = Variable<String>(artifactId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportArtifactsCompanion(')
          ..write('artifactId: $artifactId, ')
          ..write('sourceType: $sourceType, ')
          ..write('fileName: $fileName, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportJobsTable extends ImportJobs
    with TableInfo<$ImportJobsTable, ImportJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artifactIdMeta = const VerificationMeta(
    'artifactId',
  );
  @override
  late final GeneratedColumn<String> artifactId = GeneratedColumn<String>(
    'artifact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES import_artifacts (artifact_id)',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statsJsonMeta = const VerificationMeta(
    'statsJson',
  );
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
    'stats_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    jobId,
    artifactId,
    sourceType,
    status,
    startedAt,
    finishedAt,
    statsJson,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('artifact_id')) {
      context.handle(
        _artifactIdMeta,
        artifactId.isAcceptableOrUnknown(data['artifact_id']!, _artifactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artifactIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('stats_json')) {
      context.handle(
        _statsJsonMeta,
        statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jobId};
  @override
  ImportJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportJob(
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      artifactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artifact_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
      statsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stats_json'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $ImportJobsTable createAlias(String alias) {
    return $ImportJobsTable(attachedDatabase, alias);
  }
}

class ImportJob extends DataClass implements Insertable<ImportJob> {
  final String jobId;
  final String artifactId;
  final String sourceType;
  final String status;
  final int startedAt;
  final int? finishedAt;
  final String? statsJson;
  final String? error;
  const ImportJob({
    required this.jobId,
    required this.artifactId,
    required this.sourceType,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.statsJson,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['job_id'] = Variable<String>(jobId);
    map['artifact_id'] = Variable<String>(artifactId);
    map['source_type'] = Variable<String>(sourceType);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    if (!nullToAbsent || statsJson != null) {
      map['stats_json'] = Variable<String>(statsJson);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  ImportJobsCompanion toCompanion(bool nullToAbsent) {
    return ImportJobsCompanion(
      jobId: Value(jobId),
      artifactId: Value(artifactId),
      sourceType: Value(sourceType),
      status: Value(status),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      statsJson: statsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(statsJson),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory ImportJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportJob(
      jobId: serializer.fromJson<String>(json['jobId']),
      artifactId: serializer.fromJson<String>(json['artifactId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      statsJson: serializer.fromJson<String?>(json['statsJson']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jobId': serializer.toJson<String>(jobId),
      'artifactId': serializer.toJson<String>(artifactId),
      'sourceType': serializer.toJson<String>(sourceType),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'statsJson': serializer.toJson<String?>(statsJson),
      'error': serializer.toJson<String?>(error),
    };
  }

  ImportJob copyWith({
    String? jobId,
    String? artifactId,
    String? sourceType,
    String? status,
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
    Value<String?> statsJson = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => ImportJob(
    jobId: jobId ?? this.jobId,
    artifactId: artifactId ?? this.artifactId,
    sourceType: sourceType ?? this.sourceType,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    statsJson: statsJson.present ? statsJson.value : this.statsJson,
    error: error.present ? error.value : this.error,
  );
  ImportJob copyWithCompanion(ImportJobsCompanion data) {
    return ImportJob(
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      artifactId: data.artifactId.present
          ? data.artifactId.value
          : this.artifactId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportJob(')
          ..write('jobId: $jobId, ')
          ..write('artifactId: $artifactId, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('statsJson: $statsJson, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    jobId,
    artifactId,
    sourceType,
    status,
    startedAt,
    finishedAt,
    statsJson,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportJob &&
          other.jobId == this.jobId &&
          other.artifactId == this.artifactId &&
          other.sourceType == this.sourceType &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.statsJson == this.statsJson &&
          other.error == this.error);
}

class ImportJobsCompanion extends UpdateCompanion<ImportJob> {
  final Value<String> jobId;
  final Value<String> artifactId;
  final Value<String> sourceType;
  final Value<String> status;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<String?> statsJson;
  final Value<String?> error;
  final Value<int> rowid;
  const ImportJobsCompanion({
    this.jobId = const Value.absent(),
    this.artifactId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.statsJson = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportJobsCompanion.insert({
    required String jobId,
    required String artifactId,
    required String sourceType,
    required String status,
    required int startedAt,
    this.finishedAt = const Value.absent(),
    this.statsJson = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : jobId = Value(jobId),
       artifactId = Value(artifactId),
       sourceType = Value(sourceType),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<ImportJob> custom({
    Expression<String>? jobId,
    Expression<String>? artifactId,
    Expression<String>? sourceType,
    Expression<String>? status,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<String>? statsJson,
    Expression<String>? error,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (jobId != null) 'job_id': jobId,
      if (artifactId != null) 'artifact_id': artifactId,
      if (sourceType != null) 'source_type': sourceType,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (statsJson != null) 'stats_json': statsJson,
      if (error != null) 'error': error,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportJobsCompanion copyWith({
    Value<String>? jobId,
    Value<String>? artifactId,
    Value<String>? sourceType,
    Value<String>? status,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<String?>? statsJson,
    Value<String?>? error,
    Value<int>? rowid,
  }) {
    return ImportJobsCompanion(
      jobId: jobId ?? this.jobId,
      artifactId: artifactId ?? this.artifactId,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      statsJson: statsJson ?? this.statsJson,
      error: error ?? this.error,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (artifactId.present) {
      map['artifact_id'] = Variable<String>(artifactId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobsCompanion(')
          ..write('jobId: $jobId, ')
          ..write('artifactId: $artifactId, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('statsJson: $statsJson, ')
          ..write('error: $error, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProvenanceRecordsTable extends ProvenanceRecords
    with TableInfo<$ProvenanceRecordsTable, ProvenanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProvenanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentExternalIdMeta = const VerificationMeta(
    'parentExternalId',
  );
  @override
  late final GeneratedColumn<String> parentExternalId = GeneratedColumn<String>(
    'parent_external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<int> firstSeenAt = GeneratedColumn<int>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceType,
    entityType,
    externalId,
    entityId,
    parentExternalId,
    fingerprint,
    firstSeenAt,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provenance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProvenanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('parent_external_id')) {
      context.handle(
        _parentExternalIdMeta,
        parentExternalId.isAcceptableOrUnknown(
          data['parent_external_id']!,
          _parentExternalIdMeta,
        ),
      );
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceType, entityType, externalId};
  @override
  ProvenanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProvenanceRecord(
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      parentExternalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_external_id'],
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      ),
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_seen_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
    );
  }

  @override
  $ProvenanceRecordsTable createAlias(String alias) {
    return $ProvenanceRecordsTable(attachedDatabase, alias);
  }
}

class ProvenanceRecord extends DataClass
    implements Insertable<ProvenanceRecord> {
  final String sourceType;
  final String entityType;
  final String externalId;
  final String entityId;
  final String? parentExternalId;
  final String? fingerprint;
  final int firstSeenAt;
  final int lastSeenAt;
  const ProvenanceRecord({
    required this.sourceType,
    required this.entityType,
    required this.externalId,
    required this.entityId,
    this.parentExternalId,
    this.fingerprint,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_type'] = Variable<String>(sourceType);
    map['entity_type'] = Variable<String>(entityType);
    map['external_id'] = Variable<String>(externalId);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || parentExternalId != null) {
      map['parent_external_id'] = Variable<String>(parentExternalId);
    }
    if (!nullToAbsent || fingerprint != null) {
      map['fingerprint'] = Variable<String>(fingerprint);
    }
    map['first_seen_at'] = Variable<int>(firstSeenAt);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    return map;
  }

  ProvenanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return ProvenanceRecordsCompanion(
      sourceType: Value(sourceType),
      entityType: Value(entityType),
      externalId: Value(externalId),
      entityId: Value(entityId),
      parentExternalId: parentExternalId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentExternalId),
      fingerprint: fingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprint),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory ProvenanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProvenanceRecord(
      sourceType: serializer.fromJson<String>(json['sourceType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      externalId: serializer.fromJson<String>(json['externalId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      parentExternalId: serializer.fromJson<String?>(json['parentExternalId']),
      fingerprint: serializer.fromJson<String?>(json['fingerprint']),
      firstSeenAt: serializer.fromJson<int>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceType': serializer.toJson<String>(sourceType),
      'entityType': serializer.toJson<String>(entityType),
      'externalId': serializer.toJson<String>(externalId),
      'entityId': serializer.toJson<String>(entityId),
      'parentExternalId': serializer.toJson<String?>(parentExternalId),
      'fingerprint': serializer.toJson<String?>(fingerprint),
      'firstSeenAt': serializer.toJson<int>(firstSeenAt),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
    };
  }

  ProvenanceRecord copyWith({
    String? sourceType,
    String? entityType,
    String? externalId,
    String? entityId,
    Value<String?> parentExternalId = const Value.absent(),
    Value<String?> fingerprint = const Value.absent(),
    int? firstSeenAt,
    int? lastSeenAt,
  }) => ProvenanceRecord(
    sourceType: sourceType ?? this.sourceType,
    entityType: entityType ?? this.entityType,
    externalId: externalId ?? this.externalId,
    entityId: entityId ?? this.entityId,
    parentExternalId: parentExternalId.present
        ? parentExternalId.value
        : this.parentExternalId,
    fingerprint: fingerprint.present ? fingerprint.value : this.fingerprint,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );
  ProvenanceRecord copyWithCompanion(ProvenanceRecordsCompanion data) {
    return ProvenanceRecord(
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      parentExternalId: data.parentExternalId.present
          ? data.parentExternalId.value
          : this.parentExternalId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProvenanceRecord(')
          ..write('sourceType: $sourceType, ')
          ..write('entityType: $entityType, ')
          ..write('externalId: $externalId, ')
          ..write('entityId: $entityId, ')
          ..write('parentExternalId: $parentExternalId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceType,
    entityType,
    externalId,
    entityId,
    parentExternalId,
    fingerprint,
    firstSeenAt,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProvenanceRecord &&
          other.sourceType == this.sourceType &&
          other.entityType == this.entityType &&
          other.externalId == this.externalId &&
          other.entityId == this.entityId &&
          other.parentExternalId == this.parentExternalId &&
          other.fingerprint == this.fingerprint &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt);
}

class ProvenanceRecordsCompanion extends UpdateCompanion<ProvenanceRecord> {
  final Value<String> sourceType;
  final Value<String> entityType;
  final Value<String> externalId;
  final Value<String> entityId;
  final Value<String?> parentExternalId;
  final Value<String?> fingerprint;
  final Value<int> firstSeenAt;
  final Value<int> lastSeenAt;
  final Value<int> rowid;
  const ProvenanceRecordsCompanion({
    this.sourceType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.externalId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.parentExternalId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProvenanceRecordsCompanion.insert({
    required String sourceType,
    required String entityType,
    required String externalId,
    required String entityId,
    this.parentExternalId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    required int firstSeenAt,
    required int lastSeenAt,
    this.rowid = const Value.absent(),
  }) : sourceType = Value(sourceType),
       entityType = Value(entityType),
       externalId = Value(externalId),
       entityId = Value(entityId),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<ProvenanceRecord> custom({
    Expression<String>? sourceType,
    Expression<String>? entityType,
    Expression<String>? externalId,
    Expression<String>? entityId,
    Expression<String>? parentExternalId,
    Expression<String>? fingerprint,
    Expression<int>? firstSeenAt,
    Expression<int>? lastSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceType != null) 'source_type': sourceType,
      if (entityType != null) 'entity_type': entityType,
      if (externalId != null) 'external_id': externalId,
      if (entityId != null) 'entity_id': entityId,
      if (parentExternalId != null) 'parent_external_id': parentExternalId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProvenanceRecordsCompanion copyWith({
    Value<String>? sourceType,
    Value<String>? entityType,
    Value<String>? externalId,
    Value<String>? entityId,
    Value<String?>? parentExternalId,
    Value<String?>? fingerprint,
    Value<int>? firstSeenAt,
    Value<int>? lastSeenAt,
    Value<int>? rowid,
  }) {
    return ProvenanceRecordsCompanion(
      sourceType: sourceType ?? this.sourceType,
      entityType: entityType ?? this.entityType,
      externalId: externalId ?? this.externalId,
      entityId: entityId ?? this.entityId,
      parentExternalId: parentExternalId ?? this.parentExternalId,
      fingerprint: fingerprint ?? this.fingerprint,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (parentExternalId.present) {
      map['parent_external_id'] = Variable<String>(parentExternalId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<int>(firstSeenAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProvenanceRecordsCompanion(')
          ..write('sourceType: $sourceType, ')
          ..write('entityType: $entityType, ')
          ..write('externalId: $externalId, ')
          ..write('entityId: $entityId, ')
          ..write('parentExternalId: $parentExternalId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopicEmbeddingsTable extends TopicEmbeddings
    with TableInfo<$TopicEmbeddingsTable, TopicEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicEmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstQueryTextMeta = const VerificationMeta(
    'firstQueryText',
  );
  @override
  late final GeneratedColumn<String> firstQueryText = GeneratedColumn<String>(
    'first_query_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingJsonMeta = const VerificationMeta(
    'embeddingJson',
  );
  @override
  late final GeneratedColumn<String> embeddingJson = GeneratedColumn<String>(
    'embedding_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    topicId,
    firstQueryText,
    embeddingJson,
    modelName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_embeddings';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicEmbedding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('first_query_text')) {
      context.handle(
        _firstQueryTextMeta,
        firstQueryText.isAcceptableOrUnknown(
          data['first_query_text']!,
          _firstQueryTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstQueryTextMeta);
    }
    if (data.containsKey('embedding_json')) {
      context.handle(
        _embeddingJsonMeta,
        embeddingJson.isAcceptableOrUnknown(
          data['embedding_json']!,
          _embeddingJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_embeddingJsonMeta);
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_modelNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topicId};
  @override
  TopicEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicEmbedding(
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      firstQueryText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_query_text'],
      )!,
      embeddingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_json'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TopicEmbeddingsTable createAlias(String alias) {
    return $TopicEmbeddingsTable(attachedDatabase, alias);
  }
}

class TopicEmbedding extends DataClass implements Insertable<TopicEmbedding> {
  final String topicId;
  final String firstQueryText;
  final String embeddingJson;
  final String modelName;
  final int createdAt;
  const TopicEmbedding({
    required this.topicId,
    required this.firstQueryText,
    required this.embeddingJson,
    required this.modelName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic_id'] = Variable<String>(topicId);
    map['first_query_text'] = Variable<String>(firstQueryText);
    map['embedding_json'] = Variable<String>(embeddingJson);
    map['model_name'] = Variable<String>(modelName);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TopicEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return TopicEmbeddingsCompanion(
      topicId: Value(topicId),
      firstQueryText: Value(firstQueryText),
      embeddingJson: Value(embeddingJson),
      modelName: Value(modelName),
      createdAt: Value(createdAt),
    );
  }

  factory TopicEmbedding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicEmbedding(
      topicId: serializer.fromJson<String>(json['topicId']),
      firstQueryText: serializer.fromJson<String>(json['firstQueryText']),
      embeddingJson: serializer.fromJson<String>(json['embeddingJson']),
      modelName: serializer.fromJson<String>(json['modelName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topicId': serializer.toJson<String>(topicId),
      'firstQueryText': serializer.toJson<String>(firstQueryText),
      'embeddingJson': serializer.toJson<String>(embeddingJson),
      'modelName': serializer.toJson<String>(modelName),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  TopicEmbedding copyWith({
    String? topicId,
    String? firstQueryText,
    String? embeddingJson,
    String? modelName,
    int? createdAt,
  }) => TopicEmbedding(
    topicId: topicId ?? this.topicId,
    firstQueryText: firstQueryText ?? this.firstQueryText,
    embeddingJson: embeddingJson ?? this.embeddingJson,
    modelName: modelName ?? this.modelName,
    createdAt: createdAt ?? this.createdAt,
  );
  TopicEmbedding copyWithCompanion(TopicEmbeddingsCompanion data) {
    return TopicEmbedding(
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      firstQueryText: data.firstQueryText.present
          ? data.firstQueryText.value
          : this.firstQueryText,
      embeddingJson: data.embeddingJson.present
          ? data.embeddingJson.value
          : this.embeddingJson,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicEmbedding(')
          ..write('topicId: $topicId, ')
          ..write('firstQueryText: $firstQueryText, ')
          ..write('embeddingJson: $embeddingJson, ')
          ..write('modelName: $modelName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(topicId, firstQueryText, embeddingJson, modelName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicEmbedding &&
          other.topicId == this.topicId &&
          other.firstQueryText == this.firstQueryText &&
          other.embeddingJson == this.embeddingJson &&
          other.modelName == this.modelName &&
          other.createdAt == this.createdAt);
}

class TopicEmbeddingsCompanion extends UpdateCompanion<TopicEmbedding> {
  final Value<String> topicId;
  final Value<String> firstQueryText;
  final Value<String> embeddingJson;
  final Value<String> modelName;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TopicEmbeddingsCompanion({
    this.topicId = const Value.absent(),
    this.firstQueryText = const Value.absent(),
    this.embeddingJson = const Value.absent(),
    this.modelName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicEmbeddingsCompanion.insert({
    required String topicId,
    required String firstQueryText,
    required String embeddingJson,
    required String modelName,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : topicId = Value(topicId),
       firstQueryText = Value(firstQueryText),
       embeddingJson = Value(embeddingJson),
       modelName = Value(modelName),
       createdAt = Value(createdAt);
  static Insertable<TopicEmbedding> custom({
    Expression<String>? topicId,
    Expression<String>? firstQueryText,
    Expression<String>? embeddingJson,
    Expression<String>? modelName,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topicId != null) 'topic_id': topicId,
      if (firstQueryText != null) 'first_query_text': firstQueryText,
      if (embeddingJson != null) 'embedding_json': embeddingJson,
      if (modelName != null) 'model_name': modelName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicEmbeddingsCompanion copyWith({
    Value<String>? topicId,
    Value<String>? firstQueryText,
    Value<String>? embeddingJson,
    Value<String>? modelName,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return TopicEmbeddingsCompanion(
      topicId: topicId ?? this.topicId,
      firstQueryText: firstQueryText ?? this.firstQueryText,
      embeddingJson: embeddingJson ?? this.embeddingJson,
      modelName: modelName ?? this.modelName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (firstQueryText.present) {
      map['first_query_text'] = Variable<String>(firstQueryText.value);
    }
    if (embeddingJson.present) {
      map['embedding_json'] = Variable<String>(embeddingJson.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicEmbeddingsCompanion(')
          ..write('topicId: $topicId, ')
          ..write('firstQueryText: $firstQueryText, ')
          ..write('embeddingJson: $embeddingJson, ')
          ..write('modelName: $modelName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ImportDatabase extends GeneratedDatabase {
  _$ImportDatabase(QueryExecutor e) : super(e);
  $ImportDatabaseManager get managers => $ImportDatabaseManager(this);
  late final $AssistantsTable assistants = $AssistantsTable(this);
  late final $TopicsTable topics = $TopicsTable(this);
  late final $TopicAssistantsTable topicAssistants = $TopicAssistantsTable(
    this,
  );
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageBlocksTable messageBlocks = $MessageBlocksTable(this);
  late final $FilesTable files = $FilesTable(this);
  late final $ImportArtifactsTable importArtifacts = $ImportArtifactsTable(
    this,
  );
  late final $ImportJobsTable importJobs = $ImportJobsTable(this);
  late final $ProvenanceRecordsTable provenanceRecords =
      $ProvenanceRecordsTable(this);
  late final $TopicEmbeddingsTable topicEmbeddings = $TopicEmbeddingsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    assistants,
    topics,
    topicAssistants,
    messages,
    messageBlocks,
    files,
    importArtifacts,
    importJobs,
    provenanceRecords,
    topicEmbeddings,
  ];
}

typedef $$AssistantsTableCreateCompanionBuilder =
    AssistantsCompanion Function({
      required String assistantId,
      required String name,
      Value<String?> description,
      Value<String?> avatar,
      Value<String?> prompt,
      Value<int> topicCount,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AssistantsTableUpdateCompanionBuilder =
    AssistantsCompanion Function({
      Value<String> assistantId,
      Value<String> name,
      Value<String?> description,
      Value<String?> avatar,
      Value<String?> prompt,
      Value<int> topicCount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$AssistantsTableReferences
    extends BaseReferences<_$ImportDatabase, $AssistantsTable, Assistant> {
  $$AssistantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TopicAssistantsTable, List<TopicAssistant>>
  _topicAssistantsRefsTable(_$ImportDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.topicAssistants,
        aliasName: $_aliasNameGenerator(
          db.assistants.assistantId,
          db.topicAssistants.assistantId,
        ),
      );

  $$TopicAssistantsTableProcessedTableManager get topicAssistantsRefs {
    final manager =
        $$TopicAssistantsTableTableManager($_db, $_db.topicAssistants).filter(
          (f) => f.assistantId.assistantId.sqlEquals(
            $_itemColumn<String>('assistant_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _topicAssistantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssistantsTableFilterComposer
    extends Composer<_$ImportDatabase, $AssistantsTable> {
  $$AssistantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assistantId => $composableBuilder(
    column: $table.assistantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicCount => $composableBuilder(
    column: $table.topicCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> topicAssistantsRefs(
    Expression<bool> Function($$TopicAssistantsTableFilterComposer f) f,
  ) {
    final $$TopicAssistantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assistantId,
      referencedTable: $db.topicAssistants,
      getReferencedColumn: (t) => t.assistantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicAssistantsTableFilterComposer(
            $db: $db,
            $table: $db.topicAssistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssistantsTableOrderingComposer
    extends Composer<_$ImportDatabase, $AssistantsTable> {
  $$AssistantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assistantId => $composableBuilder(
    column: $table.assistantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicCount => $composableBuilder(
    column: $table.topicCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssistantsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $AssistantsTable> {
  $$AssistantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assistantId => $composableBuilder(
    column: $table.assistantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<int> get topicCount => $composableBuilder(
    column: $table.topicCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> topicAssistantsRefs<T extends Object>(
    Expression<T> Function($$TopicAssistantsTableAnnotationComposer a) f,
  ) {
    final $$TopicAssistantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assistantId,
      referencedTable: $db.topicAssistants,
      getReferencedColumn: (t) => t.assistantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicAssistantsTableAnnotationComposer(
            $db: $db,
            $table: $db.topicAssistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssistantsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $AssistantsTable,
          Assistant,
          $$AssistantsTableFilterComposer,
          $$AssistantsTableOrderingComposer,
          $$AssistantsTableAnnotationComposer,
          $$AssistantsTableCreateCompanionBuilder,
          $$AssistantsTableUpdateCompanionBuilder,
          (Assistant, $$AssistantsTableReferences),
          Assistant,
          PrefetchHooks Function({bool topicAssistantsRefs})
        > {
  $$AssistantsTableTableManager(_$ImportDatabase db, $AssistantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssistantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssistantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssistantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assistantId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> prompt = const Value.absent(),
                Value<int> topicCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssistantsCompanion(
                assistantId: assistantId,
                name: name,
                description: description,
                avatar: avatar,
                prompt: prompt,
                topicCount: topicCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assistantId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> prompt = const Value.absent(),
                Value<int> topicCount = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AssistantsCompanion.insert(
                assistantId: assistantId,
                name: name,
                description: description,
                avatar: avatar,
                prompt: prompt,
                topicCount: topicCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssistantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({topicAssistantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (topicAssistantsRefs) db.topicAssistants,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (topicAssistantsRefs)
                    await $_getPrefetchedData<
                      Assistant,
                      $AssistantsTable,
                      TopicAssistant
                    >(
                      currentTable: table,
                      referencedTable: $$AssistantsTableReferences
                          ._topicAssistantsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AssistantsTableReferences(
                            db,
                            table,
                            p0,
                          ).topicAssistantsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.assistantId == item.assistantId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AssistantsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $AssistantsTable,
      Assistant,
      $$AssistantsTableFilterComposer,
      $$AssistantsTableOrderingComposer,
      $$AssistantsTableAnnotationComposer,
      $$AssistantsTableCreateCompanionBuilder,
      $$AssistantsTableUpdateCompanionBuilder,
      (Assistant, $$AssistantsTableReferences),
      Assistant,
      PrefetchHooks Function({bool topicAssistantsRefs})
    >;
typedef $$TopicsTableCreateCompanionBuilder =
    TopicsCompanion Function({
      required String topicId,
      required String name,
      required int messageCount,
      required int roundCount,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$TopicsTableUpdateCompanionBuilder =
    TopicsCompanion Function({
      Value<String> topicId,
      Value<String> name,
      Value<int> messageCount,
      Value<int> roundCount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$TopicsTableReferences
    extends BaseReferences<_$ImportDatabase, $TopicsTable, Topic> {
  $$TopicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TopicAssistantsTable, List<TopicAssistant>>
  _topicAssistantsRefsTable(_$ImportDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.topicAssistants,
        aliasName: $_aliasNameGenerator(
          db.topics.topicId,
          db.topicAssistants.topicId,
        ),
      );

  $$TopicAssistantsTableProcessedTableManager get topicAssistantsRefs {
    final manager =
        $$TopicAssistantsTableTableManager($_db, $_db.topicAssistants).filter(
          (f) => f.topicId.topicId.sqlEquals($_itemColumn<String>('topic_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _topicAssistantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$ImportDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: $_aliasNameGenerator(db.topics.topicId, db.messages.topicId),
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
      (f) => f.topicId.topicId.sqlEquals($_itemColumn<String>('topic_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessageBlocksTable, List<MessageBlock>>
  _messageBlocksRefsTable(_$ImportDatabase db) => MultiTypedResultKey.fromTable(
    db.messageBlocks,
    aliasName: $_aliasNameGenerator(
      db.topics.topicId,
      db.messageBlocks.topicId,
    ),
  );

  $$MessageBlocksTableProcessedTableManager get messageBlocksRefs {
    final manager = $$MessageBlocksTableTableManager($_db, $_db.messageBlocks)
        .filter(
          (f) => f.topicId.topicId.sqlEquals($_itemColumn<String>('topic_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_messageBlocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TopicsTableFilterComposer
    extends Composer<_$ImportDatabase, $TopicsTable> {
  $$TopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> topicAssistantsRefs(
    Expression<bool> Function($$TopicAssistantsTableFilterComposer f) f,
  ) {
    final $$TopicAssistantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topicAssistants,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicAssistantsTableFilterComposer(
            $db: $db,
            $table: $db.topicAssistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messageBlocksRefs(
    Expression<bool> Function($$MessageBlocksTableFilterComposer f) f,
  ) {
    final $$MessageBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.messageBlocks,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageBlocksTableFilterComposer(
            $db: $db,
            $table: $db.messageBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TopicsTableOrderingComposer
    extends Composer<_$ImportDatabase, $TopicsTable> {
  $$TopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $TopicsTable> {
  $$TopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> topicAssistantsRefs<T extends Object>(
    Expression<T> Function($$TopicAssistantsTableAnnotationComposer a) f,
  ) {
    final $$TopicAssistantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topicAssistants,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicAssistantsTableAnnotationComposer(
            $db: $db,
            $table: $db.topicAssistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> messageBlocksRefs<T extends Object>(
    Expression<T> Function($$MessageBlocksTableAnnotationComposer a) f,
  ) {
    final $$MessageBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.messageBlocks,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.messageBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TopicsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $TopicsTable,
          Topic,
          $$TopicsTableFilterComposer,
          $$TopicsTableOrderingComposer,
          $$TopicsTableAnnotationComposer,
          $$TopicsTableCreateCompanionBuilder,
          $$TopicsTableUpdateCompanionBuilder,
          (Topic, $$TopicsTableReferences),
          Topic,
          PrefetchHooks Function({
            bool topicAssistantsRefs,
            bool messagesRefs,
            bool messageBlocksRefs,
          })
        > {
  $$TopicsTableTableManager(_$ImportDatabase db, $TopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topicId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> roundCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicsCompanion(
                topicId: topicId,
                name: name,
                messageCount: messageCount,
                roundCount: roundCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topicId,
                required String name,
                required int messageCount,
                required int roundCount,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TopicsCompanion.insert(
                topicId: topicId,
                name: name,
                messageCount: messageCount,
                roundCount: roundCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TopicsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                topicAssistantsRefs = false,
                messagesRefs = false,
                messageBlocksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (topicAssistantsRefs) db.topicAssistants,
                    if (messagesRefs) db.messages,
                    if (messageBlocksRefs) db.messageBlocks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (topicAssistantsRefs)
                        await $_getPrefetchedData<
                          Topic,
                          $TopicsTable,
                          TopicAssistant
                        >(
                          currentTable: table,
                          referencedTable: $$TopicsTableReferences
                              ._topicAssistantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TopicsTableReferences(
                                db,
                                table,
                                p0,
                              ).topicAssistantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.topicId == item.topicId,
                              ),
                          typedResults: items,
                        ),
                      if (messagesRefs)
                        await $_getPrefetchedData<Topic, $TopicsTable, Message>(
                          currentTable: table,
                          referencedTable: $$TopicsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TopicsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.topicId == item.topicId,
                              ),
                          typedResults: items,
                        ),
                      if (messageBlocksRefs)
                        await $_getPrefetchedData<
                          Topic,
                          $TopicsTable,
                          MessageBlock
                        >(
                          currentTable: table,
                          referencedTable: $$TopicsTableReferences
                              ._messageBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TopicsTableReferences(
                                db,
                                table,
                                p0,
                              ).messageBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.topicId == item.topicId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $TopicsTable,
      Topic,
      $$TopicsTableFilterComposer,
      $$TopicsTableOrderingComposer,
      $$TopicsTableAnnotationComposer,
      $$TopicsTableCreateCompanionBuilder,
      $$TopicsTableUpdateCompanionBuilder,
      (Topic, $$TopicsTableReferences),
      Topic,
      PrefetchHooks Function({
        bool topicAssistantsRefs,
        bool messagesRefs,
        bool messageBlocksRefs,
      })
    >;
typedef $$TopicAssistantsTableCreateCompanionBuilder =
    TopicAssistantsCompanion Function({
      required String topicId,
      required String assistantId,
      Value<int> rowid,
    });
typedef $$TopicAssistantsTableUpdateCompanionBuilder =
    TopicAssistantsCompanion Function({
      Value<String> topicId,
      Value<String> assistantId,
      Value<int> rowid,
    });

final class $$TopicAssistantsTableReferences
    extends
        BaseReferences<
          _$ImportDatabase,
          $TopicAssistantsTable,
          TopicAssistant
        > {
  $$TopicAssistantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TopicsTable _topicIdTable(_$ImportDatabase db) =>
      db.topics.createAlias(
        $_aliasNameGenerator(db.topicAssistants.topicId, db.topics.topicId),
      );

  $$TopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<String>('topic_id')!;

    final manager = $$TopicsTableTableManager(
      $_db,
      $_db.topics,
    ).filter((f) => f.topicId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssistantsTable _assistantIdTable(_$ImportDatabase db) =>
      db.assistants.createAlias(
        $_aliasNameGenerator(
          db.topicAssistants.assistantId,
          db.assistants.assistantId,
        ),
      );

  $$AssistantsTableProcessedTableManager get assistantId {
    final $_column = $_itemColumn<String>('assistant_id')!;

    final manager = $$AssistantsTableTableManager(
      $_db,
      $_db.assistants,
    ).filter((f) => f.assistantId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assistantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TopicAssistantsTableFilterComposer
    extends Composer<_$ImportDatabase, $TopicAssistantsTable> {
  $$TopicAssistantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TopicsTableFilterComposer get topicId {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableFilterComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssistantsTableFilterComposer get assistantId {
    final $$AssistantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assistantId,
      referencedTable: $db.assistants,
      getReferencedColumn: (t) => t.assistantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssistantsTableFilterComposer(
            $db: $db,
            $table: $db.assistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicAssistantsTableOrderingComposer
    extends Composer<_$ImportDatabase, $TopicAssistantsTable> {
  $$TopicAssistantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TopicsTableOrderingComposer get topicId {
    final $$TopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableOrderingComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssistantsTableOrderingComposer get assistantId {
    final $$AssistantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assistantId,
      referencedTable: $db.assistants,
      getReferencedColumn: (t) => t.assistantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssistantsTableOrderingComposer(
            $db: $db,
            $table: $db.assistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicAssistantsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $TopicAssistantsTable> {
  $$TopicAssistantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TopicsTableAnnotationComposer get topicId {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssistantsTableAnnotationComposer get assistantId {
    final $$AssistantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assistantId,
      referencedTable: $db.assistants,
      getReferencedColumn: (t) => t.assistantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssistantsTableAnnotationComposer(
            $db: $db,
            $table: $db.assistants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicAssistantsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $TopicAssistantsTable,
          TopicAssistant,
          $$TopicAssistantsTableFilterComposer,
          $$TopicAssistantsTableOrderingComposer,
          $$TopicAssistantsTableAnnotationComposer,
          $$TopicAssistantsTableCreateCompanionBuilder,
          $$TopicAssistantsTableUpdateCompanionBuilder,
          (TopicAssistant, $$TopicAssistantsTableReferences),
          TopicAssistant,
          PrefetchHooks Function({bool topicId, bool assistantId})
        > {
  $$TopicAssistantsTableTableManager(
    _$ImportDatabase db,
    $TopicAssistantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicAssistantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicAssistantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicAssistantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topicId = const Value.absent(),
                Value<String> assistantId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicAssistantsCompanion(
                topicId: topicId,
                assistantId: assistantId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topicId,
                required String assistantId,
                Value<int> rowid = const Value.absent(),
              }) => TopicAssistantsCompanion.insert(
                topicId: topicId,
                assistantId: assistantId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TopicAssistantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({topicId = false, assistantId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (topicId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.topicId,
                                referencedTable:
                                    $$TopicAssistantsTableReferences
                                        ._topicIdTable(db),
                                referencedColumn:
                                    $$TopicAssistantsTableReferences
                                        ._topicIdTable(db)
                                        .topicId,
                              )
                              as T;
                    }
                    if (assistantId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assistantId,
                                referencedTable:
                                    $$TopicAssistantsTableReferences
                                        ._assistantIdTable(db),
                                referencedColumn:
                                    $$TopicAssistantsTableReferences
                                        ._assistantIdTable(db)
                                        .assistantId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TopicAssistantsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $TopicAssistantsTable,
      TopicAssistant,
      $$TopicAssistantsTableFilterComposer,
      $$TopicAssistantsTableOrderingComposer,
      $$TopicAssistantsTableAnnotationComposer,
      $$TopicAssistantsTableCreateCompanionBuilder,
      $$TopicAssistantsTableUpdateCompanionBuilder,
      (TopicAssistant, $$TopicAssistantsTableReferences),
      TopicAssistant,
      PrefetchHooks Function({bool topicId, bool assistantId})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String messageId,
      required String topicId,
      required int orderIndex,
      required int roundIndex,
      required String role,
      Value<String?> askId,
      required bool useful,
      Value<String?> modelId,
      Value<String?> modelName,
      Value<String?> usageJson,
      Value<String?> metricsJson,
      Value<String?> mentionsJson,
      required int createdAt,
      required String status,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> messageId,
      Value<String> topicId,
      Value<int> orderIndex,
      Value<int> roundIndex,
      Value<String> role,
      Value<String?> askId,
      Value<bool> useful,
      Value<String?> modelId,
      Value<String?> modelName,
      Value<String?> usageJson,
      Value<String?> metricsJson,
      Value<String?> mentionsJson,
      Value<int> createdAt,
      Value<String> status,
      Value<int> rowid,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$ImportDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TopicsTable _topicIdTable(_$ImportDatabase db) =>
      db.topics.createAlias(
        $_aliasNameGenerator(db.messages.topicId, db.topics.topicId),
      );

  $$TopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<String>('topic_id')!;

    final manager = $$TopicsTableTableManager(
      $_db,
      $_db.topics,
    ).filter((f) => f.topicId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessageBlocksTable, List<MessageBlock>>
  _messageBlocksRefsTable(_$ImportDatabase db) => MultiTypedResultKey.fromTable(
    db.messageBlocks,
    aliasName: $_aliasNameGenerator(
      db.messages.messageId,
      db.messageBlocks.messageId,
    ),
  );

  $$MessageBlocksTableProcessedTableManager get messageBlocksRefs {
    final manager = $$MessageBlocksTableTableManager($_db, $_db.messageBlocks)
        .filter(
          (f) => f.messageId.messageId.sqlEquals(
            $_itemColumn<String>('message_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_messageBlocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$ImportDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundIndex => $composableBuilder(
    column: $table.roundIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get askId => $composableBuilder(
    column: $table.askId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useful => $composableBuilder(
    column: $table.useful,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usageJson => $composableBuilder(
    column: $table.usageJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricsJson => $composableBuilder(
    column: $table.metricsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mentionsJson => $composableBuilder(
    column: $table.mentionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$TopicsTableFilterComposer get topicId {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableFilterComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messageBlocksRefs(
    Expression<bool> Function($$MessageBlocksTableFilterComposer f) f,
  ) {
    final $$MessageBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messageBlocks,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageBlocksTableFilterComposer(
            $db: $db,
            $table: $db.messageBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$ImportDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundIndex => $composableBuilder(
    column: $table.roundIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get askId => $composableBuilder(
    column: $table.askId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useful => $composableBuilder(
    column: $table.useful,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usageJson => $composableBuilder(
    column: $table.usageJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricsJson => $composableBuilder(
    column: $table.metricsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mentionsJson => $composableBuilder(
    column: $table.mentionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$TopicsTableOrderingComposer get topicId {
    final $$TopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableOrderingComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$ImportDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundIndex => $composableBuilder(
    column: $table.roundIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get askId =>
      $composableBuilder(column: $table.askId, builder: (column) => column);

  GeneratedColumn<bool> get useful =>
      $composableBuilder(column: $table.useful, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get usageJson =>
      $composableBuilder(column: $table.usageJson, builder: (column) => column);

  GeneratedColumn<String> get metricsJson => $composableBuilder(
    column: $table.metricsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mentionsJson => $composableBuilder(
    column: $table.mentionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$TopicsTableAnnotationComposer get topicId {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messageBlocksRefs<T extends Object>(
    Expression<T> Function($$MessageBlocksTableAnnotationComposer a) f,
  ) {
    final $$MessageBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messageBlocks,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.messageBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool topicId, bool messageBlocksRefs})
        > {
  $$MessagesTableTableManager(_$ImportDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> roundIndex = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> askId = const Value.absent(),
                Value<bool> useful = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> usageJson = const Value.absent(),
                Value<String?> metricsJson = const Value.absent(),
                Value<String?> mentionsJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                messageId: messageId,
                topicId: topicId,
                orderIndex: orderIndex,
                roundIndex: roundIndex,
                role: role,
                askId: askId,
                useful: useful,
                modelId: modelId,
                modelName: modelName,
                usageJson: usageJson,
                metricsJson: metricsJson,
                mentionsJson: mentionsJson,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String topicId,
                required int orderIndex,
                required int roundIndex,
                required String role,
                Value<String?> askId = const Value.absent(),
                required bool useful,
                Value<String?> modelId = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> usageJson = const Value.absent(),
                Value<String?> metricsJson = const Value.absent(),
                Value<String?> mentionsJson = const Value.absent(),
                required int createdAt,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                messageId: messageId,
                topicId: topicId,
                orderIndex: orderIndex,
                roundIndex: roundIndex,
                role: role,
                askId: askId,
                useful: useful,
                modelId: modelId,
                modelName: modelName,
                usageJson: usageJson,
                metricsJson: metricsJson,
                mentionsJson: mentionsJson,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({topicId = false, messageBlocksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messageBlocksRefs) db.messageBlocks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (topicId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.topicId,
                                    referencedTable: $$MessagesTableReferences
                                        ._topicIdTable(db),
                                    referencedColumn: $$MessagesTableReferences
                                        ._topicIdTable(db)
                                        .topicId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messageBlocksRefs)
                        await $_getPrefetchedData<
                          Message,
                          $MessagesTable,
                          MessageBlock
                        >(
                          currentTable: table,
                          referencedTable: $$MessagesTableReferences
                              ._messageBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MessagesTableReferences(
                                db,
                                table,
                                p0,
                              ).messageBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.messageId == item.messageId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool topicId, bool messageBlocksRefs})
    >;
typedef $$MessageBlocksTableCreateCompanionBuilder =
    MessageBlocksCompanion Function({
      required String blockId,
      required String topicId,
      required String messageId,
      required int orderIndex,
      required String type,
      Value<String?> content,
      Value<double?> thinkingMillsec,
      Value<String?> url,
      Value<String?> fileJson,
      Value<String?> toolJson,
      Value<String?> errorJson,
      Value<String?> targetLanguage,
      Value<String?> responseJson,
      Value<String?> knowledgeJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$MessageBlocksTableUpdateCompanionBuilder =
    MessageBlocksCompanion Function({
      Value<String> blockId,
      Value<String> topicId,
      Value<String> messageId,
      Value<int> orderIndex,
      Value<String> type,
      Value<String?> content,
      Value<double?> thinkingMillsec,
      Value<String?> url,
      Value<String?> fileJson,
      Value<String?> toolJson,
      Value<String?> errorJson,
      Value<String?> targetLanguage,
      Value<String?> responseJson,
      Value<String?> knowledgeJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$MessageBlocksTableReferences
    extends
        BaseReferences<_$ImportDatabase, $MessageBlocksTable, MessageBlock> {
  $$MessageBlocksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TopicsTable _topicIdTable(_$ImportDatabase db) =>
      db.topics.createAlias(
        $_aliasNameGenerator(db.messageBlocks.topicId, db.topics.topicId),
      );

  $$TopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<String>('topic_id')!;

    final manager = $$TopicsTableTableManager(
      $_db,
      $_db.topics,
    ).filter((f) => f.topicId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MessagesTable _messageIdTable(_$ImportDatabase db) =>
      db.messages.createAlias(
        $_aliasNameGenerator(db.messageBlocks.messageId, db.messages.messageId),
      );

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessageBlocksTableFilterComposer
    extends Composer<_$ImportDatabase, $MessageBlocksTable> {
  $$MessageBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thinkingMillsec => $composableBuilder(
    column: $table.thinkingMillsec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileJson => $composableBuilder(
    column: $table.fileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolJson => $composableBuilder(
    column: $table.toolJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorJson => $composableBuilder(
    column: $table.errorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knowledgeJson => $composableBuilder(
    column: $table.knowledgeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TopicsTableFilterComposer get topicId {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableFilterComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageBlocksTableOrderingComposer
    extends Composer<_$ImportDatabase, $MessageBlocksTable> {
  $$MessageBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thinkingMillsec => $composableBuilder(
    column: $table.thinkingMillsec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileJson => $composableBuilder(
    column: $table.fileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolJson => $composableBuilder(
    column: $table.toolJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorJson => $composableBuilder(
    column: $table.errorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knowledgeJson => $composableBuilder(
    column: $table.knowledgeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TopicsTableOrderingComposer get topicId {
    final $$TopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableOrderingComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageBlocksTableAnnotationComposer
    extends Composer<_$ImportDatabase, $MessageBlocksTable> {
  $$MessageBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<double> get thinkingMillsec => $composableBuilder(
    column: $table.thinkingMillsec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get fileJson =>
      $composableBuilder(column: $table.fileJson, builder: (column) => column);

  GeneratedColumn<String> get toolJson =>
      $composableBuilder(column: $table.toolJson, builder: (column) => column);

  GeneratedColumn<String> get errorJson =>
      $composableBuilder(column: $table.errorJson, builder: (column) => column);

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get knowledgeJson => $composableBuilder(
    column: $table.knowledgeJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TopicsTableAnnotationComposer get topicId {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageBlocksTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $MessageBlocksTable,
          MessageBlock,
          $$MessageBlocksTableFilterComposer,
          $$MessageBlocksTableOrderingComposer,
          $$MessageBlocksTableAnnotationComposer,
          $$MessageBlocksTableCreateCompanionBuilder,
          $$MessageBlocksTableUpdateCompanionBuilder,
          (MessageBlock, $$MessageBlocksTableReferences),
          MessageBlock,
          PrefetchHooks Function({bool topicId, bool messageId})
        > {
  $$MessageBlocksTableTableManager(
    _$ImportDatabase db,
    $MessageBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> blockId = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<double?> thinkingMillsec = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> fileJson = const Value.absent(),
                Value<String?> toolJson = const Value.absent(),
                Value<String?> errorJson = const Value.absent(),
                Value<String?> targetLanguage = const Value.absent(),
                Value<String?> responseJson = const Value.absent(),
                Value<String?> knowledgeJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageBlocksCompanion(
                blockId: blockId,
                topicId: topicId,
                messageId: messageId,
                orderIndex: orderIndex,
                type: type,
                content: content,
                thinkingMillsec: thinkingMillsec,
                url: url,
                fileJson: fileJson,
                toolJson: toolJson,
                errorJson: errorJson,
                targetLanguage: targetLanguage,
                responseJson: responseJson,
                knowledgeJson: knowledgeJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String blockId,
                required String topicId,
                required String messageId,
                required int orderIndex,
                required String type,
                Value<String?> content = const Value.absent(),
                Value<double?> thinkingMillsec = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> fileJson = const Value.absent(),
                Value<String?> toolJson = const Value.absent(),
                Value<String?> errorJson = const Value.absent(),
                Value<String?> targetLanguage = const Value.absent(),
                Value<String?> responseJson = const Value.absent(),
                Value<String?> knowledgeJson = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessageBlocksCompanion.insert(
                blockId: blockId,
                topicId: topicId,
                messageId: messageId,
                orderIndex: orderIndex,
                type: type,
                content: content,
                thinkingMillsec: thinkingMillsec,
                url: url,
                fileJson: fileJson,
                toolJson: toolJson,
                errorJson: errorJson,
                targetLanguage: targetLanguage,
                responseJson: responseJson,
                knowledgeJson: knowledgeJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessageBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({topicId = false, messageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (topicId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.topicId,
                                referencedTable: $$MessageBlocksTableReferences
                                    ._topicIdTable(db),
                                referencedColumn: $$MessageBlocksTableReferences
                                    ._topicIdTable(db)
                                    .topicId,
                              )
                              as T;
                    }
                    if (messageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.messageId,
                                referencedTable: $$MessageBlocksTableReferences
                                    ._messageIdTable(db),
                                referencedColumn: $$MessageBlocksTableReferences
                                    ._messageIdTable(db)
                                    .messageId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessageBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $MessageBlocksTable,
      MessageBlock,
      $$MessageBlocksTableFilterComposer,
      $$MessageBlocksTableOrderingComposer,
      $$MessageBlocksTableAnnotationComposer,
      $$MessageBlocksTableCreateCompanionBuilder,
      $$MessageBlocksTableUpdateCompanionBuilder,
      (MessageBlock, $$MessageBlocksTableReferences),
      MessageBlock,
      PrefetchHooks Function({bool topicId, bool messageId})
    >;
typedef $$FilesTableCreateCompanionBuilder =
    FilesCompanion Function({
      required String fileId,
      Value<String?> fileName,
      Value<String?> localPath,
      Value<int?> fileSize,
      Value<String?> mimeType,
      Value<String?> sha256,
      Value<int> referenceCount,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$FilesTableUpdateCompanionBuilder =
    FilesCompanion Function({
      Value<String> fileId,
      Value<String?> fileName,
      Value<String?> localPath,
      Value<int?> fileSize,
      Value<String?> mimeType,
      Value<String?> sha256,
      Value<int> referenceCount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$FilesTableFilterComposer
    extends Composer<_$ImportDatabase, $FilesTable> {
  $$FilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceCount => $composableBuilder(
    column: $table.referenceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilesTableOrderingComposer
    extends Composer<_$ImportDatabase, $FilesTable> {
  $$FilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceCount => $composableBuilder(
    column: $table.referenceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilesTableAnnotationComposer
    extends Composer<_$ImportDatabase, $FilesTable> {
  $$FilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get referenceCount => $composableBuilder(
    column: $table.referenceCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FilesTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $FilesTable,
          File,
          $$FilesTableFilterComposer,
          $$FilesTableOrderingComposer,
          $$FilesTableAnnotationComposer,
          $$FilesTableCreateCompanionBuilder,
          $$FilesTableUpdateCompanionBuilder,
          (File, BaseReferences<_$ImportDatabase, $FilesTable, File>),
          File,
          PrefetchHooks Function()
        > {
  $$FilesTableTableManager(_$ImportDatabase db, $FilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<int> referenceCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilesCompanion(
                fileId: fileId,
                fileName: fileName,
                localPath: localPath,
                fileSize: fileSize,
                mimeType: mimeType,
                sha256: sha256,
                referenceCount: referenceCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                Value<String?> fileName = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<int> referenceCount = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FilesCompanion.insert(
                fileId: fileId,
                fileName: fileName,
                localPath: localPath,
                fileSize: fileSize,
                mimeType: mimeType,
                sha256: sha256,
                referenceCount: referenceCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $FilesTable,
      File,
      $$FilesTableFilterComposer,
      $$FilesTableOrderingComposer,
      $$FilesTableAnnotationComposer,
      $$FilesTableCreateCompanionBuilder,
      $$FilesTableUpdateCompanionBuilder,
      (File, BaseReferences<_$ImportDatabase, $FilesTable, File>),
      File,
      PrefetchHooks Function()
    >;
typedef $$ImportArtifactsTableCreateCompanionBuilder =
    ImportArtifactsCompanion Function({
      required String artifactId,
      required String sourceType,
      Value<String?> fileName,
      Value<String?> sourcePath,
      Value<int?> fileSize,
      Value<String?> sha256,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ImportArtifactsTableUpdateCompanionBuilder =
    ImportArtifactsCompanion Function({
      Value<String> artifactId,
      Value<String> sourceType,
      Value<String?> fileName,
      Value<String?> sourcePath,
      Value<int?> fileSize,
      Value<String?> sha256,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$ImportArtifactsTableReferences
    extends
        BaseReferences<
          _$ImportDatabase,
          $ImportArtifactsTable,
          ImportArtifact
        > {
  $$ImportArtifactsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ImportJobsTable, List<ImportJob>>
  _importJobsRefsTable(_$ImportDatabase db) => MultiTypedResultKey.fromTable(
    db.importJobs,
    aliasName: $_aliasNameGenerator(
      db.importArtifacts.artifactId,
      db.importJobs.artifactId,
    ),
  );

  $$ImportJobsTableProcessedTableManager get importJobsRefs {
    final manager = $$ImportJobsTableTableManager($_db, $_db.importJobs).filter(
      (f) => f.artifactId.artifactId.sqlEquals(
        $_itemColumn<String>('artifact_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_importJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ImportArtifactsTableFilterComposer
    extends Composer<_$ImportDatabase, $ImportArtifactsTable> {
  $$ImportArtifactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get artifactId => $composableBuilder(
    column: $table.artifactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> importJobsRefs(
    Expression<bool> Function($$ImportJobsTableFilterComposer f) f,
  ) {
    final $$ImportJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactId,
      referencedTable: $db.importJobs,
      getReferencedColumn: (t) => t.artifactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportJobsTableFilterComposer(
            $db: $db,
            $table: $db.importJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImportArtifactsTableOrderingComposer
    extends Composer<_$ImportDatabase, $ImportArtifactsTable> {
  $$ImportArtifactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get artifactId => $composableBuilder(
    column: $table.artifactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportArtifactsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $ImportArtifactsTable> {
  $$ImportArtifactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get artifactId => $composableBuilder(
    column: $table.artifactId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> importJobsRefs<T extends Object>(
    Expression<T> Function($$ImportJobsTableAnnotationComposer a) f,
  ) {
    final $$ImportJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactId,
      referencedTable: $db.importJobs,
      getReferencedColumn: (t) => t.artifactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.importJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImportArtifactsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $ImportArtifactsTable,
          ImportArtifact,
          $$ImportArtifactsTableFilterComposer,
          $$ImportArtifactsTableOrderingComposer,
          $$ImportArtifactsTableAnnotationComposer,
          $$ImportArtifactsTableCreateCompanionBuilder,
          $$ImportArtifactsTableUpdateCompanionBuilder,
          (ImportArtifact, $$ImportArtifactsTableReferences),
          ImportArtifact,
          PrefetchHooks Function({bool importJobsRefs})
        > {
  $$ImportArtifactsTableTableManager(
    _$ImportDatabase db,
    $ImportArtifactsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportArtifactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportArtifactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportArtifactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> artifactId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> sourcePath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportArtifactsCompanion(
                artifactId: artifactId,
                sourceType: sourceType,
                fileName: fileName,
                sourcePath: sourcePath,
                fileSize: fileSize,
                sha256: sha256,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String artifactId,
                required String sourceType,
                Value<String?> fileName = const Value.absent(),
                Value<String?> sourcePath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportArtifactsCompanion.insert(
                artifactId: artifactId,
                sourceType: sourceType,
                fileName: fileName,
                sourcePath: sourcePath,
                fileSize: fileSize,
                sha256: sha256,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportArtifactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({importJobsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (importJobsRefs) db.importJobs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (importJobsRefs)
                    await $_getPrefetchedData<
                      ImportArtifact,
                      $ImportArtifactsTable,
                      ImportJob
                    >(
                      currentTable: table,
                      referencedTable: $$ImportArtifactsTableReferences
                          ._importJobsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ImportArtifactsTableReferences(
                            db,
                            table,
                            p0,
                          ).importJobsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.artifactId == item.artifactId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ImportArtifactsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $ImportArtifactsTable,
      ImportArtifact,
      $$ImportArtifactsTableFilterComposer,
      $$ImportArtifactsTableOrderingComposer,
      $$ImportArtifactsTableAnnotationComposer,
      $$ImportArtifactsTableCreateCompanionBuilder,
      $$ImportArtifactsTableUpdateCompanionBuilder,
      (ImportArtifact, $$ImportArtifactsTableReferences),
      ImportArtifact,
      PrefetchHooks Function({bool importJobsRefs})
    >;
typedef $$ImportJobsTableCreateCompanionBuilder =
    ImportJobsCompanion Function({
      required String jobId,
      required String artifactId,
      required String sourceType,
      required String status,
      required int startedAt,
      Value<int?> finishedAt,
      Value<String?> statsJson,
      Value<String?> error,
      Value<int> rowid,
    });
typedef $$ImportJobsTableUpdateCompanionBuilder =
    ImportJobsCompanion Function({
      Value<String> jobId,
      Value<String> artifactId,
      Value<String> sourceType,
      Value<String> status,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<String?> statsJson,
      Value<String?> error,
      Value<int> rowid,
    });

final class $$ImportJobsTableReferences
    extends BaseReferences<_$ImportDatabase, $ImportJobsTable, ImportJob> {
  $$ImportJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImportArtifactsTable _artifactIdTable(_$ImportDatabase db) =>
      db.importArtifacts.createAlias(
        $_aliasNameGenerator(
          db.importJobs.artifactId,
          db.importArtifacts.artifactId,
        ),
      );

  $$ImportArtifactsTableProcessedTableManager get artifactId {
    final $_column = $_itemColumn<String>('artifact_id')!;

    final manager = $$ImportArtifactsTableTableManager(
      $_db,
      $_db.importArtifacts,
    ).filter((f) => f.artifactId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artifactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImportJobsTableFilterComposer
    extends Composer<_$ImportDatabase, $ImportJobsTable> {
  $$ImportJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  $$ImportArtifactsTableFilterComposer get artifactId {
    final $$ImportArtifactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactId,
      referencedTable: $db.importArtifacts,
      getReferencedColumn: (t) => t.artifactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportArtifactsTableFilterComposer(
            $db: $db,
            $table: $db.importArtifacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportJobsTableOrderingComposer
    extends Composer<_$ImportDatabase, $ImportJobsTable> {
  $$ImportJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImportArtifactsTableOrderingComposer get artifactId {
    final $$ImportArtifactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactId,
      referencedTable: $db.importArtifacts,
      getReferencedColumn: (t) => t.artifactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportArtifactsTableOrderingComposer(
            $db: $db,
            $table: $db.importArtifacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportJobsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $ImportJobsTable> {
  $$ImportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  $$ImportArtifactsTableAnnotationComposer get artifactId {
    final $$ImportArtifactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artifactId,
      referencedTable: $db.importArtifacts,
      getReferencedColumn: (t) => t.artifactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportArtifactsTableAnnotationComposer(
            $db: $db,
            $table: $db.importArtifacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportJobsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $ImportJobsTable,
          ImportJob,
          $$ImportJobsTableFilterComposer,
          $$ImportJobsTableOrderingComposer,
          $$ImportJobsTableAnnotationComposer,
          $$ImportJobsTableCreateCompanionBuilder,
          $$ImportJobsTableUpdateCompanionBuilder,
          (ImportJob, $$ImportJobsTableReferences),
          ImportJob,
          PrefetchHooks Function({bool artifactId})
        > {
  $$ImportJobsTableTableManager(_$ImportDatabase db, $ImportJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> jobId = const Value.absent(),
                Value<String> artifactId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<String?> statsJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion(
                jobId: jobId,
                artifactId: artifactId,
                sourceType: sourceType,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                statsJson: statsJson,
                error: error,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String jobId,
                required String artifactId,
                required String sourceType,
                required String status,
                required int startedAt,
                Value<int?> finishedAt = const Value.absent(),
                Value<String?> statsJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion.insert(
                jobId: jobId,
                artifactId: artifactId,
                sourceType: sourceType,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                statsJson: statsJson,
                error: error,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({artifactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (artifactId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.artifactId,
                                referencedTable: $$ImportJobsTableReferences
                                    ._artifactIdTable(db),
                                referencedColumn: $$ImportJobsTableReferences
                                    ._artifactIdTable(db)
                                    .artifactId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $ImportJobsTable,
      ImportJob,
      $$ImportJobsTableFilterComposer,
      $$ImportJobsTableOrderingComposer,
      $$ImportJobsTableAnnotationComposer,
      $$ImportJobsTableCreateCompanionBuilder,
      $$ImportJobsTableUpdateCompanionBuilder,
      (ImportJob, $$ImportJobsTableReferences),
      ImportJob,
      PrefetchHooks Function({bool artifactId})
    >;
typedef $$ProvenanceRecordsTableCreateCompanionBuilder =
    ProvenanceRecordsCompanion Function({
      required String sourceType,
      required String entityType,
      required String externalId,
      required String entityId,
      Value<String?> parentExternalId,
      Value<String?> fingerprint,
      required int firstSeenAt,
      required int lastSeenAt,
      Value<int> rowid,
    });
typedef $$ProvenanceRecordsTableUpdateCompanionBuilder =
    ProvenanceRecordsCompanion Function({
      Value<String> sourceType,
      Value<String> entityType,
      Value<String> externalId,
      Value<String> entityId,
      Value<String?> parentExternalId,
      Value<String?> fingerprint,
      Value<int> firstSeenAt,
      Value<int> lastSeenAt,
      Value<int> rowid,
    });

class $$ProvenanceRecordsTableFilterComposer
    extends Composer<_$ImportDatabase, $ProvenanceRecordsTable> {
  $$ProvenanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentExternalId => $composableBuilder(
    column: $table.parentExternalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProvenanceRecordsTableOrderingComposer
    extends Composer<_$ImportDatabase, $ProvenanceRecordsTable> {
  $$ProvenanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentExternalId => $composableBuilder(
    column: $table.parentExternalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProvenanceRecordsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $ProvenanceRecordsTable> {
  $$ProvenanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get parentExternalId => $composableBuilder(
    column: $table.parentExternalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );
}

class $$ProvenanceRecordsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $ProvenanceRecordsTable,
          ProvenanceRecord,
          $$ProvenanceRecordsTableFilterComposer,
          $$ProvenanceRecordsTableOrderingComposer,
          $$ProvenanceRecordsTableAnnotationComposer,
          $$ProvenanceRecordsTableCreateCompanionBuilder,
          $$ProvenanceRecordsTableUpdateCompanionBuilder,
          (
            ProvenanceRecord,
            BaseReferences<
              _$ImportDatabase,
              $ProvenanceRecordsTable,
              ProvenanceRecord
            >,
          ),
          ProvenanceRecord,
          PrefetchHooks Function()
        > {
  $$ProvenanceRecordsTableTableManager(
    _$ImportDatabase db,
    $ProvenanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProvenanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProvenanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProvenanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sourceType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> parentExternalId = const Value.absent(),
                Value<String?> fingerprint = const Value.absent(),
                Value<int> firstSeenAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProvenanceRecordsCompanion(
                sourceType: sourceType,
                entityType: entityType,
                externalId: externalId,
                entityId: entityId,
                parentExternalId: parentExternalId,
                fingerprint: fingerprint,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceType,
                required String entityType,
                required String externalId,
                required String entityId,
                Value<String?> parentExternalId = const Value.absent(),
                Value<String?> fingerprint = const Value.absent(),
                required int firstSeenAt,
                required int lastSeenAt,
                Value<int> rowid = const Value.absent(),
              }) => ProvenanceRecordsCompanion.insert(
                sourceType: sourceType,
                entityType: entityType,
                externalId: externalId,
                entityId: entityId,
                parentExternalId: parentExternalId,
                fingerprint: fingerprint,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProvenanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $ProvenanceRecordsTable,
      ProvenanceRecord,
      $$ProvenanceRecordsTableFilterComposer,
      $$ProvenanceRecordsTableOrderingComposer,
      $$ProvenanceRecordsTableAnnotationComposer,
      $$ProvenanceRecordsTableCreateCompanionBuilder,
      $$ProvenanceRecordsTableUpdateCompanionBuilder,
      (
        ProvenanceRecord,
        BaseReferences<
          _$ImportDatabase,
          $ProvenanceRecordsTable,
          ProvenanceRecord
        >,
      ),
      ProvenanceRecord,
      PrefetchHooks Function()
    >;
typedef $$TopicEmbeddingsTableCreateCompanionBuilder =
    TopicEmbeddingsCompanion Function({
      required String topicId,
      required String firstQueryText,
      required String embeddingJson,
      required String modelName,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$TopicEmbeddingsTableUpdateCompanionBuilder =
    TopicEmbeddingsCompanion Function({
      Value<String> topicId,
      Value<String> firstQueryText,
      Value<String> embeddingJson,
      Value<String> modelName,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$TopicEmbeddingsTableFilterComposer
    extends Composer<_$ImportDatabase, $TopicEmbeddingsTable> {
  $$TopicEmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstQueryText => $composableBuilder(
    column: $table.firstQueryText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingJson => $composableBuilder(
    column: $table.embeddingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicEmbeddingsTableOrderingComposer
    extends Composer<_$ImportDatabase, $TopicEmbeddingsTable> {
  $$TopicEmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstQueryText => $composableBuilder(
    column: $table.firstQueryText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingJson => $composableBuilder(
    column: $table.embeddingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicEmbeddingsTableAnnotationComposer
    extends Composer<_$ImportDatabase, $TopicEmbeddingsTable> {
  $$TopicEmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get firstQueryText => $composableBuilder(
    column: $table.firstQueryText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get embeddingJson => $composableBuilder(
    column: $table.embeddingJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TopicEmbeddingsTableTableManager
    extends
        RootTableManager<
          _$ImportDatabase,
          $TopicEmbeddingsTable,
          TopicEmbedding,
          $$TopicEmbeddingsTableFilterComposer,
          $$TopicEmbeddingsTableOrderingComposer,
          $$TopicEmbeddingsTableAnnotationComposer,
          $$TopicEmbeddingsTableCreateCompanionBuilder,
          $$TopicEmbeddingsTableUpdateCompanionBuilder,
          (
            TopicEmbedding,
            BaseReferences<
              _$ImportDatabase,
              $TopicEmbeddingsTable,
              TopicEmbedding
            >,
          ),
          TopicEmbedding,
          PrefetchHooks Function()
        > {
  $$TopicEmbeddingsTableTableManager(
    _$ImportDatabase db,
    $TopicEmbeddingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicEmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicEmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicEmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topicId = const Value.absent(),
                Value<String> firstQueryText = const Value.absent(),
                Value<String> embeddingJson = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicEmbeddingsCompanion(
                topicId: topicId,
                firstQueryText: firstQueryText,
                embeddingJson: embeddingJson,
                modelName: modelName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topicId,
                required String firstQueryText,
                required String embeddingJson,
                required String modelName,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TopicEmbeddingsCompanion.insert(
                topicId: topicId,
                firstQueryText: firstQueryText,
                embeddingJson: embeddingJson,
                modelName: modelName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicEmbeddingsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportDatabase,
      $TopicEmbeddingsTable,
      TopicEmbedding,
      $$TopicEmbeddingsTableFilterComposer,
      $$TopicEmbeddingsTableOrderingComposer,
      $$TopicEmbeddingsTableAnnotationComposer,
      $$TopicEmbeddingsTableCreateCompanionBuilder,
      $$TopicEmbeddingsTableUpdateCompanionBuilder,
      (
        TopicEmbedding,
        BaseReferences<_$ImportDatabase, $TopicEmbeddingsTable, TopicEmbedding>,
      ),
      TopicEmbedding,
      PrefetchHooks Function()
    >;

class $ImportDatabaseManager {
  final _$ImportDatabase _db;
  $ImportDatabaseManager(this._db);
  $$AssistantsTableTableManager get assistants =>
      $$AssistantsTableTableManager(_db, _db.assistants);
  $$TopicsTableTableManager get topics =>
      $$TopicsTableTableManager(_db, _db.topics);
  $$TopicAssistantsTableTableManager get topicAssistants =>
      $$TopicAssistantsTableTableManager(_db, _db.topicAssistants);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageBlocksTableTableManager get messageBlocks =>
      $$MessageBlocksTableTableManager(_db, _db.messageBlocks);
  $$FilesTableTableManager get files =>
      $$FilesTableTableManager(_db, _db.files);
  $$ImportArtifactsTableTableManager get importArtifacts =>
      $$ImportArtifactsTableTableManager(_db, _db.importArtifacts);
  $$ImportJobsTableTableManager get importJobs =>
      $$ImportJobsTableTableManager(_db, _db.importJobs);
  $$ProvenanceRecordsTableTableManager get provenanceRecords =>
      $$ProvenanceRecordsTableTableManager(_db, _db.provenanceRecords);
  $$TopicEmbeddingsTableTableManager get topicEmbeddings =>
      $$TopicEmbeddingsTableTableManager(_db, _db.topicEmbeddings);
}

class $AiAnalysesTable extends AiAnalyses
    with TableInfo<$AiAnalysesTable, AiAnalyse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiAnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIndexMeta = const VerificationMeta(
    'groupIndex',
  );
  @override
  late final GeneratedColumn<int> groupIndex = GeneratedColumn<int>(
    'group_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    topicId,
    groupIndex,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiAnalyse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('group_index')) {
      context.handle(
        _groupIndexMeta,
        groupIndex.isAcceptableOrUnknown(data['group_index']!, _groupIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIndexMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topicId, groupIndex, createdAt};
  @override
  AiAnalyse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiAnalyse(
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      groupIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_index'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AiAnalysesTable createAlias(String alias) {
    return $AiAnalysesTable(attachedDatabase, alias);
  }
}

class AiAnalyse extends DataClass implements Insertable<AiAnalyse> {
  final String topicId;
  final int groupIndex;
  final String content;
  final int createdAt;
  const AiAnalyse({
    required this.topicId,
    required this.groupIndex,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic_id'] = Variable<String>(topicId);
    map['group_index'] = Variable<int>(groupIndex);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AiAnalysesCompanion toCompanion(bool nullToAbsent) {
    return AiAnalysesCompanion(
      topicId: Value(topicId),
      groupIndex: Value(groupIndex),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory AiAnalyse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiAnalyse(
      topicId: serializer.fromJson<String>(json['topicId']),
      groupIndex: serializer.fromJson<int>(json['groupIndex']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topicId': serializer.toJson<String>(topicId),
      'groupIndex': serializer.toJson<int>(groupIndex),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AiAnalyse copyWith({
    String? topicId,
    int? groupIndex,
    String? content,
    int? createdAt,
  }) => AiAnalyse(
    topicId: topicId ?? this.topicId,
    groupIndex: groupIndex ?? this.groupIndex,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  AiAnalyse copyWithCompanion(AiAnalysesCompanion data) {
    return AiAnalyse(
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      groupIndex: data.groupIndex.present
          ? data.groupIndex.value
          : this.groupIndex,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiAnalyse(')
          ..write('topicId: $topicId, ')
          ..write('groupIndex: $groupIndex, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(topicId, groupIndex, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiAnalyse &&
          other.topicId == this.topicId &&
          other.groupIndex == this.groupIndex &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AiAnalysesCompanion extends UpdateCompanion<AiAnalyse> {
  final Value<String> topicId;
  final Value<int> groupIndex;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AiAnalysesCompanion({
    this.topicId = const Value.absent(),
    this.groupIndex = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiAnalysesCompanion.insert({
    required String topicId,
    required int groupIndex,
    required String content,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : topicId = Value(topicId),
       groupIndex = Value(groupIndex),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<AiAnalyse> custom({
    Expression<String>? topicId,
    Expression<int>? groupIndex,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topicId != null) 'topic_id': topicId,
      if (groupIndex != null) 'group_index': groupIndex,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiAnalysesCompanion copyWith({
    Value<String>? topicId,
    Value<int>? groupIndex,
    Value<String>? content,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AiAnalysesCompanion(
      topicId: topicId ?? this.topicId,
      groupIndex: groupIndex ?? this.groupIndex,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (groupIndex.present) {
      map['group_index'] = Variable<int>(groupIndex.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiAnalysesCompanion(')
          ..write('topicId: $topicId, ')
          ..write('groupIndex: $groupIndex, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeEntriesTable extends KnowledgeEntries
    with TableInfo<$KnowledgeEntriesTable, KnowledgeEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('plain'),
  );
  static const VerificationMeta _plainTextMeta = const VerificationMeta(
    'plainText',
  );
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
    'plain_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotedTextMeta = const VerificationMeta(
    'quotedText',
  );
  @override
  late final GeneratedColumn<String> quotedText = GeneratedColumn<String>(
    'quoted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _styleTypeMeta = const VerificationMeta(
    'styleType',
  );
  @override
  late final GeneratedColumn<String> styleType = GeneratedColumn<String>(
    'style_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicNameMeta = const VerificationMeta(
    'topicName',
  );
  @override
  late final GeneratedColumn<String> topicName = GeneratedColumn<String>(
    'topic_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefixMeta = const VerificationMeta('prefix');
  @override
  late final GeneratedColumn<String> prefix = GeneratedColumn<String>(
    'prefix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suffixMeta = const VerificationMeta('suffix');
  @override
  late final GeneratedColumn<String> suffix = GeneratedColumn<String>(
    'suffix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
    'start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
    'end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockIndexMeta = const VerificationMeta(
    'blockIndex',
  );
  @override
  late final GeneratedColumn<int> blockIndex = GeneratedColumn<int>(
    'block_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockContentHashMeta = const VerificationMeta(
    'blockContentHash',
  );
  @override
  late final GeneratedColumn<String> blockContentHash = GeneratedColumn<String>(
    'block_content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockInternalStartMeta =
      const VerificationMeta('blockInternalStart');
  @override
  late final GeneratedColumn<int> blockInternalStart = GeneratedColumn<int>(
    'block_internal_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockInternalEndMeta = const VerificationMeta(
    'blockInternalEnd',
  );
  @override
  late final GeneratedColumn<int> blockInternalEnd = GeneratedColumn<int>(
    'block_internal_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectionsMeta = const VerificationMeta(
    'selections',
  );
  @override
  late final GeneratedColumn<String> selections = GeneratedColumn<String>(
    'selections',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<int> lastReviewedAt = GeneratedColumn<int>(
    'last_reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importanceMeta = const VerificationMeta(
    'importance',
  );
  @override
  late final GeneratedColumn<int> importance = GeneratedColumn<int>(
    'importance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    content,
    contentType,
    plainText,
    quotedText,
    color,
    styleType,
    messageId,
    topicId,
    topicName,
    prefix,
    suffix,
    start,
    end,
    tagsJson,
    createdAt,
    updatedAt,
    blockIndex,
    blockContentHash,
    blockInternalStart,
    blockInternalEnd,
    groupId,
    selections,
    reviewCount,
    lastReviewedAt,
    importance,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnowledgeEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('plain_text')) {
      context.handle(
        _plainTextMeta,
        plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta),
      );
    }
    if (data.containsKey('quoted_text')) {
      context.handle(
        _quotedTextMeta,
        quotedText.isAcceptableOrUnknown(data['quoted_text']!, _quotedTextMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('style_type')) {
      context.handle(
        _styleTypeMeta,
        styleType.isAcceptableOrUnknown(data['style_type']!, _styleTypeMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('topic_name')) {
      context.handle(
        _topicNameMeta,
        topicName.isAcceptableOrUnknown(data['topic_name']!, _topicNameMeta),
      );
    }
    if (data.containsKey('prefix')) {
      context.handle(
        _prefixMeta,
        prefix.isAcceptableOrUnknown(data['prefix']!, _prefixMeta),
      );
    }
    if (data.containsKey('suffix')) {
      context.handle(
        _suffixMeta,
        suffix.isAcceptableOrUnknown(data['suffix']!, _suffixMeta),
      );
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('block_index')) {
      context.handle(
        _blockIndexMeta,
        blockIndex.isAcceptableOrUnknown(data['block_index']!, _blockIndexMeta),
      );
    }
    if (data.containsKey('block_content_hash')) {
      context.handle(
        _blockContentHashMeta,
        blockContentHash.isAcceptableOrUnknown(
          data['block_content_hash']!,
          _blockContentHashMeta,
        ),
      );
    }
    if (data.containsKey('block_internal_start')) {
      context.handle(
        _blockInternalStartMeta,
        blockInternalStart.isAcceptableOrUnknown(
          data['block_internal_start']!,
          _blockInternalStartMeta,
        ),
      );
    }
    if (data.containsKey('block_internal_end')) {
      context.handle(
        _blockInternalEndMeta,
        blockInternalEnd.isAcceptableOrUnknown(
          data['block_internal_end']!,
          _blockInternalEndMeta,
        ),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('selections')) {
      context.handle(
        _selectionsMeta,
        selections.isAcceptableOrUnknown(data['selections']!, _selectionsMeta),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('importance')) {
      context.handle(
        _importanceMeta,
        importance.isAcceptableOrUnknown(data['importance']!, _importanceMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  KnowledgeEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeEntryRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      plainText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plain_text'],
      ),
      quotedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quoted_text'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      styleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_type'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      ),
      topicName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_name'],
      ),
      prefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefix'],
      ),
      suffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suffix'],
      ),
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start'],
      ),
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      blockIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_index'],
      ),
      blockContentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_content_hash'],
      ),
      blockInternalStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_internal_start'],
      ),
      blockInternalEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_internal_end'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      selections: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selections'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      importance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importance'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $KnowledgeEntriesTable createAlias(String alias) {
    return $KnowledgeEntriesTable(attachedDatabase, alias);
  }
}

class KnowledgeEntryRow extends DataClass
    implements Insertable<KnowledgeEntryRow> {
  final String entryId;
  final String? content;
  final String contentType;
  final String? plainText;
  final String? quotedText;
  final int? color;
  final String? styleType;
  final String? messageId;
  final String? topicId;
  final String? topicName;
  final String? prefix;
  final String? suffix;
  final int? start;
  final int? end;
  final String tagsJson;
  final int createdAt;
  final int updatedAt;
  final int? blockIndex;
  final String? blockContentHash;
  final int? blockInternalStart;
  final int? blockInternalEnd;
  final String? groupId;
  final String? selections;
  final int reviewCount;
  final int? lastReviewedAt;
  final int importance;
  final bool isPinned;
  const KnowledgeEntryRow({
    required this.entryId,
    this.content,
    required this.contentType,
    this.plainText,
    this.quotedText,
    this.color,
    this.styleType,
    this.messageId,
    this.topicId,
    this.topicName,
    this.prefix,
    this.suffix,
    this.start,
    this.end,
    required this.tagsJson,
    required this.createdAt,
    required this.updatedAt,
    this.blockIndex,
    this.blockContentHash,
    this.blockInternalStart,
    this.blockInternalEnd,
    this.groupId,
    this.selections,
    required this.reviewCount,
    this.lastReviewedAt,
    required this.importance,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || plainText != null) {
      map['plain_text'] = Variable<String>(plainText);
    }
    if (!nullToAbsent || quotedText != null) {
      map['quoted_text'] = Variable<String>(quotedText);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || styleType != null) {
      map['style_type'] = Variable<String>(styleType);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    if (!nullToAbsent || topicName != null) {
      map['topic_name'] = Variable<String>(topicName);
    }
    if (!nullToAbsent || prefix != null) {
      map['prefix'] = Variable<String>(prefix);
    }
    if (!nullToAbsent || suffix != null) {
      map['suffix'] = Variable<String>(suffix);
    }
    if (!nullToAbsent || start != null) {
      map['start'] = Variable<int>(start);
    }
    if (!nullToAbsent || end != null) {
      map['end'] = Variable<int>(end);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || blockIndex != null) {
      map['block_index'] = Variable<int>(blockIndex);
    }
    if (!nullToAbsent || blockContentHash != null) {
      map['block_content_hash'] = Variable<String>(blockContentHash);
    }
    if (!nullToAbsent || blockInternalStart != null) {
      map['block_internal_start'] = Variable<int>(blockInternalStart);
    }
    if (!nullToAbsent || blockInternalEnd != null) {
      map['block_internal_end'] = Variable<int>(blockInternalEnd);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || selections != null) {
      map['selections'] = Variable<String>(selections);
    }
    map['review_count'] = Variable<int>(reviewCount);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt);
    }
    map['importance'] = Variable<int>(importance);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  KnowledgeEntriesCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeEntriesCompanion(
      entryId: Value(entryId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      contentType: Value(contentType),
      plainText: plainText == null && nullToAbsent
          ? const Value.absent()
          : Value(plainText),
      quotedText: quotedText == null && nullToAbsent
          ? const Value.absent()
          : Value(quotedText),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      styleType: styleType == null && nullToAbsent
          ? const Value.absent()
          : Value(styleType),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      topicName: topicName == null && nullToAbsent
          ? const Value.absent()
          : Value(topicName),
      prefix: prefix == null && nullToAbsent
          ? const Value.absent()
          : Value(prefix),
      suffix: suffix == null && nullToAbsent
          ? const Value.absent()
          : Value(suffix),
      start: start == null && nullToAbsent
          ? const Value.absent()
          : Value(start),
      end: end == null && nullToAbsent ? const Value.absent() : Value(end),
      tagsJson: Value(tagsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      blockIndex: blockIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(blockIndex),
      blockContentHash: blockContentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(blockContentHash),
      blockInternalStart: blockInternalStart == null && nullToAbsent
          ? const Value.absent()
          : Value(blockInternalStart),
      blockInternalEnd: blockInternalEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(blockInternalEnd),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      selections: selections == null && nullToAbsent
          ? const Value.absent()
          : Value(selections),
      reviewCount: Value(reviewCount),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      importance: Value(importance),
      isPinned: Value(isPinned),
    );
  }

  factory KnowledgeEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeEntryRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      content: serializer.fromJson<String?>(json['content']),
      contentType: serializer.fromJson<String>(json['contentType']),
      plainText: serializer.fromJson<String?>(json['plainText']),
      quotedText: serializer.fromJson<String?>(json['quotedText']),
      color: serializer.fromJson<int?>(json['color']),
      styleType: serializer.fromJson<String?>(json['styleType']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      topicName: serializer.fromJson<String?>(json['topicName']),
      prefix: serializer.fromJson<String?>(json['prefix']),
      suffix: serializer.fromJson<String?>(json['suffix']),
      start: serializer.fromJson<int?>(json['start']),
      end: serializer.fromJson<int?>(json['end']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      blockIndex: serializer.fromJson<int?>(json['blockIndex']),
      blockContentHash: serializer.fromJson<String?>(json['blockContentHash']),
      blockInternalStart: serializer.fromJson<int?>(json['blockInternalStart']),
      blockInternalEnd: serializer.fromJson<int?>(json['blockInternalEnd']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      selections: serializer.fromJson<String?>(json['selections']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      lastReviewedAt: serializer.fromJson<int?>(json['lastReviewedAt']),
      importance: serializer.fromJson<int>(json['importance']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'content': serializer.toJson<String?>(content),
      'contentType': serializer.toJson<String>(contentType),
      'plainText': serializer.toJson<String?>(plainText),
      'quotedText': serializer.toJson<String?>(quotedText),
      'color': serializer.toJson<int?>(color),
      'styleType': serializer.toJson<String?>(styleType),
      'messageId': serializer.toJson<String?>(messageId),
      'topicId': serializer.toJson<String?>(topicId),
      'topicName': serializer.toJson<String?>(topicName),
      'prefix': serializer.toJson<String?>(prefix),
      'suffix': serializer.toJson<String?>(suffix),
      'start': serializer.toJson<int?>(start),
      'end': serializer.toJson<int?>(end),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'blockIndex': serializer.toJson<int?>(blockIndex),
      'blockContentHash': serializer.toJson<String?>(blockContentHash),
      'blockInternalStart': serializer.toJson<int?>(blockInternalStart),
      'blockInternalEnd': serializer.toJson<int?>(blockInternalEnd),
      'groupId': serializer.toJson<String?>(groupId),
      'selections': serializer.toJson<String?>(selections),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'lastReviewedAt': serializer.toJson<int?>(lastReviewedAt),
      'importance': serializer.toJson<int>(importance),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  KnowledgeEntryRow copyWith({
    String? entryId,
    Value<String?> content = const Value.absent(),
    String? contentType,
    Value<String?> plainText = const Value.absent(),
    Value<String?> quotedText = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<String?> styleType = const Value.absent(),
    Value<String?> messageId = const Value.absent(),
    Value<String?> topicId = const Value.absent(),
    Value<String?> topicName = const Value.absent(),
    Value<String?> prefix = const Value.absent(),
    Value<String?> suffix = const Value.absent(),
    Value<int?> start = const Value.absent(),
    Value<int?> end = const Value.absent(),
    String? tagsJson,
    int? createdAt,
    int? updatedAt,
    Value<int?> blockIndex = const Value.absent(),
    Value<String?> blockContentHash = const Value.absent(),
    Value<int?> blockInternalStart = const Value.absent(),
    Value<int?> blockInternalEnd = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<String?> selections = const Value.absent(),
    int? reviewCount,
    Value<int?> lastReviewedAt = const Value.absent(),
    int? importance,
    bool? isPinned,
  }) => KnowledgeEntryRow(
    entryId: entryId ?? this.entryId,
    content: content.present ? content.value : this.content,
    contentType: contentType ?? this.contentType,
    plainText: plainText.present ? plainText.value : this.plainText,
    quotedText: quotedText.present ? quotedText.value : this.quotedText,
    color: color.present ? color.value : this.color,
    styleType: styleType.present ? styleType.value : this.styleType,
    messageId: messageId.present ? messageId.value : this.messageId,
    topicId: topicId.present ? topicId.value : this.topicId,
    topicName: topicName.present ? topicName.value : this.topicName,
    prefix: prefix.present ? prefix.value : this.prefix,
    suffix: suffix.present ? suffix.value : this.suffix,
    start: start.present ? start.value : this.start,
    end: end.present ? end.value : this.end,
    tagsJson: tagsJson ?? this.tagsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    blockIndex: blockIndex.present ? blockIndex.value : this.blockIndex,
    blockContentHash: blockContentHash.present
        ? blockContentHash.value
        : this.blockContentHash,
    blockInternalStart: blockInternalStart.present
        ? blockInternalStart.value
        : this.blockInternalStart,
    blockInternalEnd: blockInternalEnd.present
        ? blockInternalEnd.value
        : this.blockInternalEnd,
    groupId: groupId.present ? groupId.value : this.groupId,
    selections: selections.present ? selections.value : this.selections,
    reviewCount: reviewCount ?? this.reviewCount,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    importance: importance ?? this.importance,
    isPinned: isPinned ?? this.isPinned,
  );
  KnowledgeEntryRow copyWithCompanion(KnowledgeEntriesCompanion data) {
    return KnowledgeEntryRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      content: data.content.present ? data.content.value : this.content,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      quotedText: data.quotedText.present
          ? data.quotedText.value
          : this.quotedText,
      color: data.color.present ? data.color.value : this.color,
      styleType: data.styleType.present ? data.styleType.value : this.styleType,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      topicName: data.topicName.present ? data.topicName.value : this.topicName,
      prefix: data.prefix.present ? data.prefix.value : this.prefix,
      suffix: data.suffix.present ? data.suffix.value : this.suffix,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      blockIndex: data.blockIndex.present
          ? data.blockIndex.value
          : this.blockIndex,
      blockContentHash: data.blockContentHash.present
          ? data.blockContentHash.value
          : this.blockContentHash,
      blockInternalStart: data.blockInternalStart.present
          ? data.blockInternalStart.value
          : this.blockInternalStart,
      blockInternalEnd: data.blockInternalEnd.present
          ? data.blockInternalEnd.value
          : this.blockInternalEnd,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      selections: data.selections.present
          ? data.selections.value
          : this.selections,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      importance: data.importance.present
          ? data.importance.value
          : this.importance,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeEntryRow(')
          ..write('entryId: $entryId, ')
          ..write('content: $content, ')
          ..write('contentType: $contentType, ')
          ..write('plainText: $plainText, ')
          ..write('quotedText: $quotedText, ')
          ..write('color: $color, ')
          ..write('styleType: $styleType, ')
          ..write('messageId: $messageId, ')
          ..write('topicId: $topicId, ')
          ..write('topicName: $topicName, ')
          ..write('prefix: $prefix, ')
          ..write('suffix: $suffix, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('blockIndex: $blockIndex, ')
          ..write('blockContentHash: $blockContentHash, ')
          ..write('blockInternalStart: $blockInternalStart, ')
          ..write('blockInternalEnd: $blockInternalEnd, ')
          ..write('groupId: $groupId, ')
          ..write('selections: $selections, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('importance: $importance, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    entryId,
    content,
    contentType,
    plainText,
    quotedText,
    color,
    styleType,
    messageId,
    topicId,
    topicName,
    prefix,
    suffix,
    start,
    end,
    tagsJson,
    createdAt,
    updatedAt,
    blockIndex,
    blockContentHash,
    blockInternalStart,
    blockInternalEnd,
    groupId,
    selections,
    reviewCount,
    lastReviewedAt,
    importance,
    isPinned,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeEntryRow &&
          other.entryId == this.entryId &&
          other.content == this.content &&
          other.contentType == this.contentType &&
          other.plainText == this.plainText &&
          other.quotedText == this.quotedText &&
          other.color == this.color &&
          other.styleType == this.styleType &&
          other.messageId == this.messageId &&
          other.topicId == this.topicId &&
          other.topicName == this.topicName &&
          other.prefix == this.prefix &&
          other.suffix == this.suffix &&
          other.start == this.start &&
          other.end == this.end &&
          other.tagsJson == this.tagsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.blockIndex == this.blockIndex &&
          other.blockContentHash == this.blockContentHash &&
          other.blockInternalStart == this.blockInternalStart &&
          other.blockInternalEnd == this.blockInternalEnd &&
          other.groupId == this.groupId &&
          other.selections == this.selections &&
          other.reviewCount == this.reviewCount &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.importance == this.importance &&
          other.isPinned == this.isPinned);
}

class KnowledgeEntriesCompanion extends UpdateCompanion<KnowledgeEntryRow> {
  final Value<String> entryId;
  final Value<String?> content;
  final Value<String> contentType;
  final Value<String?> plainText;
  final Value<String?> quotedText;
  final Value<int?> color;
  final Value<String?> styleType;
  final Value<String?> messageId;
  final Value<String?> topicId;
  final Value<String?> topicName;
  final Value<String?> prefix;
  final Value<String?> suffix;
  final Value<int?> start;
  final Value<int?> end;
  final Value<String> tagsJson;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> blockIndex;
  final Value<String?> blockContentHash;
  final Value<int?> blockInternalStart;
  final Value<int?> blockInternalEnd;
  final Value<String?> groupId;
  final Value<String?> selections;
  final Value<int> reviewCount;
  final Value<int?> lastReviewedAt;
  final Value<int> importance;
  final Value<bool> isPinned;
  final Value<int> rowid;
  const KnowledgeEntriesCompanion({
    this.entryId = const Value.absent(),
    this.content = const Value.absent(),
    this.contentType = const Value.absent(),
    this.plainText = const Value.absent(),
    this.quotedText = const Value.absent(),
    this.color = const Value.absent(),
    this.styleType = const Value.absent(),
    this.messageId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.topicName = const Value.absent(),
    this.prefix = const Value.absent(),
    this.suffix = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.blockIndex = const Value.absent(),
    this.blockContentHash = const Value.absent(),
    this.blockInternalStart = const Value.absent(),
    this.blockInternalEnd = const Value.absent(),
    this.groupId = const Value.absent(),
    this.selections = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.importance = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnowledgeEntriesCompanion.insert({
    required String entryId,
    this.content = const Value.absent(),
    this.contentType = const Value.absent(),
    this.plainText = const Value.absent(),
    this.quotedText = const Value.absent(),
    this.color = const Value.absent(),
    this.styleType = const Value.absent(),
    this.messageId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.topicName = const Value.absent(),
    this.prefix = const Value.absent(),
    this.suffix = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.tagsJson = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.blockIndex = const Value.absent(),
    this.blockContentHash = const Value.absent(),
    this.blockInternalStart = const Value.absent(),
    this.blockInternalEnd = const Value.absent(),
    this.groupId = const Value.absent(),
    this.selections = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.importance = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<KnowledgeEntryRow> custom({
    Expression<String>? entryId,
    Expression<String>? content,
    Expression<String>? contentType,
    Expression<String>? plainText,
    Expression<String>? quotedText,
    Expression<int>? color,
    Expression<String>? styleType,
    Expression<String>? messageId,
    Expression<String>? topicId,
    Expression<String>? topicName,
    Expression<String>? prefix,
    Expression<String>? suffix,
    Expression<int>? start,
    Expression<int>? end,
    Expression<String>? tagsJson,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? blockIndex,
    Expression<String>? blockContentHash,
    Expression<int>? blockInternalStart,
    Expression<int>? blockInternalEnd,
    Expression<String>? groupId,
    Expression<String>? selections,
    Expression<int>? reviewCount,
    Expression<int>? lastReviewedAt,
    Expression<int>? importance,
    Expression<bool>? isPinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (content != null) 'content': content,
      if (contentType != null) 'content_type': contentType,
      if (plainText != null) 'plain_text': plainText,
      if (quotedText != null) 'quoted_text': quotedText,
      if (color != null) 'color': color,
      if (styleType != null) 'style_type': styleType,
      if (messageId != null) 'message_id': messageId,
      if (topicId != null) 'topic_id': topicId,
      if (topicName != null) 'topic_name': topicName,
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (blockIndex != null) 'block_index': blockIndex,
      if (blockContentHash != null) 'block_content_hash': blockContentHash,
      if (blockInternalStart != null)
        'block_internal_start': blockInternalStart,
      if (blockInternalEnd != null) 'block_internal_end': blockInternalEnd,
      if (groupId != null) 'group_id': groupId,
      if (selections != null) 'selections': selections,
      if (reviewCount != null) 'review_count': reviewCount,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (importance != null) 'importance': importance,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnowledgeEntriesCompanion copyWith({
    Value<String>? entryId,
    Value<String?>? content,
    Value<String>? contentType,
    Value<String?>? plainText,
    Value<String?>? quotedText,
    Value<int?>? color,
    Value<String?>? styleType,
    Value<String?>? messageId,
    Value<String?>? topicId,
    Value<String?>? topicName,
    Value<String?>? prefix,
    Value<String?>? suffix,
    Value<int?>? start,
    Value<int?>? end,
    Value<String>? tagsJson,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? blockIndex,
    Value<String?>? blockContentHash,
    Value<int?>? blockInternalStart,
    Value<int?>? blockInternalEnd,
    Value<String?>? groupId,
    Value<String?>? selections,
    Value<int>? reviewCount,
    Value<int?>? lastReviewedAt,
    Value<int>? importance,
    Value<bool>? isPinned,
    Value<int>? rowid,
  }) {
    return KnowledgeEntriesCompanion(
      entryId: entryId ?? this.entryId,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      plainText: plainText ?? this.plainText,
      quotedText: quotedText ?? this.quotedText,
      color: color ?? this.color,
      styleType: styleType ?? this.styleType,
      messageId: messageId ?? this.messageId,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      start: start ?? this.start,
      end: end ?? this.end,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blockIndex: blockIndex ?? this.blockIndex,
      blockContentHash: blockContentHash ?? this.blockContentHash,
      blockInternalStart: blockInternalStart ?? this.blockInternalStart,
      blockInternalEnd: blockInternalEnd ?? this.blockInternalEnd,
      groupId: groupId ?? this.groupId,
      selections: selections ?? this.selections,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      importance: importance ?? this.importance,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (quotedText.present) {
      map['quoted_text'] = Variable<String>(quotedText.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (styleType.present) {
      map['style_type'] = Variable<String>(styleType.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (topicName.present) {
      map['topic_name'] = Variable<String>(topicName.value);
    }
    if (prefix.present) {
      map['prefix'] = Variable<String>(prefix.value);
    }
    if (suffix.present) {
      map['suffix'] = Variable<String>(suffix.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (blockIndex.present) {
      map['block_index'] = Variable<int>(blockIndex.value);
    }
    if (blockContentHash.present) {
      map['block_content_hash'] = Variable<String>(blockContentHash.value);
    }
    if (blockInternalStart.present) {
      map['block_internal_start'] = Variable<int>(blockInternalStart.value);
    }
    if (blockInternalEnd.present) {
      map['block_internal_end'] = Variable<int>(blockInternalEnd.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (selections.present) {
      map['selections'] = Variable<String>(selections.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt.value);
    }
    if (importance.present) {
      map['importance'] = Variable<int>(importance.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeEntriesCompanion(')
          ..write('entryId: $entryId, ')
          ..write('content: $content, ')
          ..write('contentType: $contentType, ')
          ..write('plainText: $plainText, ')
          ..write('quotedText: $quotedText, ')
          ..write('color: $color, ')
          ..write('styleType: $styleType, ')
          ..write('messageId: $messageId, ')
          ..write('topicId: $topicId, ')
          ..write('topicName: $topicName, ')
          ..write('prefix: $prefix, ')
          ..write('suffix: $suffix, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('blockIndex: $blockIndex, ')
          ..write('blockContentHash: $blockContentHash, ')
          ..write('blockInternalStart: $blockInternalStart, ')
          ..write('blockInternalEnd: $blockInternalEnd, ')
          ..write('groupId: $groupId, ')
          ..write('selections: $selections, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('importance: $importance, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiscussionsTable extends Discussions
    with TableInfo<$DiscussionsTable, Discussion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscussionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _discussionIdMeta = const VerificationMeta(
    'discussionId',
  );
  @override
  late final GeneratedColumn<String> discussionId = GeneratedColumn<String>(
    'discussion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    discussionId,
    messageId,
    title,
    messageCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discussions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Discussion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('discussion_id')) {
      context.handle(
        _discussionIdMeta,
        discussionId.isAcceptableOrUnknown(
          data['discussion_id']!,
          _discussionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discussionIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {discussionId};
  @override
  Discussion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Discussion(
      discussionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discussion_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DiscussionsTable createAlias(String alias) {
    return $DiscussionsTable(attachedDatabase, alias);
  }
}

class Discussion extends DataClass implements Insertable<Discussion> {
  final String discussionId;
  final String messageId;
  final String title;
  final int messageCount;
  final int createdAt;
  final int updatedAt;
  const Discussion({
    required this.discussionId,
    required this.messageId,
    required this.title,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['discussion_id'] = Variable<String>(discussionId);
    map['message_id'] = Variable<String>(messageId);
    map['title'] = Variable<String>(title);
    map['message_count'] = Variable<int>(messageCount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DiscussionsCompanion toCompanion(bool nullToAbsent) {
    return DiscussionsCompanion(
      discussionId: Value(discussionId),
      messageId: Value(messageId),
      title: Value(title),
      messageCount: Value(messageCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Discussion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Discussion(
      discussionId: serializer.fromJson<String>(json['discussionId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      title: serializer.fromJson<String>(json['title']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'discussionId': serializer.toJson<String>(discussionId),
      'messageId': serializer.toJson<String>(messageId),
      'title': serializer.toJson<String>(title),
      'messageCount': serializer.toJson<int>(messageCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Discussion copyWith({
    String? discussionId,
    String? messageId,
    String? title,
    int? messageCount,
    int? createdAt,
    int? updatedAt,
  }) => Discussion(
    discussionId: discussionId ?? this.discussionId,
    messageId: messageId ?? this.messageId,
    title: title ?? this.title,
    messageCount: messageCount ?? this.messageCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Discussion copyWithCompanion(DiscussionsCompanion data) {
    return Discussion(
      discussionId: data.discussionId.present
          ? data.discussionId.value
          : this.discussionId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      title: data.title.present ? data.title.value : this.title,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Discussion(')
          ..write('discussionId: $discussionId, ')
          ..write('messageId: $messageId, ')
          ..write('title: $title, ')
          ..write('messageCount: $messageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    discussionId,
    messageId,
    title,
    messageCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Discussion &&
          other.discussionId == this.discussionId &&
          other.messageId == this.messageId &&
          other.title == this.title &&
          other.messageCount == this.messageCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DiscussionsCompanion extends UpdateCompanion<Discussion> {
  final Value<String> discussionId;
  final Value<String> messageId;
  final Value<String> title;
  final Value<int> messageCount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DiscussionsCompanion({
    this.discussionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.title = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscussionsCompanion.insert({
    required String discussionId,
    required String messageId,
    required String title,
    this.messageCount = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : discussionId = Value(discussionId),
       messageId = Value(messageId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Discussion> custom({
    Expression<String>? discussionId,
    Expression<String>? messageId,
    Expression<String>? title,
    Expression<int>? messageCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (discussionId != null) 'discussion_id': discussionId,
      if (messageId != null) 'message_id': messageId,
      if (title != null) 'title': title,
      if (messageCount != null) 'message_count': messageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscussionsCompanion copyWith({
    Value<String>? discussionId,
    Value<String>? messageId,
    Value<String>? title,
    Value<int>? messageCount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DiscussionsCompanion(
      discussionId: discussionId ?? this.discussionId,
      messageId: messageId ?? this.messageId,
      title: title ?? this.title,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (discussionId.present) {
      map['discussion_id'] = Variable<String>(discussionId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscussionsCompanion(')
          ..write('discussionId: $discussionId, ')
          ..write('messageId: $messageId, ')
          ..write('title: $title, ')
          ..write('messageCount: $messageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiscussionMessagesTable extends DiscussionMessages
    with TableInfo<$DiscussionMessagesTable, DiscussionMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscussionMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discussionIdMeta = const VerificationMeta(
    'discussionId',
  );
  @override
  late final GeneratedColumn<String> discussionId = GeneratedColumn<String>(
    'discussion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES discussions (discussion_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    discussionId,
    role,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discussion_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiscussionMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('discussion_id')) {
      context.handle(
        _discussionIdMeta,
        discussionId.isAcceptableOrUnknown(
          data['discussion_id']!,
          _discussionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discussionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  DiscussionMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscussionMessage(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      discussionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discussion_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DiscussionMessagesTable createAlias(String alias) {
    return $DiscussionMessagesTable(attachedDatabase, alias);
  }
}

class DiscussionMessage extends DataClass
    implements Insertable<DiscussionMessage> {
  final String messageId;
  final String discussionId;
  final String role;
  final String content;
  final int createdAt;
  const DiscussionMessage({
    required this.messageId,
    required this.discussionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['discussion_id'] = Variable<String>(discussionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  DiscussionMessagesCompanion toCompanion(bool nullToAbsent) {
    return DiscussionMessagesCompanion(
      messageId: Value(messageId),
      discussionId: Value(discussionId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory DiscussionMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscussionMessage(
      messageId: serializer.fromJson<String>(json['messageId']),
      discussionId: serializer.fromJson<String>(json['discussionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'discussionId': serializer.toJson<String>(discussionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  DiscussionMessage copyWith({
    String? messageId,
    String? discussionId,
    String? role,
    String? content,
    int? createdAt,
  }) => DiscussionMessage(
    messageId: messageId ?? this.messageId,
    discussionId: discussionId ?? this.discussionId,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  DiscussionMessage copyWithCompanion(DiscussionMessagesCompanion data) {
    return DiscussionMessage(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      discussionId: data.discussionId.present
          ? data.discussionId.value
          : this.discussionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscussionMessage(')
          ..write('messageId: $messageId, ')
          ..write('discussionId: $discussionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(messageId, discussionId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscussionMessage &&
          other.messageId == this.messageId &&
          other.discussionId == this.discussionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class DiscussionMessagesCompanion extends UpdateCompanion<DiscussionMessage> {
  final Value<String> messageId;
  final Value<String> discussionId;
  final Value<String> role;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<int> rowid;
  const DiscussionMessagesCompanion({
    this.messageId = const Value.absent(),
    this.discussionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscussionMessagesCompanion.insert({
    required String messageId,
    required String discussionId,
    required String role,
    required String content,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       discussionId = Value(discussionId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<DiscussionMessage> custom({
    Expression<String>? messageId,
    Expression<String>? discussionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (discussionId != null) 'discussion_id': discussionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscussionMessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? discussionId,
    Value<String>? role,
    Value<String>? content,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return DiscussionMessagesCompanion(
      messageId: messageId ?? this.messageId,
      discussionId: discussionId ?? this.discussionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (discussionId.present) {
      map['discussion_id'] = Variable<String>(discussionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscussionMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('discussionId: $discussionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnifiedConversationsTable extends UnifiedConversations
    with TableInfo<$UnifiedConversationsTable, UnifiedConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnifiedConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextTypeMeta = const VerificationMeta(
    'contextType',
  );
  @override
  late final GeneratedColumn<String> contextType = GeneratedColumn<String>(
    'context_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextIdMeta = const VerificationMeta(
    'contextId',
  );
  @override
  late final GeneratedColumn<String> contextId = GeneratedColumn<String>(
    'context_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextSnapshotMeta = const VerificationMeta(
    'contextSnapshot',
  );
  @override
  late final GeneratedColumn<String> contextSnapshot = GeneratedColumn<String>(
    'context_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roundCountMeta = const VerificationMeta(
    'roundCount',
  );
  @override
  late final GeneratedColumn<int> roundCount = GeneratedColumn<int>(
    'round_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    conversationId,
    title,
    contextType,
    contextId,
    contextSnapshot,
    providerId,
    modelId,
    messageCount,
    roundCount,
    createdAt,
    updatedAt,
    isArchived,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unified_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnifiedConversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('context_type')) {
      context.handle(
        _contextTypeMeta,
        contextType.isAcceptableOrUnknown(
          data['context_type']!,
          _contextTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextTypeMeta);
    }
    if (data.containsKey('context_id')) {
      context.handle(
        _contextIdMeta,
        contextId.isAcceptableOrUnknown(data['context_id']!, _contextIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contextIdMeta);
    }
    if (data.containsKey('context_snapshot')) {
      context.handle(
        _contextSnapshotMeta,
        contextSnapshot.isAcceptableOrUnknown(
          data['context_snapshot']!,
          _contextSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    if (data.containsKey('round_count')) {
      context.handle(
        _roundCountMeta,
        roundCount.isAcceptableOrUnknown(data['round_count']!, _roundCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  UnifiedConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnifiedConversation(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      contextType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_type'],
      )!,
      contextId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_id'],
      )!,
      contextSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_snapshot'],
      ),
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      roundCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $UnifiedConversationsTable createAlias(String alias) {
    return $UnifiedConversationsTable(attachedDatabase, alias);
  }
}

class UnifiedConversation extends DataClass
    implements Insertable<UnifiedConversation> {
  final String conversationId;
  final String title;
  final String contextType;
  final String contextId;
  final String? contextSnapshot;
  final String? providerId;
  final String? modelId;
  final int messageCount;
  final int roundCount;
  final int createdAt;
  final int updatedAt;
  final bool isArchived;
  final bool isPinned;
  const UnifiedConversation({
    required this.conversationId,
    required this.title,
    required this.contextType,
    required this.contextId,
    this.contextSnapshot,
    this.providerId,
    this.modelId,
    required this.messageCount,
    required this.roundCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isArchived,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['title'] = Variable<String>(title);
    map['context_type'] = Variable<String>(contextType);
    map['context_id'] = Variable<String>(contextId);
    if (!nullToAbsent || contextSnapshot != null) {
      map['context_snapshot'] = Variable<String>(contextSnapshot);
    }
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    map['message_count'] = Variable<int>(messageCount);
    map['round_count'] = Variable<int>(roundCount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  UnifiedConversationsCompanion toCompanion(bool nullToAbsent) {
    return UnifiedConversationsCompanion(
      conversationId: Value(conversationId),
      title: Value(title),
      contextType: Value(contextType),
      contextId: Value(contextId),
      contextSnapshot: contextSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(contextSnapshot),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      messageCount: Value(messageCount),
      roundCount: Value(roundCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isArchived: Value(isArchived),
      isPinned: Value(isPinned),
    );
  }

  factory UnifiedConversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnifiedConversation(
      conversationId: serializer.fromJson<String>(json['conversationId']),
      title: serializer.fromJson<String>(json['title']),
      contextType: serializer.fromJson<String>(json['contextType']),
      contextId: serializer.fromJson<String>(json['contextId']),
      contextSnapshot: serializer.fromJson<String?>(json['contextSnapshot']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      roundCount: serializer.fromJson<int>(json['roundCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<String>(conversationId),
      'title': serializer.toJson<String>(title),
      'contextType': serializer.toJson<String>(contextType),
      'contextId': serializer.toJson<String>(contextId),
      'contextSnapshot': serializer.toJson<String?>(contextSnapshot),
      'providerId': serializer.toJson<String?>(providerId),
      'modelId': serializer.toJson<String?>(modelId),
      'messageCount': serializer.toJson<int>(messageCount),
      'roundCount': serializer.toJson<int>(roundCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  UnifiedConversation copyWith({
    String? conversationId,
    String? title,
    String? contextType,
    String? contextId,
    Value<String?> contextSnapshot = const Value.absent(),
    Value<String?> providerId = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    int? messageCount,
    int? roundCount,
    int? createdAt,
    int? updatedAt,
    bool? isArchived,
    bool? isPinned,
  }) => UnifiedConversation(
    conversationId: conversationId ?? this.conversationId,
    title: title ?? this.title,
    contextType: contextType ?? this.contextType,
    contextId: contextId ?? this.contextId,
    contextSnapshot: contextSnapshot.present
        ? contextSnapshot.value
        : this.contextSnapshot,
    providerId: providerId.present ? providerId.value : this.providerId,
    modelId: modelId.present ? modelId.value : this.modelId,
    messageCount: messageCount ?? this.messageCount,
    roundCount: roundCount ?? this.roundCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
    isPinned: isPinned ?? this.isPinned,
  );
  UnifiedConversation copyWithCompanion(UnifiedConversationsCompanion data) {
    return UnifiedConversation(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      title: data.title.present ? data.title.value : this.title,
      contextType: data.contextType.present
          ? data.contextType.value
          : this.contextType,
      contextId: data.contextId.present ? data.contextId.value : this.contextId,
      contextSnapshot: data.contextSnapshot.present
          ? data.contextSnapshot.value
          : this.contextSnapshot,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      roundCount: data.roundCount.present
          ? data.roundCount.value
          : this.roundCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnifiedConversation(')
          ..write('conversationId: $conversationId, ')
          ..write('title: $title, ')
          ..write('contextType: $contextType, ')
          ..write('contextId: $contextId, ')
          ..write('contextSnapshot: $contextSnapshot, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('messageCount: $messageCount, ')
          ..write('roundCount: $roundCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    conversationId,
    title,
    contextType,
    contextId,
    contextSnapshot,
    providerId,
    modelId,
    messageCount,
    roundCount,
    createdAt,
    updatedAt,
    isArchived,
    isPinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnifiedConversation &&
          other.conversationId == this.conversationId &&
          other.title == this.title &&
          other.contextType == this.contextType &&
          other.contextId == this.contextId &&
          other.contextSnapshot == this.contextSnapshot &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId &&
          other.messageCount == this.messageCount &&
          other.roundCount == this.roundCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isArchived == this.isArchived &&
          other.isPinned == this.isPinned);
}

class UnifiedConversationsCompanion
    extends UpdateCompanion<UnifiedConversation> {
  final Value<String> conversationId;
  final Value<String> title;
  final Value<String> contextType;
  final Value<String> contextId;
  final Value<String?> contextSnapshot;
  final Value<String?> providerId;
  final Value<String?> modelId;
  final Value<int> messageCount;
  final Value<int> roundCount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isArchived;
  final Value<bool> isPinned;
  final Value<int> rowid;
  const UnifiedConversationsCompanion({
    this.conversationId = const Value.absent(),
    this.title = const Value.absent(),
    this.contextType = const Value.absent(),
    this.contextId = const Value.absent(),
    this.contextSnapshot = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.roundCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnifiedConversationsCompanion.insert({
    required String conversationId,
    required String title,
    required String contextType,
    required String contextId,
    this.contextSnapshot = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.roundCount = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.isArchived = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       title = Value(title),
       contextType = Value(contextType),
       contextId = Value(contextId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UnifiedConversation> custom({
    Expression<String>? conversationId,
    Expression<String>? title,
    Expression<String>? contextType,
    Expression<String>? contextId,
    Expression<String>? contextSnapshot,
    Expression<String>? providerId,
    Expression<String>? modelId,
    Expression<int>? messageCount,
    Expression<int>? roundCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isArchived,
    Expression<bool>? isPinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (title != null) 'title': title,
      if (contextType != null) 'context_type': contextType,
      if (contextId != null) 'context_id': contextId,
      if (contextSnapshot != null) 'context_snapshot': contextSnapshot,
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (messageCount != null) 'message_count': messageCount,
      if (roundCount != null) 'round_count': roundCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnifiedConversationsCompanion copyWith({
    Value<String>? conversationId,
    Value<String>? title,
    Value<String>? contextType,
    Value<String>? contextId,
    Value<String?>? contextSnapshot,
    Value<String?>? providerId,
    Value<String?>? modelId,
    Value<int>? messageCount,
    Value<int>? roundCount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<bool>? isArchived,
    Value<bool>? isPinned,
    Value<int>? rowid,
  }) {
    return UnifiedConversationsCompanion(
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      messageCount: messageCount ?? this.messageCount,
      roundCount: roundCount ?? this.roundCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (contextType.present) {
      map['context_type'] = Variable<String>(contextType.value);
    }
    if (contextId.present) {
      map['context_id'] = Variable<String>(contextId.value);
    }
    if (contextSnapshot.present) {
      map['context_snapshot'] = Variable<String>(contextSnapshot.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (roundCount.present) {
      map['round_count'] = Variable<int>(roundCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnifiedConversationsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('title: $title, ')
          ..write('contextType: $contextType, ')
          ..write('contextId: $contextId, ')
          ..write('contextSnapshot: $contextSnapshot, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('messageCount: $messageCount, ')
          ..write('roundCount: $roundCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnifiedMessagesTable extends UnifiedMessages
    with TableInfo<$UnifiedMessagesTable, UnifiedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnifiedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES unified_conversations (conversation_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _askIdMeta = const VerificationMeta('askId');
  @override
  late final GeneratedColumn<String> askId = GeneratedColumn<String>(
    'ask_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMainlineMeta = const VerificationMeta(
    'isMainline',
  );
  @override
  late final GeneratedColumn<bool> isMainline = GeneratedColumn<bool>(
    'is_mainline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mainline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _usageJsonMeta = const VerificationMeta(
    'usageJson',
  );
  @override
  late final GeneratedColumn<String> usageJson = GeneratedColumn<String>(
    'usage_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateNameMeta = const VerificationMeta(
    'templateName',
  );
  @override
  late final GeneratedColumn<String> templateName = GeneratedColumn<String>(
    'template_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateSnapshotMeta = const VerificationMeta(
    'templateSnapshot',
  );
  @override
  late final GeneratedColumn<String> templateSnapshot = GeneratedColumn<String>(
    'template_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextSummaryMeta = const VerificationMeta(
    'contextSummary',
  );
  @override
  late final GeneratedColumn<String> contextSummary = GeneratedColumn<String>(
    'context_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextContentMeta = const VerificationMeta(
    'contextContent',
  );
  @override
  late final GeneratedColumn<String> contextContent = GeneratedColumn<String>(
    'context_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userQueryMeta = const VerificationMeta(
    'userQuery',
  );
  @override
  late final GeneratedColumn<String> userQuery = GeneratedColumn<String>(
    'user_query',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextDataJsonMeta = const VerificationMeta(
    'contextDataJson',
  );
  @override
  late final GeneratedColumn<String> contextDataJson = GeneratedColumn<String>(
    'context_data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    conversationId,
    role,
    content,
    modelId,
    modelName,
    askId,
    isMainline,
    usageJson,
    createdAt,
    status,
    errorMessage,
    templateId,
    templateName,
    templateSnapshot,
    contextSummary,
    contextContent,
    userQuery,
    contextDataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unified_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnifiedMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('ask_id')) {
      context.handle(
        _askIdMeta,
        askId.isAcceptableOrUnknown(data['ask_id']!, _askIdMeta),
      );
    }
    if (data.containsKey('is_mainline')) {
      context.handle(
        _isMainlineMeta,
        isMainline.isAcceptableOrUnknown(data['is_mainline']!, _isMainlineMeta),
      );
    }
    if (data.containsKey('usage_json')) {
      context.handle(
        _usageJsonMeta,
        usageJson.isAcceptableOrUnknown(data['usage_json']!, _usageJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('template_name')) {
      context.handle(
        _templateNameMeta,
        templateName.isAcceptableOrUnknown(
          data['template_name']!,
          _templateNameMeta,
        ),
      );
    }
    if (data.containsKey('template_snapshot')) {
      context.handle(
        _templateSnapshotMeta,
        templateSnapshot.isAcceptableOrUnknown(
          data['template_snapshot']!,
          _templateSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('context_summary')) {
      context.handle(
        _contextSummaryMeta,
        contextSummary.isAcceptableOrUnknown(
          data['context_summary']!,
          _contextSummaryMeta,
        ),
      );
    }
    if (data.containsKey('context_content')) {
      context.handle(
        _contextContentMeta,
        contextContent.isAcceptableOrUnknown(
          data['context_content']!,
          _contextContentMeta,
        ),
      );
    }
    if (data.containsKey('user_query')) {
      context.handle(
        _userQueryMeta,
        userQuery.isAcceptableOrUnknown(data['user_query']!, _userQueryMeta),
      );
    }
    if (data.containsKey('context_data_json')) {
      context.handle(
        _contextDataJsonMeta,
        contextDataJson.isAcceptableOrUnknown(
          data['context_data_json']!,
          _contextDataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  UnifiedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnifiedMessage(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      askId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ask_id'],
      ),
      isMainline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mainline'],
      )!,
      usageJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      templateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_name'],
      ),
      templateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_snapshot'],
      ),
      contextSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_summary'],
      ),
      contextContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_content'],
      ),
      userQuery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_query'],
      ),
      contextDataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_data_json'],
      ),
    );
  }

  @override
  $UnifiedMessagesTable createAlias(String alias) {
    return $UnifiedMessagesTable(attachedDatabase, alias);
  }
}

class UnifiedMessage extends DataClass implements Insertable<UnifiedMessage> {
  final String messageId;
  final String conversationId;
  final String role;
  final String content;
  final String? modelId;
  final String? modelName;
  final String? askId;
  final bool isMainline;
  final String? usageJson;
  final int createdAt;
  final String status;
  final String? errorMessage;
  final String? templateId;
  final String? templateName;
  final String? templateSnapshot;
  final String? contextSummary;
  final String? contextContent;
  final String? userQuery;
  final String? contextDataJson;
  const UnifiedMessage({
    required this.messageId,
    required this.conversationId,
    required this.role,
    required this.content,
    this.modelId,
    this.modelName,
    this.askId,
    required this.isMainline,
    this.usageJson,
    required this.createdAt,
    required this.status,
    this.errorMessage,
    this.templateId,
    this.templateName,
    this.templateSnapshot,
    this.contextSummary,
    this.contextContent,
    this.userQuery,
    this.contextDataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || askId != null) {
      map['ask_id'] = Variable<String>(askId);
    }
    map['is_mainline'] = Variable<bool>(isMainline);
    if (!nullToAbsent || usageJson != null) {
      map['usage_json'] = Variable<String>(usageJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    if (!nullToAbsent || templateName != null) {
      map['template_name'] = Variable<String>(templateName);
    }
    if (!nullToAbsent || templateSnapshot != null) {
      map['template_snapshot'] = Variable<String>(templateSnapshot);
    }
    if (!nullToAbsent || contextSummary != null) {
      map['context_summary'] = Variable<String>(contextSummary);
    }
    if (!nullToAbsent || contextContent != null) {
      map['context_content'] = Variable<String>(contextContent);
    }
    if (!nullToAbsent || userQuery != null) {
      map['user_query'] = Variable<String>(userQuery);
    }
    if (!nullToAbsent || contextDataJson != null) {
      map['context_data_json'] = Variable<String>(contextDataJson);
    }
    return map;
  }

  UnifiedMessagesCompanion toCompanion(bool nullToAbsent) {
    return UnifiedMessagesCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      askId: askId == null && nullToAbsent
          ? const Value.absent()
          : Value(askId),
      isMainline: Value(isMainline),
      usageJson: usageJson == null && nullToAbsent
          ? const Value.absent()
          : Value(usageJson),
      createdAt: Value(createdAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      templateName: templateName == null && nullToAbsent
          ? const Value.absent()
          : Value(templateName),
      templateSnapshot: templateSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(templateSnapshot),
      contextSummary: contextSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(contextSummary),
      contextContent: contextContent == null && nullToAbsent
          ? const Value.absent()
          : Value(contextContent),
      userQuery: userQuery == null && nullToAbsent
          ? const Value.absent()
          : Value(userQuery),
      contextDataJson: contextDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contextDataJson),
    );
  }

  factory UnifiedMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnifiedMessage(
      messageId: serializer.fromJson<String>(json['messageId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      askId: serializer.fromJson<String?>(json['askId']),
      isMainline: serializer.fromJson<bool>(json['isMainline']),
      usageJson: serializer.fromJson<String?>(json['usageJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      templateName: serializer.fromJson<String?>(json['templateName']),
      templateSnapshot: serializer.fromJson<String?>(json['templateSnapshot']),
      contextSummary: serializer.fromJson<String?>(json['contextSummary']),
      contextContent: serializer.fromJson<String?>(json['contextContent']),
      userQuery: serializer.fromJson<String?>(json['userQuery']),
      contextDataJson: serializer.fromJson<String?>(json['contextDataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'modelId': serializer.toJson<String?>(modelId),
      'modelName': serializer.toJson<String?>(modelName),
      'askId': serializer.toJson<String?>(askId),
      'isMainline': serializer.toJson<bool>(isMainline),
      'usageJson': serializer.toJson<String?>(usageJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'templateId': serializer.toJson<String?>(templateId),
      'templateName': serializer.toJson<String?>(templateName),
      'templateSnapshot': serializer.toJson<String?>(templateSnapshot),
      'contextSummary': serializer.toJson<String?>(contextSummary),
      'contextContent': serializer.toJson<String?>(contextContent),
      'userQuery': serializer.toJson<String?>(userQuery),
      'contextDataJson': serializer.toJson<String?>(contextDataJson),
    };
  }

  UnifiedMessage copyWith({
    String? messageId,
    String? conversationId,
    String? role,
    String? content,
    Value<String?> modelId = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> askId = const Value.absent(),
    bool? isMainline,
    Value<String?> usageJson = const Value.absent(),
    int? createdAt,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> templateId = const Value.absent(),
    Value<String?> templateName = const Value.absent(),
    Value<String?> templateSnapshot = const Value.absent(),
    Value<String?> contextSummary = const Value.absent(),
    Value<String?> contextContent = const Value.absent(),
    Value<String?> userQuery = const Value.absent(),
    Value<String?> contextDataJson = const Value.absent(),
  }) => UnifiedMessage(
    messageId: messageId ?? this.messageId,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    modelId: modelId.present ? modelId.value : this.modelId,
    modelName: modelName.present ? modelName.value : this.modelName,
    askId: askId.present ? askId.value : this.askId,
    isMainline: isMainline ?? this.isMainline,
    usageJson: usageJson.present ? usageJson.value : this.usageJson,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    templateId: templateId.present ? templateId.value : this.templateId,
    templateName: templateName.present ? templateName.value : this.templateName,
    templateSnapshot: templateSnapshot.present
        ? templateSnapshot.value
        : this.templateSnapshot,
    contextSummary: contextSummary.present
        ? contextSummary.value
        : this.contextSummary,
    contextContent: contextContent.present
        ? contextContent.value
        : this.contextContent,
    userQuery: userQuery.present ? userQuery.value : this.userQuery,
    contextDataJson: contextDataJson.present
        ? contextDataJson.value
        : this.contextDataJson,
  );
  UnifiedMessage copyWithCompanion(UnifiedMessagesCompanion data) {
    return UnifiedMessage(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      askId: data.askId.present ? data.askId.value : this.askId,
      isMainline: data.isMainline.present
          ? data.isMainline.value
          : this.isMainline,
      usageJson: data.usageJson.present ? data.usageJson.value : this.usageJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateName: data.templateName.present
          ? data.templateName.value
          : this.templateName,
      templateSnapshot: data.templateSnapshot.present
          ? data.templateSnapshot.value
          : this.templateSnapshot,
      contextSummary: data.contextSummary.present
          ? data.contextSummary.value
          : this.contextSummary,
      contextContent: data.contextContent.present
          ? data.contextContent.value
          : this.contextContent,
      userQuery: data.userQuery.present ? data.userQuery.value : this.userQuery,
      contextDataJson: data.contextDataJson.present
          ? data.contextDataJson.value
          : this.contextDataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnifiedMessage(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('modelId: $modelId, ')
          ..write('modelName: $modelName, ')
          ..write('askId: $askId, ')
          ..write('isMainline: $isMainline, ')
          ..write('usageJson: $usageJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('templateId: $templateId, ')
          ..write('templateName: $templateName, ')
          ..write('templateSnapshot: $templateSnapshot, ')
          ..write('contextSummary: $contextSummary, ')
          ..write('contextContent: $contextContent, ')
          ..write('userQuery: $userQuery, ')
          ..write('contextDataJson: $contextDataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    conversationId,
    role,
    content,
    modelId,
    modelName,
    askId,
    isMainline,
    usageJson,
    createdAt,
    status,
    errorMessage,
    templateId,
    templateName,
    templateSnapshot,
    contextSummary,
    contextContent,
    userQuery,
    contextDataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnifiedMessage &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.modelId == this.modelId &&
          other.modelName == this.modelName &&
          other.askId == this.askId &&
          other.isMainline == this.isMainline &&
          other.usageJson == this.usageJson &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.templateId == this.templateId &&
          other.templateName == this.templateName &&
          other.templateSnapshot == this.templateSnapshot &&
          other.contextSummary == this.contextSummary &&
          other.contextContent == this.contextContent &&
          other.userQuery == this.userQuery &&
          other.contextDataJson == this.contextDataJson);
}

class UnifiedMessagesCompanion extends UpdateCompanion<UnifiedMessage> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> modelId;
  final Value<String?> modelName;
  final Value<String?> askId;
  final Value<bool> isMainline;
  final Value<String?> usageJson;
  final Value<int> createdAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<String?> templateId;
  final Value<String?> templateName;
  final Value<String?> templateSnapshot;
  final Value<String?> contextSummary;
  final Value<String?> contextContent;
  final Value<String?> userQuery;
  final Value<String?> contextDataJson;
  final Value<int> rowid;
  const UnifiedMessagesCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.askId = const Value.absent(),
    this.isMainline = const Value.absent(),
    this.usageJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateName = const Value.absent(),
    this.templateSnapshot = const Value.absent(),
    this.contextSummary = const Value.absent(),
    this.contextContent = const Value.absent(),
    this.userQuery = const Value.absent(),
    this.contextDataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnifiedMessagesCompanion.insert({
    required String messageId,
    required String conversationId,
    required String role,
    required String content,
    this.modelId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.askId = const Value.absent(),
    this.isMainline = const Value.absent(),
    this.usageJson = const Value.absent(),
    required int createdAt,
    required String status,
    this.errorMessage = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateName = const Value.absent(),
    this.templateSnapshot = const Value.absent(),
    this.contextSummary = const Value.absent(),
    this.contextContent = const Value.absent(),
    this.userQuery = const Value.absent(),
    this.contextDataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<UnifiedMessage> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? modelId,
    Expression<String>? modelName,
    Expression<String>? askId,
    Expression<bool>? isMainline,
    Expression<String>? usageJson,
    Expression<int>? createdAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<String>? templateId,
    Expression<String>? templateName,
    Expression<String>? templateSnapshot,
    Expression<String>? contextSummary,
    Expression<String>? contextContent,
    Expression<String>? userQuery,
    Expression<String>? contextDataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (modelId != null) 'model_id': modelId,
      if (modelName != null) 'model_name': modelName,
      if (askId != null) 'ask_id': askId,
      if (isMainline != null) 'is_mainline': isMainline,
      if (usageJson != null) 'usage_json': usageJson,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (templateId != null) 'template_id': templateId,
      if (templateName != null) 'template_name': templateName,
      if (templateSnapshot != null) 'template_snapshot': templateSnapshot,
      if (contextSummary != null) 'context_summary': contextSummary,
      if (contextContent != null) 'context_content': contextContent,
      if (userQuery != null) 'user_query': userQuery,
      if (contextDataJson != null) 'context_data_json': contextDataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnifiedMessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? conversationId,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? modelId,
    Value<String?>? modelName,
    Value<String?>? askId,
    Value<bool>? isMainline,
    Value<String?>? usageJson,
    Value<int>? createdAt,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<String?>? templateId,
    Value<String?>? templateName,
    Value<String?>? templateSnapshot,
    Value<String?>? contextSummary,
    Value<String?>? contextContent,
    Value<String?>? userQuery,
    Value<String?>? contextDataJson,
    Value<int>? rowid,
  }) {
    return UnifiedMessagesCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      askId: askId ?? this.askId,
      isMainline: isMainline ?? this.isMainline,
      usageJson: usageJson ?? this.usageJson,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      templateSnapshot: templateSnapshot ?? this.templateSnapshot,
      contextSummary: contextSummary ?? this.contextSummary,
      contextContent: contextContent ?? this.contextContent,
      userQuery: userQuery ?? this.userQuery,
      contextDataJson: contextDataJson ?? this.contextDataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (askId.present) {
      map['ask_id'] = Variable<String>(askId.value);
    }
    if (isMainline.present) {
      map['is_mainline'] = Variable<bool>(isMainline.value);
    }
    if (usageJson.present) {
      map['usage_json'] = Variable<String>(usageJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateName.present) {
      map['template_name'] = Variable<String>(templateName.value);
    }
    if (templateSnapshot.present) {
      map['template_snapshot'] = Variable<String>(templateSnapshot.value);
    }
    if (contextSummary.present) {
      map['context_summary'] = Variable<String>(contextSummary.value);
    }
    if (contextContent.present) {
      map['context_content'] = Variable<String>(contextContent.value);
    }
    if (userQuery.present) {
      map['user_query'] = Variable<String>(userQuery.value);
    }
    if (contextDataJson.present) {
      map['context_data_json'] = Variable<String>(contextDataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnifiedMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('modelId: $modelId, ')
          ..write('modelName: $modelName, ')
          ..write('askId: $askId, ')
          ..write('isMainline: $isMainline, ')
          ..write('usageJson: $usageJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('templateId: $templateId, ')
          ..write('templateName: $templateName, ')
          ..write('templateSnapshot: $templateSnapshot, ')
          ..write('contextSummary: $contextSummary, ')
          ..write('contextContent: $contextContent, ')
          ..write('userQuery: $userQuery, ')
          ..write('contextDataJson: $contextDataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTable extends UserPreferences
    with TableInfo<$UserPreferencesTable, UserPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _preferenceIdMeta = const VerificationMeta(
    'preferenceId',
  );
  @override
  late final GeneratedColumn<String> preferenceId = GeneratedColumn<String>(
    'preference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemPromptMeta = const VerificationMeta(
    'systemPrompt',
  );
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
    'system_prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultTemplateIdMeta = const VerificationMeta(
    'defaultTemplateId',
  );
  @override
  late final GeneratedColumn<String> defaultTemplateId =
      GeneratedColumn<String>(
        'default_template_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    preferenceId,
    name,
    systemPrompt,
    isActive,
    defaultTemplateId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('preference_id')) {
      context.handle(
        _preferenceIdMeta,
        preferenceId.isAcceptableOrUnknown(
          data['preference_id']!,
          _preferenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferenceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
        _systemPromptMeta,
        systemPrompt.isAcceptableOrUnknown(
          data['system_prompt']!,
          _systemPromptMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_systemPromptMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('default_template_id')) {
      context.handle(
        _defaultTemplateIdMeta,
        defaultTemplateId.isAcceptableOrUnknown(
          data['default_template_id']!,
          _defaultTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {preferenceId};
  @override
  UserPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreference(
      preferenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preference_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      systemPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_prompt'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      defaultTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_template_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserPreferencesTable createAlias(String alias) {
    return $UserPreferencesTable(attachedDatabase, alias);
  }
}

class UserPreference extends DataClass implements Insertable<UserPreference> {
  final String preferenceId;
  final String name;
  final String systemPrompt;
  final bool isActive;
  final String? defaultTemplateId;
  final int createdAt;
  final int updatedAt;
  const UserPreference({
    required this.preferenceId,
    required this.name,
    required this.systemPrompt,
    required this.isActive,
    this.defaultTemplateId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['preference_id'] = Variable<String>(preferenceId);
    map['name'] = Variable<String>(name);
    map['system_prompt'] = Variable<String>(systemPrompt);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || defaultTemplateId != null) {
      map['default_template_id'] = Variable<String>(defaultTemplateId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UserPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesCompanion(
      preferenceId: Value(preferenceId),
      name: Value(name),
      systemPrompt: Value(systemPrompt),
      isActive: Value(isActive),
      defaultTemplateId: defaultTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultTemplateId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreference(
      preferenceId: serializer.fromJson<String>(json['preferenceId']),
      name: serializer.fromJson<String>(json['name']),
      systemPrompt: serializer.fromJson<String>(json['systemPrompt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      defaultTemplateId: serializer.fromJson<String?>(
        json['defaultTemplateId'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'preferenceId': serializer.toJson<String>(preferenceId),
      'name': serializer.toJson<String>(name),
      'systemPrompt': serializer.toJson<String>(systemPrompt),
      'isActive': serializer.toJson<bool>(isActive),
      'defaultTemplateId': serializer.toJson<String?>(defaultTemplateId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  UserPreference copyWith({
    String? preferenceId,
    String? name,
    String? systemPrompt,
    bool? isActive,
    Value<String?> defaultTemplateId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => UserPreference(
    preferenceId: preferenceId ?? this.preferenceId,
    name: name ?? this.name,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    isActive: isActive ?? this.isActive,
    defaultTemplateId: defaultTemplateId.present
        ? defaultTemplateId.value
        : this.defaultTemplateId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserPreference copyWithCompanion(UserPreferencesCompanion data) {
    return UserPreference(
      preferenceId: data.preferenceId.present
          ? data.preferenceId.value
          : this.preferenceId,
      name: data.name.present ? data.name.value : this.name,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      defaultTemplateId: data.defaultTemplateId.present
          ? data.defaultTemplateId.value
          : this.defaultTemplateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreference(')
          ..write('preferenceId: $preferenceId, ')
          ..write('name: $name, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('isActive: $isActive, ')
          ..write('defaultTemplateId: $defaultTemplateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    preferenceId,
    name,
    systemPrompt,
    isActive,
    defaultTemplateId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreference &&
          other.preferenceId == this.preferenceId &&
          other.name == this.name &&
          other.systemPrompt == this.systemPrompt &&
          other.isActive == this.isActive &&
          other.defaultTemplateId == this.defaultTemplateId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserPreferencesCompanion extends UpdateCompanion<UserPreference> {
  final Value<String> preferenceId;
  final Value<String> name;
  final Value<String> systemPrompt;
  final Value<bool> isActive;
  final Value<String?> defaultTemplateId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const UserPreferencesCompanion({
    this.preferenceId = const Value.absent(),
    this.name = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.defaultTemplateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesCompanion.insert({
    required String preferenceId,
    required String name,
    required String systemPrompt,
    this.isActive = const Value.absent(),
    this.defaultTemplateId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : preferenceId = Value(preferenceId),
       name = Value(name),
       systemPrompt = Value(systemPrompt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserPreference> custom({
    Expression<String>? preferenceId,
    Expression<String>? name,
    Expression<String>? systemPrompt,
    Expression<bool>? isActive,
    Expression<String>? defaultTemplateId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (preferenceId != null) 'preference_id': preferenceId,
      if (name != null) 'name': name,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (isActive != null) 'is_active': isActive,
      if (defaultTemplateId != null) 'default_template_id': defaultTemplateId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesCompanion copyWith({
    Value<String>? preferenceId,
    Value<String>? name,
    Value<String>? systemPrompt,
    Value<bool>? isActive,
    Value<String?>? defaultTemplateId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserPreferencesCompanion(
      preferenceId: preferenceId ?? this.preferenceId,
      name: name ?? this.name,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isActive: isActive ?? this.isActive,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (preferenceId.present) {
      map['preference_id'] = Variable<String>(preferenceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (defaultTemplateId.present) {
      map['default_template_id'] = Variable<String>(defaultTemplateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesCompanion(')
          ..write('preferenceId: $preferenceId, ')
          ..write('name: $name, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('isActive: $isActive, ')
          ..write('defaultTemplateId: $defaultTemplateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTemplatesTable extends TaskTemplates
    with TableInfo<$TaskTemplatesTable, TaskTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _usageCountMeta = const VerificationMeta(
    'usageCount',
  );
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
    'usage_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('any'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    templateId,
    name,
    description,
    content,
    isBuiltIn,
    usageCount,
    targetType,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('usage_count')) {
      context.handle(
        _usageCountMeta,
        usageCount.isAcceptableOrUnknown(data['usage_count']!, _usageCountMeta),
      );
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {templateId};
  @override
  TaskTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplate(
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      usageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_count'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TaskTemplatesTable createAlias(String alias) {
    return $TaskTemplatesTable(attachedDatabase, alias);
  }
}

class TaskTemplate extends DataClass implements Insertable<TaskTemplate> {
  final String templateId;
  final String name;
  final String? description;
  final String content;
  final bool isBuiltIn;
  final int usageCount;
  final String targetType;
  final int createdAt;
  final int updatedAt;
  const TaskTemplate({
    required this.templateId,
    required this.name,
    this.description,
    required this.content,
    required this.isBuiltIn,
    required this.usageCount,
    required this.targetType,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['template_id'] = Variable<String>(templateId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['content'] = Variable<String>(content);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['usage_count'] = Variable<int>(usageCount);
    map['target_type'] = Variable<String>(targetType);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TaskTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TaskTemplatesCompanion(
      templateId: Value(templateId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      content: Value(content),
      isBuiltIn: Value(isBuiltIn),
      usageCount: Value(usageCount),
      targetType: Value(targetType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplate(
      templateId: serializer.fromJson<String>(json['templateId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      content: serializer.fromJson<String>(json['content']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      targetType: serializer.fromJson<String>(json['targetType']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'templateId': serializer.toJson<String>(templateId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'content': serializer.toJson<String>(content),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'usageCount': serializer.toJson<int>(usageCount),
      'targetType': serializer.toJson<String>(targetType),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TaskTemplate copyWith({
    String? templateId,
    String? name,
    Value<String?> description = const Value.absent(),
    String? content,
    bool? isBuiltIn,
    int? usageCount,
    String? targetType,
    int? createdAt,
    int? updatedAt,
  }) => TaskTemplate(
    templateId: templateId ?? this.templateId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    content: content ?? this.content,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    usageCount: usageCount ?? this.usageCount,
    targetType: targetType ?? this.targetType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskTemplate copyWithCompanion(TaskTemplatesCompanion data) {
    return TaskTemplate(
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      content: data.content.present ? data.content.value : this.content,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      usageCount: data.usageCount.present
          ? data.usageCount.value
          : this.usageCount,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplate(')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('usageCount: $usageCount, ')
          ..write('targetType: $targetType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    templateId,
    name,
    description,
    content,
    isBuiltIn,
    usageCount,
    targetType,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplate &&
          other.templateId == this.templateId &&
          other.name == this.name &&
          other.description == this.description &&
          other.content == this.content &&
          other.isBuiltIn == this.isBuiltIn &&
          other.usageCount == this.usageCount &&
          other.targetType == this.targetType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TaskTemplatesCompanion extends UpdateCompanion<TaskTemplate> {
  final Value<String> templateId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> content;
  final Value<bool> isBuiltIn;
  final Value<int> usageCount;
  final Value<String> targetType;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TaskTemplatesCompanion({
    this.templateId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.targetType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTemplatesCompanion.insert({
    required String templateId,
    required String name,
    this.description = const Value.absent(),
    required String content,
    this.isBuiltIn = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.targetType = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : templateId = Value(templateId),
       name = Value(name),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskTemplate> custom({
    Expression<String>? templateId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? content,
    Expression<bool>? isBuiltIn,
    Expression<int>? usageCount,
    Expression<String>? targetType,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (templateId != null) 'template_id': templateId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (usageCount != null) 'usage_count': usageCount,
      if (targetType != null) 'target_type': targetType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTemplatesCompanion copyWith({
    Value<String>? templateId,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? content,
    Value<bool>? isBuiltIn,
    Value<int>? usageCount,
    Value<String>? targetType,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TaskTemplatesCompanion(
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      usageCount: usageCount ?? this.usageCount,
      targetType: targetType ?? this.targetType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplatesCompanion(')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('usageCount: $usageCount, ')
          ..write('targetType: $targetType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PerspectivesTable extends Perspectives
    with TableInfo<$PerspectivesTable, Perspective> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PerspectivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _perspectiveIdMeta = const VerificationMeta(
    'perspectiveId',
  );
  @override
  late final GeneratedColumn<String> perspectiveId = GeneratedColumn<String>(
    'perspective_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptTemplateMeta = const VerificationMeta(
    'promptTemplate',
  );
  @override
  late final GeneratedColumn<String> promptTemplate = GeneratedColumn<String>(
    'prompt_template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    perspectiveId,
    name,
    icon,
    description,
    category,
    promptTemplate,
    isBuiltin,
    isEnabled,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'perspectives';
  @override
  VerificationContext validateIntegrity(
    Insertable<Perspective> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('perspective_id')) {
      context.handle(
        _perspectiveIdMeta,
        perspectiveId.isAcceptableOrUnknown(
          data['perspective_id']!,
          _perspectiveIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perspectiveIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('prompt_template')) {
      context.handle(
        _promptTemplateMeta,
        promptTemplate.isAcceptableOrUnknown(
          data['prompt_template']!,
          _promptTemplateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promptTemplateMeta);
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {perspectiveId};
  @override
  Perspective map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Perspective(
      perspectiveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perspective_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      promptTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_template'],
      )!,
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PerspectivesTable createAlias(String alias) {
    return $PerspectivesTable(attachedDatabase, alias);
  }
}

class Perspective extends DataClass implements Insertable<Perspective> {
  final String perspectiveId;
  final String name;
  final String icon;
  final String description;
  final String category;
  final String promptTemplate;
  final bool isBuiltin;
  final bool isEnabled;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const Perspective({
    required this.perspectiveId,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.promptTemplate,
    required this.isBuiltin,
    required this.isEnabled,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['perspective_id'] = Variable<String>(perspectiveId);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['prompt_template'] = Variable<String>(promptTemplate);
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PerspectivesCompanion toCompanion(bool nullToAbsent) {
    return PerspectivesCompanion(
      perspectiveId: Value(perspectiveId),
      name: Value(name),
      icon: Value(icon),
      description: Value(description),
      category: Value(category),
      promptTemplate: Value(promptTemplate),
      isBuiltin: Value(isBuiltin),
      isEnabled: Value(isEnabled),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Perspective.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Perspective(
      perspectiveId: serializer.fromJson<String>(json['perspectiveId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      promptTemplate: serializer.fromJson<String>(json['promptTemplate']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'perspectiveId': serializer.toJson<String>(perspectiveId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'promptTemplate': serializer.toJson<String>(promptTemplate),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Perspective copyWith({
    String? perspectiveId,
    String? name,
    String? icon,
    String? description,
    String? category,
    String? promptTemplate,
    bool? isBuiltin,
    bool? isEnabled,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => Perspective(
    perspectiveId: perspectiveId ?? this.perspectiveId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    description: description ?? this.description,
    category: category ?? this.category,
    promptTemplate: promptTemplate ?? this.promptTemplate,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    isEnabled: isEnabled ?? this.isEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Perspective copyWithCompanion(PerspectivesCompanion data) {
    return Perspective(
      perspectiveId: data.perspectiveId.present
          ? data.perspectiveId.value
          : this.perspectiveId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      promptTemplate: data.promptTemplate.present
          ? data.promptTemplate.value
          : this.promptTemplate,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Perspective(')
          ..write('perspectiveId: $perspectiveId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('promptTemplate: $promptTemplate, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    perspectiveId,
    name,
    icon,
    description,
    category,
    promptTemplate,
    isBuiltin,
    isEnabled,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Perspective &&
          other.perspectiveId == this.perspectiveId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.description == this.description &&
          other.category == this.category &&
          other.promptTemplate == this.promptTemplate &&
          other.isBuiltin == this.isBuiltin &&
          other.isEnabled == this.isEnabled &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PerspectivesCompanion extends UpdateCompanion<Perspective> {
  final Value<String> perspectiveId;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> description;
  final Value<String> category;
  final Value<String> promptTemplate;
  final Value<bool> isBuiltin;
  final Value<bool> isEnabled;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PerspectivesCompanion({
    this.perspectiveId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.promptTemplate = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PerspectivesCompanion.insert({
    required String perspectiveId,
    required String name,
    required String icon,
    required String description,
    required String category,
    required String promptTemplate,
    this.isBuiltin = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : perspectiveId = Value(perspectiveId),
       name = Value(name),
       icon = Value(icon),
       description = Value(description),
       category = Value(category),
       promptTemplate = Value(promptTemplate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Perspective> custom({
    Expression<String>? perspectiveId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? promptTemplate,
    Expression<bool>? isBuiltin,
    Expression<bool>? isEnabled,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (perspectiveId != null) 'perspective_id': perspectiveId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (promptTemplate != null) 'prompt_template': promptTemplate,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PerspectivesCompanion copyWith({
    Value<String>? perspectiveId,
    Value<String>? name,
    Value<String>? icon,
    Value<String>? description,
    Value<String>? category,
    Value<String>? promptTemplate,
    Value<bool>? isBuiltin,
    Value<bool>? isEnabled,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PerspectivesCompanion(
      perspectiveId: perspectiveId ?? this.perspectiveId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      category: category ?? this.category,
      promptTemplate: promptTemplate ?? this.promptTemplate,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (perspectiveId.present) {
      map['perspective_id'] = Variable<String>(perspectiveId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (promptTemplate.present) {
      map['prompt_template'] = Variable<String>(promptTemplate.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PerspectivesCompanion(')
          ..write('perspectiveId: $perspectiveId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('promptTemplate: $promptTemplate, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InsightsTable extends Insights with TableInfo<$InsightsTable, Insight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _insightIdMeta = const VerificationMeta(
    'insightId',
  );
  @override
  late final GeneratedColumn<String> insightId = GeneratedColumn<String>(
    'insight_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perspectiveIdMeta = const VerificationMeta(
    'perspectiveId',
  );
  @override
  late final GeneratedColumn<String> perspectiveId = GeneratedColumn<String>(
    'perspective_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perspectiveNameMeta = const VerificationMeta(
    'perspectiveName',
  );
  @override
  late final GeneratedColumn<String> perspectiveName = GeneratedColumn<String>(
    'perspective_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perspectiveIconMeta = const VerificationMeta(
    'perspectiveIcon',
  );
  @override
  late final GeneratedColumn<String> perspectiveIcon = GeneratedColumn<String>(
    'perspective_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeRangeLabelMeta = const VerificationMeta(
    'timeRangeLabel',
  );
  @override
  late final GeneratedColumn<String> timeRangeLabel = GeneratedColumn<String>(
    'time_range_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assistantFilterMeta = const VerificationMeta(
    'assistantFilter',
  );
  @override
  late final GeneratedColumn<String> assistantFilter = GeneratedColumn<String>(
    'assistant_filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryCountMeta = const VerificationMeta(
    'queryCount',
  );
  @override
  late final GeneratedColumn<int> queryCount = GeneratedColumn<int>(
    'query_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charCountMeta = const VerificationMeta(
    'charCount',
  );
  @override
  late final GeneratedColumn<int> charCount = GeneratedColumn<int>(
    'char_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    insightId,
    perspectiveId,
    perspectiveName,
    perspectiveIcon,
    timeRangeLabel,
    assistantFilter,
    queryCount,
    charCount,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'insights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Insight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('insight_id')) {
      context.handle(
        _insightIdMeta,
        insightId.isAcceptableOrUnknown(data['insight_id']!, _insightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_insightIdMeta);
    }
    if (data.containsKey('perspective_id')) {
      context.handle(
        _perspectiveIdMeta,
        perspectiveId.isAcceptableOrUnknown(
          data['perspective_id']!,
          _perspectiveIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perspectiveIdMeta);
    }
    if (data.containsKey('perspective_name')) {
      context.handle(
        _perspectiveNameMeta,
        perspectiveName.isAcceptableOrUnknown(
          data['perspective_name']!,
          _perspectiveNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perspectiveNameMeta);
    }
    if (data.containsKey('perspective_icon')) {
      context.handle(
        _perspectiveIconMeta,
        perspectiveIcon.isAcceptableOrUnknown(
          data['perspective_icon']!,
          _perspectiveIconMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perspectiveIconMeta);
    }
    if (data.containsKey('time_range_label')) {
      context.handle(
        _timeRangeLabelMeta,
        timeRangeLabel.isAcceptableOrUnknown(
          data['time_range_label']!,
          _timeRangeLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeRangeLabelMeta);
    }
    if (data.containsKey('assistant_filter')) {
      context.handle(
        _assistantFilterMeta,
        assistantFilter.isAcceptableOrUnknown(
          data['assistant_filter']!,
          _assistantFilterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assistantFilterMeta);
    }
    if (data.containsKey('query_count')) {
      context.handle(
        _queryCountMeta,
        queryCount.isAcceptableOrUnknown(data['query_count']!, _queryCountMeta),
      );
    } else if (isInserting) {
      context.missing(_queryCountMeta);
    }
    if (data.containsKey('char_count')) {
      context.handle(
        _charCountMeta,
        charCount.isAcceptableOrUnknown(data['char_count']!, _charCountMeta),
      );
    } else if (isInserting) {
      context.missing(_charCountMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {insightId};
  @override
  Insight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Insight(
      insightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight_id'],
      )!,
      perspectiveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perspective_id'],
      )!,
      perspectiveName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perspective_name'],
      )!,
      perspectiveIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perspective_icon'],
      )!,
      timeRangeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_range_label'],
      )!,
      assistantFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assistant_filter'],
      )!,
      queryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}query_count'],
      )!,
      charCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_count'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InsightsTable createAlias(String alias) {
    return $InsightsTable(attachedDatabase, alias);
  }
}

class Insight extends DataClass implements Insertable<Insight> {
  final String insightId;
  final String perspectiveId;
  final String perspectiveName;
  final String perspectiveIcon;
  final String timeRangeLabel;
  final String assistantFilter;
  final int queryCount;
  final int charCount;
  final String content;
  final int createdAt;
  const Insight({
    required this.insightId,
    required this.perspectiveId,
    required this.perspectiveName,
    required this.perspectiveIcon,
    required this.timeRangeLabel,
    required this.assistantFilter,
    required this.queryCount,
    required this.charCount,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['insight_id'] = Variable<String>(insightId);
    map['perspective_id'] = Variable<String>(perspectiveId);
    map['perspective_name'] = Variable<String>(perspectiveName);
    map['perspective_icon'] = Variable<String>(perspectiveIcon);
    map['time_range_label'] = Variable<String>(timeRangeLabel);
    map['assistant_filter'] = Variable<String>(assistantFilter);
    map['query_count'] = Variable<int>(queryCount);
    map['char_count'] = Variable<int>(charCount);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  InsightsCompanion toCompanion(bool nullToAbsent) {
    return InsightsCompanion(
      insightId: Value(insightId),
      perspectiveId: Value(perspectiveId),
      perspectiveName: Value(perspectiveName),
      perspectiveIcon: Value(perspectiveIcon),
      timeRangeLabel: Value(timeRangeLabel),
      assistantFilter: Value(assistantFilter),
      queryCount: Value(queryCount),
      charCount: Value(charCount),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory Insight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Insight(
      insightId: serializer.fromJson<String>(json['insightId']),
      perspectiveId: serializer.fromJson<String>(json['perspectiveId']),
      perspectiveName: serializer.fromJson<String>(json['perspectiveName']),
      perspectiveIcon: serializer.fromJson<String>(json['perspectiveIcon']),
      timeRangeLabel: serializer.fromJson<String>(json['timeRangeLabel']),
      assistantFilter: serializer.fromJson<String>(json['assistantFilter']),
      queryCount: serializer.fromJson<int>(json['queryCount']),
      charCount: serializer.fromJson<int>(json['charCount']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'insightId': serializer.toJson<String>(insightId),
      'perspectiveId': serializer.toJson<String>(perspectiveId),
      'perspectiveName': serializer.toJson<String>(perspectiveName),
      'perspectiveIcon': serializer.toJson<String>(perspectiveIcon),
      'timeRangeLabel': serializer.toJson<String>(timeRangeLabel),
      'assistantFilter': serializer.toJson<String>(assistantFilter),
      'queryCount': serializer.toJson<int>(queryCount),
      'charCount': serializer.toJson<int>(charCount),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Insight copyWith({
    String? insightId,
    String? perspectiveId,
    String? perspectiveName,
    String? perspectiveIcon,
    String? timeRangeLabel,
    String? assistantFilter,
    int? queryCount,
    int? charCount,
    String? content,
    int? createdAt,
  }) => Insight(
    insightId: insightId ?? this.insightId,
    perspectiveId: perspectiveId ?? this.perspectiveId,
    perspectiveName: perspectiveName ?? this.perspectiveName,
    perspectiveIcon: perspectiveIcon ?? this.perspectiveIcon,
    timeRangeLabel: timeRangeLabel ?? this.timeRangeLabel,
    assistantFilter: assistantFilter ?? this.assistantFilter,
    queryCount: queryCount ?? this.queryCount,
    charCount: charCount ?? this.charCount,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  Insight copyWithCompanion(InsightsCompanion data) {
    return Insight(
      insightId: data.insightId.present ? data.insightId.value : this.insightId,
      perspectiveId: data.perspectiveId.present
          ? data.perspectiveId.value
          : this.perspectiveId,
      perspectiveName: data.perspectiveName.present
          ? data.perspectiveName.value
          : this.perspectiveName,
      perspectiveIcon: data.perspectiveIcon.present
          ? data.perspectiveIcon.value
          : this.perspectiveIcon,
      timeRangeLabel: data.timeRangeLabel.present
          ? data.timeRangeLabel.value
          : this.timeRangeLabel,
      assistantFilter: data.assistantFilter.present
          ? data.assistantFilter.value
          : this.assistantFilter,
      queryCount: data.queryCount.present
          ? data.queryCount.value
          : this.queryCount,
      charCount: data.charCount.present ? data.charCount.value : this.charCount,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Insight(')
          ..write('insightId: $insightId, ')
          ..write('perspectiveId: $perspectiveId, ')
          ..write('perspectiveName: $perspectiveName, ')
          ..write('perspectiveIcon: $perspectiveIcon, ')
          ..write('timeRangeLabel: $timeRangeLabel, ')
          ..write('assistantFilter: $assistantFilter, ')
          ..write('queryCount: $queryCount, ')
          ..write('charCount: $charCount, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    insightId,
    perspectiveId,
    perspectiveName,
    perspectiveIcon,
    timeRangeLabel,
    assistantFilter,
    queryCount,
    charCount,
    content,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Insight &&
          other.insightId == this.insightId &&
          other.perspectiveId == this.perspectiveId &&
          other.perspectiveName == this.perspectiveName &&
          other.perspectiveIcon == this.perspectiveIcon &&
          other.timeRangeLabel == this.timeRangeLabel &&
          other.assistantFilter == this.assistantFilter &&
          other.queryCount == this.queryCount &&
          other.charCount == this.charCount &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class InsightsCompanion extends UpdateCompanion<Insight> {
  final Value<String> insightId;
  final Value<String> perspectiveId;
  final Value<String> perspectiveName;
  final Value<String> perspectiveIcon;
  final Value<String> timeRangeLabel;
  final Value<String> assistantFilter;
  final Value<int> queryCount;
  final Value<int> charCount;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<int> rowid;
  const InsightsCompanion({
    this.insightId = const Value.absent(),
    this.perspectiveId = const Value.absent(),
    this.perspectiveName = const Value.absent(),
    this.perspectiveIcon = const Value.absent(),
    this.timeRangeLabel = const Value.absent(),
    this.assistantFilter = const Value.absent(),
    this.queryCount = const Value.absent(),
    this.charCount = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InsightsCompanion.insert({
    required String insightId,
    required String perspectiveId,
    required String perspectiveName,
    required String perspectiveIcon,
    required String timeRangeLabel,
    required String assistantFilter,
    required int queryCount,
    required int charCount,
    required String content,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : insightId = Value(insightId),
       perspectiveId = Value(perspectiveId),
       perspectiveName = Value(perspectiveName),
       perspectiveIcon = Value(perspectiveIcon),
       timeRangeLabel = Value(timeRangeLabel),
       assistantFilter = Value(assistantFilter),
       queryCount = Value(queryCount),
       charCount = Value(charCount),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<Insight> custom({
    Expression<String>? insightId,
    Expression<String>? perspectiveId,
    Expression<String>? perspectiveName,
    Expression<String>? perspectiveIcon,
    Expression<String>? timeRangeLabel,
    Expression<String>? assistantFilter,
    Expression<int>? queryCount,
    Expression<int>? charCount,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (insightId != null) 'insight_id': insightId,
      if (perspectiveId != null) 'perspective_id': perspectiveId,
      if (perspectiveName != null) 'perspective_name': perspectiveName,
      if (perspectiveIcon != null) 'perspective_icon': perspectiveIcon,
      if (timeRangeLabel != null) 'time_range_label': timeRangeLabel,
      if (assistantFilter != null) 'assistant_filter': assistantFilter,
      if (queryCount != null) 'query_count': queryCount,
      if (charCount != null) 'char_count': charCount,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InsightsCompanion copyWith({
    Value<String>? insightId,
    Value<String>? perspectiveId,
    Value<String>? perspectiveName,
    Value<String>? perspectiveIcon,
    Value<String>? timeRangeLabel,
    Value<String>? assistantFilter,
    Value<int>? queryCount,
    Value<int>? charCount,
    Value<String>? content,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return InsightsCompanion(
      insightId: insightId ?? this.insightId,
      perspectiveId: perspectiveId ?? this.perspectiveId,
      perspectiveName: perspectiveName ?? this.perspectiveName,
      perspectiveIcon: perspectiveIcon ?? this.perspectiveIcon,
      timeRangeLabel: timeRangeLabel ?? this.timeRangeLabel,
      assistantFilter: assistantFilter ?? this.assistantFilter,
      queryCount: queryCount ?? this.queryCount,
      charCount: charCount ?? this.charCount,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (insightId.present) {
      map['insight_id'] = Variable<String>(insightId.value);
    }
    if (perspectiveId.present) {
      map['perspective_id'] = Variable<String>(perspectiveId.value);
    }
    if (perspectiveName.present) {
      map['perspective_name'] = Variable<String>(perspectiveName.value);
    }
    if (perspectiveIcon.present) {
      map['perspective_icon'] = Variable<String>(perspectiveIcon.value);
    }
    if (timeRangeLabel.present) {
      map['time_range_label'] = Variable<String>(timeRangeLabel.value);
    }
    if (assistantFilter.present) {
      map['assistant_filter'] = Variable<String>(assistantFilter.value);
    }
    if (queryCount.present) {
      map['query_count'] = Variable<int>(queryCount.value);
    }
    if (charCount.present) {
      map['char_count'] = Variable<int>(charCount.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsightsCompanion(')
          ..write('insightId: $insightId, ')
          ..write('perspectiveId: $perspectiveId, ')
          ..write('perspectiveName: $perspectiveName, ')
          ..write('perspectiveIcon: $perspectiveIcon, ')
          ..write('timeRangeLabel: $timeRangeLabel, ')
          ..write('assistantFilter: $assistantFilter, ')
          ..write('queryCount: $queryCount, ')
          ..write('charCount: $charCount, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $AiAnalysesTable aiAnalyses = $AiAnalysesTable(this);
  late final $KnowledgeEntriesTable knowledgeEntries = $KnowledgeEntriesTable(
    this,
  );
  late final $DiscussionsTable discussions = $DiscussionsTable(this);
  late final $DiscussionMessagesTable discussionMessages =
      $DiscussionMessagesTable(this);
  late final $UnifiedConversationsTable unifiedConversations =
      $UnifiedConversationsTable(this);
  late final $UnifiedMessagesTable unifiedMessages = $UnifiedMessagesTable(
    this,
  );
  late final $UserPreferencesTable userPreferences = $UserPreferencesTable(
    this,
  );
  late final $TaskTemplatesTable taskTemplates = $TaskTemplatesTable(this);
  late final $PerspectivesTable perspectives = $PerspectivesTable(this);
  late final $InsightsTable insights = $InsightsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    aiAnalyses,
    knowledgeEntries,
    discussions,
    discussionMessages,
    unifiedConversations,
    unifiedMessages,
    userPreferences,
    taskTemplates,
    perspectives,
    insights,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'discussions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('discussion_messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'unified_conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('unified_messages', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AiAnalysesTableCreateCompanionBuilder =
    AiAnalysesCompanion Function({
      required String topicId,
      required int groupIndex,
      required String content,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$AiAnalysesTableUpdateCompanionBuilder =
    AiAnalysesCompanion Function({
      Value<String> topicId,
      Value<int> groupIndex,
      Value<String> content,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$AiAnalysesTableFilterComposer
    extends Composer<_$UserDatabase, $AiAnalysesTable> {
  $$AiAnalysesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupIndex => $composableBuilder(
    column: $table.groupIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiAnalysesTableOrderingComposer
    extends Composer<_$UserDatabase, $AiAnalysesTable> {
  $$AiAnalysesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupIndex => $composableBuilder(
    column: $table.groupIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiAnalysesTableAnnotationComposer
    extends Composer<_$UserDatabase, $AiAnalysesTable> {
  $$AiAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get groupIndex => $composableBuilder(
    column: $table.groupIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiAnalysesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AiAnalysesTable,
          AiAnalyse,
          $$AiAnalysesTableFilterComposer,
          $$AiAnalysesTableOrderingComposer,
          $$AiAnalysesTableAnnotationComposer,
          $$AiAnalysesTableCreateCompanionBuilder,
          $$AiAnalysesTableUpdateCompanionBuilder,
          (
            AiAnalyse,
            BaseReferences<_$UserDatabase, $AiAnalysesTable, AiAnalyse>,
          ),
          AiAnalyse,
          PrefetchHooks Function()
        > {
  $$AiAnalysesTableTableManager(_$UserDatabase db, $AiAnalysesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiAnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> topicId = const Value.absent(),
                Value<int> groupIndex = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiAnalysesCompanion(
                topicId: topicId,
                groupIndex: groupIndex,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topicId,
                required int groupIndex,
                required String content,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AiAnalysesCompanion.insert(
                topicId: topicId,
                groupIndex: groupIndex,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiAnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AiAnalysesTable,
      AiAnalyse,
      $$AiAnalysesTableFilterComposer,
      $$AiAnalysesTableOrderingComposer,
      $$AiAnalysesTableAnnotationComposer,
      $$AiAnalysesTableCreateCompanionBuilder,
      $$AiAnalysesTableUpdateCompanionBuilder,
      (AiAnalyse, BaseReferences<_$UserDatabase, $AiAnalysesTable, AiAnalyse>),
      AiAnalyse,
      PrefetchHooks Function()
    >;
typedef $$KnowledgeEntriesTableCreateCompanionBuilder =
    KnowledgeEntriesCompanion Function({
      required String entryId,
      Value<String?> content,
      Value<String> contentType,
      Value<String?> plainText,
      Value<String?> quotedText,
      Value<int?> color,
      Value<String?> styleType,
      Value<String?> messageId,
      Value<String?> topicId,
      Value<String?> topicName,
      Value<String?> prefix,
      Value<String?> suffix,
      Value<int?> start,
      Value<int?> end,
      Value<String> tagsJson,
      required int createdAt,
      required int updatedAt,
      Value<int?> blockIndex,
      Value<String?> blockContentHash,
      Value<int?> blockInternalStart,
      Value<int?> blockInternalEnd,
      Value<String?> groupId,
      Value<String?> selections,
      Value<int> reviewCount,
      Value<int?> lastReviewedAt,
      Value<int> importance,
      Value<bool> isPinned,
      Value<int> rowid,
    });
typedef $$KnowledgeEntriesTableUpdateCompanionBuilder =
    KnowledgeEntriesCompanion Function({
      Value<String> entryId,
      Value<String?> content,
      Value<String> contentType,
      Value<String?> plainText,
      Value<String?> quotedText,
      Value<int?> color,
      Value<String?> styleType,
      Value<String?> messageId,
      Value<String?> topicId,
      Value<String?> topicName,
      Value<String?> prefix,
      Value<String?> suffix,
      Value<int?> start,
      Value<int?> end,
      Value<String> tagsJson,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> blockIndex,
      Value<String?> blockContentHash,
      Value<int?> blockInternalStart,
      Value<int?> blockInternalEnd,
      Value<String?> groupId,
      Value<String?> selections,
      Value<int> reviewCount,
      Value<int?> lastReviewedAt,
      Value<int> importance,
      Value<bool> isPinned,
      Value<int> rowid,
    });

class $$KnowledgeEntriesTableFilterComposer
    extends Composer<_$UserDatabase, $KnowledgeEntriesTable> {
  $$KnowledgeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotedText => $composableBuilder(
    column: $table.quotedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get styleType => $composableBuilder(
    column: $table.styleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicName => $composableBuilder(
    column: $table.topicName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suffix => $composableBuilder(
    column: $table.suffix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockIndex => $composableBuilder(
    column: $table.blockIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockContentHash => $composableBuilder(
    column: $table.blockContentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockInternalStart => $composableBuilder(
    column: $table.blockInternalStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockInternalEnd => $composableBuilder(
    column: $table.blockInternalEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selections => $composableBuilder(
    column: $table.selections,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KnowledgeEntriesTableOrderingComposer
    extends Composer<_$UserDatabase, $KnowledgeEntriesTable> {
  $$KnowledgeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotedText => $composableBuilder(
    column: $table.quotedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styleType => $composableBuilder(
    column: $table.styleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicName => $composableBuilder(
    column: $table.topicName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suffix => $composableBuilder(
    column: $table.suffix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockIndex => $composableBuilder(
    column: $table.blockIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockContentHash => $composableBuilder(
    column: $table.blockContentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockInternalStart => $composableBuilder(
    column: $table.blockInternalStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockInternalEnd => $composableBuilder(
    column: $table.blockInternalEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selections => $composableBuilder(
    column: $table.selections,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnowledgeEntriesTableAnnotationComposer
    extends Composer<_$UserDatabase, $KnowledgeEntriesTable> {
  $$KnowledgeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<String> get quotedText => $composableBuilder(
    column: $table.quotedText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get styleType =>
      $composableBuilder(column: $table.styleType, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get topicName =>
      $composableBuilder(column: $table.topicName, builder: (column) => column);

  GeneratedColumn<String> get prefix =>
      $composableBuilder(column: $table.prefix, builder: (column) => column);

  GeneratedColumn<String> get suffix =>
      $composableBuilder(column: $table.suffix, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get blockIndex => $composableBuilder(
    column: $table.blockIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blockContentHash => $composableBuilder(
    column: $table.blockContentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blockInternalStart => $composableBuilder(
    column: $table.blockInternalStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blockInternalEnd => $composableBuilder(
    column: $table.blockInternalEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get selections => $composableBuilder(
    column: $table.selections,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);
}

class $$KnowledgeEntriesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $KnowledgeEntriesTable,
          KnowledgeEntryRow,
          $$KnowledgeEntriesTableFilterComposer,
          $$KnowledgeEntriesTableOrderingComposer,
          $$KnowledgeEntriesTableAnnotationComposer,
          $$KnowledgeEntriesTableCreateCompanionBuilder,
          $$KnowledgeEntriesTableUpdateCompanionBuilder,
          (
            KnowledgeEntryRow,
            BaseReferences<
              _$UserDatabase,
              $KnowledgeEntriesTable,
              KnowledgeEntryRow
            >,
          ),
          KnowledgeEntryRow,
          PrefetchHooks Function()
        > {
  $$KnowledgeEntriesTableTableManager(
    _$UserDatabase db,
    $KnowledgeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> plainText = const Value.absent(),
                Value<String?> quotedText = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> styleType = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<String?> topicName = const Value.absent(),
                Value<String?> prefix = const Value.absent(),
                Value<String?> suffix = const Value.absent(),
                Value<int?> start = const Value.absent(),
                Value<int?> end = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> blockIndex = const Value.absent(),
                Value<String?> blockContentHash = const Value.absent(),
                Value<int?> blockInternalStart = const Value.absent(),
                Value<int?> blockInternalEnd = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> selections = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int?> lastReviewedAt = const Value.absent(),
                Value<int> importance = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnowledgeEntriesCompanion(
                entryId: entryId,
                content: content,
                contentType: contentType,
                plainText: plainText,
                quotedText: quotedText,
                color: color,
                styleType: styleType,
                messageId: messageId,
                topicId: topicId,
                topicName: topicName,
                prefix: prefix,
                suffix: suffix,
                start: start,
                end: end,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                blockIndex: blockIndex,
                blockContentHash: blockContentHash,
                blockInternalStart: blockInternalStart,
                blockInternalEnd: blockInternalEnd,
                groupId: groupId,
                selections: selections,
                reviewCount: reviewCount,
                lastReviewedAt: lastReviewedAt,
                importance: importance,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                Value<String?> content = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> plainText = const Value.absent(),
                Value<String?> quotedText = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> styleType = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<String?> topicName = const Value.absent(),
                Value<String?> prefix = const Value.absent(),
                Value<String?> suffix = const Value.absent(),
                Value<int?> start = const Value.absent(),
                Value<int?> end = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> blockIndex = const Value.absent(),
                Value<String?> blockContentHash = const Value.absent(),
                Value<int?> blockInternalStart = const Value.absent(),
                Value<int?> blockInternalEnd = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> selections = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int?> lastReviewedAt = const Value.absent(),
                Value<int> importance = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnowledgeEntriesCompanion.insert(
                entryId: entryId,
                content: content,
                contentType: contentType,
                plainText: plainText,
                quotedText: quotedText,
                color: color,
                styleType: styleType,
                messageId: messageId,
                topicId: topicId,
                topicName: topicName,
                prefix: prefix,
                suffix: suffix,
                start: start,
                end: end,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                blockIndex: blockIndex,
                blockContentHash: blockContentHash,
                blockInternalStart: blockInternalStart,
                blockInternalEnd: blockInternalEnd,
                groupId: groupId,
                selections: selections,
                reviewCount: reviewCount,
                lastReviewedAt: lastReviewedAt,
                importance: importance,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnowledgeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $KnowledgeEntriesTable,
      KnowledgeEntryRow,
      $$KnowledgeEntriesTableFilterComposer,
      $$KnowledgeEntriesTableOrderingComposer,
      $$KnowledgeEntriesTableAnnotationComposer,
      $$KnowledgeEntriesTableCreateCompanionBuilder,
      $$KnowledgeEntriesTableUpdateCompanionBuilder,
      (
        KnowledgeEntryRow,
        BaseReferences<
          _$UserDatabase,
          $KnowledgeEntriesTable,
          KnowledgeEntryRow
        >,
      ),
      KnowledgeEntryRow,
      PrefetchHooks Function()
    >;
typedef $$DiscussionsTableCreateCompanionBuilder =
    DiscussionsCompanion Function({
      required String discussionId,
      required String messageId,
      required String title,
      Value<int> messageCount,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DiscussionsTableUpdateCompanionBuilder =
    DiscussionsCompanion Function({
      Value<String> discussionId,
      Value<String> messageId,
      Value<String> title,
      Value<int> messageCount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$DiscussionsTableReferences
    extends BaseReferences<_$UserDatabase, $DiscussionsTable, Discussion> {
  $$DiscussionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DiscussionMessagesTable, List<DiscussionMessage>>
  _discussionMessagesRefsTable(_$UserDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.discussionMessages,
        aliasName: $_aliasNameGenerator(
          db.discussions.discussionId,
          db.discussionMessages.discussionId,
        ),
      );

  $$DiscussionMessagesTableProcessedTableManager get discussionMessagesRefs {
    final manager =
        $$DiscussionMessagesTableTableManager(
          $_db,
          $_db.discussionMessages,
        ).filter(
          (f) => f.discussionId.discussionId.sqlEquals(
            $_itemColumn<String>('discussion_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _discussionMessagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiscussionsTableFilterComposer
    extends Composer<_$UserDatabase, $DiscussionsTable> {
  $$DiscussionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get discussionId => $composableBuilder(
    column: $table.discussionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> discussionMessagesRefs(
    Expression<bool> Function($$DiscussionMessagesTableFilterComposer f) f,
  ) {
    final $$DiscussionMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.discussionId,
      referencedTable: $db.discussionMessages,
      getReferencedColumn: (t) => t.discussionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiscussionMessagesTableFilterComposer(
            $db: $db,
            $table: $db.discussionMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiscussionsTableOrderingComposer
    extends Composer<_$UserDatabase, $DiscussionsTable> {
  $$DiscussionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get discussionId => $composableBuilder(
    column: $table.discussionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiscussionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $DiscussionsTable> {
  $$DiscussionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get discussionId => $composableBuilder(
    column: $table.discussionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> discussionMessagesRefs<T extends Object>(
    Expression<T> Function($$DiscussionMessagesTableAnnotationComposer a) f,
  ) {
    final $$DiscussionMessagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.discussionId,
          referencedTable: $db.discussionMessages,
          getReferencedColumn: (t) => t.discussionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiscussionMessagesTableAnnotationComposer(
                $db: $db,
                $table: $db.discussionMessages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DiscussionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $DiscussionsTable,
          Discussion,
          $$DiscussionsTableFilterComposer,
          $$DiscussionsTableOrderingComposer,
          $$DiscussionsTableAnnotationComposer,
          $$DiscussionsTableCreateCompanionBuilder,
          $$DiscussionsTableUpdateCompanionBuilder,
          (Discussion, $$DiscussionsTableReferences),
          Discussion,
          PrefetchHooks Function({bool discussionMessagesRefs})
        > {
  $$DiscussionsTableTableManager(_$UserDatabase db, $DiscussionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscussionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscussionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscussionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> discussionId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiscussionsCompanion(
                discussionId: discussionId,
                messageId: messageId,
                title: title,
                messageCount: messageCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String discussionId,
                required String messageId,
                required String title,
                Value<int> messageCount = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DiscussionsCompanion.insert(
                discussionId: discussionId,
                messageId: messageId,
                title: title,
                messageCount: messageCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiscussionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({discussionMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (discussionMessagesRefs) db.discussionMessages,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (discussionMessagesRefs)
                    await $_getPrefetchedData<
                      Discussion,
                      $DiscussionsTable,
                      DiscussionMessage
                    >(
                      currentTable: table,
                      referencedTable: $$DiscussionsTableReferences
                          ._discussionMessagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DiscussionsTableReferences(
                            db,
                            table,
                            p0,
                          ).discussionMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.discussionId == item.discussionId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DiscussionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $DiscussionsTable,
      Discussion,
      $$DiscussionsTableFilterComposer,
      $$DiscussionsTableOrderingComposer,
      $$DiscussionsTableAnnotationComposer,
      $$DiscussionsTableCreateCompanionBuilder,
      $$DiscussionsTableUpdateCompanionBuilder,
      (Discussion, $$DiscussionsTableReferences),
      Discussion,
      PrefetchHooks Function({bool discussionMessagesRefs})
    >;
typedef $$DiscussionMessagesTableCreateCompanionBuilder =
    DiscussionMessagesCompanion Function({
      required String messageId,
      required String discussionId,
      required String role,
      required String content,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$DiscussionMessagesTableUpdateCompanionBuilder =
    DiscussionMessagesCompanion Function({
      Value<String> messageId,
      Value<String> discussionId,
      Value<String> role,
      Value<String> content,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$DiscussionMessagesTableReferences
    extends
        BaseReferences<
          _$UserDatabase,
          $DiscussionMessagesTable,
          DiscussionMessage
        > {
  $$DiscussionMessagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiscussionsTable _discussionIdTable(_$UserDatabase db) =>
      db.discussions.createAlias(
        $_aliasNameGenerator(
          db.discussionMessages.discussionId,
          db.discussions.discussionId,
        ),
      );

  $$DiscussionsTableProcessedTableManager get discussionId {
    final $_column = $_itemColumn<String>('discussion_id')!;

    final manager = $$DiscussionsTableTableManager(
      $_db,
      $_db.discussions,
    ).filter((f) => f.discussionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_discussionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiscussionMessagesTableFilterComposer
    extends Composer<_$UserDatabase, $DiscussionMessagesTable> {
  $$DiscussionMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DiscussionsTableFilterComposer get discussionId {
    final $$DiscussionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.discussionId,
      referencedTable: $db.discussions,
      getReferencedColumn: (t) => t.discussionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiscussionsTableFilterComposer(
            $db: $db,
            $table: $db.discussions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiscussionMessagesTableOrderingComposer
    extends Composer<_$UserDatabase, $DiscussionMessagesTable> {
  $$DiscussionMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiscussionsTableOrderingComposer get discussionId {
    final $$DiscussionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.discussionId,
      referencedTable: $db.discussions,
      getReferencedColumn: (t) => t.discussionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiscussionsTableOrderingComposer(
            $db: $db,
            $table: $db.discussions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiscussionMessagesTableAnnotationComposer
    extends Composer<_$UserDatabase, $DiscussionMessagesTable> {
  $$DiscussionMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DiscussionsTableAnnotationComposer get discussionId {
    final $$DiscussionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.discussionId,
      referencedTable: $db.discussions,
      getReferencedColumn: (t) => t.discussionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiscussionsTableAnnotationComposer(
            $db: $db,
            $table: $db.discussions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiscussionMessagesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $DiscussionMessagesTable,
          DiscussionMessage,
          $$DiscussionMessagesTableFilterComposer,
          $$DiscussionMessagesTableOrderingComposer,
          $$DiscussionMessagesTableAnnotationComposer,
          $$DiscussionMessagesTableCreateCompanionBuilder,
          $$DiscussionMessagesTableUpdateCompanionBuilder,
          (DiscussionMessage, $$DiscussionMessagesTableReferences),
          DiscussionMessage,
          PrefetchHooks Function({bool discussionId})
        > {
  $$DiscussionMessagesTableTableManager(
    _$UserDatabase db,
    $DiscussionMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscussionMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscussionMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscussionMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> discussionId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiscussionMessagesCompanion(
                messageId: messageId,
                discussionId: discussionId,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String discussionId,
                required String role,
                required String content,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DiscussionMessagesCompanion.insert(
                messageId: messageId,
                discussionId: discussionId,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiscussionMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({discussionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (discussionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.discussionId,
                                referencedTable:
                                    $$DiscussionMessagesTableReferences
                                        ._discussionIdTable(db),
                                referencedColumn:
                                    $$DiscussionMessagesTableReferences
                                        ._discussionIdTable(db)
                                        .discussionId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiscussionMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $DiscussionMessagesTable,
      DiscussionMessage,
      $$DiscussionMessagesTableFilterComposer,
      $$DiscussionMessagesTableOrderingComposer,
      $$DiscussionMessagesTableAnnotationComposer,
      $$DiscussionMessagesTableCreateCompanionBuilder,
      $$DiscussionMessagesTableUpdateCompanionBuilder,
      (DiscussionMessage, $$DiscussionMessagesTableReferences),
      DiscussionMessage,
      PrefetchHooks Function({bool discussionId})
    >;
typedef $$UnifiedConversationsTableCreateCompanionBuilder =
    UnifiedConversationsCompanion Function({
      required String conversationId,
      required String title,
      required String contextType,
      required String contextId,
      Value<String?> contextSnapshot,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<int> messageCount,
      Value<int> roundCount,
      required int createdAt,
      required int updatedAt,
      Value<bool> isArchived,
      Value<bool> isPinned,
      Value<int> rowid,
    });
typedef $$UnifiedConversationsTableUpdateCompanionBuilder =
    UnifiedConversationsCompanion Function({
      Value<String> conversationId,
      Value<String> title,
      Value<String> contextType,
      Value<String> contextId,
      Value<String?> contextSnapshot,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<int> messageCount,
      Value<int> roundCount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<bool> isArchived,
      Value<bool> isPinned,
      Value<int> rowid,
    });

final class $$UnifiedConversationsTableReferences
    extends
        BaseReferences<
          _$UserDatabase,
          $UnifiedConversationsTable,
          UnifiedConversation
        > {
  $$UnifiedConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$UnifiedMessagesTable, List<UnifiedMessage>>
  _unifiedMessagesRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.unifiedMessages,
    aliasName: $_aliasNameGenerator(
      db.unifiedConversations.conversationId,
      db.unifiedMessages.conversationId,
    ),
  );

  $$UnifiedMessagesTableProcessedTableManager get unifiedMessagesRefs {
    final manager =
        $$UnifiedMessagesTableTableManager($_db, $_db.unifiedMessages).filter(
          (f) => f.conversationId.conversationId.sqlEquals(
            $_itemColumn<String>('conversation_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _unifiedMessagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UnifiedConversationsTableFilterComposer
    extends Composer<_$UserDatabase, $UnifiedConversationsTable> {
  $$UnifiedConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextType => $composableBuilder(
    column: $table.contextType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextId => $composableBuilder(
    column: $table.contextId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextSnapshot => $composableBuilder(
    column: $table.contextSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> unifiedMessagesRefs(
    Expression<bool> Function($$UnifiedMessagesTableFilterComposer f) f,
  ) {
    final $$UnifiedMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.unifiedMessages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnifiedMessagesTableFilterComposer(
            $db: $db,
            $table: $db.unifiedMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UnifiedConversationsTableOrderingComposer
    extends Composer<_$UserDatabase, $UnifiedConversationsTable> {
  $$UnifiedConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextType => $composableBuilder(
    column: $table.contextType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextId => $composableBuilder(
    column: $table.contextId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextSnapshot => $composableBuilder(
    column: $table.contextSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnifiedConversationsTableAnnotationComposer
    extends Composer<_$UserDatabase, $UnifiedConversationsTable> {
  $$UnifiedConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get contextType => $composableBuilder(
    column: $table.contextType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextId =>
      $composableBuilder(column: $table.contextId, builder: (column) => column);

  GeneratedColumn<String> get contextSnapshot => $composableBuilder(
    column: $table.contextSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundCount => $composableBuilder(
    column: $table.roundCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  Expression<T> unifiedMessagesRefs<T extends Object>(
    Expression<T> Function($$UnifiedMessagesTableAnnotationComposer a) f,
  ) {
    final $$UnifiedMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.unifiedMessages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnifiedMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.unifiedMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UnifiedConversationsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UnifiedConversationsTable,
          UnifiedConversation,
          $$UnifiedConversationsTableFilterComposer,
          $$UnifiedConversationsTableOrderingComposer,
          $$UnifiedConversationsTableAnnotationComposer,
          $$UnifiedConversationsTableCreateCompanionBuilder,
          $$UnifiedConversationsTableUpdateCompanionBuilder,
          (UnifiedConversation, $$UnifiedConversationsTableReferences),
          UnifiedConversation,
          PrefetchHooks Function({bool unifiedMessagesRefs})
        > {
  $$UnifiedConversationsTableTableManager(
    _$UserDatabase db,
    $UnifiedConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnifiedConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnifiedConversationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UnifiedConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> conversationId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> contextType = const Value.absent(),
                Value<String> contextId = const Value.absent(),
                Value<String?> contextSnapshot = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> roundCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnifiedConversationsCompanion(
                conversationId: conversationId,
                title: title,
                contextType: contextType,
                contextId: contextId,
                contextSnapshot: contextSnapshot,
                providerId: providerId,
                modelId: modelId,
                messageCount: messageCount,
                roundCount: roundCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversationId,
                required String title,
                required String contextType,
                required String contextId,
                Value<String?> contextSnapshot = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> roundCount = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnifiedConversationsCompanion.insert(
                conversationId: conversationId,
                title: title,
                contextType: contextType,
                contextId: contextId,
                contextSnapshot: contextSnapshot,
                providerId: providerId,
                modelId: modelId,
                messageCount: messageCount,
                roundCount: roundCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UnifiedConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({unifiedMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (unifiedMessagesRefs) db.unifiedMessages,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (unifiedMessagesRefs)
                    await $_getPrefetchedData<
                      UnifiedConversation,
                      $UnifiedConversationsTable,
                      UnifiedMessage
                    >(
                      currentTable: table,
                      referencedTable: $$UnifiedConversationsTableReferences
                          ._unifiedMessagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UnifiedConversationsTableReferences(
                            db,
                            table,
                            p0,
                          ).unifiedMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.conversationId == item.conversationId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UnifiedConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UnifiedConversationsTable,
      UnifiedConversation,
      $$UnifiedConversationsTableFilterComposer,
      $$UnifiedConversationsTableOrderingComposer,
      $$UnifiedConversationsTableAnnotationComposer,
      $$UnifiedConversationsTableCreateCompanionBuilder,
      $$UnifiedConversationsTableUpdateCompanionBuilder,
      (UnifiedConversation, $$UnifiedConversationsTableReferences),
      UnifiedConversation,
      PrefetchHooks Function({bool unifiedMessagesRefs})
    >;
typedef $$UnifiedMessagesTableCreateCompanionBuilder =
    UnifiedMessagesCompanion Function({
      required String messageId,
      required String conversationId,
      required String role,
      required String content,
      Value<String?> modelId,
      Value<String?> modelName,
      Value<String?> askId,
      Value<bool> isMainline,
      Value<String?> usageJson,
      required int createdAt,
      required String status,
      Value<String?> errorMessage,
      Value<String?> templateId,
      Value<String?> templateName,
      Value<String?> templateSnapshot,
      Value<String?> contextSummary,
      Value<String?> contextContent,
      Value<String?> userQuery,
      Value<String?> contextDataJson,
      Value<int> rowid,
    });
typedef $$UnifiedMessagesTableUpdateCompanionBuilder =
    UnifiedMessagesCompanion Function({
      Value<String> messageId,
      Value<String> conversationId,
      Value<String> role,
      Value<String> content,
      Value<String?> modelId,
      Value<String?> modelName,
      Value<String?> askId,
      Value<bool> isMainline,
      Value<String?> usageJson,
      Value<int> createdAt,
      Value<String> status,
      Value<String?> errorMessage,
      Value<String?> templateId,
      Value<String?> templateName,
      Value<String?> templateSnapshot,
      Value<String?> contextSummary,
      Value<String?> contextContent,
      Value<String?> userQuery,
      Value<String?> contextDataJson,
      Value<int> rowid,
    });

final class $$UnifiedMessagesTableReferences
    extends
        BaseReferences<_$UserDatabase, $UnifiedMessagesTable, UnifiedMessage> {
  $$UnifiedMessagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UnifiedConversationsTable _conversationIdTable(_$UserDatabase db) =>
      db.unifiedConversations.createAlias(
        $_aliasNameGenerator(
          db.unifiedMessages.conversationId,
          db.unifiedConversations.conversationId,
        ),
      );

  $$UnifiedConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$UnifiedConversationsTableTableManager(
      $_db,
      $_db.unifiedConversations,
    ).filter((f) => f.conversationId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UnifiedMessagesTableFilterComposer
    extends Composer<_$UserDatabase, $UnifiedMessagesTable> {
  $$UnifiedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get askId => $composableBuilder(
    column: $table.askId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMainline => $composableBuilder(
    column: $table.isMainline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usageJson => $composableBuilder(
    column: $table.usageJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextSummary => $composableBuilder(
    column: $table.contextSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextContent => $composableBuilder(
    column: $table.contextContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userQuery => $composableBuilder(
    column: $table.userQuery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextDataJson => $composableBuilder(
    column: $table.contextDataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$UnifiedConversationsTableFilterComposer get conversationId {
    final $$UnifiedConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.unifiedConversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnifiedConversationsTableFilterComposer(
            $db: $db,
            $table: $db.unifiedConversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UnifiedMessagesTableOrderingComposer
    extends Composer<_$UserDatabase, $UnifiedMessagesTable> {
  $$UnifiedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get askId => $composableBuilder(
    column: $table.askId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMainline => $composableBuilder(
    column: $table.isMainline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usageJson => $composableBuilder(
    column: $table.usageJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextSummary => $composableBuilder(
    column: $table.contextSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextContent => $composableBuilder(
    column: $table.contextContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userQuery => $composableBuilder(
    column: $table.userQuery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextDataJson => $composableBuilder(
    column: $table.contextDataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$UnifiedConversationsTableOrderingComposer get conversationId {
    final $$UnifiedConversationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.unifiedConversations,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UnifiedConversationsTableOrderingComposer(
                $db: $db,
                $table: $db.unifiedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$UnifiedMessagesTableAnnotationComposer
    extends Composer<_$UserDatabase, $UnifiedMessagesTable> {
  $$UnifiedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get askId =>
      $composableBuilder(column: $table.askId, builder: (column) => column);

  GeneratedColumn<bool> get isMainline => $composableBuilder(
    column: $table.isMainline,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usageJson =>
      $composableBuilder(column: $table.usageJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextSummary => $composableBuilder(
    column: $table.contextSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextContent => $composableBuilder(
    column: $table.contextContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userQuery =>
      $composableBuilder(column: $table.userQuery, builder: (column) => column);

  GeneratedColumn<String> get contextDataJson => $composableBuilder(
    column: $table.contextDataJson,
    builder: (column) => column,
  );

  $$UnifiedConversationsTableAnnotationComposer get conversationId {
    final $$UnifiedConversationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.unifiedConversations,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UnifiedConversationsTableAnnotationComposer(
                $db: $db,
                $table: $db.unifiedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$UnifiedMessagesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UnifiedMessagesTable,
          UnifiedMessage,
          $$UnifiedMessagesTableFilterComposer,
          $$UnifiedMessagesTableOrderingComposer,
          $$UnifiedMessagesTableAnnotationComposer,
          $$UnifiedMessagesTableCreateCompanionBuilder,
          $$UnifiedMessagesTableUpdateCompanionBuilder,
          (UnifiedMessage, $$UnifiedMessagesTableReferences),
          UnifiedMessage,
          PrefetchHooks Function({bool conversationId})
        > {
  $$UnifiedMessagesTableTableManager(
    _$UserDatabase db,
    $UnifiedMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnifiedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnifiedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnifiedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> askId = const Value.absent(),
                Value<bool> isMainline = const Value.absent(),
                Value<String?> usageJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String?> templateName = const Value.absent(),
                Value<String?> templateSnapshot = const Value.absent(),
                Value<String?> contextSummary = const Value.absent(),
                Value<String?> contextContent = const Value.absent(),
                Value<String?> userQuery = const Value.absent(),
                Value<String?> contextDataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnifiedMessagesCompanion(
                messageId: messageId,
                conversationId: conversationId,
                role: role,
                content: content,
                modelId: modelId,
                modelName: modelName,
                askId: askId,
                isMainline: isMainline,
                usageJson: usageJson,
                createdAt: createdAt,
                status: status,
                errorMessage: errorMessage,
                templateId: templateId,
                templateName: templateName,
                templateSnapshot: templateSnapshot,
                contextSummary: contextSummary,
                contextContent: contextContent,
                userQuery: userQuery,
                contextDataJson: contextDataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String conversationId,
                required String role,
                required String content,
                Value<String?> modelId = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> askId = const Value.absent(),
                Value<bool> isMainline = const Value.absent(),
                Value<String?> usageJson = const Value.absent(),
                required int createdAt,
                required String status,
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String?> templateName = const Value.absent(),
                Value<String?> templateSnapshot = const Value.absent(),
                Value<String?> contextSummary = const Value.absent(),
                Value<String?> contextContent = const Value.absent(),
                Value<String?> userQuery = const Value.absent(),
                Value<String?> contextDataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnifiedMessagesCompanion.insert(
                messageId: messageId,
                conversationId: conversationId,
                role: role,
                content: content,
                modelId: modelId,
                modelName: modelName,
                askId: askId,
                isMainline: isMainline,
                usageJson: usageJson,
                createdAt: createdAt,
                status: status,
                errorMessage: errorMessage,
                templateId: templateId,
                templateName: templateName,
                templateSnapshot: templateSnapshot,
                contextSummary: contextSummary,
                contextContent: contextContent,
                userQuery: userQuery,
                contextDataJson: contextDataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UnifiedMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable:
                                    $$UnifiedMessagesTableReferences
                                        ._conversationIdTable(db),
                                referencedColumn:
                                    $$UnifiedMessagesTableReferences
                                        ._conversationIdTable(db)
                                        .conversationId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UnifiedMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UnifiedMessagesTable,
      UnifiedMessage,
      $$UnifiedMessagesTableFilterComposer,
      $$UnifiedMessagesTableOrderingComposer,
      $$UnifiedMessagesTableAnnotationComposer,
      $$UnifiedMessagesTableCreateCompanionBuilder,
      $$UnifiedMessagesTableUpdateCompanionBuilder,
      (UnifiedMessage, $$UnifiedMessagesTableReferences),
      UnifiedMessage,
      PrefetchHooks Function({bool conversationId})
    >;
typedef $$UserPreferencesTableCreateCompanionBuilder =
    UserPreferencesCompanion Function({
      required String preferenceId,
      required String name,
      required String systemPrompt,
      Value<bool> isActive,
      Value<String?> defaultTemplateId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableUpdateCompanionBuilder =
    UserPreferencesCompanion Function({
      Value<String> preferenceId,
      Value<String> name,
      Value<String> systemPrompt,
      Value<bool> isActive,
      Value<String?> defaultTemplateId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$UserPreferencesTableFilterComposer
    extends Composer<_$UserDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get preferenceId => $composableBuilder(
    column: $table.preferenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultTemplateId => $composableBuilder(
    column: $table.defaultTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableOrderingComposer
    extends Composer<_$UserDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get preferenceId => $composableBuilder(
    column: $table.preferenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTemplateId => $composableBuilder(
    column: $table.defaultTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableAnnotationComposer
    extends Composer<_$UserDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get preferenceId => $composableBuilder(
    column: $table.preferenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get defaultTemplateId => $composableBuilder(
    column: $table.defaultTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserPreferencesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $UserPreferencesTable,
          UserPreference,
          $$UserPreferencesTableFilterComposer,
          $$UserPreferencesTableOrderingComposer,
          $$UserPreferencesTableAnnotationComposer,
          $$UserPreferencesTableCreateCompanionBuilder,
          $$UserPreferencesTableUpdateCompanionBuilder,
          (
            UserPreference,
            BaseReferences<
              _$UserDatabase,
              $UserPreferencesTable,
              UserPreference
            >,
          ),
          UserPreference,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableManager(
    _$UserDatabase db,
    $UserPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> preferenceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> systemPrompt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> defaultTemplateId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion(
                preferenceId: preferenceId,
                name: name,
                systemPrompt: systemPrompt,
                isActive: isActive,
                defaultTemplateId: defaultTemplateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String preferenceId,
                required String name,
                required String systemPrompt,
                Value<bool> isActive = const Value.absent(),
                Value<String?> defaultTemplateId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion.insert(
                preferenceId: preferenceId,
                name: name,
                systemPrompt: systemPrompt,
                isActive: isActive,
                defaultTemplateId: defaultTemplateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $UserPreferencesTable,
      UserPreference,
      $$UserPreferencesTableFilterComposer,
      $$UserPreferencesTableOrderingComposer,
      $$UserPreferencesTableAnnotationComposer,
      $$UserPreferencesTableCreateCompanionBuilder,
      $$UserPreferencesTableUpdateCompanionBuilder,
      (
        UserPreference,
        BaseReferences<_$UserDatabase, $UserPreferencesTable, UserPreference>,
      ),
      UserPreference,
      PrefetchHooks Function()
    >;
typedef $$TaskTemplatesTableCreateCompanionBuilder =
    TaskTemplatesCompanion Function({
      required String templateId,
      required String name,
      Value<String?> description,
      required String content,
      Value<bool> isBuiltIn,
      Value<int> usageCount,
      Value<String> targetType,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$TaskTemplatesTableUpdateCompanionBuilder =
    TaskTemplatesCompanion Function({
      Value<String> templateId,
      Value<String> name,
      Value<String?> description,
      Value<String> content,
      Value<bool> isBuiltIn,
      Value<int> usageCount,
      Value<String> targetType,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$TaskTemplatesTableFilterComposer
    extends Composer<_$UserDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskTemplatesTableOrderingComposer
    extends Composer<_$UserDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskTemplatesTableAnnotationComposer
    extends Composer<_$UserDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TaskTemplatesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $TaskTemplatesTable,
          TaskTemplate,
          $$TaskTemplatesTableFilterComposer,
          $$TaskTemplatesTableOrderingComposer,
          $$TaskTemplatesTableAnnotationComposer,
          $$TaskTemplatesTableCreateCompanionBuilder,
          $$TaskTemplatesTableUpdateCompanionBuilder,
          (
            TaskTemplate,
            BaseReferences<_$UserDatabase, $TaskTemplatesTable, TaskTemplate>,
          ),
          TaskTemplate,
          PrefetchHooks Function()
        > {
  $$TaskTemplatesTableTableManager(_$UserDatabase db, $TaskTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> templateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> usageCount = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplatesCompanion(
                templateId: templateId,
                name: name,
                description: description,
                content: content,
                isBuiltIn: isBuiltIn,
                usageCount: usageCount,
                targetType: targetType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String templateId,
                required String name,
                Value<String?> description = const Value.absent(),
                required String content,
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> usageCount = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplatesCompanion.insert(
                templateId: templateId,
                name: name,
                description: description,
                content: content,
                isBuiltIn: isBuiltIn,
                usageCount: usageCount,
                targetType: targetType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $TaskTemplatesTable,
      TaskTemplate,
      $$TaskTemplatesTableFilterComposer,
      $$TaskTemplatesTableOrderingComposer,
      $$TaskTemplatesTableAnnotationComposer,
      $$TaskTemplatesTableCreateCompanionBuilder,
      $$TaskTemplatesTableUpdateCompanionBuilder,
      (
        TaskTemplate,
        BaseReferences<_$UserDatabase, $TaskTemplatesTable, TaskTemplate>,
      ),
      TaskTemplate,
      PrefetchHooks Function()
    >;
typedef $$PerspectivesTableCreateCompanionBuilder =
    PerspectivesCompanion Function({
      required String perspectiveId,
      required String name,
      required String icon,
      required String description,
      required String category,
      required String promptTemplate,
      Value<bool> isBuiltin,
      Value<bool> isEnabled,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PerspectivesTableUpdateCompanionBuilder =
    PerspectivesCompanion Function({
      Value<String> perspectiveId,
      Value<String> name,
      Value<String> icon,
      Value<String> description,
      Value<String> category,
      Value<String> promptTemplate,
      Value<bool> isBuiltin,
      Value<bool> isEnabled,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$PerspectivesTableFilterComposer
    extends Composer<_$UserDatabase, $PerspectivesTable> {
  $$PerspectivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get perspectiveId => $composableBuilder(
    column: $table.perspectiveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptTemplate => $composableBuilder(
    column: $table.promptTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PerspectivesTableOrderingComposer
    extends Composer<_$UserDatabase, $PerspectivesTable> {
  $$PerspectivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get perspectiveId => $composableBuilder(
    column: $table.perspectiveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptTemplate => $composableBuilder(
    column: $table.promptTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PerspectivesTableAnnotationComposer
    extends Composer<_$UserDatabase, $PerspectivesTable> {
  $$PerspectivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get perspectiveId => $composableBuilder(
    column: $table.perspectiveId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get promptTemplate => $composableBuilder(
    column: $table.promptTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PerspectivesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $PerspectivesTable,
          Perspective,
          $$PerspectivesTableFilterComposer,
          $$PerspectivesTableOrderingComposer,
          $$PerspectivesTableAnnotationComposer,
          $$PerspectivesTableCreateCompanionBuilder,
          $$PerspectivesTableUpdateCompanionBuilder,
          (
            Perspective,
            BaseReferences<_$UserDatabase, $PerspectivesTable, Perspective>,
          ),
          Perspective,
          PrefetchHooks Function()
        > {
  $$PerspectivesTableTableManager(_$UserDatabase db, $PerspectivesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PerspectivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PerspectivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PerspectivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> perspectiveId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> promptTemplate = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PerspectivesCompanion(
                perspectiveId: perspectiveId,
                name: name,
                icon: icon,
                description: description,
                category: category,
                promptTemplate: promptTemplate,
                isBuiltin: isBuiltin,
                isEnabled: isEnabled,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String perspectiveId,
                required String name,
                required String icon,
                required String description,
                required String category,
                required String promptTemplate,
                Value<bool> isBuiltin = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PerspectivesCompanion.insert(
                perspectiveId: perspectiveId,
                name: name,
                icon: icon,
                description: description,
                category: category,
                promptTemplate: promptTemplate,
                isBuiltin: isBuiltin,
                isEnabled: isEnabled,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PerspectivesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $PerspectivesTable,
      Perspective,
      $$PerspectivesTableFilterComposer,
      $$PerspectivesTableOrderingComposer,
      $$PerspectivesTableAnnotationComposer,
      $$PerspectivesTableCreateCompanionBuilder,
      $$PerspectivesTableUpdateCompanionBuilder,
      (
        Perspective,
        BaseReferences<_$UserDatabase, $PerspectivesTable, Perspective>,
      ),
      Perspective,
      PrefetchHooks Function()
    >;
typedef $$InsightsTableCreateCompanionBuilder =
    InsightsCompanion Function({
      required String insightId,
      required String perspectiveId,
      required String perspectiveName,
      required String perspectiveIcon,
      required String timeRangeLabel,
      required String assistantFilter,
      required int queryCount,
      required int charCount,
      required String content,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$InsightsTableUpdateCompanionBuilder =
    InsightsCompanion Function({
      Value<String> insightId,
      Value<String> perspectiveId,
      Value<String> perspectiveName,
      Value<String> perspectiveIcon,
      Value<String> timeRangeLabel,
      Value<String> assistantFilter,
      Value<int> queryCount,
      Value<int> charCount,
      Value<String> content,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$InsightsTableFilterComposer
    extends Composer<_$UserDatabase, $InsightsTable> {
  $$InsightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get insightId => $composableBuilder(
    column: $table.insightId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get perspectiveId => $composableBuilder(
    column: $table.perspectiveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get perspectiveName => $composableBuilder(
    column: $table.perspectiveName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get perspectiveIcon => $composableBuilder(
    column: $table.perspectiveIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeRangeLabel => $composableBuilder(
    column: $table.timeRangeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assistantFilter => $composableBuilder(
    column: $table.assistantFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queryCount => $composableBuilder(
    column: $table.queryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charCount => $composableBuilder(
    column: $table.charCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InsightsTableOrderingComposer
    extends Composer<_$UserDatabase, $InsightsTable> {
  $$InsightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get insightId => $composableBuilder(
    column: $table.insightId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perspectiveId => $composableBuilder(
    column: $table.perspectiveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perspectiveName => $composableBuilder(
    column: $table.perspectiveName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perspectiveIcon => $composableBuilder(
    column: $table.perspectiveIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeRangeLabel => $composableBuilder(
    column: $table.timeRangeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assistantFilter => $composableBuilder(
    column: $table.assistantFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queryCount => $composableBuilder(
    column: $table.queryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charCount => $composableBuilder(
    column: $table.charCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InsightsTableAnnotationComposer
    extends Composer<_$UserDatabase, $InsightsTable> {
  $$InsightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get insightId =>
      $composableBuilder(column: $table.insightId, builder: (column) => column);

  GeneratedColumn<String> get perspectiveId => $composableBuilder(
    column: $table.perspectiveId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get perspectiveName => $composableBuilder(
    column: $table.perspectiveName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get perspectiveIcon => $composableBuilder(
    column: $table.perspectiveIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeRangeLabel => $composableBuilder(
    column: $table.timeRangeLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assistantFilter => $composableBuilder(
    column: $table.assistantFilter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get queryCount => $composableBuilder(
    column: $table.queryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get charCount =>
      $composableBuilder(column: $table.charCount, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InsightsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $InsightsTable,
          Insight,
          $$InsightsTableFilterComposer,
          $$InsightsTableOrderingComposer,
          $$InsightsTableAnnotationComposer,
          $$InsightsTableCreateCompanionBuilder,
          $$InsightsTableUpdateCompanionBuilder,
          (Insight, BaseReferences<_$UserDatabase, $InsightsTable, Insight>),
          Insight,
          PrefetchHooks Function()
        > {
  $$InsightsTableTableManager(_$UserDatabase db, $InsightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InsightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InsightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InsightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> insightId = const Value.absent(),
                Value<String> perspectiveId = const Value.absent(),
                Value<String> perspectiveName = const Value.absent(),
                Value<String> perspectiveIcon = const Value.absent(),
                Value<String> timeRangeLabel = const Value.absent(),
                Value<String> assistantFilter = const Value.absent(),
                Value<int> queryCount = const Value.absent(),
                Value<int> charCount = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InsightsCompanion(
                insightId: insightId,
                perspectiveId: perspectiveId,
                perspectiveName: perspectiveName,
                perspectiveIcon: perspectiveIcon,
                timeRangeLabel: timeRangeLabel,
                assistantFilter: assistantFilter,
                queryCount: queryCount,
                charCount: charCount,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String insightId,
                required String perspectiveId,
                required String perspectiveName,
                required String perspectiveIcon,
                required String timeRangeLabel,
                required String assistantFilter,
                required int queryCount,
                required int charCount,
                required String content,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => InsightsCompanion.insert(
                insightId: insightId,
                perspectiveId: perspectiveId,
                perspectiveName: perspectiveName,
                perspectiveIcon: perspectiveIcon,
                timeRangeLabel: timeRangeLabel,
                assistantFilter: assistantFilter,
                queryCount: queryCount,
                charCount: charCount,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InsightsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $InsightsTable,
      Insight,
      $$InsightsTableFilterComposer,
      $$InsightsTableOrderingComposer,
      $$InsightsTableAnnotationComposer,
      $$InsightsTableCreateCompanionBuilder,
      $$InsightsTableUpdateCompanionBuilder,
      (Insight, BaseReferences<_$UserDatabase, $InsightsTable, Insight>),
      Insight,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$AiAnalysesTableTableManager get aiAnalyses =>
      $$AiAnalysesTableTableManager(_db, _db.aiAnalyses);
  $$KnowledgeEntriesTableTableManager get knowledgeEntries =>
      $$KnowledgeEntriesTableTableManager(_db, _db.knowledgeEntries);
  $$DiscussionsTableTableManager get discussions =>
      $$DiscussionsTableTableManager(_db, _db.discussions);
  $$DiscussionMessagesTableTableManager get discussionMessages =>
      $$DiscussionMessagesTableTableManager(_db, _db.discussionMessages);
  $$UnifiedConversationsTableTableManager get unifiedConversations =>
      $$UnifiedConversationsTableTableManager(_db, _db.unifiedConversations);
  $$UnifiedMessagesTableTableManager get unifiedMessages =>
      $$UnifiedMessagesTableTableManager(_db, _db.unifiedMessages);
  $$UserPreferencesTableTableManager get userPreferences =>
      $$UserPreferencesTableTableManager(_db, _db.userPreferences);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db, _db.taskTemplates);
  $$PerspectivesTableTableManager get perspectives =>
      $$PerspectivesTableTableManager(_db, _db.perspectives);
  $$InsightsTableTableManager get insights =>
      $$InsightsTableTableManager(_db, _db.insights);
}
