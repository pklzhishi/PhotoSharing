/**
 * 评论数据模型
 */
export interface Comment {
  commentId?: number;
  content: string;
  imageId: number;
  userId?: number;
  username?: string;
  createTime?: string;
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
