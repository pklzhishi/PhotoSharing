import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import preferences from '@ohos.data.preferences';
import { ApiResponse } from '../models/User';
import common from '@ohos.app.ability.common';
import { MultipartBuilder } from './MultipartBuilder';
import { BusinessError } from '@ohos.base';
import request from '@ohos.request';

/** HTTP请求选项接口 */
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: Record<string, string>;
  extraData?: string;
  connectTimeout?: number;
  readTimeout?: number;
}


/** HTTP请求服务 */
export class HttpService {
  private static readonly BASE_URL = 'http://115.29.241.234:8000';//115.29.241.234:8000，10.34.18.43:8000
  private static readonly TIMEOUT = 5000; // 减少超时时间到5秒
  private static tokenValue: string | null = null;
  private static preferencesStore: preferences.Preferences | null = null;
  private static context: common.Context | null = null;

  /** 设置应用上下文 */
  static setContext(context: common.Context): void {
    HttpService.context = context;
  }

  /** 发送GET请求 */
  static async get<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return HttpService.request<T>('GET', url, null, headers);
  }

  /** 发送POST请求 */
  static async post<T, B extends object | null>(url: string, data?: B, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return HttpService.request<T>('POST', url, data, headers);
  }

  /** 发送PUT请求 */
  static async put<T, B extends object>(url: string, data?: B, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return HttpService.request<T>('PUT', url, data, headers);
  }

  /** 发送DELETE请求 */
  static async delete<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return HttpService.request<T>('DELETE', url, null, headers);
  }



  /** 通用请求方法 */
  private static async request<T>(
    method: string,
    url: string,
    data?: object | null,
    headers?: Record<string, string>
  ): Promise<ApiResponse<T>> {
    return new Promise(async (resolve, reject) => {
      const httpRequest = http.createHttp();

      const requestUrl = url.startsWith('http') ? url : `${HttpService.BASE_URL}${url}`;
      console.log('=== HTTP请求详情 ===');
      console.log('请求URL:', requestUrl);
      console.log('请求方法:', method);
      console.log('请求数据:', data ? JSON.stringify(data, null, 2) : 'null');
      console.log('请求体内容:', data ? JSON.stringify(data) : '');
      console.log('请求体长度:', data ? JSON.stringify(data).length : 0);

      const requestHeaders: Record<string, string> = {
        'Content-Type': 'application/json'
      };

      if (headers) {
        Object.keys(headers).forEach(key => {
          requestHeaders[key] = headers[key];
        });
      }

      const token = await HttpService.getToken();
      console.log('当前token:', token);
      console.log('token类型:', typeof token);
      console.log('token长度:', token ? token.length : 0);
      if (token) {
        requestHeaders['token'] = token;
        console.log('已添加token到请求头');
        console.log('token值:', token);
      } else {
        console.log('没有token，请求将不包含认证信息');
        console.log('token为空，可能的原因：用户未登录或token已过期');
      }
      
      // 添加Cookie头（根据后端接口文档要求）
      requestHeaders['Cookie'] = '62C3252E1BA3A06A895FF08A44B31DD6';
      console.log('已添加Cookie到请求头');
      
      console.log('=== 请求头信息 ===');
      console.log('请求头:', JSON.stringify(requestHeaders, null, 2));

      const options: HttpRequestOptions = {
        method: method as http.RequestMethod,
        header: requestHeaders,
        extraData: data ? JSON.stringify(data) : '',
        connectTimeout: HttpService.TIMEOUT,
        readTimeout: HttpService.TIMEOUT
      };
      
      console.log('=== 请求选项详情 ===');
      console.log('请求选项:', JSON.stringify(options, null, 2));
      console.log('extraData内容:', options.extraData);

      // 添加超时保护
      const timeoutId = setTimeout(() => {
        console.error('=== 请求超时 ===');
        console.error('请求超时，强制取消');
        console.error('超时时间:', HttpService.TIMEOUT + 1000, 'ms');
        console.error('请求URL:', requestUrl);
        httpRequest.destroy();
        reject(new Error('请求超时'));
      }, HttpService.TIMEOUT + 1000); // 比实际超时时间多1秒

      httpRequest.request(requestUrl, options).then((response: http.HttpResponse) => {
        clearTimeout(timeoutId);
        console.log(`HTTP请求响应: ${response.responseCode}, URL: ${requestUrl}`);
        console.log('响应头:', response.header);
        console.log('响应内容:', response.result);
        
        if (response.responseCode === 200) {
          try {
            const result = JSON.parse(response.result as string) as ApiResponse<T>;
            console.log('请求成功:', result);
            resolve(result);
          } catch (error) {
            console.error('=== JSON解析失败 ===');
            console.error('JSON解析失败:', response.result);
            console.error('解析错误:', error);
            console.error('响应内容类型:', typeof response.result);
            // console.error('响应内容长度:', response.result ? response.result.length : 0);
            reject(new Error('JSON解析失败'));
          }
        } else {
          console.error('=== HTTP错误 ===');
          console.error(`HTTP错误: ${response.responseCode}, 响应: ${response.result}`);
          console.error('响应头:', response.header);
          console.error('响应内容:', response.result);
          console.error('响应内容类型:', typeof response.result);

          // 尝试解析响应内容
          // try {
          //   const responseData = JSON.parse(response.result as string);
          //   console.error('解析后的响应数据:', JSON.stringify(responseData, null, 2));
          // } catch (parseError) {
          //   console.error('无法解析响应内容:', parseError);
          // }

          reject(new Error(`HTTP错误: ${response.responseCode}`));
        }
      }).catch((error: Error) => {
        clearTimeout(timeoutId);
        console.error('=== 网络请求失败 ===');

        // 安全地获取错误信息
        let errorMessage = '未知错误';
        let errorStack = '';

        if (error && typeof error === 'object') {
          const errorObj = error as Error;
          errorMessage = errorObj.message || '未知错误';
          errorStack = errorObj.stack || '';
          console.error('网络请求失败:', errorMessage);
          console.error('错误类型:', typeof error);
          console.error('错误构造函数:', error.constructor.name);
          console.error('错误堆栈:', errorStack);
          console.error('请求URL:', requestUrl);
          console.error('请求方法:', method);

          // 尝试获取更详细的错误信息
          console.error('错误对象属性:', Object.keys(error));
          console.error('错误对象值:', JSON.stringify(error, null, 2));
        } else {
          console.error('网络请求失败:', String(error));
          console.error('错误类型:', typeof error);
          console.error('请求URL:', requestUrl);
          console.error('请求方法:', method);
        }

        // 确保抛出Error对象
        if (error instanceof Error) {
          reject(error);
        } else {
          reject(new Error(String(error)));
        }
      }).finally(() => {
        clearTimeout(timeoutId);
        httpRequest.destroy();
      });
    });
  }

  /** 文件上传方法（使用MultipartBuilder） */
  static async uploadFileWithBuilder<T>(
    url: string,
    filePath: string,
    fileName: string,
    content: string = '',
    headers?: Record<string, string>,
    userImageName?: string
  ): Promise<ApiResponse<T>> {
    return new Promise(async (resolve, reject) => {
      const httpRequest = http.createHttp();

      try {
        console.log('a=== 使用MultipartBuilder上传文件 ===');
        console.log('a文件路径:', filePath);
        console.log('a文件名:', fileName);
        console.log('a内容描述:', content);
        console.log('a用户图片名称:', userImageName);

        const requestUrl = url.startsWith('http') ? url : `${HttpService.BASE_URL}${url}`;

        // 获取文件扩展名并确定MIME类型
        const fileExtension = fileName.toLowerCase().split('.').pop() || '';
        const mimeType = MultipartBuilder.getMimeType(fileExtension);

        console.log('MultipartBuilder调试信息:');
        console.log('- 文件名:', fileName);
        console.log('- 文件扩展名:', fileExtension);
        console.log('- MIME类型:', mimeType);
        console.log('- 内容描述:', content);
        console.log('- 文件路径:', filePath);

        // 使用MultipartBuilder构建请求体
        const builder = new MultipartBuilder();
        const formDataBody = builder
          .addFile('multipartFile', filePath, fileName, mimeType)
          .addFormField('imageName', userImageName || fileName)
          .addFormField('content', content)
          .build();

        console.log('请求体长度:', formDataBody.length);
        console.log('Content-Type:', builder.getContentType());

        // 配置请求头
        const requestHeaders: Record<string, string> = {
          'Content-Type': 'multipart/form-data'
        };

        if (headers) {
          Object.keys(headers).forEach(key => {
            requestHeaders[key] = headers[key];
          });
        }

        // 添加token和Cookie
        const token = await HttpService.getToken();
        if (token) {
          requestHeaders['token'] = token;
        }
        requestHeaders['Cookie'] = '62C3252E1BA3A06A895FF08A44B31DD6';

        console.log('请求头:', requestHeaders);
        console.log('请求URL:', requestUrl);

        const options: HttpRequestOptions = {
          method: http.RequestMethod.POST,
          header: requestHeaders,
          extraData: formDataBody,
          connectTimeout: HttpService.TIMEOUT,
          readTimeout: HttpService.TIMEOUT
        };

        httpRequest.request(requestUrl, options).then((response: http.HttpResponse) => {
          console.log(`MultipartBuilder上传响应: ${response.responseCode}, URL: ${requestUrl}`);
          if (response.responseCode === 200) {
            try {
              const result = JSON.parse(response.result as string) as ApiResponse<T>;
              console.log('MultipartBuilder上传成功:', result);
              resolve(result);
            } catch (error) {
              console.error('MultipartBuilder上传JSON解析失败:', response.result);
              reject(new Error('JSON解析失败'));
            }
          } else {
            console.error(`MultipartBuilder上传HTTP错误: ${response.responseCode}, 响应: ${response.result}`);
            reject(new Error(`HTTP错误: ${response.responseCode}`));
          }
        }).catch((error: Error) => {
          console.error('MultipartBuilder上传网络请求失败:', error.message);
          reject(error);
        }).finally(() => {
          httpRequest.destroy();
        });
      } catch (error) {
        console.error('MultipartBuilder上传处理失败:', error);
        reject(new Error('文件处理失败'));
      }
    });
  }

  /** 文件上传方法（使用鸿蒙原生FormData） */
  static async uploadFileNative<T>(
    url: string,
    filePath: string,
    fileName: string,
    content: string = '',
    headers?: Record<string, string>
  ): Promise<ApiResponse<T>> {
    return new Promise(async (resolve, reject) => {
      const httpRequest = http.createHttp();

      try {
        console.log('使用鸿蒙原生FormData上传文件');
        const requestUrl = url.startsWith('http') ? url : `${HttpService.BASE_URL}${url}`;

        // 1. 读取本地图片文件（保持原逻辑，确保获取Uint8Array格式的文件内容）
        const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(file.fd);
        const buffer = new ArrayBuffer(stat.size);
        await fs.read(file.fd, buffer);
        await fs.close(file.fd);
        const fileContent = new Uint8Array(buffer); // 关键：文件内容必须是Uint8Array

        // 2. 获取MIME类型（保持原逻辑）
        const fileExtension = fileName.toLowerCase().split('.').pop() || '';
        const mimeType = HttpService.getMimeType(fileExtension);

        // 3. 构建multipart/form-data请求体（使用已读取的文件内容）
        const boundary = '----WebKitFormBoundary' + Math.random().toString(16).substring(2);
        const formDataBody = HttpService.buildMultipartFormDataWithContent(boundary, fileContent, fileName, mimeType, content);

        // 4. 配置请求头
        const requestHeaders: Record<string, string> = {
          'Content-Type': `multipart/form-data; boundary=${boundary}`
        };

        if (headers) {
          Object.keys(headers).forEach(key => {
            requestHeaders[key] = headers[key];
          });
        }

        // 添加token和Cookie
        const token = await HttpService.getToken();
        if (token) {
          requestHeaders['token'] = token;
        }
        requestHeaders['Cookie'] = '62C3252E1BA3A06A895FF08A44B31DD6';

        console.log('请求头:', requestHeaders);
        console.log('请求URL:', requestUrl);

        // 5. 发送请求
        const options: HttpRequestOptions = {
          method: http.RequestMethod.POST,
          header: requestHeaders,
          extraData: formDataBody,
          connectTimeout: HttpService.TIMEOUT,
          readTimeout: HttpService.TIMEOUT
        };

        // 后续请求逻辑保持不变...
        httpRequest.request(requestUrl, options).then((response: http.HttpResponse) => {
          console.log(`FormData上传响应: ${response.responseCode}, URL: ${requestUrl}`);
          if (response.responseCode === 200) {
            try {
              const result = JSON.parse(response.result as string) as ApiResponse<T>;
              console.log('FormData上传成功:', result);
              resolve(result);
            } catch (error) {
              console.error('FormData上传JSON解析失败:', response.result);
              reject(new Error('JSON解析失败'));
            }
          } else {
            console.error(`FormData上传HTTP错误: ${response.responseCode}, 响应: ${response.result}`);
            reject(new Error(`HTTP错误: ${response.responseCode}`));
          }
        }).catch((error: Error) => {
          console.error('FormData上传网络请求失败:', error.message);
          reject(error);
        }).finally(() => {
          httpRequest.destroy();
        });
      } catch (error) {
        console.error('FormData上传处理失败:', error);
        reject(new Error('文件处理失败'));
      }
    });
  }
  /** 文件上传方法 */
  static async uploadFile<T>(
    url: string,
    filePath: string,
    fileName: string,
    content: string = '',
    headers?: Record<string, string>,
    userImageName?: string
  ): Promise<ApiResponse<T>> {
    return new Promise(async (resolve, reject) => {
      const httpRequest = http.createHttp();

      try {
        console.log('a=== HttpService.uploadFile 开始 ===');
        console.log('a文件路径:', filePath);
        console.log('a文件名:', fileName);

        // 检查文件是否存在
        const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(file.fd);
        console.log('a文件大小:', stat.size, '字节');
        fs.closeSync(file);

        const requestUrl = url.startsWith('http') ? url : `${HttpService.BASE_URL}${url}`;

        const requestHeaders: Record<string, string> = {};

        if (headers) {
          Object.keys(headers).forEach(key => {
            requestHeaders[key] = headers[key];
          });
        }

        const token = await HttpService.getToken();
        if (token) {
          requestHeaders['token'] = token;
        }

        // 添加Cookie头部
        requestHeaders['Cookie'] = '62C3252E1BA3A06A895FF08A44B31DD6';

        console.log('a请求头:', requestHeaders);
        console.log('a请求URL:', requestUrl);
        console.log('a文件名:', fileName);
        console.log('a内容描述:', content);

        // 构建multipart/form-data请求体
        const boundary = '----WebKitFormBoundary' + Math.random().toString(16).substring(2);
        console.log('a构建multipart数据，boundary:', boundary);
        const formDataBody = HttpService.buildFileMultipartFormData(boundary, filePath, fileName, content, userImageName);

        requestHeaders['Content-Type'] = `multipart/form-data; boundary=${boundary}`;

        console.log('a请求体长度:', formDataBody.length);
        console.log('a最终Content-Type:', requestHeaders['Content-Type']);

        const options: HttpRequestOptions = {
          method: http.RequestMethod.POST,
          header: requestHeaders,
          extraData: formDataBody,
          connectTimeout: HttpService.TIMEOUT,
          readTimeout: HttpService.TIMEOUT
        };

        console.log('a开始发送网络请求...');
        console.log('a请求URL:', requestUrl);
        console.log('a请求头:', requestHeaders);
        console.log('a请求选项:', JSON.stringify(options));

        httpRequest.request(requestUrl, options).then((response: http.HttpResponse) => {
          console.log(`a文件上传响应: ${response.responseCode}, URL: ${requestUrl}`);
          console.log('a响应头:', response.header);
          console.log('a响应内容:', response.result);

          if (response.responseCode === 200) {
            try {
              const result = JSON.parse(response.result as string) as ApiResponse<T>;
              console.log('a文件上传成功，响应详情:');
              console.log('a- 响应码:', result.code);
              console.log('a- 响应消息:', result.msg);
              console.log('a- 响应数据:', result.data);
              console.log('a- 完整响应:', JSON.stringify(result));
              resolve(result);
            } catch (error) {
              console.error('a文件上传JSON解析失败:', response.result);
              console.error('a原始响应内容:', response.result);
              reject(new Error('JSON解析失败'));
            }
          } else {
            console.error(`a文件上传HTTP错误: ${response.responseCode}, 响应: ${response.result}`);
            reject(new Error(`HTTP错误: ${response.responseCode}`));
          }
        }).catch((error: Error) => {
          console.error('文件上传网络请求失败:', error.message);
          console.error('错误堆栈:', error.stack);
          reject(error);
        }).finally(() => {
          console.log('网络请求完成，销毁连接');
          httpRequest.destroy();
        });
      } catch (error) {
        console.error('文件处理失败:', error);
        reject(new Error('文件处理失败'));
      }
    });
  }


  /** 构建multipart/form-data请求体（使用已读取的文件内容） */
  private static buildMultipartFormDataWithContent(boundary: string, fileContent: Uint8Array, fileName: string, mimeType: string, content: string = ''): string {
    try {
      // 将文件内容转换为base64
      const base64 = HttpService.arrayBufferToBase64(fileContent);

      console.log('文件扩展名:', fileName.split('.').pop());
      console.log('MIME类型:', mimeType);

      // 构建multipart/form-data格式
      let body = '';

      // 添加multipartFile字段（文件内容）
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="multipartFile"; filename="${fileName}"\r\n`;
      body += `Content-Type: ${mimeType}\r\n`;
      body += `Content-Transfer-Encoding: base64\r\n\r\n`;
      body += base64;
      body += `\r\n`;

      // 添加imageName字段
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="imageName"\r\n\r\n`;
      body += fileName;
      body += `\r\n`;

      // 添加content字段
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="content"\r\n\r\n`;
      body += content;
      body += `\r\n`;

      // 结束边界
      body += `--${boundary}--\r\n`;

      return body;
    } catch (error) {
      console.error('构建multipart/form-data失败:', error);
      throw new Error('文件处理失败');
    }
  }

  /** 构建文件multipart/form-data请求体 */
  private static buildFileMultipartFormData(boundary: string, filePath: string, fileName: string, content: string = '', userImageName?: string): string {
    try {
      // 读取文件内容
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      // 将文件内容转换为base64
      const uint8Array = new Uint8Array(buffer);
      const base64 = HttpService.arrayBufferToBase64(uint8Array);

      // 获取文件扩展名并确定MIME类型
      const fileExtension = fileName.toLowerCase().split('.').pop() || '';
      const mimeType = HttpService.getMimeType(fileExtension);

      console.log('a文件扩展名:', fileExtension);
      console.log('aMIME类型:', mimeType);
      console.log('a原始文件大小:', uint8Array.length, '字节');
      console.log('aBase64编码后长度:', base64.length, '字符');
      console.log('aBase64前20个字符:', base64.substring(0, 20));
      console.log('aBase64后20个字符:', base64.substring(base64.length - 20));
      console.log('aBase64是否包含换行符:', base64.includes('\n'));
      console.log('aBase64是否包含回车符:', base64.includes('\r'));
      console.log('aBase64是否包含特殊字符:', /[^A-Za-z0-9+/=]/.test(base64));

      // 构建multipart/form-data格式
      let body = '';

      // 添加multipartFile字段（文件内容）
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="multipartFile"; filename="${fileName}"\r\n`;
      body += `Content-Type: ${mimeType}\r\n`;
      body += `Content-Transfer-Encoding: base64\r\n\r\n`;
      body += base64;
      body += `\r\n`;

      console.log('a添加multipartFile字段，文件名:', fileName);
      console.log('aBase64数据长度:', base64.length);
      console.log('aBase64数据前50字符:', base64.substring(0, 50));
      console.log('aBase64数据后50字符:', base64.substring(base64.length - 50));
      console.log('a构建的multipart body长度:', body.length);

      // 添加imageName字段
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="imageName"\r\n\r\n`;
      body += userImageName || fileName;
      body += `\r\n`;

      console.log('a添加imageName字段，值:', userImageName || fileName);
      console.log('a传递给后端的imageName:', userImageName || fileName);
      console.log('a传递给后端的multipartFile文件名:', fileName);

      // 添加content字段
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="content"\r\n\r\n`;
      body += content;
      body += `\r\n`;

      console.log('a添加content字段，值:', content);

      // 结束边界
      body += `--${boundary}--\r\n`;

      return body;
    } catch (error) {
      console.error('构建文件multipart/form-data失败:', error);
      throw new Error('文件读取失败');
    }
  }

  /** 根据文件扩展名获取MIME类型 */
  private static getMimeType(extension: string): string {
    const mimeTypes: Record<string, string> = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp'
    };

    return mimeTypes[extension] || 'image/jpeg';
  }

  /** 将ArrayBuffer转换为Base64 */
  private static arrayBufferToBase64(buffer: Uint8Array): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const result: string[] = [];
    let i = 0;

    while (i < buffer.length) {
      const a = buffer[i++];
      const b = i < buffer.length ? buffer[i++] : 0;
      const c = i < buffer.length ? buffer[i++] : 0;

      const bitmap = (a << 16) | (b << 8) | c;

      result.push(chars.charAt((bitmap >> 18) & 63));
      result.push(chars.charAt((bitmap >> 12) & 63));
      result.push(i - 2 < buffer.length ? chars.charAt((bitmap >> 6) & 63) : '=');
      result.push(i - 1 < buffer.length ? chars.charAt(bitmap & 63) : '=');
    }

    return result.join('');
  }


  /** 获取存储的token */
  static async getToken(): Promise<string | null> {
    // 先检查内存中的token
    if (HttpService.tokenValue) {
      console.log('从内存获取token:', HttpService.tokenValue);
      return HttpService.tokenValue;
    }

    // 从持久化存储中获取token
    try {
      if (HttpService.context) {
        // 修复：正确等待Promise并处理返回值
        const preferencesStore = await preferences.getPreferences(HttpService.context as common.UIAbilityContext, 'user_preferences');
        const token = await preferencesStore.get('user_token', '') as string;
        if (token) {
          HttpService.tokenValue = token;
          console.log('从持久化存储获取token:', token);
          return token;
        }
      }
    } catch (error) {
      console.error('获取token失败:', error);
    }

    console.log('没有找到token');
    return null;
  }

  /** 保存token到本地存储 */
  static async saveToken(token: string): Promise<void> {
    console.log('保存token:', token);
    HttpService.tokenValue = token;

    // 尝试保存到持久化存储
    try {
      if (HttpService.context) {
        // 修复：正确等待Promise并处理返回值
        const preferencesStore = await preferences.getPreferences(HttpService.context as common.UIAbilityContext, 'user_preferences');
        await preferencesStore.put('user_token', token);
        await preferencesStore.flush();
        console.log('token已保存到持久化存储');
      }
    } catch (error) {
      console.error('保存token到持久化存储失败:', error);
      console.log('继续使用内存存储');
    }
  }

  /** 清除token */
  static async clearToken(): Promise<void> {
    HttpService.tokenValue = null;

    // 从持久化存储中清除token
    try {
      if (HttpService.context) {
        // 修复：正确等待Promise并处理返回值
        const preferencesStore = await preferences.getPreferences(HttpService.context as common.UIAbilityContext, 'user_preferences');
        await preferencesStore.delete('user_token');
        await preferencesStore.flush();
        console.log('token已从持久化存储清除');
      }
    } catch (error) {
      console.error('清除token失败:', error);
    }
  }

  /** 使用官方推荐的文件上传方法（适配现有接口） */
  static async uploadFileOfficial<T>(
    url: string,
    filePath: string,
    fileName: string,
    content: string = ''
  ): Promise<ApiResponse<T>> {
    return new Promise<ApiResponse<T>>(async (resolve, reject) => {
      try {
        // 读取文件内容
        const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(file.fd);
        const buffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buffer);
        fs.closeSync(file);

        console.log('使用官方方法上传文件:', filePath);
        console.log('文件大小:', stat.size, '字节');

        // 调用postFile方法
        const result = await HttpService.postFile<T>(url, buffer, fileName);
        resolve(result);
      } catch (error) {
        console.error('官方方法文件处理失败:', error);
        reject(new Error('文件处理失败'));
      }
    });
  }

  /** 使用官方推荐的文件上传方法 */
  static async postFile<T>(url: string, fileData: ArrayBuffer, fileName: string): Promise<ApiResponse<T>> {
    return new Promise<ApiResponse<T>>((resolve, reject) => {
      // 创建HTTP请求对象
      const httpRequest = http.createHttp();

      const requestUrl = url.startsWith('http') ? url : `${HttpService.BASE_URL}${url}`;

      // 获取token
      HttpService.getToken().then(token => {
        const headers: Record<string, string> = {
          'Content-Type': 'multipart/form-data'
        };

        if (token) {
          headers['token'] = token;
        }
        headers['Cookie'] = '62C3252E1BA3A06A895FF08A44B31DD6';

        console.log('使用官方postFile方法上传文件');
        console.log('请求URL:', requestUrl);
        console.log('文件名:', fileName);
        console.log('请求头:', headers);

        // 发起POST请求
        httpRequest.request(
          requestUrl,
          {
            method: http.RequestMethod.POST,
            header: headers,
            // 配置表单数据
            multiFormDataList: [
              {
                name: 'multipartFile',  // 与服务端定义的参数名保持一致
                contentType: 'image/*', // 图片类型
                data: fileData, // 文件内容（ArrayBuffer）
                remoteFileName: fileName // 文件名
              }
            ],
            expectDataType: http.HttpDataType.STRING, // 预期返回数据类型
            connectTimeout: HttpService.TIMEOUT,
            readTimeout: HttpService.TIMEOUT
          },
          (err: Error | undefined, data: http.HttpResponse) => {
            // 清理HTTP资源的函数
            const cleanup = () => {
              try {
                httpRequest.destroy();
                console.info('[HTTP] 请求资源已销毁');
              } catch (destroyError) {
                console.error('[HTTP] 销毁请求时出错:', destroyError);
              }
            };

            // 处理响应结果
            if (err) {
              console.error('postFile上传失败:', err.message);
              cleanup();
              reject(new Error(err.message));
            } else {
              console.log(`postFile上传响应: ${data.responseCode}, URL: ${requestUrl}`);
              if (data.responseCode === 200) {
                try {
                  const result = JSON.parse(data.result as string) as ApiResponse<T>;
                  console.log('postFile上传成功:', result);
                  cleanup();
                  resolve(result);
                } catch (parseError) {
                  console.error('postFile上传JSON解析失败:', data.result);
                  cleanup();
                  reject(new Error('JSON解析失败'));
                }
              } else {
                console.error(`postFile上传HTTP错误: ${data.responseCode}, 响应: ${data.result}`);
                cleanup();
                reject(new Error(`HTTP错误: ${data.responseCode}`));
              }
            }
          }
        );
      }).catch((error: BusinessError) => { // 显式指定error类型为BusinessError
        console.error('获取token失败:', error);
        httpRequest.destroy();
        reject(error);
      });
    });
  }

  /** 使用@ohos.request.uploadFile进行文件上传（推荐方法） */
  static async uploadFileWithRequest<T>(
    url: string,
    filePath: string,
    fileName: string,
    content: string = ''
  ): Promise<ApiResponse<T>> {
    return new Promise<ApiResponse<T>>(async (resolve, reject) => {
      try {
        const requestUrl = url.startsWith('http') ? url : `${HttpService.BASE_URL}${url}`;

        // 获取token
        const token = await HttpService.getToken();

        // 构建请求头
        const headers: Record<string, string> = {
          'Content-Type': 'multipart/form-data'
        };

        if (token) {
          headers['token'] = token;
        }
        headers['Cookie'] = '62C3252E1BA3A06A895FF08A44B31DD6';

        console.log('=== HttpService.uploadFileWithRequest 开始 ===');
        console.log('使用@ohos.request.uploadFile上传文件');
        console.log('请求URL:', requestUrl);
        console.log('文件路径:', filePath);
        console.log('文件名:', fileName);
        console.log('请求头:', headers);
        console.log('Context是否存在:', HttpService.context !== null);

        // 获取文件扩展名
        const fileExtension = fileName.toLowerCase().split('.').pop() || 'jpg';

        // 使用@ohos.request.uploadFile上传
        console.log('准备调用 request.uploadFile...');
        console.log('Context类型:', typeof HttpService.context);
        console.log('文件扩展名:', fileExtension);

        console.log('准备发送的请求参数:');
        console.log('- URL:', requestUrl);
        console.log('- 文件名:', fileName);
        console.log('- 文件路径:', filePath);
        console.log('- 内容描述:', content);
        console.log('- 请求头:', headers);

        const uploader = await request.uploadFile(HttpService.context!, {
          method: 'POST',
          url: requestUrl,
          header: headers,
          files: [{
            filename: fileName,
            type: fileExtension,
            name: 'multipartFile', // 与服务端参数名保持一致
            uri: filePath
          }],
          data: [
            { name: 'imageName', value: fileName },
            { name: 'content', value: content }
          ]
        });

        console.log('开始设置事件监听器...');

        // 监听上传进度
        uploader.on('progress', (uploadedSize: number, totalSize: number) => {
          const progress = Math.round((uploadedSize / totalSize) * 100);
          console.log(`上传进度: ${progress}% (${uploadedSize}/${totalSize})`);
        });

        // 监听上传完成
        uploader.on('complete', (data: Array<object>) => {
          console.log('=== 上传完成事件触发 ===');
          console.log('上传完成数据:', data);
          console.log('数据类型:', typeof data);
          console.log('数据长度:', data.length);
          try {
            // 从TaskState数组中获取响应数据
            const responseData = data[0] as object;
            console.log('响应数据:', responseData);
            const result = responseData as ApiResponse<T>;
            console.log('request.uploadFile上传成功:', result);
            resolve(result);
          } catch (parseError) {
            console.error('request.uploadFile JSON解析失败:', data);
            console.error('解析错误:', parseError);
            reject(new Error('JSON解析失败'));
          }
        });

        // 监听上传失败
        uploader.on('fail', (data: Array<object>) => {
          console.error('=== 上传失败事件触发 ===');
          console.error('request.uploadFile上传失败:', data);
          console.error('失败数据类型:', typeof data);
          reject(new Error('上传失败'));
        });

        console.log('事件监听器设置完成，等待上传结果...');

      } catch (error) {
        console.error('request.uploadFile处理失败:', error);
        reject(new Error('文件处理失败'));
      }
    });
  }
}
