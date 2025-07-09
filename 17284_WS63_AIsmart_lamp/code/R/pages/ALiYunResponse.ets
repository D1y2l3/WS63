/**
 * 阿里云API响应数据模型
 * 用于解析通义千问大模型API返回的JSON数据
 */
export class ALiYunResponse {
  /**
   * 请求唯一标识，用于追踪和调试API请求
   */
  request_id: string = ''; // 初始化空字符串

  /**
   * 模型输出内容
   */
  output: ALiYunResp_output = { text: '' }; // 初始化对象

  /**
   * 令牌使用统计信息
   */
  usage: ALiYunResp_usage = { output_tokens: '', input_tokens: '' }; // 初始化对象
}

/**
 * 模型输出内容子模型
 */
class ALiYunResp_output {
  /**
   * 模型生成的文本内容
   */
  text: string = ''; // 初始化空字符串
}

/**
 * 令牌使用统计子模型
 */
class ALiYunResp_usage {
  /**
   * 输出内容消耗的令牌数量
   */
  output_tokens: string = ''; // 初始化空字符串

  /**
   * 输入内容消耗的令牌数量
   */
  input_tokens: string = ''; // 初始化空字符串
}
