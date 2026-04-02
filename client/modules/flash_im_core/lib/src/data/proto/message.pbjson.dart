// This is a generated file - do not edit.
//
// Generated from message.proto.

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
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor =
    $convert.base64Decode('CgtNZXNzYWdlVHlwZRIICgRURVhUEAA=');

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
