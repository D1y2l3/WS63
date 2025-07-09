/**
 * 消息视图对象，用于存储聊天消息的基本信息
 */
export class MessageVO {
  /**
   * 消息发送者角色，使用MessageRoleEnum枚举类型
   */
  role: MessageRoleEnum

  /**
   * 消息内容文本
   */
  message: string

  /**
   * 构造函数，初始化消息对象
   * @param role - 消息发送者角色
   * @param message - 消息内容文本
   */
  constructor(role: MessageRoleEnum, message: string) {
    this.role = role
    this.message = message
  }
}

/**
 * 消息发送者角色枚举
 */
export enum MessageRoleEnum {
  // 消息发送者为当前用户自己
  Mine,
  // 消息发送者为对方用户
  Other
}
