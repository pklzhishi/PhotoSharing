import { UserInfo,UserBasicInfo } from '../models/User';
import { HttpService } from './HttpService';
import { ApiService } from './ApiService';

/**
 * 用户状态管理类
 * 用于在应用内共享用户信息，特别是头像信息
 */
export class UserState {
  private static userInfo: UserInfo | null = null;
  private static userBasicInfo: UserBasicInfo | null = null;
  private static listeners: Array<(userInfo: UserInfo | null) => void> = [];

  /**
   * 获取当前用户信息
   */
  static getUserInfo(): UserInfo | null {
    return UserState.userInfo;
  }

  static getUserBasicInfo(): UserBasicInfo | null {
    return UserState.userInfo;
  }


  /**
   * 设置用户信息
   */
  static setUserInfo(userInfo: UserInfo | null): void {
    UserState.userInfo = userInfo;
    // 通知所有监听器
    UserState.listeners.forEach(listener => listener(userInfo));
  }

  /**
   * 添加用户信息变化监听器
   */
  static addListener(listener: (userInfo: UserInfo | null) => void): void {
    UserState.listeners.push(listener);
  }

  /**
   * 移除用户信息变化监听器
   */
  static removeListener(listener: (userInfo: UserInfo | null) => void): void {
    const index = UserState.listeners.indexOf(listener);
    if (index > -1) {
      UserState.listeners.splice(index, 1);
    }
  }

  /**
   * 刷新用户信息（从服务器获取最新信息）
   */
  static async refreshUserInfo(): Promise<void> {
    try {
      const response = await ApiService.getUserInfo();
      if (response.code === 1 && response.data) {
        UserState.setUserInfo(response.data);
        console.log('用户信息已刷新:', response.data);
      }
    } catch (error) {
      console.error('刷新用户信息失败:', error);
    }
  }

  /**
   * 更新用户头像
   */
  static updateUserAvatar(avatarUrl: string): void {
    if (UserState.userInfo) {
      UserState.userInfo.headshotUrl = avatarUrl;
      UserState.setUserInfo(UserState.userInfo);
    }
  }

  /**
   * 清除用户信息
   */
  static clearUserInfo(): void {
    UserState.setUserInfo(null);
  }
}
