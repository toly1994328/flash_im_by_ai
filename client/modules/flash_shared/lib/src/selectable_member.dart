/// 可选成员 — 通用选人组件的数据模型
///
/// 与业务无关，只包含选人页需要的最小字段。
/// 调用方负责把业务数据（Friend、群成员等）转换为 SelectableMember。
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
