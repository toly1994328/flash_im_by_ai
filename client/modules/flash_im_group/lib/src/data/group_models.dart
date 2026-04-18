/// CreateGroupPage 返回值
class CreateGroupResult {
  final String name;
  final List<int> memberIds;

  const CreateGroupResult({required this.name, required this.memberIds});
}

/// 可选成员（CreateGroupPage 用，避免依赖 flash_im_friend）
class SelectableMember {
  final String id;
  final String nickname;
  final String? avatar;
  final String letter; // 拼音首字母（A-Z / #），由调用方传入

  const SelectableMember({
    required this.id,
    required this.nickname,
    this.avatar,
    this.letter = '#',
  });
}
