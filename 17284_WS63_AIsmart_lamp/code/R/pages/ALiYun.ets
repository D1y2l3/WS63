import http from '@ohos.net.http';
import hilog from '@ohos.hilog';
import { ALiYunResponse } from './ALiYunResponse';

class ALiYunHttpUtils {

  request(question: string, callback: Function) {
    hilog.info(0x0000, 'testTag', 'ALiYunHttpUtils request invoke. question: %{public}s', question);

    let httpRequest = http.createHttp();

    httpRequest.request(
      "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
      {
        method: http.RequestMethod.POST,
        header: {
          "Content-Type": "application/json",
          "Authorization": ""
        },
        extraData: {
          "model": "qwen-turbo-latest",
          "input": {
            "messages": [
              {
                "role": "user",
                "content": question
              }
            ]
          }
        }
      },
      (err, data: http.HttpResponse) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 'Failed to request ALiYun. Cause: %{public}s', JSON.stringify(err) ?? '');
          httpRequest.destroy();
          return;
        }

        try {
          // 记录原始响应数据用于调试
          hilog.info(0x0000, 'testTag', 'Request ALiYun success. raw data: %{public}s', JSON.stringify(data.result));

          // 解析响应数据
          let resp: ALiYunResponse = JSON.parse(data.result.toString());

          // 检查响应结构是否符合预期
          if (resp && resp.output && resp.output.text) {
            hilog.info(0x0000, 'testTag', 'Request ALiYunHttpUtils-Result. text: %{public}s', resp.output.text);
            callback(resp.output.text);
          } else {
            // 响应结构不符合预期，记录完整响应
            hilog.error(0x0000, 'testTag', 'Invalid response structure. Full response: %{public}s', JSON.stringify(resp));
            // 提供默认错误消息
            callback('抱歉，AI助手暂时无法回答，请稍后再试');
          }
        } catch (parseError) {
          // 处理JSON解析错误
          hilog.error(0x0000, 'testTag', 'Failed to parse ALiYun response. Error: %{public}s', JSON.stringify(parseError));
          callback('抱歉，AI助手暂时无法回答，请稍后再试');
        } finally {
          httpRequest.destroy();
        }
      }
    )
  }
}

export default new ALiYunHttpUtils;
