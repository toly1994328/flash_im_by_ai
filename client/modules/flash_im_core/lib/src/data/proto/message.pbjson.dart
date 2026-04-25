// This is a generated file - do not edit.
//
// Generated from proto/message.proto.

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

@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = {
  '1': 'MessageType',
  '2': [
    {'1': 'TEXT', '2': 0},
    {'1': 'IMAGE', '2': 1},
    {'1': 'VIDEO', '2': 2},
    {'1': 'FILE', '2': 3},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlVHlwZRIICgRURVhUEAASCQoFSU1BR0UQARIJCgVWSURFTxACEggKBEZJTEUQAw'
    '==');

@$core.Deprecated('Use messageStatusDescriptor instead')
const MessageStatus$json = {
  '1': 'MessageStatus',
  '2': [
    {'1': 'NORMAL', '2': 0},
    {'1': 'RECALLED', '2': 1},
    {'1': 'DELETED', '2': 2},
  ],
};

/// Descriptor for `MessageStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageStatusDescriptor = $convert.base64Decode(
    'Cg1NZXNzYWdlU3RhdHVzEgoKBk5PUk1BTBAAEgwKCFJFQ0FMTEVEEAESCwoHREVMRVRFRBAC');

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'sender_id', '3': 3, '4': 1, '5': 9, '10': 'senderId'},
    {'1': 'seq', '3': 4, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'type',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.im.MessageType',
      '10': 'type'
    },
    {'1': 'content', '3': 6, '4': 1, '5': 9, '10': 'content'},
    {'1': 'extra', '3': 7, '4': 1, '5': 12, '10': 'extra'},
    {
      '1': 'status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.im.MessageStatus',
      '10': 'status'
    },
    {'1': 'created_at', '3': 9, '4': 1, '5': 3, '10': 'createdAt'},
    {'1': 'sender_name', '3': 10, '4': 1, '5': 9, '10': 'senderName'},
    {'1': 'sender_avatar', '3': 11, '4': 1, '5': 9, '10': 'senderAvatar'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor = $convert.base64Decode(
    'CgtDaGF0TWVzc2FnZRIOCgJpZBgBIAEoCVICaWQSJwoPY29udmVyc2F0aW9uX2lkGAIgASgJUg'
    '5jb252ZXJzYXRpb25JZBIbCglzZW5kZXJfaWQYAyABKAlSCHNlbmRlcklkEhAKA3NlcRgEIAEo'
    'A1IDc2VxEiMKBHR5cGUYBSABKA4yDy5pbS5NZXNzYWdlVHlwZVIEdHlwZRIYCgdjb250ZW50GA'
    'YgASgJUgdjb250ZW50EhQKBWV4dHJhGAcgASgMUgVleHRyYRIpCgZzdGF0dXMYCCABKA4yES5p'
    'bS5NZXNzYWdlU3RhdHVzUgZzdGF0dXMSHQoKY3JlYXRlZF9hdBgJIAEoA1IJY3JlYXRlZEF0Eh'
    '8KC3NlbmRlcl9uYW1lGAogASgJUgpzZW5kZXJOYW1lEiMKDXNlbmRlcl9hdmF0YXIYCyABKAlS'
    'DHNlbmRlckF2YXRhcg==');

@$core.Deprecated('Use sendMessageRequestDescriptor instead')
const SendMessageRequest$json = {
  '1': 'SendMessageRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.im.MessageType',
      '10': 'type'
    },
    {'1': 'content', '3': 3, '4': 1, '5': 9, '10': 'content'},
    {'1': 'extra', '3': 4, '4': 1, '5': 12, '10': 'extra'},
    {'1': 'client_id', '3': 5, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `SendMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageRequestDescriptor = $convert.base64Decode(
    'ChJTZW5kTWVzc2FnZVJlcXVlc3QSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYX'
    'Rpb25JZBIjCgR0eXBlGAIgASgOMg8uaW0uTWVzc2FnZVR5cGVSBHR5cGUSGAoHY29udGVudBgD'
    'IAEoCVIHY29udGVudBIUCgVleHRyYRgEIAEoDFIFZXh0cmESGwoJY2xpZW50X2lkGAUgASgJUg'
    'hjbGllbnRJZA==');

@$core.Deprecated('Use messageAckDescriptor instead')
const MessageAck$json = {
  '1': 'MessageAck',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'seq', '3': 2, '4': 1, '5': 3, '10': 'seq'},
  ],
};

/// Descriptor for `MessageAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageAckDescriptor = $convert.base64Decode(
    'CgpNZXNzYWdlQWNrEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZBIQCgNzZXEYAiABKA'
    'NSA3NlcQ==');

@$core.Deprecated('Use conversationUpdateDescriptor instead')
const ConversationUpdate$json = {
  '1': 'ConversationUpdate',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'last_message_preview',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'lastMessagePreview'
    },
    {'1': 'last_message_at', '3': 3, '4': 1, '5': 3, '10': 'lastMessageAt'},
    {'1': 'unread_count', '3': 4, '4': 1, '5': 5, '10': 'unreadCount'},
    {'1': 'total_unread', '3': 5, '4': 1, '5': 5, '10': 'totalUnread'},
  ],
};

/// Descriptor for `ConversationUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationUpdateDescriptor = $convert.base64Decode(
    'ChJDb252ZXJzYXRpb25VcGRhdGUSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYX'
    'Rpb25JZBIwChRsYXN0X21lc3NhZ2VfcHJldmlldxgCIAEoCVISbGFzdE1lc3NhZ2VQcmV2aWV3'
    'EiYKD2xhc3RfbWVzc2FnZV9hdBgDIAEoA1INbGFzdE1lc3NhZ2VBdBIhCgx1bnJlYWRfY291bn'
    'QYBCABKAVSC3VucmVhZENvdW50EiEKDHRvdGFsX3VucmVhZBgFIAEoBVILdG90YWxVbnJlYWQ=');

@$core.Deprecated('Use groupInfoUpdateDescriptor instead')
const GroupInfoUpdate$json = {
  '1': 'GroupInfoUpdate',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'avatar', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'avatar', '17': true},
    {
      '1': 'announcement',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'announcement',
      '17': true
    },
    {'1': 'status', '3': 5, '4': 1, '5': 5, '9': 3, '10': 'status', '17': true},
  ],
  '8': [
    {'1': '_name'},
    {'1': '_avatar'},
    {'1': '_announcement'},
    {'1': '_status'},
  ],
};

/// Descriptor for `GroupInfoUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupInfoUpdateDescriptor = $convert.base64Decode(
    'Cg9Hcm91cEluZm9VcGRhdGUSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb2'
    '5JZBIXCgRuYW1lGAIgASgJSABSBG5hbWWIAQESGwoGYXZhdGFyGAMgASgJSAFSBmF2YXRhcogB'
    'ARInCgxhbm5vdW5jZW1lbnQYBCABKAlIAlIMYW5ub3VuY2VtZW50iAEBEhsKBnN0YXR1cxgFIA'
    'EoBUgDUgZzdGF0dXOIAQFCBwoFX25hbWVCCQoHX2F2YXRhckIPCg1fYW5ub3VuY2VtZW50QgkK'
    'B19zdGF0dXM=');

@$core.Deprecated('Use userStatusNotificationDescriptor instead')
const UserStatusNotification$json = {
  '1': 'UserStatusNotification',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `UserStatusNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userStatusNotificationDescriptor =
    $convert.base64Decode(
        'ChZVc2VyU3RhdHVzTm90aWZpY2F0aW9uEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZA==');

@$core.Deprecated('Use onlineListNotificationDescriptor instead')
const OnlineListNotification$json = {
  '1': 'OnlineListNotification',
  '2': [
    {'1': 'user_ids', '3': 1, '4': 3, '5': 9, '10': 'userIds'},
  ],
};

/// Descriptor for `OnlineListNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List onlineListNotificationDescriptor =
    $convert.base64Decode(
        'ChZPbmxpbmVMaXN0Tm90aWZpY2F0aW9uEhkKCHVzZXJfaWRzGAEgAygJUgd1c2VySWRz');

@$core.Deprecated('Use readReceiptRequestDescriptor instead')
const ReadReceiptRequest$json = {
  '1': 'ReadReceiptRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'read_seq', '3': 2, '4': 1, '5': 3, '10': 'readSeq'},
  ],
};

/// Descriptor for `ReadReceiptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readReceiptRequestDescriptor = $convert.base64Decode(
    'ChJSZWFkUmVjZWlwdFJlcXVlc3QSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYX'
    'Rpb25JZBIZCghyZWFkX3NlcRgCIAEoA1IHcmVhZFNlcQ==');

@$core.Deprecated('Use readReceiptNotificationDescriptor instead')
const ReadReceiptNotification$json = {
  '1': 'ReadReceiptNotification',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'read_seq', '3': 3, '4': 1, '5': 3, '10': 'readSeq'},
  ],
};

/// Descriptor for `ReadReceiptNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readReceiptNotificationDescriptor = $convert.base64Decode(
    'ChdSZWFkUmVjZWlwdE5vdGlmaWNhdGlvbhInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbn'
    'ZlcnNhdGlvbklkEhcKB3VzZXJfaWQYAiABKAlSBnVzZXJJZBIZCghyZWFkX3NlcRgDIAEoA1IH'
    'cmVhZFNlcQ==');
