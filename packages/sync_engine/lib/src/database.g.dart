// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trnMeta = const VerificationMeta('trn');
  @override
  late final GeneratedColumn<String> trn = GeneratedColumn<String>(
    'trn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('retail'),
  );
  static const VerificationMeta _creditLimitFilsMeta = const VerificationMeta(
    'creditLimitFils',
  );
  @override
  late final GeneratedColumn<int> creditLimitFils = GeneratedColumn<int>(
    'credit_limit_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentTermsDaysMeta = const VerificationMeta(
    'paymentTermsDays',
  );
  @override
  late final GeneratedColumn<int> paymentTermsDays = GeneratedColumn<int>(
    'payment_terms_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatsappOptInMeta = const VerificationMeta(
    'whatsappOptIn',
  );
  @override
  late final GeneratedColumn<bool> whatsappOptIn = GeneratedColumn<bool>(
    'whatsapp_opt_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("whatsapp_opt_in" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    name,
    company,
    trn,
    tier,
    creditLimitFils,
    paymentTermsDays,
    notes,
    whatsappOptIn,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    }
    if (data.containsKey('trn')) {
      context.handle(
        _trnMeta,
        trn.isAcceptableOrUnknown(data['trn']!, _trnMeta),
      );
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    }
    if (data.containsKey('credit_limit_fils')) {
      context.handle(
        _creditLimitFilsMeta,
        creditLimitFils.isAcceptableOrUnknown(
          data['credit_limit_fils']!,
          _creditLimitFilsMeta,
        ),
      );
    }
    if (data.containsKey('payment_terms_days')) {
      context.handle(
        _paymentTermsDaysMeta,
        paymentTermsDays.isAcceptableOrUnknown(
          data['payment_terms_days']!,
          _paymentTermsDaysMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('whatsapp_opt_in')) {
      context.handle(
        _whatsappOptInMeta,
        whatsappOptIn.isAcceptableOrUnknown(
          data['whatsapp_opt_in']!,
          _whatsappOptInMeta,
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      ),
      trn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trn'],
      ),
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      creditLimitFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit_fils'],
      )!,
      paymentTermsDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_terms_days'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      whatsappOptIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}whatsapp_opt_in'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String name;
  final String? company;
  final String? trn;
  final String tier;
  final int creditLimitFils;
  final int paymentTermsDays;
  final String? notes;
  final bool whatsappOptIn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;

  /// Server tombstone. Rows are never hard-deleted, so a deletion can sync.
  final DateTime? deletedAt;
  const Customer({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.name,
    this.company,
    this.trn,
    required this.tier,
    required this.creditLimitFils,
    required this.paymentTermsDays,
    this.notes,
    required this.whatsappOptIn,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || trn != null) {
      map['trn'] = Variable<String>(trn);
    }
    map['tier'] = Variable<String>(tier);
    map['credit_limit_fils'] = Variable<int>(creditLimitFils);
    map['payment_terms_days'] = Variable<int>(paymentTermsDays);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['whatsapp_opt_in'] = Variable<bool>(whatsappOptIn);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      name: Value(name),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      trn: trn == null && nullToAbsent ? const Value.absent() : Value(trn),
      tier: Value(tier),
      creditLimitFils: Value(creditLimitFils),
      paymentTermsDays: Value(paymentTermsDays),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      whatsappOptIn: Value(whatsappOptIn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      name: serializer.fromJson<String>(json['name']),
      company: serializer.fromJson<String?>(json['company']),
      trn: serializer.fromJson<String?>(json['trn']),
      tier: serializer.fromJson<String>(json['tier']),
      creditLimitFils: serializer.fromJson<int>(json['creditLimitFils']),
      paymentTermsDays: serializer.fromJson<int>(json['paymentTermsDays']),
      notes: serializer.fromJson<String?>(json['notes']),
      whatsappOptIn: serializer.fromJson<bool>(json['whatsappOptIn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'name': serializer.toJson<String>(name),
      'company': serializer.toJson<String?>(company),
      'trn': serializer.toJson<String?>(trn),
      'tier': serializer.toJson<String>(tier),
      'creditLimitFils': serializer.toJson<int>(creditLimitFils),
      'paymentTermsDays': serializer.toJson<int>(paymentTermsDays),
      'notes': serializer.toJson<String?>(notes),
      'whatsappOptIn': serializer.toJson<bool>(whatsappOptIn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Customer copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? name,
    Value<String?> company = const Value.absent(),
    Value<String?> trn = const Value.absent(),
    String? tier,
    int? creditLimitFils,
    int? paymentTermsDays,
    Value<String?> notes = const Value.absent(),
    bool? whatsappOptIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Customer(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    name: name ?? this.name,
    company: company.present ? company.value : this.company,
    trn: trn.present ? trn.value : this.trn,
    tier: tier ?? this.tier,
    creditLimitFils: creditLimitFils ?? this.creditLimitFils,
    paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
    notes: notes.present ? notes.value : this.notes,
    whatsappOptIn: whatsappOptIn ?? this.whatsappOptIn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      name: data.name.present ? data.name.value : this.name,
      company: data.company.present ? data.company.value : this.company,
      trn: data.trn.present ? data.trn.value : this.trn,
      tier: data.tier.present ? data.tier.value : this.tier,
      creditLimitFils: data.creditLimitFils.present
          ? data.creditLimitFils.value
          : this.creditLimitFils,
      paymentTermsDays: data.paymentTermsDays.present
          ? data.paymentTermsDays.value
          : this.paymentTermsDays,
      notes: data.notes.present ? data.notes.value : this.notes,
      whatsappOptIn: data.whatsappOptIn.present
          ? data.whatsappOptIn.value
          : this.whatsappOptIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('company: $company, ')
          ..write('trn: $trn, ')
          ..write('tier: $tier, ')
          ..write('creditLimitFils: $creditLimitFils, ')
          ..write('paymentTermsDays: $paymentTermsDays, ')
          ..write('notes: $notes, ')
          ..write('whatsappOptIn: $whatsappOptIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    branchId,
    name,
    company,
    trn,
    tier,
    creditLimitFils,
    paymentTermsDays,
    notes,
    whatsappOptIn,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.name == this.name &&
          other.company == this.company &&
          other.trn == this.trn &&
          other.tier == this.tier &&
          other.creditLimitFils == this.creditLimitFils &&
          other.paymentTermsDays == this.paymentTermsDays &&
          other.notes == this.notes &&
          other.whatsappOptIn == this.whatsappOptIn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> name;
  final Value<String?> company;
  final Value<String?> trn;
  final Value<String> tier;
  final Value<int> creditLimitFils;
  final Value<int> paymentTermsDays;
  final Value<String?> notes;
  final Value<bool> whatsappOptIn;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.name = const Value.absent(),
    this.company = const Value.absent(),
    this.trn = const Value.absent(),
    this.tier = const Value.absent(),
    this.creditLimitFils = const Value.absent(),
    this.paymentTermsDays = const Value.absent(),
    this.notes = const Value.absent(),
    this.whatsappOptIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String name,
    this.company = const Value.absent(),
    this.trn = const Value.absent(),
    this.tier = const Value.absent(),
    this.creditLimitFils = const Value.absent(),
    this.paymentTermsDays = const Value.absent(),
    this.notes = const Value.absent(),
    this.whatsappOptIn = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? name,
    Expression<String>? company,
    Expression<String>? trn,
    Expression<String>? tier,
    Expression<int>? creditLimitFils,
    Expression<int>? paymentTermsDays,
    Expression<String>? notes,
    Expression<bool>? whatsappOptIn,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (name != null) 'name': name,
      if (company != null) 'company': company,
      if (trn != null) 'trn': trn,
      if (tier != null) 'tier': tier,
      if (creditLimitFils != null) 'credit_limit_fils': creditLimitFils,
      if (paymentTermsDays != null) 'payment_terms_days': paymentTermsDays,
      if (notes != null) 'notes': notes,
      if (whatsappOptIn != null) 'whatsapp_opt_in': whatsappOptIn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? name,
    Value<String?>? company,
    Value<String?>? trn,
    Value<String>? tier,
    Value<int>? creditLimitFils,
    Value<int>? paymentTermsDays,
    Value<String?>? notes,
    Value<bool>? whatsappOptIn,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      company: company ?? this.company,
      trn: trn ?? this.trn,
      tier: tier ?? this.tier,
      creditLimitFils: creditLimitFils ?? this.creditLimitFils,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      notes: notes ?? this.notes,
      whatsappOptIn: whatsappOptIn ?? this.whatsappOptIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (trn.present) {
      map['trn'] = Variable<String>(trn.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (creditLimitFils.present) {
      map['credit_limit_fils'] = Variable<int>(creditLimitFils.value);
    }
    if (paymentTermsDays.present) {
      map['payment_terms_days'] = Variable<int>(paymentTermsDays.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (whatsappOptIn.present) {
      map['whatsapp_opt_in'] = Variable<bool>(whatsappOptIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('company: $company, ')
          ..write('trn: $trn, ')
          ..write('tier: $tier, ')
          ..write('creditLimitFils: $creditLimitFils, ')
          ..write('paymentTermsDays: $paymentTermsDays, ')
          ..write('notes: $notes, ')
          ..write('whatsappOptIn: $whatsappOptIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerPhonesTable extends CustomerPhones
    with TableInfo<$CustomerPhonesTable, CustomerPhone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerPhonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _e164Meta = const VerificationMeta('e164');
  @override
  late final GeneratedColumn<String> e164 = GeneratedColumn<String>(
    'e164',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneLast9Meta = const VerificationMeta(
    'phoneLast9',
  );
  @override
  late final GeneratedColumn<String> phoneLast9 = GeneratedColumn<String>(
    'phone_last9',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    customerId,
    e164,
    phoneLast9,
    label,
    isPrimary,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_phones';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerPhone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('e164')) {
      context.handle(
        _e164Meta,
        e164.isAcceptableOrUnknown(data['e164']!, _e164Meta),
      );
    } else if (isInserting) {
      context.missing(_e164Meta);
    }
    if (data.containsKey('phone_last9')) {
      context.handle(
        _phoneLast9Meta,
        phoneLast9.isAcceptableOrUnknown(data['phone_last9']!, _phoneLast9Meta),
      );
    } else if (isInserting) {
      context.missing(_phoneLast9Meta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerPhone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerPhone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      e164: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}e164'],
      )!,
      phoneLast9: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_last9'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CustomerPhonesTable createAlias(String alias) {
    return $CustomerPhonesTable(attachedDatabase, alias);
  }
}

class CustomerPhone extends DataClass implements Insertable<CustomerPhone> {
  final String id;
  final String tenantId;
  final String customerId;

  /// Normalised `+9715…` and the last nine digits, which is what the search
  /// box matches against (people type 050…, 971…, or just the last digits).
  final String e164;
  final String phoneLast9;
  final String? label;
  final bool isPrimary;
  final int version;
  final DateTime? deletedAt;
  const CustomerPhone({
    required this.id,
    required this.tenantId,
    required this.customerId,
    required this.e164,
    required this.phoneLast9,
    this.label,
    required this.isPrimary,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['customer_id'] = Variable<String>(customerId);
    map['e164'] = Variable<String>(e164);
    map['phone_last9'] = Variable<String>(phoneLast9);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CustomerPhonesCompanion toCompanion(bool nullToAbsent) {
    return CustomerPhonesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      customerId: Value(customerId),
      e164: Value(e164),
      phoneLast9: Value(phoneLast9),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      isPrimary: Value(isPrimary),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CustomerPhone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerPhone(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      e164: serializer.fromJson<String>(json['e164']),
      phoneLast9: serializer.fromJson<String>(json['phoneLast9']),
      label: serializer.fromJson<String?>(json['label']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'customerId': serializer.toJson<String>(customerId),
      'e164': serializer.toJson<String>(e164),
      'phoneLast9': serializer.toJson<String>(phoneLast9),
      'label': serializer.toJson<String?>(label),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CustomerPhone copyWith({
    String? id,
    String? tenantId,
    String? customerId,
    String? e164,
    String? phoneLast9,
    Value<String?> label = const Value.absent(),
    bool? isPrimary,
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CustomerPhone(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    customerId: customerId ?? this.customerId,
    e164: e164 ?? this.e164,
    phoneLast9: phoneLast9 ?? this.phoneLast9,
    label: label.present ? label.value : this.label,
    isPrimary: isPrimary ?? this.isPrimary,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CustomerPhone copyWithCompanion(CustomerPhonesCompanion data) {
    return CustomerPhone(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      e164: data.e164.present ? data.e164.value : this.e164,
      phoneLast9: data.phoneLast9.present
          ? data.phoneLast9.value
          : this.phoneLast9,
      label: data.label.present ? data.label.value : this.label,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerPhone(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('customerId: $customerId, ')
          ..write('e164: $e164, ')
          ..write('phoneLast9: $phoneLast9, ')
          ..write('label: $label, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    customerId,
    e164,
    phoneLast9,
    label,
    isPrimary,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerPhone &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.customerId == this.customerId &&
          other.e164 == this.e164 &&
          other.phoneLast9 == this.phoneLast9 &&
          other.label == this.label &&
          other.isPrimary == this.isPrimary &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class CustomerPhonesCompanion extends UpdateCompanion<CustomerPhone> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> customerId;
  final Value<String> e164;
  final Value<String> phoneLast9;
  final Value<String?> label;
  final Value<bool> isPrimary;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CustomerPhonesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.e164 = const Value.absent(),
    this.phoneLast9 = const Value.absent(),
    this.label = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerPhonesCompanion.insert({
    required String id,
    required String tenantId,
    required String customerId,
    required String e164,
    required String phoneLast9,
    this.label = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       customerId = Value(customerId),
       e164 = Value(e164),
       phoneLast9 = Value(phoneLast9);
  static Insertable<CustomerPhone> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? customerId,
    Expression<String>? e164,
    Expression<String>? phoneLast9,
    Expression<String>? label,
    Expression<bool>? isPrimary,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (customerId != null) 'customer_id': customerId,
      if (e164 != null) 'e164': e164,
      if (phoneLast9 != null) 'phone_last9': phoneLast9,
      if (label != null) 'label': label,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerPhonesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? customerId,
    Value<String>? e164,
    Value<String>? phoneLast9,
    Value<String?>? label,
    Value<bool>? isPrimary,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CustomerPhonesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      customerId: customerId ?? this.customerId,
      e164: e164 ?? this.e164,
      phoneLast9: phoneLast9 ?? this.phoneLast9,
      label: label ?? this.label,
      isPrimary: isPrimary ?? this.isPrimary,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (e164.present) {
      map['e164'] = Variable<String>(e164.value);
    }
    if (phoneLast9.present) {
      map['phone_last9'] = Variable<String>(phoneLast9.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerPhonesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('customerId: $customerId, ')
          ..write('e164: $e164, ')
          ..write('phoneLast9: $phoneLast9, ')
          ..write('label: $label, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkflowStagesTable extends WorkflowStages
    with TableInfo<$WorkflowStagesTable, WorkflowStage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowStagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workflowKeyMeta = const VerificationMeta(
    'workflowKey',
  );
  @override
  late final GeneratedColumn<String> workflowKey = GeneratedColumn<String>(
    'workflow_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('print_std'),
  );
  static const VerificationMeta _stageKeyMeta = const VerificationMeta(
    'stageKey',
  );
  @override
  late final GeneratedColumn<String> stageKey = GeneratedColumn<String>(
    'stage_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredRoleMeta = const VerificationMeta(
    'requiredRole',
  );
  @override
  late final GeneratedColumn<String> requiredRole = GeneratedColumn<String>(
    'required_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waitsForPreviousMeta = const VerificationMeta(
    'waitsForPrevious',
  );
  @override
  late final GeneratedColumn<bool> waitsForPrevious = GeneratedColumn<bool>(
    'waits_for_previous',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("waits_for_previous" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    workflowKey,
    stageKey,
    nameEn,
    nameAr,
    sequence,
    requiredRole,
    waitsForPrevious,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflow_stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkflowStage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('workflow_key')) {
      context.handle(
        _workflowKeyMeta,
        workflowKey.isAcceptableOrUnknown(
          data['workflow_key']!,
          _workflowKeyMeta,
        ),
      );
    }
    if (data.containsKey('stage_key')) {
      context.handle(
        _stageKeyMeta,
        stageKey.isAcceptableOrUnknown(data['stage_key']!, _stageKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_stageKeyMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('required_role')) {
      context.handle(
        _requiredRoleMeta,
        requiredRole.isAcceptableOrUnknown(
          data['required_role']!,
          _requiredRoleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requiredRoleMeta);
    }
    if (data.containsKey('waits_for_previous')) {
      context.handle(
        _waitsForPreviousMeta,
        waitsForPrevious.isAcceptableOrUnknown(
          data['waits_for_previous']!,
          _waitsForPreviousMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkflowStage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkflowStage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      workflowKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_key'],
      )!,
      stageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_key'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      requiredRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_role'],
      )!,
      waitsForPrevious: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}waits_for_previous'],
      )!,
    );
  }

  @override
  $WorkflowStagesTable createAlias(String alias) {
    return $WorkflowStagesTable(attachedDatabase, alias);
  }
}

class WorkflowStage extends DataClass implements Insertable<WorkflowStage> {
  final String id;
  final String tenantId;
  final String workflowKey;
  final String stageKey;
  final String nameEn;
  final String? nameAr;
  final int sequence;
  final String requiredRole;
  final bool waitsForPrevious;
  const WorkflowStage({
    required this.id,
    required this.tenantId,
    required this.workflowKey,
    required this.stageKey,
    required this.nameEn,
    this.nameAr,
    required this.sequence,
    required this.requiredRole,
    required this.waitsForPrevious,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['workflow_key'] = Variable<String>(workflowKey);
    map['stage_key'] = Variable<String>(stageKey);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    map['sequence'] = Variable<int>(sequence);
    map['required_role'] = Variable<String>(requiredRole);
    map['waits_for_previous'] = Variable<bool>(waitsForPrevious);
    return map;
  }

  WorkflowStagesCompanion toCompanion(bool nullToAbsent) {
    return WorkflowStagesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      workflowKey: Value(workflowKey),
      stageKey: Value(stageKey),
      nameEn: Value(nameEn),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      sequence: Value(sequence),
      requiredRole: Value(requiredRole),
      waitsForPrevious: Value(waitsForPrevious),
    );
  }

  factory WorkflowStage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkflowStage(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      workflowKey: serializer.fromJson<String>(json['workflowKey']),
      stageKey: serializer.fromJson<String>(json['stageKey']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      sequence: serializer.fromJson<int>(json['sequence']),
      requiredRole: serializer.fromJson<String>(json['requiredRole']),
      waitsForPrevious: serializer.fromJson<bool>(json['waitsForPrevious']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'workflowKey': serializer.toJson<String>(workflowKey),
      'stageKey': serializer.toJson<String>(stageKey),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameAr': serializer.toJson<String?>(nameAr),
      'sequence': serializer.toJson<int>(sequence),
      'requiredRole': serializer.toJson<String>(requiredRole),
      'waitsForPrevious': serializer.toJson<bool>(waitsForPrevious),
    };
  }

  WorkflowStage copyWith({
    String? id,
    String? tenantId,
    String? workflowKey,
    String? stageKey,
    String? nameEn,
    Value<String?> nameAr = const Value.absent(),
    int? sequence,
    String? requiredRole,
    bool? waitsForPrevious,
  }) => WorkflowStage(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    workflowKey: workflowKey ?? this.workflowKey,
    stageKey: stageKey ?? this.stageKey,
    nameEn: nameEn ?? this.nameEn,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    sequence: sequence ?? this.sequence,
    requiredRole: requiredRole ?? this.requiredRole,
    waitsForPrevious: waitsForPrevious ?? this.waitsForPrevious,
  );
  WorkflowStage copyWithCompanion(WorkflowStagesCompanion data) {
    return WorkflowStage(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      workflowKey: data.workflowKey.present
          ? data.workflowKey.value
          : this.workflowKey,
      stageKey: data.stageKey.present ? data.stageKey.value : this.stageKey,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      requiredRole: data.requiredRole.present
          ? data.requiredRole.value
          : this.requiredRole,
      waitsForPrevious: data.waitsForPrevious.present
          ? data.waitsForPrevious.value
          : this.waitsForPrevious,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowStage(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('workflowKey: $workflowKey, ')
          ..write('stageKey: $stageKey, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('sequence: $sequence, ')
          ..write('requiredRole: $requiredRole, ')
          ..write('waitsForPrevious: $waitsForPrevious')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    workflowKey,
    stageKey,
    nameEn,
    nameAr,
    sequence,
    requiredRole,
    waitsForPrevious,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkflowStage &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.workflowKey == this.workflowKey &&
          other.stageKey == this.stageKey &&
          other.nameEn == this.nameEn &&
          other.nameAr == this.nameAr &&
          other.sequence == this.sequence &&
          other.requiredRole == this.requiredRole &&
          other.waitsForPrevious == this.waitsForPrevious);
}

class WorkflowStagesCompanion extends UpdateCompanion<WorkflowStage> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> workflowKey;
  final Value<String> stageKey;
  final Value<String> nameEn;
  final Value<String?> nameAr;
  final Value<int> sequence;
  final Value<String> requiredRole;
  final Value<bool> waitsForPrevious;
  final Value<int> rowid;
  const WorkflowStagesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.workflowKey = const Value.absent(),
    this.stageKey = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.sequence = const Value.absent(),
    this.requiredRole = const Value.absent(),
    this.waitsForPrevious = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkflowStagesCompanion.insert({
    required String id,
    required String tenantId,
    this.workflowKey = const Value.absent(),
    required String stageKey,
    required String nameEn,
    this.nameAr = const Value.absent(),
    required int sequence,
    required String requiredRole,
    this.waitsForPrevious = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       stageKey = Value(stageKey),
       nameEn = Value(nameEn),
       sequence = Value(sequence),
       requiredRole = Value(requiredRole);
  static Insertable<WorkflowStage> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? workflowKey,
    Expression<String>? stageKey,
    Expression<String>? nameEn,
    Expression<String>? nameAr,
    Expression<int>? sequence,
    Expression<String>? requiredRole,
    Expression<bool>? waitsForPrevious,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (workflowKey != null) 'workflow_key': workflowKey,
      if (stageKey != null) 'stage_key': stageKey,
      if (nameEn != null) 'name_en': nameEn,
      if (nameAr != null) 'name_ar': nameAr,
      if (sequence != null) 'sequence': sequence,
      if (requiredRole != null) 'required_role': requiredRole,
      if (waitsForPrevious != null) 'waits_for_previous': waitsForPrevious,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkflowStagesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? workflowKey,
    Value<String>? stageKey,
    Value<String>? nameEn,
    Value<String?>? nameAr,
    Value<int>? sequence,
    Value<String>? requiredRole,
    Value<bool>? waitsForPrevious,
    Value<int>? rowid,
  }) {
    return WorkflowStagesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      workflowKey: workflowKey ?? this.workflowKey,
      stageKey: stageKey ?? this.stageKey,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      sequence: sequence ?? this.sequence,
      requiredRole: requiredRole ?? this.requiredRole,
      waitsForPrevious: waitsForPrevious ?? this.waitsForPrevious,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (workflowKey.present) {
      map['workflow_key'] = Variable<String>(workflowKey.value);
    }
    if (stageKey.present) {
      map['stage_key'] = Variable<String>(stageKey.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (requiredRole.present) {
      map['required_role'] = Variable<String>(requiredRole.value);
    }
    if (waitsForPrevious.present) {
      map['waits_for_previous'] = Variable<bool>(waitsForPrevious.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowStagesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('workflowKey: $workflowKey, ')
          ..write('stageKey: $stageKey, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('sequence: $sequence, ')
          ..write('requiredRole: $requiredRole, ')
          ..write('waitsForPrevious: $waitsForPrevious, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderItemIdMeta = const VerificationMeta(
    'orderItemId',
  );
  @override
  late final GeneratedColumn<String> orderItemId = GeneratedColumn<String>(
    'order_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageKeyMeta = const VerificationMeta(
    'stageKey',
  );
  @override
  late final GeneratedColumn<String> stageKey = GeneratedColumn<String>(
    'stage_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageNameMeta = const VerificationMeta(
    'stageName',
  );
  @override
  late final GeneratedColumn<String> stageName = GeneratedColumn<String>(
    'stage_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('waiting'),
  );
  static const VerificationMeta _assignedToMeta = const VerificationMeta(
    'assignedTo',
  );
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
    'assigned_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredRoleMeta = const VerificationMeta(
    'requiredRole',
  );
  @override
  late final GeneratedColumn<String> requiredRole = GeneratedColumn<String>(
    'required_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reworkCountMeta = const VerificationMeta(
    'reworkCount',
  );
  @override
  late final GeneratedColumn<int> reworkCount = GeneratedColumn<int>(
    'rework_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    orderId,
    orderItemId,
    stageKey,
    stageName,
    sequence,
    title,
    status,
    assignedTo,
    requiredRole,
    qty,
    priority,
    dueAt,
    startedAt,
    doneAt,
    reason,
    reworkCount,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('order_item_id')) {
      context.handle(
        _orderItemIdMeta,
        orderItemId.isAcceptableOrUnknown(
          data['order_item_id']!,
          _orderItemIdMeta,
        ),
      );
    }
    if (data.containsKey('stage_key')) {
      context.handle(
        _stageKeyMeta,
        stageKey.isAcceptableOrUnknown(data['stage_key']!, _stageKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_stageKeyMeta);
    }
    if (data.containsKey('stage_name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['stage_name']!, _stageNameMeta),
      );
    } else if (isInserting) {
      context.missing(_stageNameMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('assigned_to')) {
      context.handle(
        _assignedToMeta,
        assignedTo.isAcceptableOrUnknown(data['assigned_to']!, _assignedToMeta),
      );
    }
    if (data.containsKey('required_role')) {
      context.handle(
        _requiredRoleMeta,
        requiredRole.isAcceptableOrUnknown(
          data['required_role']!,
          _requiredRoleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requiredRoleMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('rework_count')) {
      context.handle(
        _reworkCountMeta,
        reworkCount.isAcceptableOrUnknown(
          data['rework_count']!,
          _reworkCountMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      orderItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_item_id'],
      ),
      stageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_key'],
      )!,
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_name'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      assignedTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_to'],
      ),
      requiredRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_role'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      reworkCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rework_count'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String orderId;
  final String? orderItemId;
  final String stageKey;
  final String stageName;
  final int sequence;
  final String title;

  /// waiting, available, assigned, in_progress, paused, done, rework, cancelled
  final String status;
  final String? assignedTo;
  final String requiredRole;
  final int qty;
  final String priority;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? doneAt;
  final String? reason;
  final int reworkCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;
  final DateTime? deletedAt;
  const Task({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.orderId,
    this.orderItemId,
    required this.stageKey,
    required this.stageName,
    required this.sequence,
    required this.title,
    required this.status,
    this.assignedTo,
    required this.requiredRole,
    required this.qty,
    required this.priority,
    this.dueAt,
    this.startedAt,
    this.doneAt,
    this.reason,
    required this.reworkCount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['order_id'] = Variable<String>(orderId);
    if (!nullToAbsent || orderItemId != null) {
      map['order_item_id'] = Variable<String>(orderItemId);
    }
    map['stage_key'] = Variable<String>(stageKey);
    map['stage_name'] = Variable<String>(stageName);
    map['sequence'] = Variable<int>(sequence);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || assignedTo != null) {
      map['assigned_to'] = Variable<String>(assignedTo);
    }
    map['required_role'] = Variable<String>(requiredRole);
    map['qty'] = Variable<int>(qty);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['rework_count'] = Variable<int>(reworkCount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      orderId: Value(orderId),
      orderItemId: orderItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderItemId),
      stageKey: Value(stageKey),
      stageName: Value(stageName),
      sequence: Value(sequence),
      title: Value(title),
      status: Value(status),
      assignedTo: assignedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedTo),
      requiredRole: Value(requiredRole),
      qty: Value(qty),
      priority: Value(priority),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      reworkCount: Value(reworkCount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      orderId: serializer.fromJson<String>(json['orderId']),
      orderItemId: serializer.fromJson<String?>(json['orderItemId']),
      stageKey: serializer.fromJson<String>(json['stageKey']),
      stageName: serializer.fromJson<String>(json['stageName']),
      sequence: serializer.fromJson<int>(json['sequence']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      assignedTo: serializer.fromJson<String?>(json['assignedTo']),
      requiredRole: serializer.fromJson<String>(json['requiredRole']),
      qty: serializer.fromJson<int>(json['qty']),
      priority: serializer.fromJson<String>(json['priority']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      reason: serializer.fromJson<String?>(json['reason']),
      reworkCount: serializer.fromJson<int>(json['reworkCount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'orderId': serializer.toJson<String>(orderId),
      'orderItemId': serializer.toJson<String?>(orderItemId),
      'stageKey': serializer.toJson<String>(stageKey),
      'stageName': serializer.toJson<String>(stageName),
      'sequence': serializer.toJson<int>(sequence),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'assignedTo': serializer.toJson<String?>(assignedTo),
      'requiredRole': serializer.toJson<String>(requiredRole),
      'qty': serializer.toJson<int>(qty),
      'priority': serializer.toJson<String>(priority),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'reason': serializer.toJson<String?>(reason),
      'reworkCount': serializer.toJson<int>(reworkCount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Task copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? orderId,
    Value<String?> orderItemId = const Value.absent(),
    String? stageKey,
    String? stageName,
    int? sequence,
    String? title,
    String? status,
    Value<String?> assignedTo = const Value.absent(),
    String? requiredRole,
    int? qty,
    String? priority,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> doneAt = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    int? reworkCount,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    orderId: orderId ?? this.orderId,
    orderItemId: orderItemId.present ? orderItemId.value : this.orderItemId,
    stageKey: stageKey ?? this.stageKey,
    stageName: stageName ?? this.stageName,
    sequence: sequence ?? this.sequence,
    title: title ?? this.title,
    status: status ?? this.status,
    assignedTo: assignedTo.present ? assignedTo.value : this.assignedTo,
    requiredRole: requiredRole ?? this.requiredRole,
    qty: qty ?? this.qty,
    priority: priority ?? this.priority,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    reason: reason.present ? reason.value : this.reason,
    reworkCount: reworkCount ?? this.reworkCount,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      orderItemId: data.orderItemId.present
          ? data.orderItemId.value
          : this.orderItemId,
      stageKey: data.stageKey.present ? data.stageKey.value : this.stageKey,
      stageName: data.stageName.present ? data.stageName.value : this.stageName,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      assignedTo: data.assignedTo.present
          ? data.assignedTo.value
          : this.assignedTo,
      requiredRole: data.requiredRole.present
          ? data.requiredRole.value
          : this.requiredRole,
      qty: data.qty.present ? data.qty.value : this.qty,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      reworkCount: data.reworkCount.present
          ? data.reworkCount.value
          : this.reworkCount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('orderItemId: $orderItemId, ')
          ..write('stageKey: $stageKey, ')
          ..write('stageName: $stageName, ')
          ..write('sequence: $sequence, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('requiredRole: $requiredRole, ')
          ..write('qty: $qty, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('doneAt: $doneAt, ')
          ..write('reason: $reason, ')
          ..write('reworkCount: $reworkCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    branchId,
    orderId,
    orderItemId,
    stageKey,
    stageName,
    sequence,
    title,
    status,
    assignedTo,
    requiredRole,
    qty,
    priority,
    dueAt,
    startedAt,
    doneAt,
    reason,
    reworkCount,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.orderId == this.orderId &&
          other.orderItemId == this.orderItemId &&
          other.stageKey == this.stageKey &&
          other.stageName == this.stageName &&
          other.sequence == this.sequence &&
          other.title == this.title &&
          other.status == this.status &&
          other.assignedTo == this.assignedTo &&
          other.requiredRole == this.requiredRole &&
          other.qty == this.qty &&
          other.priority == this.priority &&
          other.dueAt == this.dueAt &&
          other.startedAt == this.startedAt &&
          other.doneAt == this.doneAt &&
          other.reason == this.reason &&
          other.reworkCount == this.reworkCount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> orderId;
  final Value<String?> orderItemId;
  final Value<String> stageKey;
  final Value<String> stageName;
  final Value<int> sequence;
  final Value<String> title;
  final Value<String> status;
  final Value<String?> assignedTo;
  final Value<String> requiredRole;
  final Value<int> qty;
  final Value<String> priority;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> doneAt;
  final Value<String?> reason;
  final Value<int> reworkCount;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.orderItemId = const Value.absent(),
    this.stageKey = const Value.absent(),
    this.stageName = const Value.absent(),
    this.sequence = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.requiredRole = const Value.absent(),
    this.qty = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.reworkCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String orderId,
    this.orderItemId = const Value.absent(),
    required String stageKey,
    required String stageName,
    required int sequence,
    required String title,
    this.status = const Value.absent(),
    this.assignedTo = const Value.absent(),
    required String requiredRole,
    this.qty = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.reworkCount = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       orderId = Value(orderId),
       stageKey = Value(stageKey),
       stageName = Value(stageName),
       sequence = Value(sequence),
       title = Value(title),
       requiredRole = Value(requiredRole),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? orderId,
    Expression<String>? orderItemId,
    Expression<String>? stageKey,
    Expression<String>? stageName,
    Expression<int>? sequence,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? assignedTo,
    Expression<String>? requiredRole,
    Expression<int>? qty,
    Expression<String>? priority,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? doneAt,
    Expression<String>? reason,
    Expression<int>? reworkCount,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (orderId != null) 'order_id': orderId,
      if (orderItemId != null) 'order_item_id': orderItemId,
      if (stageKey != null) 'stage_key': stageKey,
      if (stageName != null) 'stage_name': stageName,
      if (sequence != null) 'sequence': sequence,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (requiredRole != null) 'required_role': requiredRole,
      if (qty != null) 'qty': qty,
      if (priority != null) 'priority': priority,
      if (dueAt != null) 'due_at': dueAt,
      if (startedAt != null) 'started_at': startedAt,
      if (doneAt != null) 'done_at': doneAt,
      if (reason != null) 'reason': reason,
      if (reworkCount != null) 'rework_count': reworkCount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? orderId,
    Value<String?>? orderItemId,
    Value<String>? stageKey,
    Value<String>? stageName,
    Value<int>? sequence,
    Value<String>? title,
    Value<String>? status,
    Value<String?>? assignedTo,
    Value<String>? requiredRole,
    Value<int>? qty,
    Value<String>? priority,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? doneAt,
    Value<String?>? reason,
    Value<int>? reworkCount,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      stageKey: stageKey ?? this.stageKey,
      stageName: stageName ?? this.stageName,
      sequence: sequence ?? this.sequence,
      title: title ?? this.title,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      requiredRole: requiredRole ?? this.requiredRole,
      qty: qty ?? this.qty,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      doneAt: doneAt ?? this.doneAt,
      reason: reason ?? this.reason,
      reworkCount: reworkCount ?? this.reworkCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (orderItemId.present) {
      map['order_item_id'] = Variable<String>(orderItemId.value);
    }
    if (stageKey.present) {
      map['stage_key'] = Variable<String>(stageKey.value);
    }
    if (stageName.present) {
      map['stage_name'] = Variable<String>(stageName.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (requiredRole.present) {
      map['required_role'] = Variable<String>(requiredRole.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (reworkCount.present) {
      map['rework_count'] = Variable<int>(reworkCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('orderItemId: $orderItemId, ')
          ..write('stageKey: $stageKey, ')
          ..write('stageName: $stageName, ')
          ..write('sequence: $sequence, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('requiredRole: $requiredRole, ')
          ..write('qty: $qty, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('doneAt: $doneAt, ')
          ..write('reason: $reason, ')
          ..write('reworkCount: $reworkCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProofsTable extends Proofs with TableInfo<$ProofsTable, Proof> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProofsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('proof'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decidedNoteMeta = const VerificationMeta(
    'decidedNote',
  );
  @override
  late final GeneratedColumn<String> decidedNote = GeneratedColumn<String>(
    'decided_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    orderId,
    revision,
    kind,
    label,
    url,
    note,
    status,
    sentAt,
    decidedAt,
    decidedNote,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proofs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Proof> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('decided_note')) {
      context.handle(
        _decidedNoteMeta,
        decidedNote.isAcceptableOrUnknown(
          data['decided_note']!,
          _decidedNoteMeta,
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Proof map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Proof(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      decidedNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProofsTable createAlias(String alias) {
    return $ProofsTable(attachedDatabase, alias);
  }
}

class Proof extends DataClass implements Insertable<Proof> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String orderId;

  /// The version the customer sees: v1, v2, …
  final int revision;
  final String kind;
  final String label;
  final String url;
  final String? note;

  /// draft, sent, approved, rejected, superseded
  final String status;
  final DateTime? sentAt;
  final DateTime? decidedAt;
  final String? decidedNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;
  final DateTime? deletedAt;
  const Proof({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.orderId,
    required this.revision,
    required this.kind,
    required this.label,
    required this.url,
    this.note,
    required this.status,
    this.sentAt,
    this.decidedAt,
    this.decidedNote,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['order_id'] = Variable<String>(orderId);
    map['revision'] = Variable<int>(revision);
    map['kind'] = Variable<String>(kind);
    map['label'] = Variable<String>(label);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    if (!nullToAbsent || decidedNote != null) {
      map['decided_note'] = Variable<String>(decidedNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProofsCompanion toCompanion(bool nullToAbsent) {
    return ProofsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      orderId: Value(orderId),
      revision: Value(revision),
      kind: Value(kind),
      label: Value(label),
      url: Value(url),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      decidedNote: decidedNote == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Proof.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Proof(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      orderId: serializer.fromJson<String>(json['orderId']),
      revision: serializer.fromJson<int>(json['revision']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String>(json['label']),
      url: serializer.fromJson<String>(json['url']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      decidedNote: serializer.fromJson<String?>(json['decidedNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'orderId': serializer.toJson<String>(orderId),
      'revision': serializer.toJson<int>(revision),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String>(label),
      'url': serializer.toJson<String>(url),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'decidedNote': serializer.toJson<String?>(decidedNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Proof copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? orderId,
    int? revision,
    String? kind,
    String? label,
    String? url,
    Value<String?> note = const Value.absent(),
    String? status,
    Value<DateTime?> sentAt = const Value.absent(),
    Value<DateTime?> decidedAt = const Value.absent(),
    Value<String?> decidedNote = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Proof(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    orderId: orderId ?? this.orderId,
    revision: revision ?? this.revision,
    kind: kind ?? this.kind,
    label: label ?? this.label,
    url: url ?? this.url,
    note: note.present ? note.value : this.note,
    status: status ?? this.status,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    decidedNote: decidedNote.present ? decidedNote.value : this.decidedNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Proof copyWithCompanion(ProofsCompanion data) {
    return Proof(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      revision: data.revision.present ? data.revision.value : this.revision,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      url: data.url.present ? data.url.value : this.url,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      decidedNote: data.decidedNote.present
          ? data.decidedNote.value
          : this.decidedNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Proof(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('revision: $revision, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('url: $url, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('decidedNote: $decidedNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    branchId,
    orderId,
    revision,
    kind,
    label,
    url,
    note,
    status,
    sentAt,
    decidedAt,
    decidedNote,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Proof &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.orderId == this.orderId &&
          other.revision == this.revision &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.url == this.url &&
          other.note == this.note &&
          other.status == this.status &&
          other.sentAt == this.sentAt &&
          other.decidedAt == this.decidedAt &&
          other.decidedNote == this.decidedNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class ProofsCompanion extends UpdateCompanion<Proof> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> orderId;
  final Value<int> revision;
  final Value<String> kind;
  final Value<String> label;
  final Value<String> url;
  final Value<String?> note;
  final Value<String> status;
  final Value<DateTime?> sentAt;
  final Value<DateTime?> decidedAt;
  final Value<String?> decidedNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProofsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.revision = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.url = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.decidedNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProofsCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String orderId,
    this.revision = const Value.absent(),
    this.kind = const Value.absent(),
    required String label,
    required String url,
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.decidedNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       orderId = Value(orderId),
       label = Value(label),
       url = Value(url),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Proof> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? orderId,
    Expression<int>? revision,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<String>? url,
    Expression<String>? note,
    Expression<String>? status,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? decidedAt,
    Expression<String>? decidedNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (orderId != null) 'order_id': orderId,
      if (revision != null) 'revision': revision,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (url != null) 'url': url,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (sentAt != null) 'sent_at': sentAt,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (decidedNote != null) 'decided_note': decidedNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProofsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? orderId,
    Value<int>? revision,
    Value<String>? kind,
    Value<String>? label,
    Value<String>? url,
    Value<String?>? note,
    Value<String>? status,
    Value<DateTime?>? sentAt,
    Value<DateTime?>? decidedAt,
    Value<String?>? decidedNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProofsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      orderId: orderId ?? this.orderId,
      revision: revision ?? this.revision,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      url: url ?? this.url,
      note: note ?? this.note,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      decidedAt: decidedAt ?? this.decidedAt,
      decidedNote: decidedNote ?? this.decidedNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (decidedNote.present) {
      map['decided_note'] = Variable<String>(decidedNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProofsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('revision: $revision, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('url: $url, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('decidedNote: $decidedNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeEntriesTable extends TimeEntries
    with TableInfo<$TimeEntriesTable, TimeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoMeta = const VerificationMeta('auto');
  @override
  late final GeneratedColumn<bool> auto = GeneratedColumn<bool>(
    'auto',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    taskId,
    orderId,
    userId,
    startedAt,
    endedAt,
    minutes,
    auto,
    createdAt,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('auto')) {
      context.handle(
        _autoMeta,
        auto.isAcceptableOrUnknown(data['auto']!, _autoMeta),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      auto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TimeEntriesTable createAlias(String alias) {
    return $TimeEntriesTable(attachedDatabase, alias);
  }
}

class TimeEntry extends DataClass implements Insertable<TimeEntry> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String taskId;
  final String orderId;
  final String? userId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int minutes;
  final bool auto;
  final DateTime createdAt;
  final int version;
  final DateTime? deletedAt;
  const TimeEntry({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.taskId,
    required this.orderId,
    this.userId,
    required this.startedAt,
    required this.endedAt,
    required this.minutes,
    required this.auto,
    required this.createdAt,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['task_id'] = Variable<String>(taskId);
    map['order_id'] = Variable<String>(orderId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['minutes'] = Variable<int>(minutes);
    map['auto'] = Variable<bool>(auto);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TimeEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimeEntriesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      taskId: Value(taskId),
      orderId: Value(orderId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      minutes: Value(minutes),
      auto: Value(auto),
      createdAt: Value(createdAt),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TimeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeEntry(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      orderId: serializer.fromJson<String>(json['orderId']),
      userId: serializer.fromJson<String?>(json['userId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      minutes: serializer.fromJson<int>(json['minutes']),
      auto: serializer.fromJson<bool>(json['auto']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'taskId': serializer.toJson<String>(taskId),
      'orderId': serializer.toJson<String>(orderId),
      'userId': serializer.toJson<String?>(userId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'minutes': serializer.toJson<int>(minutes),
      'auto': serializer.toJson<bool>(auto),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TimeEntry copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? taskId,
    String? orderId,
    Value<String?> userId = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    int? minutes,
    bool? auto,
    DateTime? createdAt,
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TimeEntry(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    taskId: taskId ?? this.taskId,
    orderId: orderId ?? this.orderId,
    userId: userId.present ? userId.value : this.userId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    minutes: minutes ?? this.minutes,
    auto: auto ?? this.auto,
    createdAt: createdAt ?? this.createdAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TimeEntry copyWithCompanion(TimeEntriesCompanion data) {
    return TimeEntry(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      userId: data.userId.present ? data.userId.value : this.userId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      auto: data.auto.present ? data.auto.value : this.auto,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeEntry(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('taskId: $taskId, ')
          ..write('orderId: $orderId, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('minutes: $minutes, ')
          ..write('auto: $auto, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    branchId,
    taskId,
    orderId,
    userId,
    startedAt,
    endedAt,
    minutes,
    auto,
    createdAt,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeEntry &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.taskId == this.taskId &&
          other.orderId == this.orderId &&
          other.userId == this.userId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.minutes == this.minutes &&
          other.auto == this.auto &&
          other.createdAt == this.createdAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class TimeEntriesCompanion extends UpdateCompanion<TimeEntry> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> taskId;
  final Value<String> orderId;
  final Value<String?> userId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> minutes;
  final Value<bool> auto;
  final Value<DateTime> createdAt;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TimeEntriesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.userId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.minutes = const Value.absent(),
    this.auto = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeEntriesCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String taskId,
    required String orderId,
    this.userId = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required int minutes,
    this.auto = const Value.absent(),
    required DateTime createdAt,
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       taskId = Value(taskId),
       orderId = Value(orderId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       minutes = Value(minutes),
       createdAt = Value(createdAt);
  static Insertable<TimeEntry> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? taskId,
    Expression<String>? orderId,
    Expression<String>? userId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? minutes,
    Expression<bool>? auto,
    Expression<DateTime>? createdAt,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (taskId != null) 'task_id': taskId,
      if (orderId != null) 'order_id': orderId,
      if (userId != null) 'user_id': userId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (minutes != null) 'minutes': minutes,
      if (auto != null) 'auto': auto,
      if (createdAt != null) 'created_at': createdAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? taskId,
    Value<String>? orderId,
    Value<String?>? userId,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? minutes,
    Value<bool>? auto,
    Value<DateTime>? createdAt,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TimeEntriesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      taskId: taskId ?? this.taskId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      minutes: minutes ?? this.minutes,
      auto: auto ?? this.auto,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (auto.present) {
      map['auto'] = Variable<bool>(auto.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('taskId: $taskId, ')
          ..write('orderId: $orderId, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('minutes: $minutes, ')
          ..write('auto: $auto, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerTrnMeta = const VerificationMeta(
    'customerTrn',
  );
  @override
  late final GeneratedColumn<String> customerTrn = GeneratedColumn<String>(
    'customer_trn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerAddressMeta = const VerificationMeta(
    'customerAddress',
  );
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
    'customer_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalFilsMeta = const VerificationMeta(
    'subtotalFils',
  );
  @override
  late final GeneratedColumn<int> subtotalFils = GeneratedColumn<int>(
    'subtotal_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountFilsMeta = const VerificationMeta(
    'discountFils',
  );
  @override
  late final GeneratedColumn<int> discountFils = GeneratedColumn<int>(
    'discount_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vatBpsMeta = const VerificationMeta('vatBps');
  @override
  late final GeneratedColumn<int> vatBps = GeneratedColumn<int>(
    'vat_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _vatFilsMeta = const VerificationMeta(
    'vatFils',
  );
  @override
  late final GeneratedColumn<int> vatFils = GeneratedColumn<int>(
    'vat_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFilsMeta = const VerificationMeta(
    'totalFils',
  );
  @override
  late final GeneratedColumn<int> totalFils = GeneratedColumn<int>(
    'total_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidFilsMeta = const VerificationMeta(
    'paidFils',
  );
  @override
  late final GeneratedColumn<int> paidFils = GeneratedColumn<int>(
    'paid_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('issued'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    orderId,
    number,
    issuedAt,
    dueAt,
    customerId,
    customerName,
    customerTrn,
    customerAddress,
    subtotalFils,
    discountFils,
    vatBps,
    vatFils,
    totalFils,
    paidFils,
    status,
    notes,
    voidReason,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Invoice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_trn')) {
      context.handle(
        _customerTrnMeta,
        customerTrn.isAcceptableOrUnknown(
          data['customer_trn']!,
          _customerTrnMeta,
        ),
      );
    }
    if (data.containsKey('customer_address')) {
      context.handle(
        _customerAddressMeta,
        customerAddress.isAcceptableOrUnknown(
          data['customer_address']!,
          _customerAddressMeta,
        ),
      );
    }
    if (data.containsKey('subtotal_fils')) {
      context.handle(
        _subtotalFilsMeta,
        subtotalFils.isAcceptableOrUnknown(
          data['subtotal_fils']!,
          _subtotalFilsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalFilsMeta);
    }
    if (data.containsKey('discount_fils')) {
      context.handle(
        _discountFilsMeta,
        discountFils.isAcceptableOrUnknown(
          data['discount_fils']!,
          _discountFilsMeta,
        ),
      );
    }
    if (data.containsKey('vat_bps')) {
      context.handle(
        _vatBpsMeta,
        vatBps.isAcceptableOrUnknown(data['vat_bps']!, _vatBpsMeta),
      );
    }
    if (data.containsKey('vat_fils')) {
      context.handle(
        _vatFilsMeta,
        vatFils.isAcceptableOrUnknown(data['vat_fils']!, _vatFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_vatFilsMeta);
    }
    if (data.containsKey('total_fils')) {
      context.handle(
        _totalFilsMeta,
        totalFils.isAcceptableOrUnknown(data['total_fils']!, _totalFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalFilsMeta);
    }
    if (data.containsKey('paid_fils')) {
      context.handle(
        _paidFilsMeta,
        paidFils.isAcceptableOrUnknown(data['paid_fils']!, _paidFilsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerTrn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_trn'],
      ),
      customerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address'],
      ),
      subtotalFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_fils'],
      )!,
      discountFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_fils'],
      )!,
      vatBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_bps'],
      )!,
      vatFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_fils'],
      )!,
      totalFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_fils'],
      )!,
      paidFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_fils'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String orderId;
  final String number;
  final DateTime issuedAt;
  final DateTime? dueAt;
  final String customerId;
  final String customerName;
  final String? customerTrn;
  final String? customerAddress;
  final int subtotalFils;
  final int discountFils;
  final int vatBps;
  final int vatFils;
  final int totalFils;
  final int paidFils;
  final String status;
  final String? notes;
  final String? voidReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;
  final DateTime? deletedAt;
  const Invoice({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.orderId,
    required this.number,
    required this.issuedAt,
    this.dueAt,
    required this.customerId,
    required this.customerName,
    this.customerTrn,
    this.customerAddress,
    required this.subtotalFils,
    required this.discountFils,
    required this.vatBps,
    required this.vatFils,
    required this.totalFils,
    required this.paidFils,
    required this.status,
    this.notes,
    this.voidReason,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['order_id'] = Variable<String>(orderId);
    map['number'] = Variable<String>(number);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || customerTrn != null) {
      map['customer_trn'] = Variable<String>(customerTrn);
    }
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    map['subtotal_fils'] = Variable<int>(subtotalFils);
    map['discount_fils'] = Variable<int>(discountFils);
    map['vat_bps'] = Variable<int>(vatBps);
    map['vat_fils'] = Variable<int>(vatFils);
    map['total_fils'] = Variable<int>(totalFils);
    map['paid_fils'] = Variable<int>(paidFils);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      orderId: Value(orderId),
      number: Value(number),
      issuedAt: Value(issuedAt),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      customerId: Value(customerId),
      customerName: Value(customerName),
      customerTrn: customerTrn == null && nullToAbsent
          ? const Value.absent()
          : Value(customerTrn),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      subtotalFils: Value(subtotalFils),
      discountFils: Value(discountFils),
      vatBps: Value(vatBps),
      vatFils: Value(vatFils),
      totalFils: Value(totalFils),
      paidFils: Value(paidFils),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      orderId: serializer.fromJson<String>(json['orderId']),
      number: serializer.fromJson<String>(json['number']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerTrn: serializer.fromJson<String?>(json['customerTrn']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      subtotalFils: serializer.fromJson<int>(json['subtotalFils']),
      discountFils: serializer.fromJson<int>(json['discountFils']),
      vatBps: serializer.fromJson<int>(json['vatBps']),
      vatFils: serializer.fromJson<int>(json['vatFils']),
      totalFils: serializer.fromJson<int>(json['totalFils']),
      paidFils: serializer.fromJson<int>(json['paidFils']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'orderId': serializer.toJson<String>(orderId),
      'number': serializer.toJson<String>(number),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'customerId': serializer.toJson<String>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'customerTrn': serializer.toJson<String?>(customerTrn),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'subtotalFils': serializer.toJson<int>(subtotalFils),
      'discountFils': serializer.toJson<int>(discountFils),
      'vatBps': serializer.toJson<int>(vatBps),
      'vatFils': serializer.toJson<int>(vatFils),
      'totalFils': serializer.toJson<int>(totalFils),
      'paidFils': serializer.toJson<int>(paidFils),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'voidReason': serializer.toJson<String?>(voidReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Invoice copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? orderId,
    String? number,
    DateTime? issuedAt,
    Value<DateTime?> dueAt = const Value.absent(),
    String? customerId,
    String? customerName,
    Value<String?> customerTrn = const Value.absent(),
    Value<String?> customerAddress = const Value.absent(),
    int? subtotalFils,
    int? discountFils,
    int? vatBps,
    int? vatFils,
    int? totalFils,
    int? paidFils,
    String? status,
    Value<String?> notes = const Value.absent(),
    Value<String?> voidReason = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Invoice(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    orderId: orderId ?? this.orderId,
    number: number ?? this.number,
    issuedAt: issuedAt ?? this.issuedAt,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerTrn: customerTrn.present ? customerTrn.value : this.customerTrn,
    customerAddress: customerAddress.present
        ? customerAddress.value
        : this.customerAddress,
    subtotalFils: subtotalFils ?? this.subtotalFils,
    discountFils: discountFils ?? this.discountFils,
    vatBps: vatBps ?? this.vatBps,
    vatFils: vatFils ?? this.vatFils,
    totalFils: totalFils ?? this.totalFils,
    paidFils: paidFils ?? this.paidFils,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      number: data.number.present ? data.number.value : this.number,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerTrn: data.customerTrn.present
          ? data.customerTrn.value
          : this.customerTrn,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      subtotalFils: data.subtotalFils.present
          ? data.subtotalFils.value
          : this.subtotalFils,
      discountFils: data.discountFils.present
          ? data.discountFils.value
          : this.discountFils,
      vatBps: data.vatBps.present ? data.vatBps.value : this.vatBps,
      vatFils: data.vatFils.present ? data.vatFils.value : this.vatFils,
      totalFils: data.totalFils.present ? data.totalFils.value : this.totalFils,
      paidFils: data.paidFils.present ? data.paidFils.value : this.paidFils,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('number: $number, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerTrn: $customerTrn, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('subtotalFils: $subtotalFils, ')
          ..write('discountFils: $discountFils, ')
          ..write('vatBps: $vatBps, ')
          ..write('vatFils: $vatFils, ')
          ..write('totalFils: $totalFils, ')
          ..write('paidFils: $paidFils, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('voidReason: $voidReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    branchId,
    orderId,
    number,
    issuedAt,
    dueAt,
    customerId,
    customerName,
    customerTrn,
    customerAddress,
    subtotalFils,
    discountFils,
    vatBps,
    vatFils,
    totalFils,
    paidFils,
    status,
    notes,
    voidReason,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.orderId == this.orderId &&
          other.number == this.number &&
          other.issuedAt == this.issuedAt &&
          other.dueAt == this.dueAt &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerTrn == this.customerTrn &&
          other.customerAddress == this.customerAddress &&
          other.subtotalFils == this.subtotalFils &&
          other.discountFils == this.discountFils &&
          other.vatBps == this.vatBps &&
          other.vatFils == this.vatFils &&
          other.totalFils == this.totalFils &&
          other.paidFils == this.paidFils &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.voidReason == this.voidReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> orderId;
  final Value<String> number;
  final Value<DateTime> issuedAt;
  final Value<DateTime?> dueAt;
  final Value<String> customerId;
  final Value<String> customerName;
  final Value<String?> customerTrn;
  final Value<String?> customerAddress;
  final Value<int> subtotalFils;
  final Value<int> discountFils;
  final Value<int> vatBps;
  final Value<int> vatFils;
  final Value<int> totalFils;
  final Value<int> paidFils;
  final Value<String> status;
  final Value<String?> notes;
  final Value<String?> voidReason;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.number = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerTrn = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.subtotalFils = const Value.absent(),
    this.discountFils = const Value.absent(),
    this.vatBps = const Value.absent(),
    this.vatFils = const Value.absent(),
    this.totalFils = const Value.absent(),
    this.paidFils = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String orderId,
    required String number,
    required DateTime issuedAt,
    this.dueAt = const Value.absent(),
    required String customerId,
    required String customerName,
    this.customerTrn = const Value.absent(),
    this.customerAddress = const Value.absent(),
    required int subtotalFils,
    this.discountFils = const Value.absent(),
    this.vatBps = const Value.absent(),
    required int vatFils,
    required int totalFils,
    this.paidFils = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.voidReason = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       orderId = Value(orderId),
       number = Value(number),
       issuedAt = Value(issuedAt),
       customerId = Value(customerId),
       customerName = Value(customerName),
       subtotalFils = Value(subtotalFils),
       vatFils = Value(vatFils),
       totalFils = Value(totalFils),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Invoice> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? orderId,
    Expression<String>? number,
    Expression<DateTime>? issuedAt,
    Expression<DateTime>? dueAt,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerTrn,
    Expression<String>? customerAddress,
    Expression<int>? subtotalFils,
    Expression<int>? discountFils,
    Expression<int>? vatBps,
    Expression<int>? vatFils,
    Expression<int>? totalFils,
    Expression<int>? paidFils,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? voidReason,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (orderId != null) 'order_id': orderId,
      if (number != null) 'number': number,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (dueAt != null) 'due_at': dueAt,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerTrn != null) 'customer_trn': customerTrn,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (subtotalFils != null) 'subtotal_fils': subtotalFils,
      if (discountFils != null) 'discount_fils': discountFils,
      if (vatBps != null) 'vat_bps': vatBps,
      if (vatFils != null) 'vat_fils': vatFils,
      if (totalFils != null) 'total_fils': totalFils,
      if (paidFils != null) 'paid_fils': paidFils,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (voidReason != null) 'void_reason': voidReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? orderId,
    Value<String>? number,
    Value<DateTime>? issuedAt,
    Value<DateTime?>? dueAt,
    Value<String>? customerId,
    Value<String>? customerName,
    Value<String?>? customerTrn,
    Value<String?>? customerAddress,
    Value<int>? subtotalFils,
    Value<int>? discountFils,
    Value<int>? vatBps,
    Value<int>? vatFils,
    Value<int>? totalFils,
    Value<int>? paidFils,
    Value<String>? status,
    Value<String?>? notes,
    Value<String?>? voidReason,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      orderId: orderId ?? this.orderId,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: dueAt ?? this.dueAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerTrn: customerTrn ?? this.customerTrn,
      customerAddress: customerAddress ?? this.customerAddress,
      subtotalFils: subtotalFils ?? this.subtotalFils,
      discountFils: discountFils ?? this.discountFils,
      vatBps: vatBps ?? this.vatBps,
      vatFils: vatFils ?? this.vatFils,
      totalFils: totalFils ?? this.totalFils,
      paidFils: paidFils ?? this.paidFils,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      voidReason: voidReason ?? this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerTrn.present) {
      map['customer_trn'] = Variable<String>(customerTrn.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (subtotalFils.present) {
      map['subtotal_fils'] = Variable<int>(subtotalFils.value);
    }
    if (discountFils.present) {
      map['discount_fils'] = Variable<int>(discountFils.value);
    }
    if (vatBps.present) {
      map['vat_bps'] = Variable<int>(vatBps.value);
    }
    if (vatFils.present) {
      map['vat_fils'] = Variable<int>(vatFils.value);
    }
    if (totalFils.present) {
      map['total_fils'] = Variable<int>(totalFils.value);
    }
    if (paidFils.present) {
      map['paid_fils'] = Variable<int>(paidFils.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('number: $number, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerTrn: $customerTrn, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('subtotalFils: $subtotalFils, ')
          ..write('discountFils: $discountFils, ')
          ..write('vatBps: $vatBps, ')
          ..write('vatFils: $vatFils, ')
          ..write('totalFils: $totalFils, ')
          ..write('paidFils: $paidFils, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('voidReason: $voidReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceLinesTable extends InvoiceLines
    with TableInfo<$InvoiceLinesTable, InvoiceLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineNoMeta = const VerificationMeta('lineNo');
  @override
  late final GeneratedColumn<int> lineNo = GeneratedColumn<int>(
    'line_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitFilsMeta = const VerificationMeta(
    'unitFils',
  );
  @override
  late final GeneratedColumn<int> unitFils = GeneratedColumn<int>(
    'unit_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountFilsMeta = const VerificationMeta(
    'amountFils',
  );
  @override
  late final GeneratedColumn<int> amountFils = GeneratedColumn<int>(
    'amount_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatBpsMeta = const VerificationMeta('vatBps');
  @override
  late final GeneratedColumn<int> vatBps = GeneratedColumn<int>(
    'vat_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    invoiceId,
    lineNo,
    description,
    quantity,
    unitFils,
    amountFils,
    vatBps,
    createdAt,
    updatedAt,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('line_no')) {
      context.handle(
        _lineNoMeta,
        lineNo.isAcceptableOrUnknown(data['line_no']!, _lineNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNoMeta);
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
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_fils')) {
      context.handle(
        _unitFilsMeta,
        unitFils.isAcceptableOrUnknown(data['unit_fils']!, _unitFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_unitFilsMeta);
    }
    if (data.containsKey('amount_fils')) {
      context.handle(
        _amountFilsMeta,
        amountFils.isAcceptableOrUnknown(data['amount_fils']!, _amountFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_amountFilsMeta);
    }
    if (data.containsKey('vat_bps')) {
      context.handle(
        _vatBpsMeta,
        vatBps.isAcceptableOrUnknown(data['vat_bps']!, _vatBpsMeta),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      lineNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_no'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_fils'],
      )!,
      amountFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_fils'],
      )!,
      vatBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_bps'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $InvoiceLinesTable createAlias(String alias) {
    return $InvoiceLinesTable(attachedDatabase, alias);
  }
}

class InvoiceLine extends DataClass implements Insertable<InvoiceLine> {
  final String id;
  final String tenantId;
  final String invoiceId;
  final int lineNo;
  final String description;
  final int quantity;
  final int unitFils;
  final int amountFils;
  final int vatBps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final DateTime? deletedAt;
  const InvoiceLine({
    required this.id,
    required this.tenantId,
    required this.invoiceId,
    required this.lineNo,
    required this.description,
    required this.quantity,
    required this.unitFils,
    required this.amountFils,
    required this.vatBps,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['line_no'] = Variable<int>(lineNo);
    map['description'] = Variable<String>(description);
    map['quantity'] = Variable<int>(quantity);
    map['unit_fils'] = Variable<int>(unitFils);
    map['amount_fils'] = Variable<int>(amountFils);
    map['vat_bps'] = Variable<int>(vatBps);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  InvoiceLinesCompanion toCompanion(bool nullToAbsent) {
    return InvoiceLinesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      invoiceId: Value(invoiceId),
      lineNo: Value(lineNo),
      description: Value(description),
      quantity: Value(quantity),
      unitFils: Value(unitFils),
      amountFils: Value(amountFils),
      vatBps: Value(vatBps),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory InvoiceLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceLine(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      lineNo: serializer.fromJson<int>(json['lineNo']),
      description: serializer.fromJson<String>(json['description']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitFils: serializer.fromJson<int>(json['unitFils']),
      amountFils: serializer.fromJson<int>(json['amountFils']),
      vatBps: serializer.fromJson<int>(json['vatBps']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'lineNo': serializer.toJson<int>(lineNo),
      'description': serializer.toJson<String>(description),
      'quantity': serializer.toJson<int>(quantity),
      'unitFils': serializer.toJson<int>(unitFils),
      'amountFils': serializer.toJson<int>(amountFils),
      'vatBps': serializer.toJson<int>(vatBps),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  InvoiceLine copyWith({
    String? id,
    String? tenantId,
    String? invoiceId,
    int? lineNo,
    String? description,
    int? quantity,
    int? unitFils,
    int? amountFils,
    int? vatBps,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => InvoiceLine(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    invoiceId: invoiceId ?? this.invoiceId,
    lineNo: lineNo ?? this.lineNo,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitFils: unitFils ?? this.unitFils,
    amountFils: amountFils ?? this.amountFils,
    vatBps: vatBps ?? this.vatBps,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  InvoiceLine copyWithCompanion(InvoiceLinesCompanion data) {
    return InvoiceLine(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      lineNo: data.lineNo.present ? data.lineNo.value : this.lineNo,
      description: data.description.present
          ? data.description.value
          : this.description,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitFils: data.unitFils.present ? data.unitFils.value : this.unitFils,
      amountFils: data.amountFils.present
          ? data.amountFils.value
          : this.amountFils,
      vatBps: data.vatBps.present ? data.vatBps.value : this.vatBps,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceLine(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('lineNo: $lineNo, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitFils: $unitFils, ')
          ..write('amountFils: $amountFils, ')
          ..write('vatBps: $vatBps, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    invoiceId,
    lineNo,
    description,
    quantity,
    unitFils,
    amountFils,
    vatBps,
    createdAt,
    updatedAt,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceLine &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.invoiceId == this.invoiceId &&
          other.lineNo == this.lineNo &&
          other.description == this.description &&
          other.quantity == this.quantity &&
          other.unitFils == this.unitFils &&
          other.amountFils == this.amountFils &&
          other.vatBps == this.vatBps &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class InvoiceLinesCompanion extends UpdateCompanion<InvoiceLine> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> invoiceId;
  final Value<int> lineNo;
  final Value<String> description;
  final Value<int> quantity;
  final Value<int> unitFils;
  final Value<int> amountFils;
  final Value<int> vatBps;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const InvoiceLinesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.lineNo = const Value.absent(),
    this.description = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitFils = const Value.absent(),
    this.amountFils = const Value.absent(),
    this.vatBps = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceLinesCompanion.insert({
    required String id,
    required String tenantId,
    required String invoiceId,
    required int lineNo,
    required String description,
    required int quantity,
    required int unitFils,
    required int amountFils,
    this.vatBps = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       invoiceId = Value(invoiceId),
       lineNo = Value(lineNo),
       description = Value(description),
       quantity = Value(quantity),
       unitFils = Value(unitFils),
       amountFils = Value(amountFils),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InvoiceLine> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? invoiceId,
    Expression<int>? lineNo,
    Expression<String>? description,
    Expression<int>? quantity,
    Expression<int>? unitFils,
    Expression<int>? amountFils,
    Expression<int>? vatBps,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (lineNo != null) 'line_no': lineNo,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (unitFils != null) 'unit_fils': unitFils,
      if (amountFils != null) 'amount_fils': amountFils,
      if (vatBps != null) 'vat_bps': vatBps,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? invoiceId,
    Value<int>? lineNo,
    Value<String>? description,
    Value<int>? quantity,
    Value<int>? unitFils,
    Value<int>? amountFils,
    Value<int>? vatBps,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return InvoiceLinesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      invoiceId: invoiceId ?? this.invoiceId,
      lineNo: lineNo ?? this.lineNo,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitFils: unitFils ?? this.unitFils,
      amountFils: amountFils ?? this.amountFils,
      vatBps: vatBps ?? this.vatBps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (lineNo.present) {
      map['line_no'] = Variable<int>(lineNo.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitFils.present) {
      map['unit_fils'] = Variable<int>(unitFils.value);
    }
    if (amountFils.present) {
      map['amount_fils'] = Variable<int>(amountFils.value);
    }
    if (vatBps.present) {
      map['vat_bps'] = Variable<int>(vatBps.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceLinesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('lineNo: $lineNo, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitFils: $unitFils, ')
          ..write('amountFils: $amountFils, ')
          ..write('vatBps: $vatBps, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountFilsMeta = const VerificationMeta(
    'amountFils',
  );
  @override
  late final GeneratedColumn<int> amountFils = GeneratedColumn<int>(
    'amount_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenByMeta = const VerificationMeta(
    'takenBy',
  );
  @override
  late final GeneratedColumn<String> takenBy = GeneratedColumn<String>(
    'taken_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    invoiceId,
    amountFils,
    method,
    reference,
    takenAt,
    takenBy,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('amount_fils')) {
      context.handle(
        _amountFilsMeta,
        amountFils.isAcceptableOrUnknown(data['amount_fils']!, _amountFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_amountFilsMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('taken_by')) {
      context.handle(
        _takenByMeta,
        takenBy.isAcceptableOrUnknown(data['taken_by']!, _takenByMeta),
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      amountFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_fils'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      takenBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taken_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String invoiceId;
  final int amountFils;
  final String method;
  final String? reference;
  final DateTime takenAt;
  final String? takenBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;
  final DateTime? deletedAt;
  const Payment({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.invoiceId,
    required this.amountFils,
    required this.method,
    this.reference,
    required this.takenAt,
    this.takenBy,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['invoice_id'] = Variable<String>(invoiceId);
    map['amount_fils'] = Variable<int>(amountFils);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    if (!nullToAbsent || takenBy != null) {
      map['taken_by'] = Variable<String>(takenBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      invoiceId: Value(invoiceId),
      amountFils: Value(amountFils),
      method: Value(method),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      takenAt: Value(takenAt),
      takenBy: takenBy == null && nullToAbsent
          ? const Value.absent()
          : Value(takenBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      amountFils: serializer.fromJson<int>(json['amountFils']),
      method: serializer.fromJson<String>(json['method']),
      reference: serializer.fromJson<String?>(json['reference']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      takenBy: serializer.fromJson<String?>(json['takenBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'amountFils': serializer.toJson<int>(amountFils),
      'method': serializer.toJson<String>(method),
      'reference': serializer.toJson<String?>(reference),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'takenBy': serializer.toJson<String?>(takenBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Payment copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? invoiceId,
    int? amountFils,
    String? method,
    Value<String?> reference = const Value.absent(),
    DateTime? takenAt,
    Value<String?> takenBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Payment(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    invoiceId: invoiceId ?? this.invoiceId,
    amountFils: amountFils ?? this.amountFils,
    method: method ?? this.method,
    reference: reference.present ? reference.value : this.reference,
    takenAt: takenAt ?? this.takenAt,
    takenBy: takenBy.present ? takenBy.value : this.takenBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      amountFils: data.amountFils.present
          ? data.amountFils.value
          : this.amountFils,
      method: data.method.present ? data.method.value : this.method,
      reference: data.reference.present ? data.reference.value : this.reference,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      takenBy: data.takenBy.present ? data.takenBy.value : this.takenBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amountFils: $amountFils, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('takenAt: $takenAt, ')
          ..write('takenBy: $takenBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    branchId,
    invoiceId,
    amountFils,
    method,
    reference,
    takenAt,
    takenBy,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.invoiceId == this.invoiceId &&
          other.amountFils == this.amountFils &&
          other.method == this.method &&
          other.reference == this.reference &&
          other.takenAt == this.takenAt &&
          other.takenBy == this.takenBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> invoiceId;
  final Value<int> amountFils;
  final Value<String> method;
  final Value<String?> reference;
  final Value<DateTime> takenAt;
  final Value<String?> takenBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.amountFils = const Value.absent(),
    this.method = const Value.absent(),
    this.reference = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.takenBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String invoiceId,
    required int amountFils,
    required String method,
    this.reference = const Value.absent(),
    required DateTime takenAt,
    this.takenBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       invoiceId = Value(invoiceId),
       amountFils = Value(amountFils),
       method = Value(method),
       takenAt = Value(takenAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Payment> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? invoiceId,
    Expression<int>? amountFils,
    Expression<String>? method,
    Expression<String>? reference,
    Expression<DateTime>? takenAt,
    Expression<String>? takenBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (amountFils != null) 'amount_fils': amountFils,
      if (method != null) 'method': method,
      if (reference != null) 'reference': reference,
      if (takenAt != null) 'taken_at': takenAt,
      if (takenBy != null) 'taken_by': takenBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? invoiceId,
    Value<int>? amountFils,
    Value<String>? method,
    Value<String?>? reference,
    Value<DateTime>? takenAt,
    Value<String?>? takenBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      invoiceId: invoiceId ?? this.invoiceId,
      amountFils: amountFils ?? this.amountFils,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      takenAt: takenAt ?? this.takenAt,
      takenBy: takenBy ?? this.takenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (amountFils.present) {
      map['amount_fils'] = Variable<int>(amountFils.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (takenBy.present) {
      map['taken_by'] = Variable<String>(takenBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amountFils: $amountFils, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('takenAt: $takenAt, ')
          ..write('takenBy: $takenBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricingModeMeta = const VerificationMeta(
    'pricingMode',
  );
  @override
  late final GeneratedColumn<String> pricingMode = GeneratedColumn<String>(
    'pricing_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sheetWidthMmMeta = const VerificationMeta(
    'sheetWidthMm',
  );
  @override
  late final GeneratedColumn<int> sheetWidthMm = GeneratedColumn<int>(
    'sheet_width_mm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sheetHeightMmMeta = const VerificationMeta(
    'sheetHeightMm',
  );
  @override
  late final GeneratedColumn<int> sheetHeightMm = GeneratedColumn<int>(
    'sheet_height_mm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bleedMmMeta = const VerificationMeta(
    'bleedMm',
  );
  @override
  late final GeneratedColumn<int> bleedMm = GeneratedColumn<int>(
    'bleed_mm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _gutterMmMeta = const VerificationMeta(
    'gutterMm',
  );
  @override
  late final GeneratedColumn<int> gutterMm = GeneratedColumn<int>(
    'gutter_mm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _setupSheetsMeta = const VerificationMeta(
    'setupSheets',
  );
  @override
  late final GeneratedColumn<int> setupSheets = GeneratedColumn<int>(
    'setup_sheets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _spoilageBpsMeta = const VerificationMeta(
    'spoilageBps',
  );
  @override
  late final GeneratedColumn<int> spoilageBps = GeneratedColumn<int>(
    'spoilage_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _materialCodeMeta = const VerificationMeta(
    'materialCode',
  );
  @override
  late final GeneratedColumn<String> materialCode = GeneratedColumn<String>(
    'material_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printRateFilsMeta = const VerificationMeta(
    'printRateFils',
  );
  @override
  late final GeneratedColumn<int> printRateFils = GeneratedColumn<int>(
    'print_rate_fils',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaRateFilsPerSqmMeta =
      const VerificationMeta('areaRateFilsPerSqm');
  @override
  late final GeneratedColumn<int> areaRateFilsPerSqm = GeneratedColumn<int>(
    'area_rate_fils_per_sqm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _markupBpsMeta = const VerificationMeta(
    'markupBps',
  );
  @override
  late final GeneratedColumn<int> markupBps = GeneratedColumn<int>(
    'markup_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minOrderFilsMeta = const VerificationMeta(
    'minOrderFils',
  );
  @override
  late final GeneratedColumn<int> minOrderFils = GeneratedColumn<int>(
    'min_order_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roundingStepFilsMeta = const VerificationMeta(
    'roundingStepFils',
  );
  @override
  late final GeneratedColumn<int> roundingStepFils = GeneratedColumn<int>(
    'rounding_step_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _sizesJsonMeta = const VerificationMeta(
    'sizesJson',
  );
  @override
  late final GeneratedColumn<String> sizesJson = GeneratedColumn<String>(
    'sizes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _finishesJsonMeta = const VerificationMeta(
    'finishesJson',
  );
  @override
  late final GeneratedColumn<String> finishesJson = GeneratedColumn<String>(
    'finishes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _quantityPresetsJsonMeta =
      const VerificationMeta('quantityPresetsJson');
  @override
  late final GeneratedColumn<String> quantityPresetsJson =
      GeneratedColumn<String>(
        'quantity_presets_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _workflowKeyMeta = const VerificationMeta(
    'workflowKey',
  );
  @override
  late final GeneratedColumn<String> workflowKey = GeneratedColumn<String>(
    'workflow_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('print_std'),
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    code,
    nameEn,
    nameAr,
    category,
    kind,
    pricingMode,
    sheetWidthMm,
    sheetHeightMm,
    bleedMm,
    gutterMm,
    setupSheets,
    spoilageBps,
    materialCode,
    printRateFils,
    areaRateFilsPerSqm,
    markupBps,
    minOrderFils,
    roundingStepFils,
    sizesJson,
    finishesJson,
    quantityPresetsJson,
    workflowKey,
    sort,
    active,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('pricing_mode')) {
      context.handle(
        _pricingModeMeta,
        pricingMode.isAcceptableOrUnknown(
          data['pricing_mode']!,
          _pricingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricingModeMeta);
    }
    if (data.containsKey('sheet_width_mm')) {
      context.handle(
        _sheetWidthMmMeta,
        sheetWidthMm.isAcceptableOrUnknown(
          data['sheet_width_mm']!,
          _sheetWidthMmMeta,
        ),
      );
    }
    if (data.containsKey('sheet_height_mm')) {
      context.handle(
        _sheetHeightMmMeta,
        sheetHeightMm.isAcceptableOrUnknown(
          data['sheet_height_mm']!,
          _sheetHeightMmMeta,
        ),
      );
    }
    if (data.containsKey('bleed_mm')) {
      context.handle(
        _bleedMmMeta,
        bleedMm.isAcceptableOrUnknown(data['bleed_mm']!, _bleedMmMeta),
      );
    }
    if (data.containsKey('gutter_mm')) {
      context.handle(
        _gutterMmMeta,
        gutterMm.isAcceptableOrUnknown(data['gutter_mm']!, _gutterMmMeta),
      );
    }
    if (data.containsKey('setup_sheets')) {
      context.handle(
        _setupSheetsMeta,
        setupSheets.isAcceptableOrUnknown(
          data['setup_sheets']!,
          _setupSheetsMeta,
        ),
      );
    }
    if (data.containsKey('spoilage_bps')) {
      context.handle(
        _spoilageBpsMeta,
        spoilageBps.isAcceptableOrUnknown(
          data['spoilage_bps']!,
          _spoilageBpsMeta,
        ),
      );
    }
    if (data.containsKey('material_code')) {
      context.handle(
        _materialCodeMeta,
        materialCode.isAcceptableOrUnknown(
          data['material_code']!,
          _materialCodeMeta,
        ),
      );
    }
    if (data.containsKey('print_rate_fils')) {
      context.handle(
        _printRateFilsMeta,
        printRateFils.isAcceptableOrUnknown(
          data['print_rate_fils']!,
          _printRateFilsMeta,
        ),
      );
    }
    if (data.containsKey('area_rate_fils_per_sqm')) {
      context.handle(
        _areaRateFilsPerSqmMeta,
        areaRateFilsPerSqm.isAcceptableOrUnknown(
          data['area_rate_fils_per_sqm']!,
          _areaRateFilsPerSqmMeta,
        ),
      );
    }
    if (data.containsKey('markup_bps')) {
      context.handle(
        _markupBpsMeta,
        markupBps.isAcceptableOrUnknown(data['markup_bps']!, _markupBpsMeta),
      );
    }
    if (data.containsKey('min_order_fils')) {
      context.handle(
        _minOrderFilsMeta,
        minOrderFils.isAcceptableOrUnknown(
          data['min_order_fils']!,
          _minOrderFilsMeta,
        ),
      );
    }
    if (data.containsKey('rounding_step_fils')) {
      context.handle(
        _roundingStepFilsMeta,
        roundingStepFils.isAcceptableOrUnknown(
          data['rounding_step_fils']!,
          _roundingStepFilsMeta,
        ),
      );
    }
    if (data.containsKey('sizes_json')) {
      context.handle(
        _sizesJsonMeta,
        sizesJson.isAcceptableOrUnknown(data['sizes_json']!, _sizesJsonMeta),
      );
    }
    if (data.containsKey('finishes_json')) {
      context.handle(
        _finishesJsonMeta,
        finishesJson.isAcceptableOrUnknown(
          data['finishes_json']!,
          _finishesJsonMeta,
        ),
      );
    }
    if (data.containsKey('quantity_presets_json')) {
      context.handle(
        _quantityPresetsJsonMeta,
        quantityPresetsJson.isAcceptableOrUnknown(
          data['quantity_presets_json']!,
          _quantityPresetsJsonMeta,
        ),
      );
    }
    if (data.containsKey('workflow_key')) {
      context.handle(
        _workflowKeyMeta,
        workflowKey.isAcceptableOrUnknown(
          data['workflow_key']!,
          _workflowKeyMeta,
        ),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      pricingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pricing_mode'],
      )!,
      sheetWidthMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sheet_width_mm'],
      ),
      sheetHeightMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sheet_height_mm'],
      ),
      bleedMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bleed_mm'],
      )!,
      gutterMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gutter_mm'],
      )!,
      setupSheets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}setup_sheets'],
      )!,
      spoilageBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spoilage_bps'],
      )!,
      materialCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material_code'],
      ),
      printRateFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}print_rate_fils'],
      ),
      areaRateFilsPerSqm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}area_rate_fils_per_sqm'],
      ),
      markupBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}markup_bps'],
      )!,
      minOrderFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_order_fils'],
      )!,
      roundingStepFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounding_step_fils'],
      )!,
      sizesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sizes_json'],
      )!,
      finishesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finishes_json'],
      )!,
      quantityPresetsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_presets_json'],
      )!,
      workflowKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_key'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String tenantId;
  final String code;
  final String nameEn;
  final String? nameAr;
  final String? category;
  final String kind;

  /// `cost_plus`, `price_table` or `vendor_markup`.
  final String pricingMode;
  final int? sheetWidthMm;
  final int? sheetHeightMm;
  final int bleedMm;
  final int gutterMm;
  final int setupSheets;
  final int spoilageBps;
  final String? materialCode;
  final int? printRateFils;
  final int? areaRateFilsPerSqm;
  final int markupBps;
  final int minOrderFils;
  final int roundingStepFils;
  final String sizesJson;
  final String finishesJson;
  final String quantityPresetsJson;

  /// Which production workflow this product creates (see WorkflowStages).
  final String workflowKey;
  final int sort;
  final bool active;
  final DateTime? updatedAt;
  const Product({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.nameEn,
    this.nameAr,
    this.category,
    required this.kind,
    required this.pricingMode,
    this.sheetWidthMm,
    this.sheetHeightMm,
    required this.bleedMm,
    required this.gutterMm,
    required this.setupSheets,
    required this.spoilageBps,
    this.materialCode,
    this.printRateFils,
    this.areaRateFilsPerSqm,
    required this.markupBps,
    required this.minOrderFils,
    required this.roundingStepFils,
    required this.sizesJson,
    required this.finishesJson,
    required this.quantityPresetsJson,
    required this.workflowKey,
    required this.sort,
    required this.active,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['code'] = Variable<String>(code);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['kind'] = Variable<String>(kind);
    map['pricing_mode'] = Variable<String>(pricingMode);
    if (!nullToAbsent || sheetWidthMm != null) {
      map['sheet_width_mm'] = Variable<int>(sheetWidthMm);
    }
    if (!nullToAbsent || sheetHeightMm != null) {
      map['sheet_height_mm'] = Variable<int>(sheetHeightMm);
    }
    map['bleed_mm'] = Variable<int>(bleedMm);
    map['gutter_mm'] = Variable<int>(gutterMm);
    map['setup_sheets'] = Variable<int>(setupSheets);
    map['spoilage_bps'] = Variable<int>(spoilageBps);
    if (!nullToAbsent || materialCode != null) {
      map['material_code'] = Variable<String>(materialCode);
    }
    if (!nullToAbsent || printRateFils != null) {
      map['print_rate_fils'] = Variable<int>(printRateFils);
    }
    if (!nullToAbsent || areaRateFilsPerSqm != null) {
      map['area_rate_fils_per_sqm'] = Variable<int>(areaRateFilsPerSqm);
    }
    map['markup_bps'] = Variable<int>(markupBps);
    map['min_order_fils'] = Variable<int>(minOrderFils);
    map['rounding_step_fils'] = Variable<int>(roundingStepFils);
    map['sizes_json'] = Variable<String>(sizesJson);
    map['finishes_json'] = Variable<String>(finishesJson);
    map['quantity_presets_json'] = Variable<String>(quantityPresetsJson);
    map['workflow_key'] = Variable<String>(workflowKey);
    map['sort'] = Variable<int>(sort);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      code: Value(code),
      nameEn: Value(nameEn),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      kind: Value(kind),
      pricingMode: Value(pricingMode),
      sheetWidthMm: sheetWidthMm == null && nullToAbsent
          ? const Value.absent()
          : Value(sheetWidthMm),
      sheetHeightMm: sheetHeightMm == null && nullToAbsent
          ? const Value.absent()
          : Value(sheetHeightMm),
      bleedMm: Value(bleedMm),
      gutterMm: Value(gutterMm),
      setupSheets: Value(setupSheets),
      spoilageBps: Value(spoilageBps),
      materialCode: materialCode == null && nullToAbsent
          ? const Value.absent()
          : Value(materialCode),
      printRateFils: printRateFils == null && nullToAbsent
          ? const Value.absent()
          : Value(printRateFils),
      areaRateFilsPerSqm: areaRateFilsPerSqm == null && nullToAbsent
          ? const Value.absent()
          : Value(areaRateFilsPerSqm),
      markupBps: Value(markupBps),
      minOrderFils: Value(minOrderFils),
      roundingStepFils: Value(roundingStepFils),
      sizesJson: Value(sizesJson),
      finishesJson: Value(finishesJson),
      quantityPresetsJson: Value(quantityPresetsJson),
      workflowKey: Value(workflowKey),
      sort: Value(sort),
      active: Value(active),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      code: serializer.fromJson<String>(json['code']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      category: serializer.fromJson<String?>(json['category']),
      kind: serializer.fromJson<String>(json['kind']),
      pricingMode: serializer.fromJson<String>(json['pricingMode']),
      sheetWidthMm: serializer.fromJson<int?>(json['sheetWidthMm']),
      sheetHeightMm: serializer.fromJson<int?>(json['sheetHeightMm']),
      bleedMm: serializer.fromJson<int>(json['bleedMm']),
      gutterMm: serializer.fromJson<int>(json['gutterMm']),
      setupSheets: serializer.fromJson<int>(json['setupSheets']),
      spoilageBps: serializer.fromJson<int>(json['spoilageBps']),
      materialCode: serializer.fromJson<String?>(json['materialCode']),
      printRateFils: serializer.fromJson<int?>(json['printRateFils']),
      areaRateFilsPerSqm: serializer.fromJson<int?>(json['areaRateFilsPerSqm']),
      markupBps: serializer.fromJson<int>(json['markupBps']),
      minOrderFils: serializer.fromJson<int>(json['minOrderFils']),
      roundingStepFils: serializer.fromJson<int>(json['roundingStepFils']),
      sizesJson: serializer.fromJson<String>(json['sizesJson']),
      finishesJson: serializer.fromJson<String>(json['finishesJson']),
      quantityPresetsJson: serializer.fromJson<String>(
        json['quantityPresetsJson'],
      ),
      workflowKey: serializer.fromJson<String>(json['workflowKey']),
      sort: serializer.fromJson<int>(json['sort']),
      active: serializer.fromJson<bool>(json['active']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'code': serializer.toJson<String>(code),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameAr': serializer.toJson<String?>(nameAr),
      'category': serializer.toJson<String?>(category),
      'kind': serializer.toJson<String>(kind),
      'pricingMode': serializer.toJson<String>(pricingMode),
      'sheetWidthMm': serializer.toJson<int?>(sheetWidthMm),
      'sheetHeightMm': serializer.toJson<int?>(sheetHeightMm),
      'bleedMm': serializer.toJson<int>(bleedMm),
      'gutterMm': serializer.toJson<int>(gutterMm),
      'setupSheets': serializer.toJson<int>(setupSheets),
      'spoilageBps': serializer.toJson<int>(spoilageBps),
      'materialCode': serializer.toJson<String?>(materialCode),
      'printRateFils': serializer.toJson<int?>(printRateFils),
      'areaRateFilsPerSqm': serializer.toJson<int?>(areaRateFilsPerSqm),
      'markupBps': serializer.toJson<int>(markupBps),
      'minOrderFils': serializer.toJson<int>(minOrderFils),
      'roundingStepFils': serializer.toJson<int>(roundingStepFils),
      'sizesJson': serializer.toJson<String>(sizesJson),
      'finishesJson': serializer.toJson<String>(finishesJson),
      'quantityPresetsJson': serializer.toJson<String>(quantityPresetsJson),
      'workflowKey': serializer.toJson<String>(workflowKey),
      'sort': serializer.toJson<int>(sort),
      'active': serializer.toJson<bool>(active),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? tenantId,
    String? code,
    String? nameEn,
    Value<String?> nameAr = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? kind,
    String? pricingMode,
    Value<int?> sheetWidthMm = const Value.absent(),
    Value<int?> sheetHeightMm = const Value.absent(),
    int? bleedMm,
    int? gutterMm,
    int? setupSheets,
    int? spoilageBps,
    Value<String?> materialCode = const Value.absent(),
    Value<int?> printRateFils = const Value.absent(),
    Value<int?> areaRateFilsPerSqm = const Value.absent(),
    int? markupBps,
    int? minOrderFils,
    int? roundingStepFils,
    String? sizesJson,
    String? finishesJson,
    String? quantityPresetsJson,
    String? workflowKey,
    int? sort,
    bool? active,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    code: code ?? this.code,
    nameEn: nameEn ?? this.nameEn,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    category: category.present ? category.value : this.category,
    kind: kind ?? this.kind,
    pricingMode: pricingMode ?? this.pricingMode,
    sheetWidthMm: sheetWidthMm.present ? sheetWidthMm.value : this.sheetWidthMm,
    sheetHeightMm: sheetHeightMm.present
        ? sheetHeightMm.value
        : this.sheetHeightMm,
    bleedMm: bleedMm ?? this.bleedMm,
    gutterMm: gutterMm ?? this.gutterMm,
    setupSheets: setupSheets ?? this.setupSheets,
    spoilageBps: spoilageBps ?? this.spoilageBps,
    materialCode: materialCode.present ? materialCode.value : this.materialCode,
    printRateFils: printRateFils.present
        ? printRateFils.value
        : this.printRateFils,
    areaRateFilsPerSqm: areaRateFilsPerSqm.present
        ? areaRateFilsPerSqm.value
        : this.areaRateFilsPerSqm,
    markupBps: markupBps ?? this.markupBps,
    minOrderFils: minOrderFils ?? this.minOrderFils,
    roundingStepFils: roundingStepFils ?? this.roundingStepFils,
    sizesJson: sizesJson ?? this.sizesJson,
    finishesJson: finishesJson ?? this.finishesJson,
    quantityPresetsJson: quantityPresetsJson ?? this.quantityPresetsJson,
    workflowKey: workflowKey ?? this.workflowKey,
    sort: sort ?? this.sort,
    active: active ?? this.active,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      code: data.code.present ? data.code.value : this.code,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      category: data.category.present ? data.category.value : this.category,
      kind: data.kind.present ? data.kind.value : this.kind,
      pricingMode: data.pricingMode.present
          ? data.pricingMode.value
          : this.pricingMode,
      sheetWidthMm: data.sheetWidthMm.present
          ? data.sheetWidthMm.value
          : this.sheetWidthMm,
      sheetHeightMm: data.sheetHeightMm.present
          ? data.sheetHeightMm.value
          : this.sheetHeightMm,
      bleedMm: data.bleedMm.present ? data.bleedMm.value : this.bleedMm,
      gutterMm: data.gutterMm.present ? data.gutterMm.value : this.gutterMm,
      setupSheets: data.setupSheets.present
          ? data.setupSheets.value
          : this.setupSheets,
      spoilageBps: data.spoilageBps.present
          ? data.spoilageBps.value
          : this.spoilageBps,
      materialCode: data.materialCode.present
          ? data.materialCode.value
          : this.materialCode,
      printRateFils: data.printRateFils.present
          ? data.printRateFils.value
          : this.printRateFils,
      areaRateFilsPerSqm: data.areaRateFilsPerSqm.present
          ? data.areaRateFilsPerSqm.value
          : this.areaRateFilsPerSqm,
      markupBps: data.markupBps.present ? data.markupBps.value : this.markupBps,
      minOrderFils: data.minOrderFils.present
          ? data.minOrderFils.value
          : this.minOrderFils,
      roundingStepFils: data.roundingStepFils.present
          ? data.roundingStepFils.value
          : this.roundingStepFils,
      sizesJson: data.sizesJson.present ? data.sizesJson.value : this.sizesJson,
      finishesJson: data.finishesJson.present
          ? data.finishesJson.value
          : this.finishesJson,
      quantityPresetsJson: data.quantityPresetsJson.present
          ? data.quantityPresetsJson.value
          : this.quantityPresetsJson,
      workflowKey: data.workflowKey.present
          ? data.workflowKey.value
          : this.workflowKey,
      sort: data.sort.present ? data.sort.value : this.sort,
      active: data.active.present ? data.active.value : this.active,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('code: $code, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('category: $category, ')
          ..write('kind: $kind, ')
          ..write('pricingMode: $pricingMode, ')
          ..write('sheetWidthMm: $sheetWidthMm, ')
          ..write('sheetHeightMm: $sheetHeightMm, ')
          ..write('bleedMm: $bleedMm, ')
          ..write('gutterMm: $gutterMm, ')
          ..write('setupSheets: $setupSheets, ')
          ..write('spoilageBps: $spoilageBps, ')
          ..write('materialCode: $materialCode, ')
          ..write('printRateFils: $printRateFils, ')
          ..write('areaRateFilsPerSqm: $areaRateFilsPerSqm, ')
          ..write('markupBps: $markupBps, ')
          ..write('minOrderFils: $minOrderFils, ')
          ..write('roundingStepFils: $roundingStepFils, ')
          ..write('sizesJson: $sizesJson, ')
          ..write('finishesJson: $finishesJson, ')
          ..write('quantityPresetsJson: $quantityPresetsJson, ')
          ..write('workflowKey: $workflowKey, ')
          ..write('sort: $sort, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    code,
    nameEn,
    nameAr,
    category,
    kind,
    pricingMode,
    sheetWidthMm,
    sheetHeightMm,
    bleedMm,
    gutterMm,
    setupSheets,
    spoilageBps,
    materialCode,
    printRateFils,
    areaRateFilsPerSqm,
    markupBps,
    minOrderFils,
    roundingStepFils,
    sizesJson,
    finishesJson,
    quantityPresetsJson,
    workflowKey,
    sort,
    active,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.code == this.code &&
          other.nameEn == this.nameEn &&
          other.nameAr == this.nameAr &&
          other.category == this.category &&
          other.kind == this.kind &&
          other.pricingMode == this.pricingMode &&
          other.sheetWidthMm == this.sheetWidthMm &&
          other.sheetHeightMm == this.sheetHeightMm &&
          other.bleedMm == this.bleedMm &&
          other.gutterMm == this.gutterMm &&
          other.setupSheets == this.setupSheets &&
          other.spoilageBps == this.spoilageBps &&
          other.materialCode == this.materialCode &&
          other.printRateFils == this.printRateFils &&
          other.areaRateFilsPerSqm == this.areaRateFilsPerSqm &&
          other.markupBps == this.markupBps &&
          other.minOrderFils == this.minOrderFils &&
          other.roundingStepFils == this.roundingStepFils &&
          other.sizesJson == this.sizesJson &&
          other.finishesJson == this.finishesJson &&
          other.quantityPresetsJson == this.quantityPresetsJson &&
          other.workflowKey == this.workflowKey &&
          other.sort == this.sort &&
          other.active == this.active &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> code;
  final Value<String> nameEn;
  final Value<String?> nameAr;
  final Value<String?> category;
  final Value<String> kind;
  final Value<String> pricingMode;
  final Value<int?> sheetWidthMm;
  final Value<int?> sheetHeightMm;
  final Value<int> bleedMm;
  final Value<int> gutterMm;
  final Value<int> setupSheets;
  final Value<int> spoilageBps;
  final Value<String?> materialCode;
  final Value<int?> printRateFils;
  final Value<int?> areaRateFilsPerSqm;
  final Value<int> markupBps;
  final Value<int> minOrderFils;
  final Value<int> roundingStepFils;
  final Value<String> sizesJson;
  final Value<String> finishesJson;
  final Value<String> quantityPresetsJson;
  final Value<String> workflowKey;
  final Value<int> sort;
  final Value<bool> active;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.code = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.category = const Value.absent(),
    this.kind = const Value.absent(),
    this.pricingMode = const Value.absent(),
    this.sheetWidthMm = const Value.absent(),
    this.sheetHeightMm = const Value.absent(),
    this.bleedMm = const Value.absent(),
    this.gutterMm = const Value.absent(),
    this.setupSheets = const Value.absent(),
    this.spoilageBps = const Value.absent(),
    this.materialCode = const Value.absent(),
    this.printRateFils = const Value.absent(),
    this.areaRateFilsPerSqm = const Value.absent(),
    this.markupBps = const Value.absent(),
    this.minOrderFils = const Value.absent(),
    this.roundingStepFils = const Value.absent(),
    this.sizesJson = const Value.absent(),
    this.finishesJson = const Value.absent(),
    this.quantityPresetsJson = const Value.absent(),
    this.workflowKey = const Value.absent(),
    this.sort = const Value.absent(),
    this.active = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String tenantId,
    required String code,
    required String nameEn,
    this.nameAr = const Value.absent(),
    this.category = const Value.absent(),
    required String kind,
    required String pricingMode,
    this.sheetWidthMm = const Value.absent(),
    this.sheetHeightMm = const Value.absent(),
    this.bleedMm = const Value.absent(),
    this.gutterMm = const Value.absent(),
    this.setupSheets = const Value.absent(),
    this.spoilageBps = const Value.absent(),
    this.materialCode = const Value.absent(),
    this.printRateFils = const Value.absent(),
    this.areaRateFilsPerSqm = const Value.absent(),
    this.markupBps = const Value.absent(),
    this.minOrderFils = const Value.absent(),
    this.roundingStepFils = const Value.absent(),
    this.sizesJson = const Value.absent(),
    this.finishesJson = const Value.absent(),
    this.quantityPresetsJson = const Value.absent(),
    this.workflowKey = const Value.absent(),
    this.sort = const Value.absent(),
    this.active = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       code = Value(code),
       nameEn = Value(nameEn),
       kind = Value(kind),
       pricingMode = Value(pricingMode);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? code,
    Expression<String>? nameEn,
    Expression<String>? nameAr,
    Expression<String>? category,
    Expression<String>? kind,
    Expression<String>? pricingMode,
    Expression<int>? sheetWidthMm,
    Expression<int>? sheetHeightMm,
    Expression<int>? bleedMm,
    Expression<int>? gutterMm,
    Expression<int>? setupSheets,
    Expression<int>? spoilageBps,
    Expression<String>? materialCode,
    Expression<int>? printRateFils,
    Expression<int>? areaRateFilsPerSqm,
    Expression<int>? markupBps,
    Expression<int>? minOrderFils,
    Expression<int>? roundingStepFils,
    Expression<String>? sizesJson,
    Expression<String>? finishesJson,
    Expression<String>? quantityPresetsJson,
    Expression<String>? workflowKey,
    Expression<int>? sort,
    Expression<bool>? active,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (code != null) 'code': code,
      if (nameEn != null) 'name_en': nameEn,
      if (nameAr != null) 'name_ar': nameAr,
      if (category != null) 'category': category,
      if (kind != null) 'kind': kind,
      if (pricingMode != null) 'pricing_mode': pricingMode,
      if (sheetWidthMm != null) 'sheet_width_mm': sheetWidthMm,
      if (sheetHeightMm != null) 'sheet_height_mm': sheetHeightMm,
      if (bleedMm != null) 'bleed_mm': bleedMm,
      if (gutterMm != null) 'gutter_mm': gutterMm,
      if (setupSheets != null) 'setup_sheets': setupSheets,
      if (spoilageBps != null) 'spoilage_bps': spoilageBps,
      if (materialCode != null) 'material_code': materialCode,
      if (printRateFils != null) 'print_rate_fils': printRateFils,
      if (areaRateFilsPerSqm != null)
        'area_rate_fils_per_sqm': areaRateFilsPerSqm,
      if (markupBps != null) 'markup_bps': markupBps,
      if (minOrderFils != null) 'min_order_fils': minOrderFils,
      if (roundingStepFils != null) 'rounding_step_fils': roundingStepFils,
      if (sizesJson != null) 'sizes_json': sizesJson,
      if (finishesJson != null) 'finishes_json': finishesJson,
      if (quantityPresetsJson != null)
        'quantity_presets_json': quantityPresetsJson,
      if (workflowKey != null) 'workflow_key': workflowKey,
      if (sort != null) 'sort': sort,
      if (active != null) 'active': active,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? code,
    Value<String>? nameEn,
    Value<String?>? nameAr,
    Value<String?>? category,
    Value<String>? kind,
    Value<String>? pricingMode,
    Value<int?>? sheetWidthMm,
    Value<int?>? sheetHeightMm,
    Value<int>? bleedMm,
    Value<int>? gutterMm,
    Value<int>? setupSheets,
    Value<int>? spoilageBps,
    Value<String?>? materialCode,
    Value<int?>? printRateFils,
    Value<int?>? areaRateFilsPerSqm,
    Value<int>? markupBps,
    Value<int>? minOrderFils,
    Value<int>? roundingStepFils,
    Value<String>? sizesJson,
    Value<String>? finishesJson,
    Value<String>? quantityPresetsJson,
    Value<String>? workflowKey,
    Value<int>? sort,
    Value<bool>? active,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      code: code ?? this.code,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      category: category ?? this.category,
      kind: kind ?? this.kind,
      pricingMode: pricingMode ?? this.pricingMode,
      sheetWidthMm: sheetWidthMm ?? this.sheetWidthMm,
      sheetHeightMm: sheetHeightMm ?? this.sheetHeightMm,
      bleedMm: bleedMm ?? this.bleedMm,
      gutterMm: gutterMm ?? this.gutterMm,
      setupSheets: setupSheets ?? this.setupSheets,
      spoilageBps: spoilageBps ?? this.spoilageBps,
      materialCode: materialCode ?? this.materialCode,
      printRateFils: printRateFils ?? this.printRateFils,
      areaRateFilsPerSqm: areaRateFilsPerSqm ?? this.areaRateFilsPerSqm,
      markupBps: markupBps ?? this.markupBps,
      minOrderFils: minOrderFils ?? this.minOrderFils,
      roundingStepFils: roundingStepFils ?? this.roundingStepFils,
      sizesJson: sizesJson ?? this.sizesJson,
      finishesJson: finishesJson ?? this.finishesJson,
      quantityPresetsJson: quantityPresetsJson ?? this.quantityPresetsJson,
      workflowKey: workflowKey ?? this.workflowKey,
      sort: sort ?? this.sort,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (pricingMode.present) {
      map['pricing_mode'] = Variable<String>(pricingMode.value);
    }
    if (sheetWidthMm.present) {
      map['sheet_width_mm'] = Variable<int>(sheetWidthMm.value);
    }
    if (sheetHeightMm.present) {
      map['sheet_height_mm'] = Variable<int>(sheetHeightMm.value);
    }
    if (bleedMm.present) {
      map['bleed_mm'] = Variable<int>(bleedMm.value);
    }
    if (gutterMm.present) {
      map['gutter_mm'] = Variable<int>(gutterMm.value);
    }
    if (setupSheets.present) {
      map['setup_sheets'] = Variable<int>(setupSheets.value);
    }
    if (spoilageBps.present) {
      map['spoilage_bps'] = Variable<int>(spoilageBps.value);
    }
    if (materialCode.present) {
      map['material_code'] = Variable<String>(materialCode.value);
    }
    if (printRateFils.present) {
      map['print_rate_fils'] = Variable<int>(printRateFils.value);
    }
    if (areaRateFilsPerSqm.present) {
      map['area_rate_fils_per_sqm'] = Variable<int>(areaRateFilsPerSqm.value);
    }
    if (markupBps.present) {
      map['markup_bps'] = Variable<int>(markupBps.value);
    }
    if (minOrderFils.present) {
      map['min_order_fils'] = Variable<int>(minOrderFils.value);
    }
    if (roundingStepFils.present) {
      map['rounding_step_fils'] = Variable<int>(roundingStepFils.value);
    }
    if (sizesJson.present) {
      map['sizes_json'] = Variable<String>(sizesJson.value);
    }
    if (finishesJson.present) {
      map['finishes_json'] = Variable<String>(finishesJson.value);
    }
    if (quantityPresetsJson.present) {
      map['quantity_presets_json'] = Variable<String>(
        quantityPresetsJson.value,
      );
    }
    if (workflowKey.present) {
      map['workflow_key'] = Variable<String>(workflowKey.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('code: $code, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('category: $category, ')
          ..write('kind: $kind, ')
          ..write('pricingMode: $pricingMode, ')
          ..write('sheetWidthMm: $sheetWidthMm, ')
          ..write('sheetHeightMm: $sheetHeightMm, ')
          ..write('bleedMm: $bleedMm, ')
          ..write('gutterMm: $gutterMm, ')
          ..write('setupSheets: $setupSheets, ')
          ..write('spoilageBps: $spoilageBps, ')
          ..write('materialCode: $materialCode, ')
          ..write('printRateFils: $printRateFils, ')
          ..write('areaRateFilsPerSqm: $areaRateFilsPerSqm, ')
          ..write('markupBps: $markupBps, ')
          ..write('minOrderFils: $minOrderFils, ')
          ..write('roundingStepFils: $roundingStepFils, ')
          ..write('sizesJson: $sizesJson, ')
          ..write('finishesJson: $finishesJson, ')
          ..write('quantityPresetsJson: $quantityPresetsJson, ')
          ..write('workflowKey: $workflowKey, ')
          ..write('sort: $sort, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialsTable extends Materials
    with TableInfo<$MaterialsTable, MaterialRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gsmMeta = const VerificationMeta('gsm');
  @override
  late final GeneratedColumn<int> gsm = GeneratedColumn<int>(
    'gsm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPerSheetFilsMeta = const VerificationMeta(
    'costPerSheetFils',
  );
  @override
  late final GeneratedColumn<int> costPerSheetFils = GeneratedColumn<int>(
    'cost_per_sheet_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    code,
    name,
    type,
    gsm,
    costPerSheetFils,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'materials';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('gsm')) {
      context.handle(
        _gsmMeta,
        gsm.isAcceptableOrUnknown(data['gsm']!, _gsmMeta),
      );
    }
    if (data.containsKey('cost_per_sheet_fils')) {
      context.handle(
        _costPerSheetFilsMeta,
        costPerSheetFils.isAcceptableOrUnknown(
          data['cost_per_sheet_fils']!,
          _costPerSheetFilsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaterialRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      gsm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gsm'],
      ),
      costPerSheetFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_per_sheet_fils'],
      )!,
    );
  }

  @override
  $MaterialsTable createAlias(String alias) {
    return $MaterialsTable(attachedDatabase, alias);
  }
}

class MaterialRow extends DataClass implements Insertable<MaterialRow> {
  final String id;
  final String tenantId;
  final String code;
  final String name;
  final String? type;
  final int? gsm;
  final int costPerSheetFils;
  const MaterialRow({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.name,
    this.type,
    this.gsm,
    required this.costPerSheetFils,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || gsm != null) {
      map['gsm'] = Variable<int>(gsm);
    }
    map['cost_per_sheet_fils'] = Variable<int>(costPerSheetFils);
    return map;
  }

  MaterialsCompanion toCompanion(bool nullToAbsent) {
    return MaterialsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      code: Value(code),
      name: Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      gsm: gsm == null && nullToAbsent ? const Value.absent() : Value(gsm),
      costPerSheetFils: Value(costPerSheetFils),
    );
  }

  factory MaterialRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      gsm: serializer.fromJson<int?>(json['gsm']),
      costPerSheetFils: serializer.fromJson<int>(json['costPerSheetFils']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String?>(type),
      'gsm': serializer.toJson<int?>(gsm),
      'costPerSheetFils': serializer.toJson<int>(costPerSheetFils),
    };
  }

  MaterialRow copyWith({
    String? id,
    String? tenantId,
    String? code,
    String? name,
    Value<String?> type = const Value.absent(),
    Value<int?> gsm = const Value.absent(),
    int? costPerSheetFils,
  }) => MaterialRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    code: code ?? this.code,
    name: name ?? this.name,
    type: type.present ? type.value : this.type,
    gsm: gsm.present ? gsm.value : this.gsm,
    costPerSheetFils: costPerSheetFils ?? this.costPerSheetFils,
  );
  MaterialRow copyWithCompanion(MaterialsCompanion data) {
    return MaterialRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      gsm: data.gsm.present ? data.gsm.value : this.gsm,
      costPerSheetFils: data.costPerSheetFils.present
          ? data.costPerSheetFils.value
          : this.costPerSheetFils,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('gsm: $gsm, ')
          ..write('costPerSheetFils: $costPerSheetFils')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tenantId, code, name, type, gsm, costPerSheetFils);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.code == this.code &&
          other.name == this.name &&
          other.type == this.type &&
          other.gsm == this.gsm &&
          other.costPerSheetFils == this.costPerSheetFils);
}

class MaterialsCompanion extends UpdateCompanion<MaterialRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> type;
  final Value<int?> gsm;
  final Value<int> costPerSheetFils;
  final Value<int> rowid;
  const MaterialsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.gsm = const Value.absent(),
    this.costPerSheetFils = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialsCompanion.insert({
    required String id,
    required String tenantId,
    required String code,
    required String name,
    this.type = const Value.absent(),
    this.gsm = const Value.absent(),
    this.costPerSheetFils = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       code = Value(code),
       name = Value(name);
  static Insertable<MaterialRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? gsm,
    Expression<int>? costPerSheetFils,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (gsm != null) 'gsm': gsm,
      if (costPerSheetFils != null) 'cost_per_sheet_fils': costPerSheetFils,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? code,
    Value<String>? name,
    Value<String?>? type,
    Value<int?>? gsm,
    Value<int>? costPerSheetFils,
    Value<int>? rowid,
  }) {
    return MaterialsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      gsm: gsm ?? this.gsm,
      costPerSheetFils: costPerSheetFils ?? this.costPerSheetFils,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (gsm.present) {
      map['gsm'] = Variable<int>(gsm.value);
    }
    if (costPerSheetFils.present) {
      map['cost_per_sheet_fils'] = Variable<int>(costPerSheetFils.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('gsm: $gsm, ')
          ..write('costPerSheetFils: $costPerSheetFils, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceRulesTable extends PriceRules
    with TableInfo<$PriceRulesTable, PriceRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceBookVersionMeta = const VerificationMeta(
    'priceBookVersion',
  );
  @override
  late final GeneratedColumn<int> priceBookVersion = GeneratedColumn<int>(
    'price_book_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _basisMeta = const VerificationMeta('basis');
  @override
  late final GeneratedColumn<String> basis = GeneratedColumn<String>(
    'basis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateFilsMeta = const VerificationMeta(
    'rateFils',
  );
  @override
  late final GeneratedColumn<int> rateFils = GeneratedColumn<int>(
    'rate_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minChargeFilsMeta = const VerificationMeta(
    'minChargeFils',
  );
  @override
  late final GeneratedColumn<int> minChargeFils = GeneratedColumn<int>(
    'min_charge_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _whenJsonMeta = const VerificationMeta(
    'whenJson',
  );
  @override
  late final GeneratedColumn<String> whenJson = GeneratedColumn<String>(
    'when_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    priceBookVersion,
    productId,
    label,
    phase,
    basis,
    rateFils,
    minChargeFils,
    priority,
    whenJson,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('price_book_version')) {
      context.handle(
        _priceBookVersionMeta,
        priceBookVersion.isAcceptableOrUnknown(
          data['price_book_version']!,
          _priceBookVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceBookVersionMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('basis')) {
      context.handle(
        _basisMeta,
        basis.isAcceptableOrUnknown(data['basis']!, _basisMeta),
      );
    } else if (isInserting) {
      context.missing(_basisMeta);
    }
    if (data.containsKey('rate_fils')) {
      context.handle(
        _rateFilsMeta,
        rateFils.isAcceptableOrUnknown(data['rate_fils']!, _rateFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_rateFilsMeta);
    }
    if (data.containsKey('min_charge_fils')) {
      context.handle(
        _minChargeFilsMeta,
        minChargeFils.isAcceptableOrUnknown(
          data['min_charge_fils']!,
          _minChargeFilsMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('when_json')) {
      context.handle(
        _whenJsonMeta,
        whenJson.isAcceptableOrUnknown(data['when_json']!, _whenJsonMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      priceBookVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_book_version'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      basis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis'],
      )!,
      rateFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_fils'],
      )!,
      minChargeFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_charge_fils'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      whenJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}when_json'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $PriceRulesTable createAlias(String alias) {
    return $PriceRulesTable(attachedDatabase, alias);
  }
}

class PriceRuleRow extends DataClass implements Insertable<PriceRuleRow> {
  final String id;
  final String tenantId;
  final int priceBookVersion;
  final String? productId;
  final String label;
  final String phase;
  final String basis;
  final int rateFils;
  final int minChargeFils;
  final int priority;
  final String whenJson;
  final bool active;
  const PriceRuleRow({
    required this.id,
    required this.tenantId,
    required this.priceBookVersion,
    this.productId,
    required this.label,
    required this.phase,
    required this.basis,
    required this.rateFils,
    required this.minChargeFils,
    required this.priority,
    required this.whenJson,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['price_book_version'] = Variable<int>(priceBookVersion);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['label'] = Variable<String>(label);
    map['phase'] = Variable<String>(phase);
    map['basis'] = Variable<String>(basis);
    map['rate_fils'] = Variable<int>(rateFils);
    map['min_charge_fils'] = Variable<int>(minChargeFils);
    map['priority'] = Variable<int>(priority);
    map['when_json'] = Variable<String>(whenJson);
    map['active'] = Variable<bool>(active);
    return map;
  }

  PriceRulesCompanion toCompanion(bool nullToAbsent) {
    return PriceRulesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      priceBookVersion: Value(priceBookVersion),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      label: Value(label),
      phase: Value(phase),
      basis: Value(basis),
      rateFils: Value(rateFils),
      minChargeFils: Value(minChargeFils),
      priority: Value(priority),
      whenJson: Value(whenJson),
      active: Value(active),
    );
  }

  factory PriceRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceRuleRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      priceBookVersion: serializer.fromJson<int>(json['priceBookVersion']),
      productId: serializer.fromJson<String?>(json['productId']),
      label: serializer.fromJson<String>(json['label']),
      phase: serializer.fromJson<String>(json['phase']),
      basis: serializer.fromJson<String>(json['basis']),
      rateFils: serializer.fromJson<int>(json['rateFils']),
      minChargeFils: serializer.fromJson<int>(json['minChargeFils']),
      priority: serializer.fromJson<int>(json['priority']),
      whenJson: serializer.fromJson<String>(json['whenJson']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'priceBookVersion': serializer.toJson<int>(priceBookVersion),
      'productId': serializer.toJson<String?>(productId),
      'label': serializer.toJson<String>(label),
      'phase': serializer.toJson<String>(phase),
      'basis': serializer.toJson<String>(basis),
      'rateFils': serializer.toJson<int>(rateFils),
      'minChargeFils': serializer.toJson<int>(minChargeFils),
      'priority': serializer.toJson<int>(priority),
      'whenJson': serializer.toJson<String>(whenJson),
      'active': serializer.toJson<bool>(active),
    };
  }

  PriceRuleRow copyWith({
    String? id,
    String? tenantId,
    int? priceBookVersion,
    Value<String?> productId = const Value.absent(),
    String? label,
    String? phase,
    String? basis,
    int? rateFils,
    int? minChargeFils,
    int? priority,
    String? whenJson,
    bool? active,
  }) => PriceRuleRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    priceBookVersion: priceBookVersion ?? this.priceBookVersion,
    productId: productId.present ? productId.value : this.productId,
    label: label ?? this.label,
    phase: phase ?? this.phase,
    basis: basis ?? this.basis,
    rateFils: rateFils ?? this.rateFils,
    minChargeFils: minChargeFils ?? this.minChargeFils,
    priority: priority ?? this.priority,
    whenJson: whenJson ?? this.whenJson,
    active: active ?? this.active,
  );
  PriceRuleRow copyWithCompanion(PriceRulesCompanion data) {
    return PriceRuleRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      priceBookVersion: data.priceBookVersion.present
          ? data.priceBookVersion.value
          : this.priceBookVersion,
      productId: data.productId.present ? data.productId.value : this.productId,
      label: data.label.present ? data.label.value : this.label,
      phase: data.phase.present ? data.phase.value : this.phase,
      basis: data.basis.present ? data.basis.value : this.basis,
      rateFils: data.rateFils.present ? data.rateFils.value : this.rateFils,
      minChargeFils: data.minChargeFils.present
          ? data.minChargeFils.value
          : this.minChargeFils,
      priority: data.priority.present ? data.priority.value : this.priority,
      whenJson: data.whenJson.present ? data.whenJson.value : this.whenJson,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceRuleRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('priceBookVersion: $priceBookVersion, ')
          ..write('productId: $productId, ')
          ..write('label: $label, ')
          ..write('phase: $phase, ')
          ..write('basis: $basis, ')
          ..write('rateFils: $rateFils, ')
          ..write('minChargeFils: $minChargeFils, ')
          ..write('priority: $priority, ')
          ..write('whenJson: $whenJson, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    priceBookVersion,
    productId,
    label,
    phase,
    basis,
    rateFils,
    minChargeFils,
    priority,
    whenJson,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceRuleRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.priceBookVersion == this.priceBookVersion &&
          other.productId == this.productId &&
          other.label == this.label &&
          other.phase == this.phase &&
          other.basis == this.basis &&
          other.rateFils == this.rateFils &&
          other.minChargeFils == this.minChargeFils &&
          other.priority == this.priority &&
          other.whenJson == this.whenJson &&
          other.active == this.active);
}

class PriceRulesCompanion extends UpdateCompanion<PriceRuleRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<int> priceBookVersion;
  final Value<String?> productId;
  final Value<String> label;
  final Value<String> phase;
  final Value<String> basis;
  final Value<int> rateFils;
  final Value<int> minChargeFils;
  final Value<int> priority;
  final Value<String> whenJson;
  final Value<bool> active;
  final Value<int> rowid;
  const PriceRulesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.priceBookVersion = const Value.absent(),
    this.productId = const Value.absent(),
    this.label = const Value.absent(),
    this.phase = const Value.absent(),
    this.basis = const Value.absent(),
    this.rateFils = const Value.absent(),
    this.minChargeFils = const Value.absent(),
    this.priority = const Value.absent(),
    this.whenJson = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceRulesCompanion.insert({
    required String id,
    required String tenantId,
    required int priceBookVersion,
    this.productId = const Value.absent(),
    required String label,
    required String phase,
    required String basis,
    required int rateFils,
    this.minChargeFils = const Value.absent(),
    this.priority = const Value.absent(),
    this.whenJson = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       priceBookVersion = Value(priceBookVersion),
       label = Value(label),
       phase = Value(phase),
       basis = Value(basis),
       rateFils = Value(rateFils);
  static Insertable<PriceRuleRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<int>? priceBookVersion,
    Expression<String>? productId,
    Expression<String>? label,
    Expression<String>? phase,
    Expression<String>? basis,
    Expression<int>? rateFils,
    Expression<int>? minChargeFils,
    Expression<int>? priority,
    Expression<String>? whenJson,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (priceBookVersion != null) 'price_book_version': priceBookVersion,
      if (productId != null) 'product_id': productId,
      if (label != null) 'label': label,
      if (phase != null) 'phase': phase,
      if (basis != null) 'basis': basis,
      if (rateFils != null) 'rate_fils': rateFils,
      if (minChargeFils != null) 'min_charge_fils': minChargeFils,
      if (priority != null) 'priority': priority,
      if (whenJson != null) 'when_json': whenJson,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<int>? priceBookVersion,
    Value<String?>? productId,
    Value<String>? label,
    Value<String>? phase,
    Value<String>? basis,
    Value<int>? rateFils,
    Value<int>? minChargeFils,
    Value<int>? priority,
    Value<String>? whenJson,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return PriceRulesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      priceBookVersion: priceBookVersion ?? this.priceBookVersion,
      productId: productId ?? this.productId,
      label: label ?? this.label,
      phase: phase ?? this.phase,
      basis: basis ?? this.basis,
      rateFils: rateFils ?? this.rateFils,
      minChargeFils: minChargeFils ?? this.minChargeFils,
      priority: priority ?? this.priority,
      whenJson: whenJson ?? this.whenJson,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (priceBookVersion.present) {
      map['price_book_version'] = Variable<int>(priceBookVersion.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (basis.present) {
      map['basis'] = Variable<String>(basis.value);
    }
    if (rateFils.present) {
      map['rate_fils'] = Variable<int>(rateFils.value);
    }
    if (minChargeFils.present) {
      map['min_charge_fils'] = Variable<int>(minChargeFils.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (whenJson.present) {
      map['when_json'] = Variable<String>(whenJson.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceRulesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('priceBookVersion: $priceBookVersion, ')
          ..write('productId: $productId, ')
          ..write('label: $label, ')
          ..write('phase: $phase, ')
          ..write('basis: $basis, ')
          ..write('rateFils: $rateFils, ')
          ..write('minChargeFils: $minChargeFils, ')
          ..write('priority: $priority, ')
          ..write('whenJson: $whenJson, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberDisplayMeta = const VerificationMeta(
    'numberDisplay',
  );
  @override
  late final GeneratedColumn<String> numberDisplay = GeneratedColumn<String>(
    'number_display',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isQuoteMeta = const VerificationMeta(
    'isQuote',
  );
  @override
  late final GeneratedColumn<bool> isQuote = GeneratedColumn<bool>(
    'is_quote',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_quote" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('confirmed'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryMethodMeta = const VerificationMeta(
    'deliveryMethod',
  );
  @override
  late final GeneratedColumn<String> deliveryMethod = GeneratedColumn<String>(
    'delivery_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('collect'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalFilsMeta = const VerificationMeta(
    'subtotalFils',
  );
  @override
  late final GeneratedColumn<int> subtotalFils = GeneratedColumn<int>(
    'subtotal_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vatFilsMeta = const VerificationMeta(
    'vatFils',
  );
  @override
  late final GeneratedColumn<int> vatFils = GeneratedColumn<int>(
    'vat_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalFilsMeta = const VerificationMeta(
    'totalFils',
  );
  @override
  late final GeneratedColumn<int> totalFils = GeneratedColumn<int>(
    'total_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    number,
    numberDisplay,
    isQuote,
    customerId,
    customerName,
    status,
    priority,
    dueAt,
    deliveryMethod,
    notes,
    subtotalFils,
    vatFils,
    totalFils,
    itemCount,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('number_display')) {
      context.handle(
        _numberDisplayMeta,
        numberDisplay.isAcceptableOrUnknown(
          data['number_display']!,
          _numberDisplayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_numberDisplayMeta);
    }
    if (data.containsKey('is_quote')) {
      context.handle(
        _isQuoteMeta,
        isQuote.isAcceptableOrUnknown(data['is_quote']!, _isQuoteMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('delivery_method')) {
      context.handle(
        _deliveryMethodMeta,
        deliveryMethod.isAcceptableOrUnknown(
          data['delivery_method']!,
          _deliveryMethodMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('subtotal_fils')) {
      context.handle(
        _subtotalFilsMeta,
        subtotalFils.isAcceptableOrUnknown(
          data['subtotal_fils']!,
          _subtotalFilsMeta,
        ),
      );
    }
    if (data.containsKey('vat_fils')) {
      context.handle(
        _vatFilsMeta,
        vatFils.isAcceptableOrUnknown(data['vat_fils']!, _vatFilsMeta),
      );
    }
    if (data.containsKey('total_fils')) {
      context.handle(
        _totalFilsMeta,
        totalFils.isAcceptableOrUnknown(data['total_fils']!, _totalFilsMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      numberDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number_display'],
      )!,
      isQuote: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_quote'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      deliveryMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_method'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      subtotalFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_fils'],
      )!,
      vatFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_fils'],
      )!,
      totalFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_fils'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String tenantId;
  final String? branchId;

  /// Null while a device is offline and using a temporary `T-0007` display.
  final int? number;
  final String numberDisplay;
  final bool isQuote;
  final String customerId;
  final String? customerName;
  final String status;
  final String priority;
  final DateTime? dueAt;
  final String deliveryMethod;
  final String? notes;
  final int subtotalFils;
  final int vatFils;
  final int totalFils;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;
  final DateTime? deletedAt;
  const Order({
    required this.id,
    required this.tenantId,
    this.branchId,
    this.number,
    required this.numberDisplay,
    required this.isQuote,
    required this.customerId,
    this.customerName,
    required this.status,
    required this.priority,
    this.dueAt,
    required this.deliveryMethod,
    this.notes,
    required this.subtotalFils,
    required this.vatFils,
    required this.totalFils,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    map['number_display'] = Variable<String>(numberDisplay);
    map['is_quote'] = Variable<bool>(isQuote);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['delivery_method'] = Variable<String>(deliveryMethod);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['subtotal_fils'] = Variable<int>(subtotalFils);
    map['vat_fils'] = Variable<int>(vatFils);
    map['total_fils'] = Variable<int>(totalFils);
    map['item_count'] = Variable<int>(itemCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      numberDisplay: Value(numberDisplay),
      isQuote: Value(isQuote),
      customerId: Value(customerId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      status: Value(status),
      priority: Value(priority),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      deliveryMethod: Value(deliveryMethod),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      subtotalFils: Value(subtotalFils),
      vatFils: Value(vatFils),
      totalFils: Value(totalFils),
      itemCount: Value(itemCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      number: serializer.fromJson<int?>(json['number']),
      numberDisplay: serializer.fromJson<String>(json['numberDisplay']),
      isQuote: serializer.fromJson<bool>(json['isQuote']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      deliveryMethod: serializer.fromJson<String>(json['deliveryMethod']),
      notes: serializer.fromJson<String?>(json['notes']),
      subtotalFils: serializer.fromJson<int>(json['subtotalFils']),
      vatFils: serializer.fromJson<int>(json['vatFils']),
      totalFils: serializer.fromJson<int>(json['totalFils']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'number': serializer.toJson<int?>(number),
      'numberDisplay': serializer.toJson<String>(numberDisplay),
      'isQuote': serializer.toJson<bool>(isQuote),
      'customerId': serializer.toJson<String>(customerId),
      'customerName': serializer.toJson<String?>(customerName),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'deliveryMethod': serializer.toJson<String>(deliveryMethod),
      'notes': serializer.toJson<String?>(notes),
      'subtotalFils': serializer.toJson<int>(subtotalFils),
      'vatFils': serializer.toJson<int>(vatFils),
      'totalFils': serializer.toJson<int>(totalFils),
      'itemCount': serializer.toJson<int>(itemCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Order copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    Value<int?> number = const Value.absent(),
    String? numberDisplay,
    bool? isQuote,
    String? customerId,
    Value<String?> customerName = const Value.absent(),
    String? status,
    String? priority,
    Value<DateTime?> dueAt = const Value.absent(),
    String? deliveryMethod,
    Value<String?> notes = const Value.absent(),
    int? subtotalFils,
    int? vatFils,
    int? totalFils,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Order(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    number: number.present ? number.value : this.number,
    numberDisplay: numberDisplay ?? this.numberDisplay,
    isQuote: isQuote ?? this.isQuote,
    customerId: customerId ?? this.customerId,
    customerName: customerName.present ? customerName.value : this.customerName,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    deliveryMethod: deliveryMethod ?? this.deliveryMethod,
    notes: notes.present ? notes.value : this.notes,
    subtotalFils: subtotalFils ?? this.subtotalFils,
    vatFils: vatFils ?? this.vatFils,
    totalFils: totalFils ?? this.totalFils,
    itemCount: itemCount ?? this.itemCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      number: data.number.present ? data.number.value : this.number,
      numberDisplay: data.numberDisplay.present
          ? data.numberDisplay.value
          : this.numberDisplay,
      isQuote: data.isQuote.present ? data.isQuote.value : this.isQuote,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      deliveryMethod: data.deliveryMethod.present
          ? data.deliveryMethod.value
          : this.deliveryMethod,
      notes: data.notes.present ? data.notes.value : this.notes,
      subtotalFils: data.subtotalFils.present
          ? data.subtotalFils.value
          : this.subtotalFils,
      vatFils: data.vatFils.present ? data.vatFils.value : this.vatFils,
      totalFils: data.totalFils.present ? data.totalFils.value : this.totalFils,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('number: $number, ')
          ..write('numberDisplay: $numberDisplay, ')
          ..write('isQuote: $isQuote, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('deliveryMethod: $deliveryMethod, ')
          ..write('notes: $notes, ')
          ..write('subtotalFils: $subtotalFils, ')
          ..write('vatFils: $vatFils, ')
          ..write('totalFils: $totalFils, ')
          ..write('itemCount: $itemCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    branchId,
    number,
    numberDisplay,
    isQuote,
    customerId,
    customerName,
    status,
    priority,
    dueAt,
    deliveryMethod,
    notes,
    subtotalFils,
    vatFils,
    totalFils,
    itemCount,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.number == this.number &&
          other.numberDisplay == this.numberDisplay &&
          other.isQuote == this.isQuote &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueAt == this.dueAt &&
          other.deliveryMethod == this.deliveryMethod &&
          other.notes == this.notes &&
          other.subtotalFils == this.subtotalFils &&
          other.vatFils == this.vatFils &&
          other.totalFils == this.totalFils &&
          other.itemCount == this.itemCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<int?> number;
  final Value<String> numberDisplay;
  final Value<bool> isQuote;
  final Value<String> customerId;
  final Value<String?> customerName;
  final Value<String> status;
  final Value<String> priority;
  final Value<DateTime?> dueAt;
  final Value<String> deliveryMethod;
  final Value<String?> notes;
  final Value<int> subtotalFils;
  final Value<int> vatFils;
  final Value<int> totalFils;
  final Value<int> itemCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.number = const Value.absent(),
    this.numberDisplay = const Value.absent(),
    this.isQuote = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.deliveryMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.subtotalFils = const Value.absent(),
    this.vatFils = const Value.absent(),
    this.totalFils = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    this.number = const Value.absent(),
    required String numberDisplay,
    this.isQuote = const Value.absent(),
    required String customerId,
    this.customerName = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.deliveryMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.subtotalFils = const Value.absent(),
    this.vatFils = const Value.absent(),
    this.totalFils = const Value.absent(),
    this.itemCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       numberDisplay = Value(numberDisplay),
       customerId = Value(customerId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<int>? number,
    Expression<String>? numberDisplay,
    Expression<bool>? isQuote,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<DateTime>? dueAt,
    Expression<String>? deliveryMethod,
    Expression<String>? notes,
    Expression<int>? subtotalFils,
    Expression<int>? vatFils,
    Expression<int>? totalFils,
    Expression<int>? itemCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (number != null) 'number': number,
      if (numberDisplay != null) 'number_display': numberDisplay,
      if (isQuote != null) 'is_quote': isQuote,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueAt != null) 'due_at': dueAt,
      if (deliveryMethod != null) 'delivery_method': deliveryMethod,
      if (notes != null) 'notes': notes,
      if (subtotalFils != null) 'subtotal_fils': subtotalFils,
      if (vatFils != null) 'vat_fils': vatFils,
      if (totalFils != null) 'total_fils': totalFils,
      if (itemCount != null) 'item_count': itemCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<int?>? number,
    Value<String>? numberDisplay,
    Value<bool>? isQuote,
    Value<String>? customerId,
    Value<String?>? customerName,
    Value<String>? status,
    Value<String>? priority,
    Value<DateTime?>? dueAt,
    Value<String>? deliveryMethod,
    Value<String?>? notes,
    Value<int>? subtotalFils,
    Value<int>? vatFils,
    Value<int>? totalFils,
    Value<int>? itemCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      number: number ?? this.number,
      numberDisplay: numberDisplay ?? this.numberDisplay,
      isQuote: isQuote ?? this.isQuote,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      notes: notes ?? this.notes,
      subtotalFils: subtotalFils ?? this.subtotalFils,
      vatFils: vatFils ?? this.vatFils,
      totalFils: totalFils ?? this.totalFils,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (numberDisplay.present) {
      map['number_display'] = Variable<String>(numberDisplay.value);
    }
    if (isQuote.present) {
      map['is_quote'] = Variable<bool>(isQuote.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (deliveryMethod.present) {
      map['delivery_method'] = Variable<String>(deliveryMethod.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (subtotalFils.present) {
      map['subtotal_fils'] = Variable<int>(subtotalFils.value);
    }
    if (vatFils.present) {
      map['vat_fils'] = Variable<int>(vatFils.value);
    }
    if (totalFils.present) {
      map['total_fils'] = Variable<int>(totalFils.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('number: $number, ')
          ..write('numberDisplay: $numberDisplay, ')
          ..write('isQuote: $isQuote, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('deliveryMethod: $deliveryMethod, ')
          ..write('notes: $notes, ')
          ..write('subtotalFils: $subtotalFils, ')
          ..write('vatFils: $vatFils, ')
          ..write('totalFils: $totalFils, ')
          ..write('itemCount: $itemCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
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
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceBookVersionMeta = const VerificationMeta(
    'priceBookVersion',
  );
  @override
  late final GeneratedColumn<int> priceBookVersion = GeneratedColumn<int>(
    'price_book_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakdownJsonMeta = const VerificationMeta(
    'breakdownJson',
  );
  @override
  late final GeneratedColumn<String> breakdownJson = GeneratedColumn<String>(
    'breakdown_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalFilsMeta = const VerificationMeta(
    'subtotalFils',
  );
  @override
  late final GeneratedColumn<int> subtotalFils = GeneratedColumn<int>(
    'subtotal_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatFilsMeta = const VerificationMeta(
    'vatFils',
  );
  @override
  late final GeneratedColumn<int> vatFils = GeneratedColumn<int>(
    'vat_fils',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFilsMeta = const VerificationMeta(
    'totalFils',
  );
  @override
  late final GeneratedColumn<int> totalFils = GeneratedColumn<int>(
    'total_fils',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    orderId,
    productId,
    description,
    optionsJson,
    quantity,
    priceBookVersion,
    breakdownJson,
    subtotalFils,
    vatFils,
    totalFils,
    status,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
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
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('price_book_version')) {
      context.handle(
        _priceBookVersionMeta,
        priceBookVersion.isAcceptableOrUnknown(
          data['price_book_version']!,
          _priceBookVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceBookVersionMeta);
    }
    if (data.containsKey('breakdown_json')) {
      context.handle(
        _breakdownJsonMeta,
        breakdownJson.isAcceptableOrUnknown(
          data['breakdown_json']!,
          _breakdownJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breakdownJsonMeta);
    }
    if (data.containsKey('subtotal_fils')) {
      context.handle(
        _subtotalFilsMeta,
        subtotalFils.isAcceptableOrUnknown(
          data['subtotal_fils']!,
          _subtotalFilsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalFilsMeta);
    }
    if (data.containsKey('vat_fils')) {
      context.handle(
        _vatFilsMeta,
        vatFils.isAcceptableOrUnknown(data['vat_fils']!, _vatFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_vatFilsMeta);
    }
    if (data.containsKey('total_fils')) {
      context.handle(
        _totalFilsMeta,
        totalFils.isAcceptableOrUnknown(data['total_fils']!, _totalFilsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalFilsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      priceBookVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_book_version'],
      )!,
      breakdownJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breakdown_json'],
      )!,
      subtotalFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_fils'],
      )!,
      vatFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_fils'],
      )!,
      totalFils: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_fils'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final String id;
  final String tenantId;
  final String? branchId;
  final String orderId;
  final String productId;
  final String description;
  final String optionsJson;
  final int quantity;
  final int priceBookVersion;

  /// The full pricing breakdown, frozen at the moment of sale. Changing the
  /// price book later must not be able to rewrite this line.
  final String breakdownJson;
  final int subtotalFils;
  final int vatFils;
  final int totalFils;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int version;
  final DateTime? deletedAt;
  const OrderItem({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.orderId,
    required this.productId,
    required this.description,
    required this.optionsJson,
    required this.quantity,
    required this.priceBookVersion,
    required this.breakdownJson,
    required this.subtotalFils,
    required this.vatFils,
    required this.totalFils,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    map['description'] = Variable<String>(description);
    map['options_json'] = Variable<String>(optionsJson);
    map['quantity'] = Variable<int>(quantity);
    map['price_book_version'] = Variable<int>(priceBookVersion);
    map['breakdown_json'] = Variable<String>(breakdownJson);
    map['subtotal_fils'] = Variable<int>(subtotalFils);
    map['vat_fils'] = Variable<int>(vatFils);
    map['total_fils'] = Variable<int>(totalFils);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      orderId: Value(orderId),
      productId: Value(productId),
      description: Value(description),
      optionsJson: Value(optionsJson),
      quantity: Value(quantity),
      priceBookVersion: Value(priceBookVersion),
      breakdownJson: Value(breakdownJson),
      subtotalFils: Value(subtotalFils),
      vatFils: Value(vatFils),
      totalFils: Value(totalFils),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      description: serializer.fromJson<String>(json['description']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      quantity: serializer.fromJson<int>(json['quantity']),
      priceBookVersion: serializer.fromJson<int>(json['priceBookVersion']),
      breakdownJson: serializer.fromJson<String>(json['breakdownJson']),
      subtotalFils: serializer.fromJson<int>(json['subtotalFils']),
      vatFils: serializer.fromJson<int>(json['vatFils']),
      totalFils: serializer.fromJson<int>(json['totalFils']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'description': serializer.toJson<String>(description),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'quantity': serializer.toJson<int>(quantity),
      'priceBookVersion': serializer.toJson<int>(priceBookVersion),
      'breakdownJson': serializer.toJson<String>(breakdownJson),
      'subtotalFils': serializer.toJson<int>(subtotalFils),
      'vatFils': serializer.toJson<int>(vatFils),
      'totalFils': serializer.toJson<int>(totalFils),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  OrderItem copyWith({
    String? id,
    String? tenantId,
    Value<String?> branchId = const Value.absent(),
    String? orderId,
    String? productId,
    String? description,
    String? optionsJson,
    int? quantity,
    int? priceBookVersion,
    String? breakdownJson,
    int? subtotalFils,
    int? vatFils,
    int? totalFils,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> createdBy = const Value.absent(),
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => OrderItem(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
    description: description ?? this.description,
    optionsJson: optionsJson ?? this.optionsJson,
    quantity: quantity ?? this.quantity,
    priceBookVersion: priceBookVersion ?? this.priceBookVersion,
    breakdownJson: breakdownJson ?? this.breakdownJson,
    subtotalFils: subtotalFils ?? this.subtotalFils,
    vatFils: vatFils ?? this.vatFils,
    totalFils: totalFils ?? this.totalFils,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      description: data.description.present
          ? data.description.value
          : this.description,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      priceBookVersion: data.priceBookVersion.present
          ? data.priceBookVersion.value
          : this.priceBookVersion,
      breakdownJson: data.breakdownJson.present
          ? data.breakdownJson.value
          : this.breakdownJson,
      subtotalFils: data.subtotalFils.present
          ? data.subtotalFils.value
          : this.subtotalFils,
      vatFils: data.vatFils.present ? data.vatFils.value : this.vatFils,
      totalFils: data.totalFils.present ? data.totalFils.value : this.totalFils,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('description: $description, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('quantity: $quantity, ')
          ..write('priceBookVersion: $priceBookVersion, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('subtotalFils: $subtotalFils, ')
          ..write('vatFils: $vatFils, ')
          ..write('totalFils: $totalFils, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    branchId,
    orderId,
    productId,
    description,
    optionsJson,
    quantity,
    priceBookVersion,
    breakdownJson,
    subtotalFils,
    vatFils,
    totalFils,
    status,
    createdAt,
    updatedAt,
    createdBy,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.description == this.description &&
          other.optionsJson == this.optionsJson &&
          other.quantity == this.quantity &&
          other.priceBookVersion == this.priceBookVersion &&
          other.breakdownJson == this.breakdownJson &&
          other.subtotalFils == this.subtotalFils &&
          other.vatFils == this.vatFils &&
          other.totalFils == this.totalFils &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> branchId;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<String> description;
  final Value<String> optionsJson;
  final Value<int> quantity;
  final Value<int> priceBookVersion;
  final Value<String> breakdownJson;
  final Value<int> subtotalFils;
  final Value<int> vatFils;
  final Value<int> totalFils;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> createdBy;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.description = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.quantity = const Value.absent(),
    this.priceBookVersion = const Value.absent(),
    this.breakdownJson = const Value.absent(),
    this.subtotalFils = const Value.absent(),
    this.vatFils = const Value.absent(),
    this.totalFils = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    required String id,
    required String tenantId,
    this.branchId = const Value.absent(),
    required String orderId,
    required String productId,
    required String description,
    this.optionsJson = const Value.absent(),
    required int quantity,
    required int priceBookVersion,
    required String breakdownJson,
    required int subtotalFils,
    required int vatFils,
    required int totalFils,
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       orderId = Value(orderId),
       productId = Value(productId),
       description = Value(description),
       quantity = Value(quantity),
       priceBookVersion = Value(priceBookVersion),
       breakdownJson = Value(breakdownJson),
       subtotalFils = Value(subtotalFils),
       vatFils = Value(vatFils),
       totalFils = Value(totalFils),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OrderItem> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<String>? description,
    Expression<String>? optionsJson,
    Expression<int>? quantity,
    Expression<int>? priceBookVersion,
    Expression<String>? breakdownJson,
    Expression<int>? subtotalFils,
    Expression<int>? vatFils,
    Expression<int>? totalFils,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (description != null) 'description': description,
      if (optionsJson != null) 'options_json': optionsJson,
      if (quantity != null) 'quantity': quantity,
      if (priceBookVersion != null) 'price_book_version': priceBookVersion,
      if (breakdownJson != null) 'breakdown_json': breakdownJson,
      if (subtotalFils != null) 'subtotal_fils': subtotalFils,
      if (vatFils != null) 'vat_fils': vatFils,
      if (totalFils != null) 'total_fils': totalFils,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? branchId,
    Value<String>? orderId,
    Value<String>? productId,
    Value<String>? description,
    Value<String>? optionsJson,
    Value<int>? quantity,
    Value<int>? priceBookVersion,
    Value<String>? breakdownJson,
    Value<int>? subtotalFils,
    Value<int>? vatFils,
    Value<int>? totalFils,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? createdBy,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      description: description ?? this.description,
      optionsJson: optionsJson ?? this.optionsJson,
      quantity: quantity ?? this.quantity,
      priceBookVersion: priceBookVersion ?? this.priceBookVersion,
      breakdownJson: breakdownJson ?? this.breakdownJson,
      subtotalFils: subtotalFils ?? this.subtotalFils,
      vatFils: vatFils ?? this.vatFils,
      totalFils: totalFils ?? this.totalFils,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (priceBookVersion.present) {
      map['price_book_version'] = Variable<int>(priceBookVersion.value);
    }
    if (breakdownJson.present) {
      map['breakdown_json'] = Variable<String>(breakdownJson.value);
    }
    if (subtotalFils.present) {
      map['subtotal_fils'] = Variable<int>(subtotalFils.value);
    }
    if (vatFils.present) {
      map['vat_fils'] = Variable<int>(vatFils.value);
    }
    if (totalFils.present) {
      map['total_fils'] = Variable<int>(totalFils.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('description: $description, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('quantity: $quantity, ')
          ..write('priceBookVersion: $priceBookVersion, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('subtotalFils: $subtotalFils, ')
          ..write('vatFils: $vatFils, ')
          ..write('totalFils: $totalFils, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxMutationsTable extends OutboxMutations
    with TableInfo<$OutboxMutationsTable, OutboxMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceTsMeta = const VerificationMeta(
    'deviceTs',
  );
  @override
  late final GeneratedColumn<DateTime> deviceTs = GeneratedColumn<DateTime>(
    'device_ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mutationId,
    entity,
    rowId,
    op,
    payloadJson,
    baseVersion,
    deviceTs,
    attempts,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseVersionMeta);
    }
    if (data.containsKey('device_ts')) {
      context.handle(
        _deviceTsMeta,
        deviceTs.isAcceptableOrUnknown(data['device_ts']!, _deviceTsMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceTsMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
  Set<GeneratedColumn> get $primaryKey => {mutationId};
  @override
  OutboxMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxMutation(
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      )!,
      deviceTs: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}device_ts'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxMutationsTable createAlias(String alias) {
    return $OutboxMutationsTable(attachedDatabase, alias);
  }
}

class OutboxMutation extends DataClass implements Insertable<OutboxMutation> {
  final String mutationId;
  final String entity;
  final String rowId;
  final String op;
  final String payloadJson;
  final int baseVersion;
  final DateTime deviceTs;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  const OutboxMutation({
    required this.mutationId,
    required this.entity,
    required this.rowId,
    required this.op,
    required this.payloadJson,
    required this.baseVersion,
    required this.deviceTs,
    required this.attempts,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mutation_id'] = Variable<String>(mutationId);
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    map['op'] = Variable<String>(op);
    map['payload_json'] = Variable<String>(payloadJson);
    map['base_version'] = Variable<int>(baseVersion);
    map['device_ts'] = Variable<DateTime>(deviceTs);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxMutationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxMutationsCompanion(
      mutationId: Value(mutationId),
      entity: Value(entity),
      rowId: Value(rowId),
      op: Value(op),
      payloadJson: Value(payloadJson),
      baseVersion: Value(baseVersion),
      deviceTs: Value(deviceTs),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxMutation(
      mutationId: serializer.fromJson<String>(json['mutationId']),
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      op: serializer.fromJson<String>(json['op']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseVersion: serializer.fromJson<int>(json['baseVersion']),
      deviceTs: serializer.fromJson<DateTime>(json['deviceTs']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mutationId': serializer.toJson<String>(mutationId),
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'op': serializer.toJson<String>(op),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseVersion': serializer.toJson<int>(baseVersion),
      'deviceTs': serializer.toJson<DateTime>(deviceTs),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxMutation copyWith({
    String? mutationId,
    String? entity,
    String? rowId,
    String? op,
    String? payloadJson,
    int? baseVersion,
    DateTime? deviceTs,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxMutation(
    mutationId: mutationId ?? this.mutationId,
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    op: op ?? this.op,
    payloadJson: payloadJson ?? this.payloadJson,
    baseVersion: baseVersion ?? this.baseVersion,
    deviceTs: deviceTs ?? this.deviceTs,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxMutation copyWithCompanion(OutboxMutationsCompanion data) {
    return OutboxMutation(
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      op: data.op.present ? data.op.value : this.op,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      deviceTs: data.deviceTs.present ? data.deviceTs.value : this.deviceTs,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxMutation(')
          ..write('mutationId: $mutationId, ')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('deviceTs: $deviceTs, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mutationId,
    entity,
    rowId,
    op,
    payloadJson,
    baseVersion,
    deviceTs,
    attempts,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxMutation &&
          other.mutationId == this.mutationId &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.op == this.op &&
          other.payloadJson == this.payloadJson &&
          other.baseVersion == this.baseVersion &&
          other.deviceTs == this.deviceTs &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxMutationsCompanion extends UpdateCompanion<OutboxMutation> {
  final Value<String> mutationId;
  final Value<String> entity;
  final Value<String> rowId;
  final Value<String> op;
  final Value<String> payloadJson;
  final Value<int> baseVersion;
  final Value<DateTime> deviceTs;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OutboxMutationsCompanion({
    this.mutationId = const Value.absent(),
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.op = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.deviceTs = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxMutationsCompanion.insert({
    required String mutationId,
    required String entity,
    required String rowId,
    required String op,
    required String payloadJson,
    required int baseVersion,
    required DateTime deviceTs,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : mutationId = Value(mutationId),
       entity = Value(entity),
       rowId = Value(rowId),
       op = Value(op),
       payloadJson = Value(payloadJson),
       baseVersion = Value(baseVersion),
       deviceTs = Value(deviceTs),
       createdAt = Value(createdAt);
  static Insertable<OutboxMutation> custom({
    Expression<String>? mutationId,
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<String>? op,
    Expression<String>? payloadJson,
    Expression<int>? baseVersion,
    Expression<DateTime>? deviceTs,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mutationId != null) 'mutation_id': mutationId,
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (op != null) 'op': op,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseVersion != null) 'base_version': baseVersion,
      if (deviceTs != null) 'device_ts': deviceTs,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxMutationsCompanion copyWith({
    Value<String>? mutationId,
    Value<String>? entity,
    Value<String>? rowId,
    Value<String>? op,
    Value<String>? payloadJson,
    Value<int>? baseVersion,
    Value<DateTime>? deviceTs,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OutboxMutationsCompanion(
      mutationId: mutationId ?? this.mutationId,
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      op: op ?? this.op,
      payloadJson: payloadJson ?? this.payloadJson,
      baseVersion: baseVersion ?? this.baseVersion,
      deviceTs: deviceTs ?? this.deviceTs,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (deviceTs.present) {
      map['device_ts'] = Variable<DateTime>(deviceTs.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxMutationsCompanion(')
          ..write('mutationId: $mutationId, ')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('deviceTs: $deviceTs, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String value;
  const SyncMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaData copyWith({String? key, String? value}) =>
      SyncMetaData(key: key ?? this.key, value: value ?? this.value);
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $CustomerPhonesTable customerPhones = $CustomerPhonesTable(this);
  late final $WorkflowStagesTable workflowStages = $WorkflowStagesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ProofsTable proofs = $ProofsTable(this);
  late final $TimeEntriesTable timeEntries = $TimeEntriesTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceLinesTable invoiceLines = $InvoiceLinesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $MaterialsTable materials = $MaterialsTable(this);
  late final $PriceRulesTable priceRules = $PriceRulesTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $OutboxMutationsTable outboxMutations = $OutboxMutationsTable(
    this,
  );
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customers,
    customerPhones,
    workflowStages,
    tasks,
    proofs,
    timeEntries,
    invoices,
    invoiceLines,
    payments,
    products,
    materials,
    priceRules,
    orders,
    orderItems,
    outboxMutations,
    syncMeta,
  ];
}

typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  required String name,
  Value<String?> company,
  Value<String?> trn,
  Value<String> tier,
  Value<int> creditLimitFils,
  Value<int> paymentTermsDays,
  Value<String?> notes,
  Value<bool> whatsappOptIn,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<String> name,
  Value<String?> company,
  Value<String?> trn,
  Value<String> tier,
  Value<int> creditLimitFils,
  Value<int> paymentTermsDays,
  Value<String?> notes,
  Value<bool> whatsappOptIn,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$CustomersTableFilterComposer
    extends Composer<_$LocalDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trn => $composableBuilder(
    column: $table.trn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimitFils => $composableBuilder(
    column: $table.creditLimitFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentTermsDays => $composableBuilder(
    column: $table.paymentTermsDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get whatsappOptIn => $composableBuilder(
    column: $table.whatsappOptIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$LocalDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trn => $composableBuilder(
    column: $table.trn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimitFils => $composableBuilder(
    column: $table.creditLimitFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentTermsDays => $composableBuilder(
    column: $table.paymentTermsDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get whatsappOptIn => $composableBuilder(
    column: $table.whatsappOptIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get trn =>
      $composableBuilder(column: $table.trn, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<int> get creditLimitFils => $composableBuilder(
    column: $table.creditLimitFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentTermsDays => $composableBuilder(
    column: $table.paymentTermsDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get whatsappOptIn => $composableBuilder(
    column: $table.whatsappOptIn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (
            Customer,
            BaseReferences<_$LocalDatabase, $CustomersTable, Customer>,
          ),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$LocalDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> company = const Value.absent(),
                Value<String?> trn = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<int> creditLimitFils = const Value.absent(),
                Value<int> paymentTermsDays = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> whatsappOptIn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                name: name,
                company: company,
                trn: trn,
                tier: tier,
                creditLimitFils: creditLimitFils,
                paymentTermsDays: paymentTermsDays,
                notes: notes,
                whatsappOptIn: whatsappOptIn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String name,
                Value<String?> company = const Value.absent(),
                Value<String?> trn = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<int> creditLimitFils = const Value.absent(),
                Value<int> paymentTermsDays = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> whatsappOptIn = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                name: name,
                company: company,
                trn: trn,
                tier: tier,
                creditLimitFils: creditLimitFils,
                paymentTermsDays: paymentTermsDays,
                notes: notes,
                whatsappOptIn: whatsappOptIn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomersTable, Customer>(table),
                  BaseReferences<_$LocalDatabase, $CustomersTable, Customer>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$LocalDatabase, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;
typedef $$CustomerPhonesTableCreateCompanionBuilder =
    CustomerPhonesCompanion Function({
      required String id,
      required String tenantId,
      required String customerId,
      required String e164,
      required String phoneLast9,
      Value<String?> label,
      Value<bool> isPrimary,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CustomerPhonesTableUpdateCompanionBuilder =
    CustomerPhonesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> customerId,
      Value<String> e164,
      Value<String> phoneLast9,
      Value<String?> label,
      Value<bool> isPrimary,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CustomerPhonesTableFilterComposer
    extends Composer<_$LocalDatabase, $CustomerPhonesTable> {
  $$CustomerPhonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneLast9 => $composableBuilder(
    column: $table.phoneLast9,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerPhonesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CustomerPhonesTable> {
  $$CustomerPhonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneLast9 => $composableBuilder(
    column: $table.phoneLast9,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerPhonesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CustomerPhonesTable> {
  $$CustomerPhonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get e164 =>
      $composableBuilder(column: $table.e164, builder: (column) => column);

  GeneratedColumn<String> get phoneLast9 => $composableBuilder(
    column: $table.phoneLast9,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CustomerPhonesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CustomerPhonesTable,
          CustomerPhone,
          $$CustomerPhonesTableFilterComposer,
          $$CustomerPhonesTableOrderingComposer,
          $$CustomerPhonesTableAnnotationComposer,
          $$CustomerPhonesTableCreateCompanionBuilder,
          $$CustomerPhonesTableUpdateCompanionBuilder,
          (
            CustomerPhone,
            BaseReferences<
              _$LocalDatabase,
              $CustomerPhonesTable,
              CustomerPhone
            >,
          ),
          CustomerPhone,
          PrefetchHooks Function()
        > {
  $$CustomerPhonesTableTableManager(
    _$LocalDatabase db,
    $CustomerPhonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerPhonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerPhonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomerPhonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> e164 = const Value.absent(),
                Value<String> phoneLast9 = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerPhonesCompanion(
                id: id,
                tenantId: tenantId,
                customerId: customerId,
                e164: e164,
                phoneLast9: phoneLast9,
                label: label,
                isPrimary: isPrimary,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String customerId,
                required String e164,
                required String phoneLast9,
                Value<String?> label = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerPhonesCompanion.insert(
                id: id,
                tenantId: tenantId,
                customerId: customerId,
                e164: e164,
                phoneLast9: phoneLast9,
                label: label,
                isPrimary: isPrimary,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomerPhonesTable, CustomerPhone>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    $CustomerPhonesTable,
                    CustomerPhone
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerPhonesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CustomerPhonesTable,
      CustomerPhone,
      $$CustomerPhonesTableFilterComposer,
      $$CustomerPhonesTableOrderingComposer,
      $$CustomerPhonesTableAnnotationComposer,
      $$CustomerPhonesTableCreateCompanionBuilder,
      $$CustomerPhonesTableUpdateCompanionBuilder,
      (
        CustomerPhone,
        BaseReferences<_$LocalDatabase, $CustomerPhonesTable, CustomerPhone>,
      ),
      CustomerPhone,
      PrefetchHooks Function()
    >;
typedef $$WorkflowStagesTableCreateCompanionBuilder =
    WorkflowStagesCompanion Function({
      required String id,
      required String tenantId,
      Value<String> workflowKey,
      required String stageKey,
      required String nameEn,
      Value<String?> nameAr,
      required int sequence,
      required String requiredRole,
      Value<bool> waitsForPrevious,
      Value<int> rowid,
    });
typedef $$WorkflowStagesTableUpdateCompanionBuilder =
    WorkflowStagesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> workflowKey,
      Value<String> stageKey,
      Value<String> nameEn,
      Value<String?> nameAr,
      Value<int> sequence,
      Value<String> requiredRole,
      Value<bool> waitsForPrevious,
      Value<int> rowid,
    });

class $$WorkflowStagesTableFilterComposer
    extends Composer<_$LocalDatabase, $WorkflowStagesTable> {
  $$WorkflowStagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowKey => $composableBuilder(
    column: $table.workflowKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageKey => $composableBuilder(
    column: $table.stageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredRole => $composableBuilder(
    column: $table.requiredRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get waitsForPrevious => $composableBuilder(
    column: $table.waitsForPrevious,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkflowStagesTableOrderingComposer
    extends Composer<_$LocalDatabase, $WorkflowStagesTable> {
  $$WorkflowStagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowKey => $composableBuilder(
    column: $table.workflowKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageKey => $composableBuilder(
    column: $table.stageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredRole => $composableBuilder(
    column: $table.requiredRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get waitsForPrevious => $composableBuilder(
    column: $table.waitsForPrevious,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkflowStagesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $WorkflowStagesTable> {
  $$WorkflowStagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get workflowKey => $composableBuilder(
    column: $table.workflowKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stageKey =>
      $composableBuilder(column: $table.stageKey, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get requiredRole => $composableBuilder(
    column: $table.requiredRole,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get waitsForPrevious => $composableBuilder(
    column: $table.waitsForPrevious,
    builder: (column) => column,
  );
}

class $$WorkflowStagesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $WorkflowStagesTable,
          WorkflowStage,
          $$WorkflowStagesTableFilterComposer,
          $$WorkflowStagesTableOrderingComposer,
          $$WorkflowStagesTableAnnotationComposer,
          $$WorkflowStagesTableCreateCompanionBuilder,
          $$WorkflowStagesTableUpdateCompanionBuilder,
          (
            WorkflowStage,
            BaseReferences<
              _$LocalDatabase,
              $WorkflowStagesTable,
              WorkflowStage
            >,
          ),
          WorkflowStage,
          PrefetchHooks Function()
        > {
  $$WorkflowStagesTableTableManager(
    _$LocalDatabase db,
    $WorkflowStagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowStagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowStagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowStagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> workflowKey = const Value.absent(),
                Value<String> stageKey = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> requiredRole = const Value.absent(),
                Value<bool> waitsForPrevious = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkflowStagesCompanion(
                id: id,
                tenantId: tenantId,
                workflowKey: workflowKey,
                stageKey: stageKey,
                nameEn: nameEn,
                nameAr: nameAr,
                sequence: sequence,
                requiredRole: requiredRole,
                waitsForPrevious: waitsForPrevious,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String> workflowKey = const Value.absent(),
                required String stageKey,
                required String nameEn,
                Value<String?> nameAr = const Value.absent(),
                required int sequence,
                required String requiredRole,
                Value<bool> waitsForPrevious = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkflowStagesCompanion.insert(
                id: id,
                tenantId: tenantId,
                workflowKey: workflowKey,
                stageKey: stageKey,
                nameEn: nameEn,
                nameAr: nameAr,
                sequence: sequence,
                requiredRole: requiredRole,
                waitsForPrevious: waitsForPrevious,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkflowStagesTable, WorkflowStage>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    $WorkflowStagesTable,
                    WorkflowStage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkflowStagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $WorkflowStagesTable,
      WorkflowStage,
      $$WorkflowStagesTableFilterComposer,
      $$WorkflowStagesTableOrderingComposer,
      $$WorkflowStagesTableAnnotationComposer,
      $$WorkflowStagesTableCreateCompanionBuilder,
      $$WorkflowStagesTableUpdateCompanionBuilder,
      (
        WorkflowStage,
        BaseReferences<_$LocalDatabase, $WorkflowStagesTable, WorkflowStage>,
      ),
      WorkflowStage,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  required String orderId,
  Value<String?> orderItemId,
  required String stageKey,
  required String stageName,
  required int sequence,
  required String title,
  Value<String> status,
  Value<String?> assignedTo,
  required String requiredRole,
  Value<int> qty,
  Value<String> priority,
  Value<DateTime?> dueAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> doneAt,
  Value<String?> reason,
  Value<int> reworkCount,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<String> orderId,
  Value<String?> orderItemId,
  Value<String> stageKey,
  Value<String> stageName,
  Value<int> sequence,
  Value<String> title,
  Value<String> status,
  Value<String?> assignedTo,
  Value<String> requiredRole,
  Value<int> qty,
  Value<String> priority,
  Value<DateTime?> dueAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> doneAt,
  Value<String?> reason,
  Value<int> reworkCount,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$TasksTableFilterComposer
    extends Composer<_$LocalDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderItemId => $composableBuilder(
    column: $table.orderItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageKey => $composableBuilder(
    column: $table.stageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedTo => $composableBuilder(
    column: $table.assignedTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredRole => $composableBuilder(
    column: $table.requiredRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reworkCount => $composableBuilder(
    column: $table.reworkCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$LocalDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderItemId => $composableBuilder(
    column: $table.orderItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageKey => $composableBuilder(
    column: $table.stageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedTo => $composableBuilder(
    column: $table.assignedTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredRole => $composableBuilder(
    column: $table.requiredRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reworkCount => $composableBuilder(
    column: $table.reworkCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$LocalDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get orderItemId => $composableBuilder(
    column: $table.orderItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stageKey =>
      $composableBuilder(column: $table.stageKey, builder: (column) => column);

  GeneratedColumn<String> get stageName =>
      $composableBuilder(column: $table.stageName, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get assignedTo => $composableBuilder(
    column: $table.assignedTo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requiredRole => $composableBuilder(
    column: $table.requiredRole,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get reworkCount => $composableBuilder(
    column: $table.reworkCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$LocalDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$LocalDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String?> orderItemId = const Value.absent(),
                Value<String> stageKey = const Value.absent(),
                Value<String> stageName = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> assignedTo = const Value.absent(),
                Value<String> requiredRole = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> reworkCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                orderItemId: orderItemId,
                stageKey: stageKey,
                stageName: stageName,
                sequence: sequence,
                title: title,
                status: status,
                assignedTo: assignedTo,
                requiredRole: requiredRole,
                qty: qty,
                priority: priority,
                dueAt: dueAt,
                startedAt: startedAt,
                doneAt: doneAt,
                reason: reason,
                reworkCount: reworkCount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String orderId,
                Value<String?> orderItemId = const Value.absent(),
                required String stageKey,
                required String stageName,
                required int sequence,
                required String title,
                Value<String> status = const Value.absent(),
                Value<String?> assignedTo = const Value.absent(),
                required String requiredRole,
                Value<int> qty = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> reworkCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                orderItemId: orderItemId,
                stageKey: stageKey,
                stageName: stageName,
                sequence: sequence,
                title: title,
                status: status,
                assignedTo: assignedTo,
                requiredRole: requiredRole,
                qty: qty,
                priority: priority,
                dueAt: dueAt,
                startedAt: startedAt,
                doneAt: doneAt,
                reason: reason,
                reworkCount: reworkCount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  BaseReferences<_$LocalDatabase, $TasksTable, Task>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$LocalDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$ProofsTableCreateCompanionBuilder = ProofsCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  required String orderId,
  Value<int> revision,
  Value<String> kind,
  required String label,
  required String url,
  Value<String?> note,
  Value<String> status,
  Value<DateTime?> sentAt,
  Value<DateTime?> decidedAt,
  Value<String?> decidedNote,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ProofsTableUpdateCompanionBuilder = ProofsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<String> orderId,
  Value<int> revision,
  Value<String> kind,
  Value<String> label,
  Value<String> url,
  Value<String?> note,
  Value<String> status,
  Value<DateTime?> sentAt,
  Value<DateTime?> decidedAt,
  Value<String?> decidedNote,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$ProofsTableFilterComposer
    extends Composer<_$LocalDatabase, $ProofsTable> {
  $$ProofsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decidedNote => $composableBuilder(
    column: $table.decidedNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProofsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ProofsTable> {
  $$ProofsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedNote => $composableBuilder(
    column: $table.decidedNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProofsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ProofsTable> {
  $$ProofsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get decidedNote => $composableBuilder(
    column: $table.decidedNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProofsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ProofsTable,
          Proof,
          $$ProofsTableFilterComposer,
          $$ProofsTableOrderingComposer,
          $$ProofsTableAnnotationComposer,
          $$ProofsTableCreateCompanionBuilder,
          $$ProofsTableUpdateCompanionBuilder,
          (Proof, BaseReferences<_$LocalDatabase, $ProofsTable, Proof>),
          Proof,
          PrefetchHooks Function()
        > {
  $$ProofsTableTableManager(_$LocalDatabase db, $ProofsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProofsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProofsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProofsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<String?> decidedNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProofsCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                revision: revision,
                kind: kind,
                label: label,
                url: url,
                note: note,
                status: status,
                sentAt: sentAt,
                decidedAt: decidedAt,
                decidedNote: decidedNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String orderId,
                Value<int> revision = const Value.absent(),
                Value<String> kind = const Value.absent(),
                required String label,
                required String url,
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<String?> decidedNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProofsCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                revision: revision,
                kind: kind,
                label: label,
                url: url,
                note: note,
                status: status,
                sentAt: sentAt,
                decidedAt: decidedAt,
                decidedNote: decidedNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProofsTable, Proof>(table),
                  BaseReferences<_$LocalDatabase, $ProofsTable, Proof>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProofsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ProofsTable,
      Proof,
      $$ProofsTableFilterComposer,
      $$ProofsTableOrderingComposer,
      $$ProofsTableAnnotationComposer,
      $$ProofsTableCreateCompanionBuilder,
      $$ProofsTableUpdateCompanionBuilder,
      (Proof, BaseReferences<_$LocalDatabase, $ProofsTable, Proof>),
      Proof,
      PrefetchHooks Function()
    >;
typedef $$TimeEntriesTableCreateCompanionBuilder =
    TimeEntriesCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> branchId,
      required String taskId,
      required String orderId,
      Value<String?> userId,
      required DateTime startedAt,
      required DateTime endedAt,
      required int minutes,
      Value<bool> auto,
      required DateTime createdAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TimeEntriesTableUpdateCompanionBuilder =
    TimeEntriesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> branchId,
      Value<String> taskId,
      Value<String> orderId,
      Value<String?> userId,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> minutes,
      Value<bool> auto,
      Value<DateTime> createdAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$TimeEntriesTableFilterComposer
    extends Composer<_$LocalDatabase, $TimeEntriesTable> {
  $$TimeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get auto => $composableBuilder(
    column: $table.auto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimeEntriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $TimeEntriesTable> {
  $$TimeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get auto => $composableBuilder(
    column: $table.auto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimeEntriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $TimeEntriesTable> {
  $$TimeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<bool> get auto =>
      $composableBuilder(column: $table.auto, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TimeEntriesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $TimeEntriesTable,
          TimeEntry,
          $$TimeEntriesTableFilterComposer,
          $$TimeEntriesTableOrderingComposer,
          $$TimeEntriesTableAnnotationComposer,
          $$TimeEntriesTableCreateCompanionBuilder,
          $$TimeEntriesTableUpdateCompanionBuilder,
          (
            TimeEntry,
            BaseReferences<_$LocalDatabase, $TimeEntriesTable, TimeEntry>,
          ),
          TimeEntry,
          PrefetchHooks Function()
        > {
  $$TimeEntriesTableTableManager(_$LocalDatabase db, $TimeEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<bool> auto = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimeEntriesCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                taskId: taskId,
                orderId: orderId,
                userId: userId,
                startedAt: startedAt,
                endedAt: endedAt,
                minutes: minutes,
                auto: auto,
                createdAt: createdAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String taskId,
                required String orderId,
                Value<String?> userId = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required int minutes,
                Value<bool> auto = const Value.absent(),
                required DateTime createdAt,
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimeEntriesCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                taskId: taskId,
                orderId: orderId,
                userId: userId,
                startedAt: startedAt,
                endedAt: endedAt,
                minutes: minutes,
                auto: auto,
                createdAt: createdAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TimeEntriesTable, TimeEntry>(table),
                  BaseReferences<_$LocalDatabase, $TimeEntriesTable, TimeEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $TimeEntriesTable,
      TimeEntry,
      $$TimeEntriesTableFilterComposer,
      $$TimeEntriesTableOrderingComposer,
      $$TimeEntriesTableAnnotationComposer,
      $$TimeEntriesTableCreateCompanionBuilder,
      $$TimeEntriesTableUpdateCompanionBuilder,
      (
        TimeEntry,
        BaseReferences<_$LocalDatabase, $TimeEntriesTable, TimeEntry>,
      ),
      TimeEntry,
      PrefetchHooks Function()
    >;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  required String orderId,
  required String number,
  required DateTime issuedAt,
  Value<DateTime?> dueAt,
  required String customerId,
  required String customerName,
  Value<String?> customerTrn,
  Value<String?> customerAddress,
  required int subtotalFils,
  Value<int> discountFils,
  Value<int> vatBps,
  required int vatFils,
  required int totalFils,
  Value<int> paidFils,
  Value<String> status,
  Value<String?> notes,
  Value<String?> voidReason,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<String> orderId,
  Value<String> number,
  Value<DateTime> issuedAt,
  Value<DateTime?> dueAt,
  Value<String> customerId,
  Value<String> customerName,
  Value<String?> customerTrn,
  Value<String?> customerAddress,
  Value<int> subtotalFils,
  Value<int> discountFils,
  Value<int> vatBps,
  Value<int> vatFils,
  Value<int> totalFils,
  Value<int> paidFils,
  Value<String> status,
  Value<String?> notes,
  Value<String?> voidReason,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$InvoicesTableFilterComposer
    extends Composer<_$LocalDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerTrn => $composableBuilder(
    column: $table.customerTrn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountFils => $composableBuilder(
    column: $table.discountFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatBps => $composableBuilder(
    column: $table.vatBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatFils => $composableBuilder(
    column: $table.vatFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFils => $composableBuilder(
    column: $table.totalFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidFils => $composableBuilder(
    column: $table.paidFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$LocalDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerTrn => $composableBuilder(
    column: $table.customerTrn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountFils => $composableBuilder(
    column: $table.discountFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatBps => $composableBuilder(
    column: $table.vatBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatFils => $composableBuilder(
    column: $table.vatFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFils => $composableBuilder(
    column: $table.totalFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidFils => $composableBuilder(
    column: $table.paidFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerTrn => $composableBuilder(
    column: $table.customerTrn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountFils => $composableBuilder(
    column: $table.discountFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatBps =>
      $composableBuilder(column: $table.vatBps, builder: (column) => column);

  GeneratedColumn<int> get vatFils =>
      $composableBuilder(column: $table.vatFils, builder: (column) => column);

  GeneratedColumn<int> get totalFils =>
      $composableBuilder(column: $table.totalFils, builder: (column) => column);

  GeneratedColumn<int> get paidFils =>
      $composableBuilder(column: $table.paidFils, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $InvoicesTable,
          Invoice,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (Invoice, BaseReferences<_$LocalDatabase, $InvoicesTable, Invoice>),
          Invoice,
          PrefetchHooks Function()
        > {
  $$InvoicesTableTableManager(_$LocalDatabase db, $InvoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> customerTrn = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<int> subtotalFils = const Value.absent(),
                Value<int> discountFils = const Value.absent(),
                Value<int> vatBps = const Value.absent(),
                Value<int> vatFils = const Value.absent(),
                Value<int> totalFils = const Value.absent(),
                Value<int> paidFils = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                number: number,
                issuedAt: issuedAt,
                dueAt: dueAt,
                customerId: customerId,
                customerName: customerName,
                customerTrn: customerTrn,
                customerAddress: customerAddress,
                subtotalFils: subtotalFils,
                discountFils: discountFils,
                vatBps: vatBps,
                vatFils: vatFils,
                totalFils: totalFils,
                paidFils: paidFils,
                status: status,
                notes: notes,
                voidReason: voidReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String orderId,
                required String number,
                required DateTime issuedAt,
                Value<DateTime?> dueAt = const Value.absent(),
                required String customerId,
                required String customerName,
                Value<String?> customerTrn = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                required int subtotalFils,
                Value<int> discountFils = const Value.absent(),
                Value<int> vatBps = const Value.absent(),
                required int vatFils,
                required int totalFils,
                Value<int> paidFils = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                number: number,
                issuedAt: issuedAt,
                dueAt: dueAt,
                customerId: customerId,
                customerName: customerName,
                customerTrn: customerTrn,
                customerAddress: customerAddress,
                subtotalFils: subtotalFils,
                discountFils: discountFils,
                vatBps: vatBps,
                vatFils: vatFils,
                totalFils: totalFils,
                paidFils: paidFils,
                status: status,
                notes: notes,
                voidReason: voidReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvoicesTable, Invoice>(table),
                  BaseReferences<_$LocalDatabase, $InvoicesTable, Invoice>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $InvoicesTable,
      Invoice,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (Invoice, BaseReferences<_$LocalDatabase, $InvoicesTable, Invoice>),
      Invoice,
      PrefetchHooks Function()
    >;
typedef $$InvoiceLinesTableCreateCompanionBuilder =
    InvoiceLinesCompanion Function({
      required String id,
      required String tenantId,
      required String invoiceId,
      required int lineNo,
      required String description,
      required int quantity,
      required int unitFils,
      required int amountFils,
      Value<int> vatBps,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$InvoiceLinesTableUpdateCompanionBuilder =
    InvoiceLinesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> invoiceId,
      Value<int> lineNo,
      Value<String> description,
      Value<int> quantity,
      Value<int> unitFils,
      Value<int> amountFils,
      Value<int> vatBps,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$InvoiceLinesTableFilterComposer
    extends Composer<_$LocalDatabase, $InvoiceLinesTable> {
  $$InvoiceLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitFils => $composableBuilder(
    column: $table.unitFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountFils => $composableBuilder(
    column: $table.amountFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatBps => $composableBuilder(
    column: $table.vatBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvoiceLinesTableOrderingComposer
    extends Composer<_$LocalDatabase, $InvoiceLinesTable> {
  $$InvoiceLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitFils => $composableBuilder(
    column: $table.unitFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountFils => $composableBuilder(
    column: $table.amountFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatBps => $composableBuilder(
    column: $table.vatBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoiceLinesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $InvoiceLinesTable> {
  $$InvoiceLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<int> get lineNo =>
      $composableBuilder(column: $table.lineNo, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitFils =>
      $composableBuilder(column: $table.unitFils, builder: (column) => column);

  GeneratedColumn<int> get amountFils => $composableBuilder(
    column: $table.amountFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatBps =>
      $composableBuilder(column: $table.vatBps, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$InvoiceLinesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $InvoiceLinesTable,
          InvoiceLine,
          $$InvoiceLinesTableFilterComposer,
          $$InvoiceLinesTableOrderingComposer,
          $$InvoiceLinesTableAnnotationComposer,
          $$InvoiceLinesTableCreateCompanionBuilder,
          $$InvoiceLinesTableUpdateCompanionBuilder,
          (
            InvoiceLine,
            BaseReferences<_$LocalDatabase, $InvoiceLinesTable, InvoiceLine>,
          ),
          InvoiceLine,
          PrefetchHooks Function()
        > {
  $$InvoiceLinesTableTableManager(_$LocalDatabase db, $InvoiceLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<int> lineNo = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> unitFils = const Value.absent(),
                Value<int> amountFils = const Value.absent(),
                Value<int> vatBps = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceLinesCompanion(
                id: id,
                tenantId: tenantId,
                invoiceId: invoiceId,
                lineNo: lineNo,
                description: description,
                quantity: quantity,
                unitFils: unitFils,
                amountFils: amountFils,
                vatBps: vatBps,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String invoiceId,
                required int lineNo,
                required String description,
                required int quantity,
                required int unitFils,
                required int amountFils,
                Value<int> vatBps = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceLinesCompanion.insert(
                id: id,
                tenantId: tenantId,
                invoiceId: invoiceId,
                lineNo: lineNo,
                description: description,
                quantity: quantity,
                unitFils: unitFils,
                amountFils: amountFils,
                vatBps: vatBps,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvoiceLinesTable, InvoiceLine>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    $InvoiceLinesTable,
                    InvoiceLine
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvoiceLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $InvoiceLinesTable,
      InvoiceLine,
      $$InvoiceLinesTableFilterComposer,
      $$InvoiceLinesTableOrderingComposer,
      $$InvoiceLinesTableAnnotationComposer,
      $$InvoiceLinesTableCreateCompanionBuilder,
      $$InvoiceLinesTableUpdateCompanionBuilder,
      (
        InvoiceLine,
        BaseReferences<_$LocalDatabase, $InvoiceLinesTable, InvoiceLine>,
      ),
      InvoiceLine,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  required String invoiceId,
  required int amountFils,
  required String method,
  Value<String?> reference,
  required DateTime takenAt,
  Value<String?> takenBy,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<String> invoiceId,
  Value<int> amountFils,
  Value<String> method,
  Value<String?> reference,
  Value<DateTime> takenAt,
  Value<String?> takenBy,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PaymentsTableFilterComposer
    extends Composer<_$LocalDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountFils => $composableBuilder(
    column: $table.amountFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get takenBy => $composableBuilder(
    column: $table.takenBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$LocalDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountFils => $composableBuilder(
    column: $table.amountFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get takenBy => $composableBuilder(
    column: $table.takenBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<int> get amountFils => $composableBuilder(
    column: $table.amountFils,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get takenBy =>
      $composableBuilder(column: $table.takenBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, BaseReferences<_$LocalDatabase, $PaymentsTable, Payment>),
          Payment,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableManager(_$LocalDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<int> amountFils = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<String?> takenBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                invoiceId: invoiceId,
                amountFils: amountFils,
                method: method,
                reference: reference,
                takenAt: takenAt,
                takenBy: takenBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String invoiceId,
                required int amountFils,
                required String method,
                Value<String?> reference = const Value.absent(),
                required DateTime takenAt,
                Value<String?> takenBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                invoiceId: invoiceId,
                amountFils: amountFils,
                method: method,
                reference: reference,
                takenAt: takenAt,
                takenBy: takenBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaymentsTable, Payment>(table),
                  BaseReferences<_$LocalDatabase, $PaymentsTable, Payment>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, BaseReferences<_$LocalDatabase, $PaymentsTable, Payment>),
      Payment,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String tenantId,
  required String code,
  required String nameEn,
  Value<String?> nameAr,
  Value<String?> category,
  required String kind,
  required String pricingMode,
  Value<int?> sheetWidthMm,
  Value<int?> sheetHeightMm,
  Value<int> bleedMm,
  Value<int> gutterMm,
  Value<int> setupSheets,
  Value<int> spoilageBps,
  Value<String?> materialCode,
  Value<int?> printRateFils,
  Value<int?> areaRateFilsPerSqm,
  Value<int> markupBps,
  Value<int> minOrderFils,
  Value<int> roundingStepFils,
  Value<String> sizesJson,
  Value<String> finishesJson,
  Value<String> quantityPresetsJson,
  Value<String> workflowKey,
  Value<int> sort,
  Value<bool> active,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> code,
  Value<String> nameEn,
  Value<String?> nameAr,
  Value<String?> category,
  Value<String> kind,
  Value<String> pricingMode,
  Value<int?> sheetWidthMm,
  Value<int?> sheetHeightMm,
  Value<int> bleedMm,
  Value<int> gutterMm,
  Value<int> setupSheets,
  Value<int> spoilageBps,
  Value<String?> materialCode,
  Value<int?> printRateFils,
  Value<int?> areaRateFilsPerSqm,
  Value<int> markupBps,
  Value<int> minOrderFils,
  Value<int> roundingStepFils,
  Value<String> sizesJson,
  Value<String> finishesJson,
  Value<String> quantityPresetsJson,
  Value<String> workflowKey,
  Value<int> sort,
  Value<bool> active,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$LocalDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pricingMode => $composableBuilder(
    column: $table.pricingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sheetWidthMm => $composableBuilder(
    column: $table.sheetWidthMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sheetHeightMm => $composableBuilder(
    column: $table.sheetHeightMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bleedMm => $composableBuilder(
    column: $table.bleedMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gutterMm => $composableBuilder(
    column: $table.gutterMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setupSheets => $composableBuilder(
    column: $table.setupSheets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spoilageBps => $composableBuilder(
    column: $table.spoilageBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materialCode => $composableBuilder(
    column: $table.materialCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get printRateFils => $composableBuilder(
    column: $table.printRateFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get areaRateFilsPerSqm => $composableBuilder(
    column: $table.areaRateFilsPerSqm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get markupBps => $composableBuilder(
    column: $table.markupBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minOrderFils => $composableBuilder(
    column: $table.minOrderFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundingStepFils => $composableBuilder(
    column: $table.roundingStepFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sizesJson => $composableBuilder(
    column: $table.sizesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishesJson => $composableBuilder(
    column: $table.finishesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityPresetsJson => $composableBuilder(
    column: $table.quantityPresetsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowKey => $composableBuilder(
    column: $table.workflowKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pricingMode => $composableBuilder(
    column: $table.pricingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sheetWidthMm => $composableBuilder(
    column: $table.sheetWidthMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sheetHeightMm => $composableBuilder(
    column: $table.sheetHeightMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bleedMm => $composableBuilder(
    column: $table.bleedMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gutterMm => $composableBuilder(
    column: $table.gutterMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setupSheets => $composableBuilder(
    column: $table.setupSheets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spoilageBps => $composableBuilder(
    column: $table.spoilageBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materialCode => $composableBuilder(
    column: $table.materialCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get printRateFils => $composableBuilder(
    column: $table.printRateFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get areaRateFilsPerSqm => $composableBuilder(
    column: $table.areaRateFilsPerSqm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get markupBps => $composableBuilder(
    column: $table.markupBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minOrderFils => $composableBuilder(
    column: $table.minOrderFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundingStepFils => $composableBuilder(
    column: $table.roundingStepFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sizesJson => $composableBuilder(
    column: $table.sizesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishesJson => $composableBuilder(
    column: $table.finishesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityPresetsJson => $composableBuilder(
    column: $table.quantityPresetsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowKey => $composableBuilder(
    column: $table.workflowKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get pricingMode => $composableBuilder(
    column: $table.pricingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sheetWidthMm => $composableBuilder(
    column: $table.sheetWidthMm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sheetHeightMm => $composableBuilder(
    column: $table.sheetHeightMm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bleedMm =>
      $composableBuilder(column: $table.bleedMm, builder: (column) => column);

  GeneratedColumn<int> get gutterMm =>
      $composableBuilder(column: $table.gutterMm, builder: (column) => column);

  GeneratedColumn<int> get setupSheets => $composableBuilder(
    column: $table.setupSheets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spoilageBps => $composableBuilder(
    column: $table.spoilageBps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get materialCode => $composableBuilder(
    column: $table.materialCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get printRateFils => $composableBuilder(
    column: $table.printRateFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get areaRateFilsPerSqm => $composableBuilder(
    column: $table.areaRateFilsPerSqm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get markupBps =>
      $composableBuilder(column: $table.markupBps, builder: (column) => column);

  GeneratedColumn<int> get minOrderFils => $composableBuilder(
    column: $table.minOrderFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundingStepFils => $composableBuilder(
    column: $table.roundingStepFils,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sizesJson =>
      $composableBuilder(column: $table.sizesJson, builder: (column) => column);

  GeneratedColumn<String> get finishesJson => $composableBuilder(
    column: $table.finishesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityPresetsJson => $composableBuilder(
    column: $table.quantityPresetsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workflowKey => $composableBuilder(
    column: $table.workflowKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$LocalDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$LocalDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> pricingMode = const Value.absent(),
                Value<int?> sheetWidthMm = const Value.absent(),
                Value<int?> sheetHeightMm = const Value.absent(),
                Value<int> bleedMm = const Value.absent(),
                Value<int> gutterMm = const Value.absent(),
                Value<int> setupSheets = const Value.absent(),
                Value<int> spoilageBps = const Value.absent(),
                Value<String?> materialCode = const Value.absent(),
                Value<int?> printRateFils = const Value.absent(),
                Value<int?> areaRateFilsPerSqm = const Value.absent(),
                Value<int> markupBps = const Value.absent(),
                Value<int> minOrderFils = const Value.absent(),
                Value<int> roundingStepFils = const Value.absent(),
                Value<String> sizesJson = const Value.absent(),
                Value<String> finishesJson = const Value.absent(),
                Value<String> quantityPresetsJson = const Value.absent(),
                Value<String> workflowKey = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                tenantId: tenantId,
                code: code,
                nameEn: nameEn,
                nameAr: nameAr,
                category: category,
                kind: kind,
                pricingMode: pricingMode,
                sheetWidthMm: sheetWidthMm,
                sheetHeightMm: sheetHeightMm,
                bleedMm: bleedMm,
                gutterMm: gutterMm,
                setupSheets: setupSheets,
                spoilageBps: spoilageBps,
                materialCode: materialCode,
                printRateFils: printRateFils,
                areaRateFilsPerSqm: areaRateFilsPerSqm,
                markupBps: markupBps,
                minOrderFils: minOrderFils,
                roundingStepFils: roundingStepFils,
                sizesJson: sizesJson,
                finishesJson: finishesJson,
                quantityPresetsJson: quantityPresetsJson,
                workflowKey: workflowKey,
                sort: sort,
                active: active,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String code,
                required String nameEn,
                Value<String?> nameAr = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required String kind,
                required String pricingMode,
                Value<int?> sheetWidthMm = const Value.absent(),
                Value<int?> sheetHeightMm = const Value.absent(),
                Value<int> bleedMm = const Value.absent(),
                Value<int> gutterMm = const Value.absent(),
                Value<int> setupSheets = const Value.absent(),
                Value<int> spoilageBps = const Value.absent(),
                Value<String?> materialCode = const Value.absent(),
                Value<int?> printRateFils = const Value.absent(),
                Value<int?> areaRateFilsPerSqm = const Value.absent(),
                Value<int> markupBps = const Value.absent(),
                Value<int> minOrderFils = const Value.absent(),
                Value<int> roundingStepFils = const Value.absent(),
                Value<String> sizesJson = const Value.absent(),
                Value<String> finishesJson = const Value.absent(),
                Value<String> quantityPresetsJson = const Value.absent(),
                Value<String> workflowKey = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                tenantId: tenantId,
                code: code,
                nameEn: nameEn,
                nameAr: nameAr,
                category: category,
                kind: kind,
                pricingMode: pricingMode,
                sheetWidthMm: sheetWidthMm,
                sheetHeightMm: sheetHeightMm,
                bleedMm: bleedMm,
                gutterMm: gutterMm,
                setupSheets: setupSheets,
                spoilageBps: spoilageBps,
                materialCode: materialCode,
                printRateFils: printRateFils,
                areaRateFilsPerSqm: areaRateFilsPerSqm,
                markupBps: markupBps,
                minOrderFils: minOrderFils,
                roundingStepFils: roundingStepFils,
                sizesJson: sizesJson,
                finishesJson: finishesJson,
                quantityPresetsJson: quantityPresetsJson,
                workflowKey: workflowKey,
                sort: sort,
                active: active,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  BaseReferences<_$LocalDatabase, $ProductsTable, Product>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$LocalDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$MaterialsTableCreateCompanionBuilder = MaterialsCompanion Function({
  required String id,
  required String tenantId,
  required String code,
  required String name,
  Value<String?> type,
  Value<int?> gsm,
  Value<int> costPerSheetFils,
  Value<int> rowid,
});
typedef $$MaterialsTableUpdateCompanionBuilder = MaterialsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> code,
  Value<String> name,
  Value<String?> type,
  Value<int?> gsm,
  Value<int> costPerSheetFils,
  Value<int> rowid,
});

class $$MaterialsTableFilterComposer
    extends Composer<_$LocalDatabase, $MaterialsTable> {
  $$MaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gsm => $composableBuilder(
    column: $table.gsm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPerSheetFils => $composableBuilder(
    column: $table.costPerSheetFils,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialsTableOrderingComposer
    extends Composer<_$LocalDatabase, $MaterialsTable> {
  $$MaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gsm => $composableBuilder(
    column: $table.gsm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPerSheetFils => $composableBuilder(
    column: $table.costPerSheetFils,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $MaterialsTable> {
  $$MaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get gsm =>
      $composableBuilder(column: $table.gsm, builder: (column) => column);

  GeneratedColumn<int> get costPerSheetFils => $composableBuilder(
    column: $table.costPerSheetFils,
    builder: (column) => column,
  );
}

class $$MaterialsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $MaterialsTable,
          MaterialRow,
          $$MaterialsTableFilterComposer,
          $$MaterialsTableOrderingComposer,
          $$MaterialsTableAnnotationComposer,
          $$MaterialsTableCreateCompanionBuilder,
          $$MaterialsTableUpdateCompanionBuilder,
          (
            MaterialRow,
            BaseReferences<_$LocalDatabase, $MaterialsTable, MaterialRow>,
          ),
          MaterialRow,
          PrefetchHooks Function()
        > {
  $$MaterialsTableTableManager(_$LocalDatabase db, $MaterialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> gsm = const Value.absent(),
                Value<int> costPerSheetFils = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialsCompanion(
                id: id,
                tenantId: tenantId,
                code: code,
                name: name,
                type: type,
                gsm: gsm,
                costPerSheetFils: costPerSheetFils,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String code,
                required String name,
                Value<String?> type = const Value.absent(),
                Value<int?> gsm = const Value.absent(),
                Value<int> costPerSheetFils = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialsCompanion.insert(
                id: id,
                tenantId: tenantId,
                code: code,
                name: name,
                type: type,
                gsm: gsm,
                costPerSheetFils: costPerSheetFils,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MaterialsTable, MaterialRow>(table),
                  BaseReferences<_$LocalDatabase, $MaterialsTable, MaterialRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $MaterialsTable,
      MaterialRow,
      $$MaterialsTableFilterComposer,
      $$MaterialsTableOrderingComposer,
      $$MaterialsTableAnnotationComposer,
      $$MaterialsTableCreateCompanionBuilder,
      $$MaterialsTableUpdateCompanionBuilder,
      (
        MaterialRow,
        BaseReferences<_$LocalDatabase, $MaterialsTable, MaterialRow>,
      ),
      MaterialRow,
      PrefetchHooks Function()
    >;
typedef $$PriceRulesTableCreateCompanionBuilder = PriceRulesCompanion Function({
  required String id,
  required String tenantId,
  required int priceBookVersion,
  Value<String?> productId,
  required String label,
  required String phase,
  required String basis,
  required int rateFils,
  Value<int> minChargeFils,
  Value<int> priority,
  Value<String> whenJson,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$PriceRulesTableUpdateCompanionBuilder = PriceRulesCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<int> priceBookVersion,
  Value<String?> productId,
  Value<String> label,
  Value<String> phase,
  Value<String> basis,
  Value<int> rateFils,
  Value<int> minChargeFils,
  Value<int> priority,
  Value<String> whenJson,
  Value<bool> active,
  Value<int> rowid,
});

class $$PriceRulesTableFilterComposer
    extends Composer<_$LocalDatabase, $PriceRulesTable> {
  $$PriceRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceBookVersion => $composableBuilder(
    column: $table.priceBookVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateFils => $composableBuilder(
    column: $table.rateFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minChargeFils => $composableBuilder(
    column: $table.minChargeFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whenJson => $composableBuilder(
    column: $table.whenJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PriceRulesTableOrderingComposer
    extends Composer<_$LocalDatabase, $PriceRulesTable> {
  $$PriceRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceBookVersion => $composableBuilder(
    column: $table.priceBookVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateFils => $composableBuilder(
    column: $table.rateFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minChargeFils => $composableBuilder(
    column: $table.minChargeFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whenJson => $composableBuilder(
    column: $table.whenJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PriceRulesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PriceRulesTable> {
  $$PriceRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<int> get priceBookVersion => $composableBuilder(
    column: $table.priceBookVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get basis =>
      $composableBuilder(column: $table.basis, builder: (column) => column);

  GeneratedColumn<int> get rateFils =>
      $composableBuilder(column: $table.rateFils, builder: (column) => column);

  GeneratedColumn<int> get minChargeFils => $composableBuilder(
    column: $table.minChargeFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get whenJson =>
      $composableBuilder(column: $table.whenJson, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$PriceRulesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PriceRulesTable,
          PriceRuleRow,
          $$PriceRulesTableFilterComposer,
          $$PriceRulesTableOrderingComposer,
          $$PriceRulesTableAnnotationComposer,
          $$PriceRulesTableCreateCompanionBuilder,
          $$PriceRulesTableUpdateCompanionBuilder,
          (
            PriceRuleRow,
            BaseReferences<_$LocalDatabase, $PriceRulesTable, PriceRuleRow>,
          ),
          PriceRuleRow,
          PrefetchHooks Function()
        > {
  $$PriceRulesTableTableManager(_$LocalDatabase db, $PriceRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<int> priceBookVersion = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<int> rateFils = const Value.absent(),
                Value<int> minChargeFils = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> whenJson = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceRulesCompanion(
                id: id,
                tenantId: tenantId,
                priceBookVersion: priceBookVersion,
                productId: productId,
                label: label,
                phase: phase,
                basis: basis,
                rateFils: rateFils,
                minChargeFils: minChargeFils,
                priority: priority,
                whenJson: whenJson,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required int priceBookVersion,
                Value<String?> productId = const Value.absent(),
                required String label,
                required String phase,
                required String basis,
                required int rateFils,
                Value<int> minChargeFils = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> whenJson = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceRulesCompanion.insert(
                id: id,
                tenantId: tenantId,
                priceBookVersion: priceBookVersion,
                productId: productId,
                label: label,
                phase: phase,
                basis: basis,
                rateFils: rateFils,
                minChargeFils: minChargeFils,
                priority: priority,
                whenJson: whenJson,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PriceRulesTable, PriceRuleRow>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    $PriceRulesTable,
                    PriceRuleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PriceRulesTable,
      PriceRuleRow,
      $$PriceRulesTableFilterComposer,
      $$PriceRulesTableOrderingComposer,
      $$PriceRulesTableAnnotationComposer,
      $$PriceRulesTableCreateCompanionBuilder,
      $$PriceRulesTableUpdateCompanionBuilder,
      (
        PriceRuleRow,
        BaseReferences<_$LocalDatabase, $PriceRulesTable, PriceRuleRow>,
      ),
      PriceRuleRow,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  Value<int?> number,
  required String numberDisplay,
  Value<bool> isQuote,
  required String customerId,
  Value<String?> customerName,
  Value<String> status,
  Value<String> priority,
  Value<DateTime?> dueAt,
  Value<String> deliveryMethod,
  Value<String?> notes,
  Value<int> subtotalFils,
  Value<int> vatFils,
  Value<int> totalFils,
  Value<int> itemCount,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<int?> number,
  Value<String> numberDisplay,
  Value<bool> isQuote,
  Value<String> customerId,
  Value<String?> customerName,
  Value<String> status,
  Value<String> priority,
  Value<DateTime?> dueAt,
  Value<String> deliveryMethod,
  Value<String?> notes,
  Value<int> subtotalFils,
  Value<int> vatFils,
  Value<int> totalFils,
  Value<int> itemCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$OrdersTableFilterComposer
    extends Composer<_$LocalDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numberDisplay => $composableBuilder(
    column: $table.numberDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isQuote => $composableBuilder(
    column: $table.isQuote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryMethod => $composableBuilder(
    column: $table.deliveryMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatFils => $composableBuilder(
    column: $table.vatFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFils => $composableBuilder(
    column: $table.totalFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableOrderingComposer
    extends Composer<_$LocalDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numberDisplay => $composableBuilder(
    column: $table.numberDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isQuote => $composableBuilder(
    column: $table.isQuote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryMethod => $composableBuilder(
    column: $table.deliveryMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatFils => $composableBuilder(
    column: $table.vatFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFils => $composableBuilder(
    column: $table.totalFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get numberDisplay => $composableBuilder(
    column: $table.numberDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isQuote =>
      $composableBuilder(column: $table.isQuote, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get deliveryMethod => $composableBuilder(
    column: $table.deliveryMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatFils =>
      $composableBuilder(column: $table.vatFils, builder: (column) => column);

  GeneratedColumn<int> get totalFils =>
      $composableBuilder(column: $table.totalFils, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, BaseReferences<_$LocalDatabase, $OrdersTable, Order>),
          Order,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableManager(_$LocalDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<String> numberDisplay = const Value.absent(),
                Value<bool> isQuote = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String> deliveryMethod = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> subtotalFils = const Value.absent(),
                Value<int> vatFils = const Value.absent(),
                Value<int> totalFils = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                number: number,
                numberDisplay: numberDisplay,
                isQuote: isQuote,
                customerId: customerId,
                customerName: customerName,
                status: status,
                priority: priority,
                dueAt: dueAt,
                deliveryMethod: deliveryMethod,
                notes: notes,
                subtotalFils: subtotalFils,
                vatFils: vatFils,
                totalFils: totalFils,
                itemCount: itemCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                Value<int?> number = const Value.absent(),
                required String numberDisplay,
                Value<bool> isQuote = const Value.absent(),
                required String customerId,
                Value<String?> customerName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String> deliveryMethod = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> subtotalFils = const Value.absent(),
                Value<int> vatFils = const Value.absent(),
                Value<int> totalFils = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                number: number,
                numberDisplay: numberDisplay,
                isQuote: isQuote,
                customerId: customerId,
                customerName: customerName,
                status: status,
                priority: priority,
                dueAt: dueAt,
                deliveryMethod: deliveryMethod,
                notes: notes,
                subtotalFils: subtotalFils,
                vatFils: vatFils,
                totalFils: totalFils,
                itemCount: itemCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrdersTable, Order>(table),
                  BaseReferences<_$LocalDatabase, $OrdersTable, Order>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, BaseReferences<_$LocalDatabase, $OrdersTable, Order>),
      Order,
      PrefetchHooks Function()
    >;
typedef $$OrderItemsTableCreateCompanionBuilder = OrderItemsCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> branchId,
  required String orderId,
  required String productId,
  required String description,
  Value<String> optionsJson,
  required int quantity,
  required int priceBookVersion,
  required String breakdownJson,
  required int subtotalFils,
  required int vatFils,
  required int totalFils,
  Value<String> status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$OrderItemsTableUpdateCompanionBuilder = OrderItemsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> branchId,
  Value<String> orderId,
  Value<String> productId,
  Value<String> description,
  Value<String> optionsJson,
  Value<int> quantity,
  Value<int> priceBookVersion,
  Value<String> breakdownJson,
  Value<int> subtotalFils,
  Value<int> vatFils,
  Value<int> totalFils,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> createdBy,
  Value<int> version,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$OrderItemsTableFilterComposer
    extends Composer<_$LocalDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceBookVersion => $composableBuilder(
    column: $table.priceBookVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatFils => $composableBuilder(
    column: $table.vatFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFils => $composableBuilder(
    column: $table.totalFils,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$LocalDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceBookVersion => $composableBuilder(
    column: $table.priceBookVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatFils => $composableBuilder(
    column: $table.vatFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFils => $composableBuilder(
    column: $table.totalFils,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get priceBookVersion => $composableBuilder(
    column: $table.priceBookVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalFils => $composableBuilder(
    column: $table.subtotalFils,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatFils =>
      $composableBuilder(column: $table.vatFils, builder: (column) => column);

  GeneratedColumn<int> get totalFils =>
      $composableBuilder(column: $table.totalFils, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $OrderItemsTable,
          OrderItem,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (
            OrderItem,
            BaseReferences<_$LocalDatabase, $OrderItemsTable, OrderItem>,
          ),
          OrderItem,
          PrefetchHooks Function()
        > {
  $$OrderItemsTableTableManager(_$LocalDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> priceBookVersion = const Value.absent(),
                Value<String> breakdownJson = const Value.absent(),
                Value<int> subtotalFils = const Value.absent(),
                Value<int> vatFils = const Value.absent(),
                Value<int> totalFils = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                productId: productId,
                description: description,
                optionsJson: optionsJson,
                quantity: quantity,
                priceBookVersion: priceBookVersion,
                breakdownJson: breakdownJson,
                subtotalFils: subtotalFils,
                vatFils: vatFils,
                totalFils: totalFils,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> branchId = const Value.absent(),
                required String orderId,
                required String productId,
                required String description,
                Value<String> optionsJson = const Value.absent(),
                required int quantity,
                required int priceBookVersion,
                required String breakdownJson,
                required int subtotalFils,
                required int vatFils,
                required int totalFils,
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> createdBy = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                orderId: orderId,
                productId: productId,
                description: description,
                optionsJson: optionsJson,
                quantity: quantity,
                priceBookVersion: priceBookVersion,
                breakdownJson: breakdownJson,
                subtotalFils: subtotalFils,
                vatFils: vatFils,
                totalFils: totalFils,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrderItemsTable, OrderItem>(table),
                  BaseReferences<_$LocalDatabase, $OrderItemsTable, OrderItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $OrderItemsTable,
      OrderItem,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItem, BaseReferences<_$LocalDatabase, $OrderItemsTable, OrderItem>),
      OrderItem,
      PrefetchHooks Function()
    >;
typedef $$OutboxMutationsTableCreateCompanionBuilder =
    OutboxMutationsCompanion Function({
      required String mutationId,
      required String entity,
      required String rowId,
      required String op,
      required String payloadJson,
      required int baseVersion,
      required DateTime deviceTs,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$OutboxMutationsTableUpdateCompanionBuilder =
    OutboxMutationsCompanion Function({
      Value<String> mutationId,
      Value<String> entity,
      Value<String> rowId,
      Value<String> op,
      Value<String> payloadJson,
      Value<int> baseVersion,
      Value<DateTime> deviceTs,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$OutboxMutationsTableFilterComposer
    extends Composer<_$LocalDatabase, $OutboxMutationsTable> {
  $$OutboxMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deviceTs => $composableBuilder(
    column: $table.deviceTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxMutationsTableOrderingComposer
    extends Composer<_$LocalDatabase, $OutboxMutationsTable> {
  $$OutboxMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deviceTs => $composableBuilder(
    column: $table.deviceTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxMutationsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $OutboxMutationsTable> {
  $$OutboxMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deviceTs =>
      $composableBuilder(column: $table.deviceTs, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxMutationsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $OutboxMutationsTable,
          OutboxMutation,
          $$OutboxMutationsTableFilterComposer,
          $$OutboxMutationsTableOrderingComposer,
          $$OutboxMutationsTableAnnotationComposer,
          $$OutboxMutationsTableCreateCompanionBuilder,
          $$OutboxMutationsTableUpdateCompanionBuilder,
          (
            OutboxMutation,
            BaseReferences<
              _$LocalDatabase,
              $OutboxMutationsTable,
              OutboxMutation
            >,
          ),
          OutboxMutation,
          PrefetchHooks Function()
        > {
  $$OutboxMutationsTableTableManager(
    _$LocalDatabase db,
    $OutboxMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mutationId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> baseVersion = const Value.absent(),
                Value<DateTime> deviceTs = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxMutationsCompanion(
                mutationId: mutationId,
                entity: entity,
                rowId: rowId,
                op: op,
                payloadJson: payloadJson,
                baseVersion: baseVersion,
                deviceTs: deviceTs,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mutationId,
                required String entity,
                required String rowId,
                required String op,
                required String payloadJson,
                required int baseVersion,
                required DateTime deviceTs,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxMutationsCompanion.insert(
                mutationId: mutationId,
                entity: entity,
                rowId: rowId,
                op: op,
                payloadJson: payloadJson,
                baseVersion: baseVersion,
                deviceTs: deviceTs,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxMutationsTable, OutboxMutation>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    $OutboxMutationsTable,
                    OutboxMutation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $OutboxMutationsTable,
      OutboxMutation,
      $$OutboxMutationsTableFilterComposer,
      $$OutboxMutationsTableOrderingComposer,
      $$OutboxMutationsTableAnnotationComposer,
      $$OutboxMutationsTableCreateCompanionBuilder,
      $$OutboxMutationsTableUpdateCompanionBuilder,
      (
        OutboxMutation,
        BaseReferences<_$LocalDatabase, $OutboxMutationsTable, OutboxMutation>,
      ),
      OutboxMutation,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$LocalDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$LocalDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$LocalDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$LocalDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaData>(table),
                  BaseReferences<_$LocalDatabase, $SyncMetaTable, SyncMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$LocalDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$CustomerPhonesTableTableManager get customerPhones =>
      $$CustomerPhonesTableTableManager(_db, _db.customerPhones);
  $$WorkflowStagesTableTableManager get workflowStages =>
      $$WorkflowStagesTableTableManager(_db, _db.workflowStages);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ProofsTableTableManager get proofs =>
      $$ProofsTableTableManager(_db, _db.proofs);
  $$TimeEntriesTableTableManager get timeEntries =>
      $$TimeEntriesTableTableManager(_db, _db.timeEntries);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceLinesTableTableManager get invoiceLines =>
      $$InvoiceLinesTableTableManager(_db, _db.invoiceLines);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$MaterialsTableTableManager get materials =>
      $$MaterialsTableTableManager(_db, _db.materials);
  $$PriceRulesTableTableManager get priceRules =>
      $$PriceRulesTableTableManager(_db, _db.priceRules);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$OutboxMutationsTableTableManager get outboxMutations =>
      $$OutboxMutationsTableTableManager(_db, _db.outboxMutations);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
