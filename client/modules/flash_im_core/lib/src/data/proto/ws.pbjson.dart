// This is a generated file - do not edit.
//
// Generated from ws.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use wsFrameTypeDescriptor instead')
const WsFrameType$json = {
  '1': 'WsFrameType',
  '2': [
    {'1': 'PING', '2': 0},
    {'1': 'PONG', '2': 1},
    {'1': 'AUTH', '2': 2},
    {'1': 'AUTH_RESULT', '2': 3},
    {'1': 'CHAT_MESSAGE', '2': 4},
    {'1': 'MESSAGE_ACK', '2': 5},
    {'1': 'CONVERSATION_UPDATE', '2': 6},
    {'1': 'FRIEND_REQUEST', '2': 7},
    {'1': 'FRIEND_ACCEPTED', '2': 8},
    {'1': 'FRIEND_REMOVED', '2': 9},
  ],
};

/// Descriptor for `WsFrameType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List wsFrameTypeDescriptor = $convert.base64Decode(
    'CgtXc0ZyYW1lVHlwZRIICgRQSU5HEAASCAoEUE9ORxABEggKBEFVVEgQAhIPCgtBVVRIX1JFU1'
    'VMVBADEhAKDENIQVRfTUVTU0FHRRAEEg8KC01FU1NBR0VfQUNLEAUSFwoTQ09OVkVSU0FUSU9O'
    'X1VQREFURRAGEhIKDkZSSUVORF9SRVFVRVNUEAcSEwoPRlJJRU5EX0FDQ0VQVEVEEAgSEgoORl'
    'JJRU5EX1JFTU9WRUQQCQ==');

@$core.Deprecated('Use wsFrameDescriptor instead')
const WsFrame$json = {
  '1': 'WsFrame',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.im.WsFrameType',
      '10': 'type'
    },
    {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `WsFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsFrameDescriptor = $convert.base64Decode(
    'CgdXc0ZyYW1lEiMKBHR5cGUYASABKA4yDy5pbS5Xc0ZyYW1lVHlwZVIEdHlwZRIYCgdwYXlsb2'
    'FkGAIgASgMUgdwYXlsb2Fk');

@$core.Deprecated('Use authRequestDescriptor instead')
const AuthRequest$json = {
  '1': 'AuthRequest',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `AuthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authRequestDescriptor =
    $convert.base64Decode('CgtBdXRoUmVxdWVzdBIUCgV0b2tlbhgBIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use authResultDescriptor instead')
const AuthResult$json = {
  '1': 'AuthResult',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `AuthResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authResultDescriptor = $convert.base64Decode(
    'CgpBdXRoUmVzdWx0EhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZRgCIAEoCV'
    'IHbWVzc2FnZQ==');

@$core.Deprecated('Use friendRequestNotificationDescriptor instead')
const FriendRequestNotification$json = {
  '1': 'FriendRequestNotification',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'from_user_id', '3': 2, '4': 1, '5': 9, '10': 'fromUserId'},
    {'1': 'nickname', '3': 3, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'avatar', '3': 4, '4': 1, '5': 9, '10': 'avatar'},
    {'1': 'message', '3': 5, '4': 1, '5': 9, '10': 'message'},
    {'1': 'created_at', '3': 6, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `FriendRequestNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendRequestNotificationDescriptor = $convert.base64Decode(
    'ChlGcmllbmRSZXF1ZXN0Tm90aWZpY2F0aW9uEh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3'
    'RJZBIgCgxmcm9tX3VzZXJfaWQYAiABKAlSCmZyb21Vc2VySWQSGgoIbmlja25hbWUYAyABKAlS'
    'CG5pY2tuYW1lEhYKBmF2YXRhchgEIAEoCVIGYXZhdGFyEhgKB21lc3NhZ2UYBSABKAlSB21lc3'
    'NhZ2USHQoKY3JlYXRlZF9hdBgGIAEoA1IJY3JlYXRlZEF0');

@$core.Deprecated('Use friendAcceptedNotificationDescriptor instead')
const FriendAcceptedNotification$json = {
  '1': 'FriendAcceptedNotification',
  '2': [
    {'1': 'friend_id', '3': 1, '4': 1, '5': 9, '10': 'friendId'},
    {'1': 'nickname', '3': 2, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'avatar', '3': 3, '4': 1, '5': 9, '10': 'avatar'},
    {'1': 'created_at', '3': 4, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `FriendAcceptedNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendAcceptedNotificationDescriptor =
    $convert.base64Decode(
        'ChpGcmllbmRBY2NlcHRlZE5vdGlmaWNhdGlvbhIbCglmcmllbmRfaWQYASABKAlSCGZyaWVuZE'
        'lkEhoKCG5pY2tuYW1lGAIgASgJUghuaWNrbmFtZRIWCgZhdmF0YXIYAyABKAlSBmF2YXRhchId'
        'CgpjcmVhdGVkX2F0GAQgASgDUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use friendRemovedNotificationDescriptor instead')
const FriendRemovedNotification$json = {
  '1': 'FriendRemovedNotification',
  '2': [
    {'1': 'friend_id', '3': 1, '4': 1, '5': 9, '10': 'friendId'},
  ],
};

/// Descriptor for `FriendRemovedNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendRemovedNotificationDescriptor =
    $convert.base64Decode(
        'ChlGcmllbmRSZW1vdmVkTm90aWZpY2F0aW9uEhsKCWZyaWVuZF9pZBgBIAEoCVIIZnJpZW5kSW'
        'Q=');
