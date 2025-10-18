/**
 * 评论数据模型
 */
export interface Comment {
  id?: number; // 服务器返回的评论ID
  commentId?: number; // 兼容旧字段
  content: string;
  imageId?: number; // 可选，因为服务器不返回
  userId?: number;
  username?: string;
  createTime?: string; // 兼容旧字段
  commentsTime?: string; // 服务器返回的时间字段
  userAvatarUrl?: string; // 评论者头像URL
  headshotUrl?: string; // 服务器返回的头像字段
}

/**
 * 发表评论请求
 */
export interface PostCommentRequest {
  content: string;
  imageId: number;
}

/**
 * 删除评论请求
 */
export interface DeleteCommentRequest {
  commentId: number;
  imageId?: number;
}
