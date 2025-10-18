export type JsonValue = string | number | boolean | null | undefined;

/** 登录请求参数类型 */
export interface LoginRequest {
  userAccount: string;
  password: string;
}

/** 注册请求参数类型 */
export interface RegisterRequest {
  userAccount: string;
  password: string;
  username: string;
  telephoneNumber: string;
}

/** API响应通用类型 */
export interface ApiResponse<T = void> {
  code?: number;
  msg?: string;
  data?: T;
}

/** 登录成功返回的数据结构（至少包含 token） */
export interface LoginSuccessData {
  token: string;
}

/** 用户信息数据结构 */
export interface UserInfo {
  username?: string;
  userAccount?: string;
  telephoneNumber?: string;
  userId?: number;
  headshotUrl?: string; // 用户头像URL
}

/** 用户基本信息数据结构（对应 getUserBasicInformation API） */
export interface UserBasicInfo {
  username?: string;
  headshotUrl?: string;
  email?: string;
}