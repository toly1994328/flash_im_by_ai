// This is a generated file - do not edit.
//
// Generated from ws.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'ws.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'ws.pbenum.dart';

class WsFrame extends $pb.GeneratedMessage {
  factory WsFrame({
    WsFrameType? type,
    $core.List<$core.int>? payload,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (payload != null) result.payload = payload;
    return result;
  }

  WsFrame._();

  factory WsFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WsFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WsFrame',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'im'),
      createEmptyInstance: create)
    ..aE<WsFrameType>(1, _omitFieldNames ? '' : 'type',
        enumValues: WsFrameType.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsFrame copyWith(void Function(WsFrame) updates) =>
      super.copyWith((message) => updates(message as WsFrame)) as WsFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WsFrame create() => WsFrame._();
  @$core.override
  WsFrame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WsFrame getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WsFrame>(create);
  static WsFrame? _defaultInstance;

  @$pb.TagNumber(1)
  WsFrameType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(WsFrameType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get payload => $_getN(1);
  @$pb.TagNumber(2)
  set payload($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField(2);
}

class AuthRequest extends $pb.GeneratedMessage {
  factory AuthRequest({
    $core.String? token,
  }) {
    final result = create();
    if (token != null) result.token = token;
    return result;
  }

  AuthRequest._();

  factory AuthRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'im'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthRequest copyWith(void Function(AuthRequest) updates) =>
      super.copyWith((message) => updates(message as AuthRequest))
          as AuthRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthRequest create() => AuthRequest._();
  @$core.override
  AuthRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthRequest>(create);
  static AuthRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);
}

class AuthResult extends $pb.GeneratedMessage {
  factory AuthResult({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  AuthResult._();

  factory AuthResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'im'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthResult copyWith(void Function(AuthResult) updates) =>
      super.copyWith((message) => updates(message as AuthResult)) as AuthResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthResult create() => AuthResult._();
  @$core.override
  AuthResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthResult>(create);
  static AuthResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class FriendRequestNotification extends $pb.GeneratedMessage {
  factory FriendRequestNotification({
    $core.String? requestId,
    $core.String? fromUserId,
    $core.String? nickname,
    $core.String? avatar,
    $core.String? message,
    $fixnum.Int64? createdAt,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (fromUserId != null) result.fromUserId = fromUserId;
    if (nickname != null) result.nickname = nickname;
    if (avatar != null) result.avatar = avatar;
    if (message != null) result.message = message;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  FriendRequestNotification._();

  factory FriendRequestNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FriendRequestNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FriendRequestNotification',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'im'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOS(2, _omitFieldNames ? '' : 'fromUserId')
    ..aOS(3, _omitFieldNames ? '' : 'nickname')
    ..aOS(4, _omitFieldNames ? '' : 'avatar')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..aInt64(6, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendRequestNotification clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendRequestNotification copyWith(
          void Function(FriendRequestNotification) updates) =>
      super.copyWith((message) => updates(message as FriendRequestNotification))
          as FriendRequestNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendRequestNotification create() => FriendRequestNotification._();
  @$core.override
  FriendRequestNotification createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FriendRequestNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FriendRequestNotification>(create);
  static FriendRequestNotification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nickname => $_getSZ(2);
  @$pb.TagNumber(3)
  set nickname($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNickname() => $_has(2);
  @$pb.TagNumber(3)
  void clearNickname() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get avatar => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatar($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatar() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatar() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createdAt => $_getI64(5);
  @$pb.TagNumber(6)
  set createdAt($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
}

class FriendAcceptedNotification extends $pb.GeneratedMessage {
  factory FriendAcceptedNotification({
    $core.String? friendId,
    $core.String? nickname,
    $core.String? avatar,
    $fixnum.Int64? createdAt,
  }) {
    final result = create();
    if (friendId != null) result.friendId = friendId;
    if (nickname != null) result.nickname = nickname;
    if (avatar != null) result.avatar = avatar;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  FriendAcceptedNotification._();

  factory FriendAcceptedNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FriendAcceptedNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FriendAcceptedNotification',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'im'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'friendId')
    ..aOS(2, _omitFieldNames ? '' : 'nickname')
    ..aOS(3, _omitFieldNames ? '' : 'avatar')
    ..aInt64(4, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendAcceptedNotification clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendAcceptedNotification copyWith(
          void Function(FriendAcceptedNotification) updates) =>
      super.copyWith(
              (message) => updates(message as FriendAcceptedNotification))
          as FriendAcceptedNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendAcceptedNotification create() => FriendAcceptedNotification._();
  @$core.override
  FriendAcceptedNotification createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FriendAcceptedNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FriendAcceptedNotification>(create);
  static FriendAcceptedNotification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get friendId => $_getSZ(0);
  @$pb.TagNumber(1)
  set friendId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFriendId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFriendId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nickname => $_getSZ(1);
  @$pb.TagNumber(2)
  set nickname($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNickname() => $_has(1);
  @$pb.TagNumber(2)
  void clearNickname() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatar => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatar($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatar() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatar() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createdAt => $_getI64(3);
  @$pb.TagNumber(4)
  set createdAt($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
}

class FriendRemovedNotification extends $pb.GeneratedMessage {
  factory FriendRemovedNotification({
    $core.String? friendId,
  }) {
    final result = create();
    if (friendId != null) result.friendId = friendId;
    return result;
  }

  FriendRemovedNotification._();

  factory FriendRemovedNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FriendRemovedNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FriendRemovedNotification',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'im'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'friendId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendRemovedNotification clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendRemovedNotification copyWith(
          void Function(FriendRemovedNotification) updates) =>
      super.copyWith((message) => updates(message as FriendRemovedNotification))
          as FriendRemovedNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendRemovedNotification create() => FriendRemovedNotification._();
  @$core.override
  FriendRemovedNotification createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FriendRemovedNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FriendRemovedNotification>(create);
  static FriendRemovedNotification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get friendId => $_getSZ(0);
  @$pb.TagNumber(1)
  set friendId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFriendId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFriendId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
