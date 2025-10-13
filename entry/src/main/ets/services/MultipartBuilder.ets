import http from '@ohos.net.http';
import fs from '@ohos.file.fs';

/**
 * ArkTS版本的MultipartBuilder
 * 用于构建multipart/form-data请求体
 */
export class MultipartBuilder {
  private boundary: string;
  private parts: string[] = [];

  constructor() {
    this.boundary = '----WebKitFormBoundary' + Math.random().toString(16).substring(2);
  }

  /**
   * 添加表单字段
   * @param name 字段名
   * @param value 字段值
   * @returns MultipartBuilder实例
   */
  addFormField(name: string, value: string): MultipartBuilder {
    let part = '';
    part += `--${this.boundary}\r\n`;
    part += `Content-Disposition: form-data; name="${name}"\r\n\r\n`;
    part += value;
    part += `\r\n`;
    
    this.parts.push(part);
    return this;
  }

  /**
   * 添加文件字段
   * @param name 字段名
   * @param filePath 文件路径
   * @param fileName 文件名
   * @param mimeType MIME类型
   * @returns MultipartBuilder实例
   */
  addFile(name: string, filePath: string, fileName: string, mimeType: string = 'application/octet-stream'): MultipartBuilder {
    try {
      // 读取文件内容
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      // 检查文件头，确定实际格式
      const uint8Array = new Uint8Array(buffer);
      const actualMimeType = this.detectImageType(uint8Array);
      console.log('检测到的实际MIME类型:', actualMimeType);
      console.log('文件大小:', stat.size, '字节');
      console.log('文件头:', Array.from(uint8Array.slice(0, 10)).map(b => b.toString(16).padStart(2, '0')).join(' '));
      console.log('原始MIME类型参数:', mimeType);
      console.log('是否使用检测到的MIME类型:', actualMimeType !== 'application/octet-stream');

      // 将文件内容转换为base64
      const base64 = this.arrayBufferToBase64(uint8Array);

      let part = '';
      part += `--${this.boundary}\r\n`;
      part += `Content-Disposition: form-data; name="${name}"; filename="${fileName}"\r\n`;
      part += `Content-Type: ${actualMimeType}\r\n`;
      part += `Content-Transfer-Encoding: base64\r\n\r\n`;
      part += base64;
      part += `\r\n`;

      this.parts.push(part);
      return this;
    } catch (error) {
      console.error('添加文件失败:', error);
      throw new Error('文件读取失败');
    }
  }

  /**
   * 构建multipart请求体
   * @returns 完整的multipart/form-data字符串
   */
  build(): string {
    let body = '';
    
    // 添加所有部分
    for (const part of this.parts) {
      body += part;
    }
    
    // 添加结束边界
    body += `--${this.boundary}--\r\n`;
    
    return body;
  }

  /**
   * 获取boundary
   * @returns boundary字符串
   */
  getBoundary(): string {
    return this.boundary;
  }

  /**
   * 获取Content-Type头部
   * @returns Content-Type字符串
   */
  getContentType(): string {
    return `multipart/form-data; boundary=${this.boundary}`;
  }

  /**
   * 将ArrayBuffer转换为Base64
   * @param buffer Uint8Array
   * @returns Base64字符串
   */
  private arrayBufferToBase64(buffer: Uint8Array): string {
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

  /**
   * 根据文件扩展名获取MIME类型
   * @param extension 文件扩展名
   * @returns MIME类型
   */
  static getMimeType(extension: string): string {
    const mimeTypes: Record<string, string> = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'json': 'application/json'
    };

    return mimeTypes[extension.toLowerCase()] || 'application/octet-stream';
  }

  /**
   * 检查文件格式是否被支持
   * @param extension 文件扩展名
   * @returns 是否支持
   */
  static isSupportedImageFormat(extension: string): boolean {
    const supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return supportedFormats.includes(extension.toLowerCase());
  }

  /**
   * 检测图片文件的实际类型
   * @param buffer 文件内容
   * @returns MIME类型
   */
  private detectImageType(buffer: Uint8Array): string {
    // 检查文件头
    if (buffer.length < 4) {
      return 'application/octet-stream';
    }

    // JPEG: FF D8 FF
    if (buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF) {
      return 'image/jpeg';
    }

    // PNG: 89 50 4E 47
    if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47) {
      return 'image/png';
    }

    // GIF: 47 49 46 38
    if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x38) {
      return 'image/gif';
    }

    // BMP: 42 4D
    if (buffer[0] === 0x42 && buffer[1] === 0x4D) {
      return 'image/bmp';
    }

    // WebP: 52 49 46 46
    if (buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46) {
      return 'image/webp';
    }

    console.warn('无法识别的文件格式，使用默认MIME类型');
    return 'application/octet-stream';
  }
}
